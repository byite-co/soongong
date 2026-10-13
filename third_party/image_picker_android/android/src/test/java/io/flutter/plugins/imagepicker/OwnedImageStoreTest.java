package io.flutter.plugins.imagepicker;

import static org.junit.Assert.*;
import static org.robolectric.Shadows.shadowOf;

import android.app.Activity;
import android.content.Context;
import android.net.Uri;
import androidx.test.core.app.ApplicationProvider;
import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.IOException;
import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicReference;
import org.json.JSONObject;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.Robolectric;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

/** Actual production owner, FileUtils stream copy and camera file creation, synthetic bytes only. */
@RunWith(RobolectricTestRunner.class)
@Config(sdk = 28)
public class OwnedImageStoreTest {
  Context context;
  String scope, task;
  File payload;

  private static void forgetProcess() throws Exception {
    for (String name : new String[] {"app", "prefs", "current"}) {
      Field field = OwnedImageStore.class.getDeclaredField(name); field.setAccessible(true); field.set(null, null);
    }
  }
  @Before public void setUp() throws Exception {
    forgetProcess();
    context = ApplicationProvider.getApplicationContext();
    context.getSharedPreferences("soongong_picker_owner_v1", 0).edit().clear().commit();
    OwnedImageStore.initialize(context);
    scope = UUID.randomUUID().toString(); task = UUID.randomUUID().toString();
    payload = createTask(scope, task, "picker");
  }
  @After public void tearDown() throws Exception { forgetProcess(); }
  private File createTask(String scope, String task, String kind) throws Exception {
    File dir = new File(context.getCacheDir(), "soongong-owned-v1/" + scope + "/" + task);
    File payload = new File(dir, "payload"); assertTrue(payload.mkdirs());
    JSONObject marker = new JSONObject().put("version", 1).put("scope", scope).put("task", task)
        .put("kind", kind).put("created", 1).put("expires", Long.MAX_VALUE);
    Files.write(new File(dir, "marker.json").toPath(), marker.toString().getBytes(StandardCharsets.UTF_8));
    return payload.getCanonicalFile();
  }
  @Test public void cannotWriteBeforePrepareOrAfterDeletion() throws Exception {
    assertThrows(IOException.class, () -> OwnedImageStore.cacheDir(context));
    OwnedImageStore.prepare(scope, task); OwnedImageStore.started();
    assertEquals(payload, OwnedImageStore.cacheDir(context));
    assertTrue(new File(payload.getParentFile(), ".delete").createNewFile());
    assertThrows(IOException.class, () -> OwnedImageStore.cacheDir(context));
    assertThrows(IOException.class, () -> OwnedImageStore.beginWrite(null));
  }
  @Test public void markerKindMismatchAndTraversalFailClosed() throws Exception {
    assertThrows(IOException.class, () -> OwnedImageStore.payload(context, "../" + scope, task, "picker"));
    assertThrows(IOException.class, () -> OwnedImageStore.payload(context, scope, task, "export"));
    Files.write(new File(payload.getParentFile(), "marker.json").toPath(), "{}".getBytes(StandardCharsets.UTF_8));
    assertThrows(IOException.class, () -> OwnedImageStore.prepare(scope, task));
  }
  @Test public void symlinkCannotRedirectPayloadOrSourceFile() throws Exception {
    Files.delete(payload.toPath());
    File foreign = new File(context.getCacheDir(), "foreign-" + UUID.randomUUID()); assertTrue(foreign.mkdir());
    Files.createSymbolicLink(payload.toPath(), foreign.toPath());
    assertThrows(IOException.class, () -> OwnedImageStore.prepare(scope, task));
    assertEquals(0, foreign.list().length);
  }
  @Test public void galleryCopyIsOwnedBeforeCallbackAndOriginalSurvives() throws Exception {
    OwnedImageStore.prepare(scope, task); OwnedImageStore.started();
    File original = new File(context.getCacheDir(), "synthetic-original.png");
    Files.write(original.toPath(), new byte[] {1, 2, 3, 4});
    String copy = new FileUtils().getPathFromUri(context, Uri.fromFile(original));
    assertNotNull(copy); assertTrue(copy.startsWith(payload.getPath() + File.separator));
    assertFalse(copy.contains("synthetic-original"));
    assertArrayEquals(Files.readAllBytes(original.toPath()), Files.readAllBytes(new File(copy).toPath()));
    assertTrue(OwnedImageStore.status(scope, task).get("active"));
    assertThrows(IOException.class, () -> OwnedImageStore.release(scope, task));
    assertTrue(original.isFile());
  }
  @Test public void realCameraTemporaryFileStartsInsideOwner() throws Exception {
    OwnedImageStore.prepare(scope, task); OwnedImageStore.started();
    Activity activity = Robolectric.buildActivity(Activity.class).setup().get();
    ImagePickerDelegate delegate = new ImagePickerPlugin().constructDelegate(activity);
    Method create = ImagePickerDelegate.class.getDeclaredMethod("createTemporaryWritableImageFile");
    create.setAccessible(true);
    File cameraFile = (File) create.invoke(delegate);
    assertEquals(payload, cameraFile.getParentFile());
    assertTrue(cameraFile.isFile()); assertTrue(OwnedImageStore.status(scope, task).get("active"));
  }
  @Test public void cancelDuringActualGalleryReadClosesAndNeverReturnsSuccess() throws Exception {
    OwnedImageStore.prepare(scope, task); OwnedImageStore.started();
    CountDownLatch entered = new CountDownLatch(1), released = new CountDownLatch(1);
    AtomicBoolean closed = new AtomicBoolean();
    ByteArrayInputStream stream = new ByteArrayInputStream(new byte[] {1, 2, 3}) {
      @Override public synchronized int read(byte[] bytes, int offset, int length) {
        entered.countDown();
        try { assertTrue(released.await(3, TimeUnit.SECONDS)); } catch (InterruptedException error) { throw new AssertionError(error); }
        return super.read(bytes, offset, length);
      }
      @Override public void close() { closed.set(true); released.countDown(); }
    };
    Uri uri = Uri.parse("content://synthetic/personal-name.png");
    shadowOf(context.getContentResolver()).registerInputStream(uri, stream);
    AtomicReference<String> result = new AtomicReference<>();
    Thread writer = new Thread(() -> result.set(new FileUtils().getPathFromUri(context, uri)));
    writer.start(); assertTrue(entered.await(3, TimeUnit.SECONDS));
    assertTrue(OwnedImageStore.cancel(scope, task).get("active"));
    writer.join(4000); assertFalse(writer.isAlive()); assertTrue(closed.get()); assertNull(result.get());
    OwnedImageStore.finished(); OwnedImageStore.release(scope, task);
  }
  @Test public void recoveredPreCallbackRootIsFencedAndCannotBecomeNextAccountResult() throws Exception {
    OwnedImageStore.prepare(scope, task); OwnedImageStore.started();
    int code = OwnedImageStore.requestCode(2342);
    Files.write(new File(payload, "partial.jpg").toPath(), new byte[] {5});
    forgetProcess(); OwnedImageStore.initialize(context);
    assertTrue(OwnedImageStore.status(scope, task).get("unknown"));
    assertFalse(OwnedImageStore.recover().get("unknown"));
    assertTrue(new File(payload.getParentFile(), ".delete").isFile());
    String scopeB = UUID.randomUUID().toString(), taskB = UUID.randomUUID().toString();
    File b = createTask(scopeB, taskB, "picker");
    OwnedImageStore.prepare(scopeB, taskB); OwnedImageStore.started();
    assertEquals(-1, OwnedImageStore.callback(code).base);
    assertTrue(OwnedImageStore.status(scopeB, taskB).get("active"));
    assertEquals(0, b.list().length); assertEquals(1, new File(payload, "partial.jpg").length());
  }
  @Test public void recoverCannotReleaseALiveWriter() throws Exception {
    OwnedImageStore.prepare(scope, task); OwnedImageStore.started();
    assertTrue(OwnedImageStore.recover().get("active"));
    assertFalse(new File(payload.getParentFile(), ".delete").exists());
  }
  @Test public void blockedProviderCloseDoesNotBlockCancelOrPretendWriterStopped() throws Exception {
    OwnedImageStore.prepare(scope, task); OwnedImageStore.started();
    CountDownLatch closing = new CountDownLatch(1), unblock = new CountDownLatch(1);
    java.io.Closeable provider = () -> {
      closing.countDown();
      try { unblock.await(3, TimeUnit.SECONDS); } catch (InterruptedException error) { Thread.currentThread().interrupt(); }
    };
    OwnedImageStore.Lease lease = OwnedImageStore.beginWrite(provider);
    long start = System.nanoTime();
    try {
      assertTrue(OwnedImageStore.cancel(scope, task).get("active"));
      assertTrue(closing.await(1, TimeUnit.SECONDS));
      assertTrue(OwnedImageStore.status(scope, task).get("active"));
      assertTrue(TimeUnit.NANOSECONDS.toMillis(System.nanoTime() - start) < 1500);
      assertThrows(IOException.class, () -> OwnedImageStore.release(scope, task));
    } finally { unblock.countDown(); OwnedImageStore.endWrite(lease, provider); OwnedImageStore.finished(); }
  }
  @Test public void persistedPathsHaveOnlyOpaqueRelativeReferences() throws Exception {
    OwnedImageStore.prepare(scope, task);
    File file = new File(payload, UUID.randomUUID() + ".jpg"); Files.write(file.toPath(), new byte[] {1});
    ImagePickerCache cache = new ImagePickerCache(context);
    cache.savePendingCameraMediaUriPath(Uri.fromFile(file));
    String persisted = context.getSharedPreferences(ImagePickerCache.SHARED_PREFERENCES_NAME, 0).getAll().toString();
    assertFalse(persisted.contains(context.getCacheDir().getPath()));
    assertEquals(file.getPath(), cache.retrievePendingCameraMediaUriPath());
    assertEquals("", OwnedImageStore.decodePath(context, "/legacy/user/photo.jpg"));
    assertTrue(OwnedImageStore.recover().get("unknown"));
  }
  @Test public void revokedCameraProviderRefusesNewOpen() throws Exception {
    OwnedImageStore.prepare(scope, task);
    File image = new File(payload, "picture.jpg"); Files.write(image.toPath(), new byte[] {9});
    ImagePickerFileProvider provider = new ImagePickerFileProvider();
    android.content.pm.ProviderInfo info = new android.content.pm.ProviderInfo();
    info.authority = "owned-picker-test"; info.exported = false; info.grantUriPermissions = true;
    info.name = ImagePickerFileProvider.class.getName(); info.packageName = context.getPackageName();
    info.applicationInfo = context.getApplicationInfo();
    info.metaData = new android.os.Bundle();
    info.metaData.putInt("android.support.FILE_PROVIDER_PATHS", R.xml.flutter_image_picker_file_paths);
    shadowOf(context.getPackageManager()).addOrUpdateProvider(info);
    provider.attachInfo(context, info);
    Uri uri = Uri.parse("content://owned-picker-test/cached_files/" + scope + "/" + task + "/payload/picture.jpg");
    try (java.io.InputStream in = new android.os.ParcelFileDescriptor.AutoCloseInputStream(provider.openFile(uri, "r"))) {
      assertEquals(9, in.read());
    }
    assertTrue(new File(payload.getParentFile(), ".delete").createNewFile());
    assertThrows(java.io.FileNotFoundException.class, () -> provider.openFile(uri, "w"));
    assertArrayEquals(new byte[] {9}, Files.readAllBytes(image.toPath()));
  }
  @Test public void twoExportsHaveIndependentRootsWithoutCopyOrGlobalClear() throws Exception {
    String one = UUID.randomUUID().toString(), two = UUID.randomUUID().toString();
    File a = createTask(scope, one, "export"), b = createTask(scope, two, "export");
    Files.write(new File(a, "attachment.json").toPath(), new byte[] {1});
    Files.write(new File(b, "attachment.json").toPath(), new byte[] {2});
    assertEquals(a, OwnedImageStore.payload(context, scope, one, "export"));
    assertEquals(b, OwnedImageStore.payload(context, scope, two, "export"));
    assertEquals(1, new File(a, "attachment.json").length());
  }
}
