package co.byite.soongong

import android.net.Uri
import android.os.ParcelFileDescriptor
import androidx.core.content.FileProvider
import io.flutter.plugins.imagepicker.OwnedImageStore
import java.io.File
import java.io.FileNotFoundException

/** A receiver cannot reopen a revoked attachment or acquire a writable descriptor. */
class OwnedShareFileProvider : FileProvider() {
    override fun openFile(uri: Uri, mode: String): ParcelFileDescriptor {
        try {
            require(mode == "r")
            val parts = uri.pathSegments
            require(parts.size == 5 && parts[0] == "owned" && parts[3] == "payload")
            require(parts[4].matches(Regex("attachment(?:\\.(?:json|csv|zip|txt))?")))
            val payload = OwnedImageStore.payload(requireNotNull(context), parts[1], parts[2], "export")
            val file = File(payload, parts[4])
            require(file.isFile && file.absoluteFile == file.canonicalFile)
            return requireNotNull(super.openFile(uri, mode))
        } catch (_: Exception) { throw FileNotFoundException("owned_share_unavailable") }
    }
}
