// SoonGong RC-02 addition. Upstream image_picker license remains in LICENSE.
package io.flutter.plugins.imagepicker;

import android.content.Context;
import android.content.SharedPreferences;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;
import java.io.Closeable;
import java.io.File;
import java.io.IOException;
import java.nio.charset.StandardCharsets;

import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import org.json.JSONObject;

/** The app registers a task before any plugin file can be created. */
public final class OwnedImageStore {
  private static Context app;
  private static SharedPreferences prefs;
  private static Lease current;
  private static final ThreadLocal<Lease> callbackOwner = new ThreadLocal<>();
  private static final String CHANNEL = "co.byite.soongong/picker_owner";
  private OwnedImageStore() {}

  static final class Lease {
    final String scope, task;
    boolean started, finished, cancelled, recovered;
    int writers;
    final Set<Closeable> streams = new HashSet<>();
    Lease(String scope, String task, boolean recovered) {
      this.scope = scope; this.task = task; this.recovered = recovered;
    }
    boolean matches(String scope, String task) { return this.scope.equals(scope) && this.task.equals(task); }
  }

  public static synchronized void register(Context context, BinaryMessenger messenger) {
    initialize(context);
    new MethodChannel(messenger, CHANNEL).setMethodCallHandler((call, result) -> {
      try {
        String scope = call.argument("scope"), task = call.argument("task");
        switch (call.method) {
          case "prepare": prepare(scope, task); result.success(null); break;
          case "status": result.success(status(scope, task)); break;
          case "cancel": result.success(cancel(scope, task)); break;
          case "release": release(scope, task); result.success(null); break;
          case "recover": result.success(recover()); break;
          default: result.notImplemented();
        }
      } catch (Exception error) {
        // Never serialize an exception containing a photo path or provider URI.
        result.error("owned_picker_unavailable", null, null);
      }
    });
  }

  static synchronized void initialize(Context context) {
    app = context.getApplicationContext();
    prefs = app.getSharedPreferences("soongong_picker_owner_v1", Context.MODE_PRIVATE);
    if (current == null && prefs.contains("scope")) {
      current = new Lease(prefs.getString("scope", ""), prefs.getString("task", ""), true);
    }
  }

  private static boolean uuid(String value) {
    if (value == null) return false;
    try { return UUID.fromString(value).toString().equals(value); }
    catch (IllegalArgumentException error) { return false; }
  }

  /** No mkdirs: a revoked/deleted task must never be recreated by a late callback. */
  public static File payload(Context context, String scope, String task, String kind) throws IOException {
    if (!uuid(scope) || !uuid(task)) throw new IOException("invalid_owner");
    File cache = context.getCacheDir().getCanonicalFile();
    File root = new File(cache, "soongong-owned-v1");
    File scopeDir = new File(root, scope), taskDir = new File(scopeDir, task);
    File payload = new File(taskDir, "payload"), marker = new File(taskDir, "marker.json");
    for (File directory : new File[] {root, scopeDir, taskDir, payload}) {
      if (!directory.isDirectory() || !directory.getAbsoluteFile().equals(directory.getCanonicalFile()))
        throw new IOException("invalid_owned_directory");
    }
    if (new File(scopeDir, ".revoked").exists() || new File(taskDir, ".delete").exists())
      throw new IOException("owner_revoked");
    if (!marker.isFile() || !marker.getAbsoluteFile().equals(marker.getCanonicalFile()) || marker.length() > 4096)
      throw new IOException("invalid_marker");
    try {
      JSONObject data = new JSONObject(new String(readMarker(marker), StandardCharsets.UTF_8));
      if (data.getInt("version") != 1 || !scope.equals(data.getString("scope")) ||
          !task.equals(data.getString("task")) || !kind.equals(data.getString("kind")) ||
          data.getLong("created") <= 0 || data.getLong("expires") <= data.getLong("created"))
        throw new IOException("invalid_marker");
    } catch (org.json.JSONException error) { throw new IOException("invalid_marker"); }
    return payload;
  }

  private static byte[] readMarker(File marker) throws IOException {
    try (java.io.FileInputStream in = new java.io.FileInputStream(marker);
        java.io.ByteArrayOutputStream out = new java.io.ByteArrayOutputStream()) {
      byte[] buffer = new byte[1024]; int count;
      while ((count = in.read(buffer)) != -1) {
        if (out.size() + count > 4096) throw new IOException("invalid_marker");
        out.write(buffer, 0, count);
      }
      return out.toByteArray();
    }
  }

