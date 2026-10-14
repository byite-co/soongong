package co.byite.soongong

import android.app.Activity
import android.content.ClipData
import android.content.Intent
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.imagepicker.OwnedImageStore
import java.io.File

/** Sends the already-owned file directly. Never uses share_plus's global copy/clear cache. */
class OwnedShareBridge(private val activity: Activity, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, "co.byite.soongong/owned_share")

    init {
        channel.setMethodCallHandler { call, result ->
            if (call.method != "share") { result.notImplemented(); return@setMethodCallHandler }
            try {
                val scope = requireNotNull(call.argument<String>("scope"))
                val task = requireNotNull(call.argument<String>("task"))
                val relativeName = call.argument<String>("relativeName") ?: "attachment"
                val name = requireNotNull(call.argument<String>("name"))
                val mimeType = requireNotNull(call.argument<String>("mimeType"))
                result.success(share(scope, task, relativeName, name, mimeType))
            } catch (_: Exception) {
                result.error("owned_share_unavailable", null, null)
            }
        }
    }

    fun share(scope: String, task: String, relativeName: String, name: String, mimeType: String): String {
        require(relativeName.matches(Regex("attachment(?:\\.(?:json|csv|zip|txt))?")))
        require(name.length in 1..120 && name != "." && name != ".." &&
            !name.any { it == '/' || it == '\\' || it.code < 32 || it.code == 127 })
        require(mimeType in setOf("application/json", "text/csv", "application/zip", "text/plain"))
        val payload = OwnedImageStore.payload(activity, scope, task, "export")
        val file = File(payload, relativeName)
        require(file.isFile && file.absoluteFile == file.canonicalFile)
        val uri = androidx.core.content.FileProvider.getUriForFile(
            activity, "${activity.packageName}.soongong.owned_share", file, name)
        val intent = Intent(Intent.ACTION_SEND).apply {
            type = mimeType
            putExtra(Intent.EXTRA_STREAM, uri)
            putExtra(Intent.EXTRA_SUBJECT, name)
            clipData = ClipData.newRawUri("attachment", uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        OwnedImageStore.payload(activity, scope, task, "export")
        activity.startActivity(Intent.createChooser(intent, null))
        // The OS accepted a presentation attempt; recipient read completion is unknown.
        return "handedOff"
    }

    fun dispose() { channel.setMethodCallHandler(null) }
}
