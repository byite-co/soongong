package co.byite.soongong;

import static org.junit.Assert.*;
import static org.mockito.Mockito.mock;
import static org.robolectric.Shadows.shadowOf;

import android.app.Activity;
import android.app.Application;
import android.content.Intent;
import android.net.Uri;
import io.flutter.plugin.common.BinaryMessenger;
import java.io.File;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.util.UUID;
import org.json.JSONObject;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.Robolectric;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

/** Real bridge Intent and FileProvider, without a receiver app or personal data. */
@RunWith(RobolectricTestRunner.class)
// Use the compiled APK resources and real provider below without starting
// unrelated SDK receivers from the merged application manifest. In particular,
// Amazon IAP's obfuscated receiver fails JVM verification before @Before runs.
@Config(sdk = 28, application = Application.class, manifest = "OwnedShareTestManifest.xml")
public class OwnedShareBridgeTest {
  Activity activity;
  OwnedShareBridge bridge;
  String scope;

  @Before public void setUp() {
    activity = Robolectric.buildActivity(Activity.class).setup().get();
    bridge = new OwnedShareBridge(activity, mock(BinaryMessenger.class));
    scope = UUID.randomUUID().toString();
    android.content.pm.ProviderInfo info = new android.content.pm.ProviderInfo();
    info.authority = activity.getPackageName() + ".soongong.owned_share";
    info.name = OwnedShareFileProvider.class.getName(); info.packageName = activity.getPackageName();
    info.applicationInfo = activity.getApplicationInfo(); info.exported = false; info.grantUriPermissions = true;
    info.metaData = new android.os.Bundle();
    info.metaData.putInt("android.support.FILE_PROVIDER_PATHS", R.xml.owned_share_paths);
    shadowOf(activity.getPackageManager()).addOrUpdateProvider(info);
    OwnedShareFileProvider provider = new OwnedShareFileProvider(); provider.attachInfo(activity, info);
    org.robolectric.shadows.ShadowContentResolver.registerProviderInternal(info.authority, provider);
  }
  private File export(String task, int content) throws Exception {
    File dir = new File(activity.getCacheDir(), "soongong-owned-v1/" + scope + "/" + task);
    File payload = new File(dir, "payload"); assertTrue(payload.mkdirs());
    JSONObject marker = new JSONObject().put("version", 1).put("scope", scope).put("task", task)
        .put("kind", "export").put("created", 1).put("expires", Long.MAX_VALUE);
    Files.write(new File(dir, "marker.json").toPath(), marker.toString().getBytes(StandardCharsets.UTF_8));
    File file = new File(payload, "attachment.json"); Files.write(file.toPath(), new byte[] {(byte)content});
    return file;
  }
  private Uri share(String task) {
    assertEquals("handedOff", bridge.share(scope, task, "attachment.json", "export.json", "application/json"));
    Intent chooser = shadowOf(activity).getNextStartedActivity();
    assertEquals(Intent.ACTION_CHOOSER, chooser.getAction());
    Intent send = chooser.getParcelableExtra(Intent.EXTRA_INTENT);
    assertEquals(Intent.ACTION_SEND, send.getAction());
    assertEquals("application/json", send.getType());
    assertEquals(Intent.FLAG_GRANT_READ_URI_PERMISSION, send.getFlags() & Intent.FLAG_GRANT_READ_URI_PERMISSION);
    assertEquals(0, send.getFlags() & Intent.FLAG_GRANT_WRITE_URI_PERMISSION);
    return send.getParcelableExtra(Intent.EXTRA_STREAM);
  }
  @Test public void twoDelayedAttachmentsRemainIndependentAndNoGlobalCacheIsMade() throws Exception {
    String a = UUID.randomUUID().toString(), b = UUID.randomUUID().toString();
    File first = export(a, 1), second = export(b, 2);
    Uri firstUri = share(a), secondUri = share(b);
    assertNotEquals(firstUri, secondUri);
    assertArrayEquals(new byte[] {1}, Files.readAllBytes(first.toPath()));
    assertArrayEquals(new byte[] {2}, Files.readAllBytes(second.toPath()));
    assertEquals(1, first.getParentFile().list().length);
    assertEquals(1, second.getParentFile().list().length);
    assertFalse(new File(activity.getCacheDir(), "share_plus").exists());
  }
  @Test public void receiverReadUsesOwnedSourceAndRevocationBlocksReopen() throws Exception {
    String task = UUID.randomUUID().toString(); File file = export(task, 7);
    Uri uri = share(task);
    try (java.io.InputStream in = activity.getContentResolver().openInputStream(uri)) { assertEquals(7, in.read()); }
    assertTrue(new File(file.getParentFile().getParentFile(), ".delete").createNewFile());
    assertThrows(java.io.FileNotFoundException.class, () -> activity.getContentResolver().openInputStream(uri));
    assertThrows(Exception.class, () -> bridge.share(scope, task, "attachment.json", "export.json", "application/json"));
    assertArrayEquals(new byte[] {7}, Files.readAllBytes(file.toPath()));
  }
  @Test public void symlinkAndPathArgumentsCannotShareUnownedOriginal() throws Exception {
    String task = UUID.randomUUID().toString(); File file = export(task, 1);
    File outside = new File(activity.getCacheDir(), "synthetic-original.txt"); Files.write(outside.toPath(), new byte[] {8});
    assertThrows(Exception.class, () -> bridge.share(scope, task, "../../synthetic-original.txt", "export.json", "application/json"));
    assertThrows(Exception.class, () -> bridge.share(scope, task, "attachment.json", "../display.json", "application/json"));
    Files.delete(file.toPath()); Files.createSymbolicLink(file.toPath(), outside.toPath());
    assertThrows(Exception.class, () -> bridge.share(scope, task, "attachment.json", "export.json", "application/json"));
    assertArrayEquals(new byte[] {8}, Files.readAllBytes(outside.toPath()));
    assertNull(shadowOf(activity).getNextStartedActivity());
  }
}