  static synchronized void prepare(String scope, String task) throws IOException {
    if (current != null) throw new IOException("picker_busy");
    payload(app, scope, task, "picker");
    // commit before launching the OS picker, no absolute path/account identifier.
    if (!prefs.edit().putString("scope", scope).putString("task", task).commit())
      throw new IOException("owner_not_durable");
    current = new Lease(scope, task, false);
  }

  static synchronized Map<String, Boolean> status(String scope, String task) {
    Map<String, Boolean> result = new HashMap<>();
    boolean matches = current != null && current.matches(scope, task);
    result.put("active", matches && (current.writers > 0 || (current.started && !current.finished)));
    result.put("unknown", (matches && current.recovered) || (prefs != null && prefs.getBoolean("legacy_unknown", false)));
    return result;
  }

  static synchronized Map<String, Boolean> cancel(String scope, String task) {
    if (current != null && current.matches(scope, task) && !current.cancelled) {
      current.cancelled = true;
      Set<Closeable> streams = new HashSet<>(current.streams);
      // A remote provider's close() may block. Never call it on the channel/main
      // thread or under this monitor. The writer stays active until its finally.
      Thread closer = new Thread(() -> {
        for (Closeable stream : streams) {
          try { stream.close(); } catch (IOException ignored) { /* writer reports failure */ }
        }
      }, "owned-picker-cancel");
      closer.setDaemon(true); closer.start();
    }
    return status(scope, task);
  }

  static synchronized void release(String scope, String task) throws IOException {
    if (current == null || !current.matches(scope, task)) return;
    if (Boolean.TRUE.equals(status(scope, task).get("active"))) throw new IOException("picker_busy");
    clearOwner();
  }

  static synchronized Map<String, Boolean> recover() throws IOException {
    if (current == null) return status(null, null);
    Map<String, Boolean> state = status(current.scope, current.task);
    if (Boolean.TRUE.equals(state.get("active"))) return state;
    if (current.recovered) {
      // Persisted lease + absent in-process writers proves the original app process died.
      // Fence fresh external opens before unlinking; an already opened OS descriptor is
      // outside our recall boundary and may remain open after unlink (not secure erase).
      if (!uuid(current.scope) || !uuid(current.task)) throw new IOException("invalid_owner");
      File task = new File(new File(new File(app.getCacheDir().getCanonicalFile(), "soongong-owned-v1"), current.scope), current.task);
      if (task.exists()) {
        if (!task.isDirectory() || !task.getAbsoluteFile().equals(task.getCanonicalFile()))
          throw new IOException("invalid_owner");
        File fence = new File(task, ".delete");
        if (fence.exists()) {
          if (!fence.isFile() || !fence.getAbsoluteFile().equals(fence.getCanonicalFile()))
            throw new IOException("invalid_owner");
        } else if (!new File(task.getParentFile(), ".revoked").exists()) {
          payload(app, current.scope, current.task, "picker");
          try {
            java.io.FileDescriptor descriptor = android.system.Os.open(fence.getPath(),
                android.system.OsConstants.O_CREAT | android.system.OsConstants.O_EXCL |
                android.system.OsConstants.O_WRONLY | android.system.OsConstants.O_NOFOLLOW, 0600);
            try (java.io.FileOutputStream out = new java.io.FileOutputStream(descriptor)) {
              out.write(1); out.getFD().sync();
            }
          } catch (android.system.ErrnoException error) { throw new IOException("owner_not_durable"); }
        }
      }
    }
    // A new process never resumes old image writes. Old request codes are
    // never reused and are ignored, so a later result cannot become B's input.
    clearOwner();
    return status(null, null);
  }

  private static void clearOwner() throws IOException {
    if (!prefs.edit().remove("scope").remove("task").commit()) throw new IOException("owner_not_durable");
    current = null;
  }

  static synchronized void started() throws IOException {
    if (app == null) return; // Upstream isolated delegate unit-test construction.
    Lease owner = checkedOwner();
    if (owner.started) throw new IOException("picker_busy");
    owner.started = true;
  }

  static synchronized void finished() {
    Lease owner = callbackOwner.get();
    if (owner == null) owner = current;
    if (owner != null) owner.finished = true;
  }

  private static Lease checkedOwner() throws IOException {
    Lease owner = callbackOwner.get();
    if (owner == null) owner = current;
    if (owner == null || owner != current || owner.finished || owner.cancelled || owner.recovered)
      throw new IOException("owner_unavailable");
    payload(app, owner.scope, owner.task, "picker");
    return owner;
  }

  static synchronized File cacheDir(Context context) throws IOException {
    if (app == null) return context.getCacheDir();
    Lease owner = checkedOwner();
    return payload(app, owner.scope, owner.task, "picker");
  }

  static synchronized Lease beginWrite(Closeable stream) throws IOException {
    if (app == null) return null;
    Lease owner = checkedOwner(); owner.writers++;
    if (stream != null) owner.streams.add(stream);
    return owner;
  }

  static synchronized void endWrite(Lease owner, Closeable stream) {
    if (owner == null) return;
    owner.writers--;
    if (stream != null) owner.streams.remove(stream);
  }

  /** Monotonic persisted 16-bit OS request codes; fail closed on exhaustion. */
  static synchronized int requestCode(int base) {
    if (app == null) return base;
    try {
      Lease owner = checkedOwner();
      int next = prefs.getInt("next_code", 16000);
      if (next >= 65000) throw new IOException("request_codes_exhausted");
      String record = owner.scope + "/" + owner.task + "/" + base;
      if (!prefs.edit().putInt("next_code", next + 1).putString("code_" + next, record).commit())
        throw new IOException("owner_not_durable");
      return next;
    } catch (IOException error) { throw new IllegalStateException("owned_picker_unavailable"); }
  }

  static final class Callback {
    final int base; final Lease owner;
    Callback(int base, Lease owner) { this.base = base; this.owner = owner; }
  }

  static synchronized Callback callback(int code) {
    if (app == null) return new Callback(code, null);
    String record = prefs.getString("code_" + code, null);
    if (record == null) return null;
    prefs.edit().remove("code_" + code).commit();
    String[] fields = record.split("/");
    if (fields.length != 3) return null;
    if (current == null || !current.matches(fields[0], fields[1])) {
      return new Callback(-1, null); // Consume stale OS result, never touch a newer pending call.
    }
    try { return new Callback(Integer.parseInt(fields[2]), current); }
    catch (Exception error) { current.finished = true; return new Callback(-1, null); }
  }

  static void run(Lease owner, Runnable action) {
    Lease previous = callbackOwner.get(); callbackOwner.set(owner);
    try { action.run(); } finally { if (previous == null) callbackOwner.remove(); else callbackOwner.set(previous); }
  }

  static synchronized Lease captureOwner() {
    Lease owner = callbackOwner.get(); return owner != null ? owner : current;
  }

  static void runCallback(Lease owner, Runnable action) {
    synchronized (OwnedImageStore.class) {
      if (app != null) {
        if (owner == null || owner != current || owner.finished) return;
        owner.writers++; // Pin the original owner through callback completion.
      }
    }
    try { run(owner, action); } finally { endWrite(owner, null); }
  }

  static synchronized boolean allowed(Lease owner) {
    if (app == null) return true;
    if (owner == null || owner != current || owner.finished || owner.cancelled || owner.recovered) return false;
    try { payload(app, owner.scope, owner.task, "picker"); return true; }
    catch (IOException error) { return false; }
  }

  static String encodePath(Context context, String path) {
    if (app == null) return path;
    try {
      File root = new File(context.getCacheDir().getCanonicalFile(), "soongong-owned-v1");
      File file = new File(path).getAbsoluteFile();
      if (!file.equals(file.getCanonicalFile()) || !file.getPath().startsWith(root.getPath() + File.separator)) return "";
      return file.getPath().substring(root.getPath().length() + 1).replace(File.separatorChar, '/');
    } catch (IOException error) { return ""; }
  }

  private static String unownedReference() {
    if (prefs != null && !prefs.edit().putBoolean("legacy_unknown", true).commit())
      throw new IllegalStateException("owned_picker_recovery_unknown");
    return "";
  }

  static String decodePath(Context context, String reference) {
    if (app == null) return reference;
    if (reference == null || reference.isEmpty()) return "";
    String[] fields = reference.split("/");
    if (fields.length < 4 || !uuid(fields[0]) || !uuid(fields[1]) || !fields[2].equals("payload")) return unownedReference();
    try {
      File root = new File(context.getCacheDir().getCanonicalFile(), "soongong-owned-v1");
      File file = new File(root, reference).getAbsoluteFile();
      if (!file.equals(file.getCanonicalFile()) || !file.getPath().startsWith(root.getPath() + File.separator)) return "";
      return file.getPath();
    } catch (IOException error) { return ""; }
  }
}
