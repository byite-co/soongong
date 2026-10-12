package co.byite.soongong

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Matrix
import android.os.Handler
import android.os.Looper
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.facelandmarker.FaceLandmarker
import io.flutter.FlutterInjector
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/** Serial, bounded single-frame bridge. No files, identity, or network output. */
class GazeBridge(private val context: Context, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, "co.byite.soongong/gaze")
    private val executor = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private var engine: FaceLandmarker? = null
    private var run: String? = null
    private var lastTime = -1L

    init {
        channel.setMethodCallHandler { call, reply ->
            executor.execute {
                try {
                    val requested = call.argument<String>("run") ?: error("missing_run")
                    val value: Any? = when (call.method) {
                        "open" -> {
                            engine?.close(); engine = null; run = null
                            val asset = FlutterInjector.instance().flutterLoader()
                                .getLookupKeyForAsset("assets/models/face_landmarker.task")
                            val options = FaceLandmarker.FaceLandmarkerOptions.builder()
                                .setBaseOptions(BaseOptions.builder().setModelAssetPath(asset).build())
                                .setRunningMode(RunningMode.VIDEO).setNumFaces(2).build()
                            engine = FaceLandmarker.createFromOptions(context, options)
                            run = requested; lastTime = -1L
                            null
                        }
                        "close" -> {
                            if (run == requested) { engine?.close(); engine = null; run = null }
                            null
                        }
                        "frame" -> {
                            check(run == requested)
                            val time = call.argument<Number>("time")!!.toLong()
                            check(time > lastTime); lastTime = time
                            val w = call.argument<Int>("width")!!
                            val h = call.argument<Int>("height")!!
                            val stride = call.argument<Int>("stride")!!
                            val rotation = call.argument<Int>("rotation")!!
                            val bytes = call.argument<ByteArray>("bytes")!!
                            require(w > 0 && h > 0 && w.toLong() * h <= 2000000)
                            require(w % 2 == 0 && h % 2 == 0 && stride == w)
                            require(bytes.size == w * h * 3 / 2 && rotation in listOf(0, 90, 180, 270))
                            val pixels = IntArray(w * h)
                            for (y in 0 until h) for (x in 0 until w) {
                                val yy = (bytes[y * w + x].toInt() and 255) - 16
                                val uv = w * h + (y / 2) * w + (x / 2) * 2
                                val v = (bytes[uv].toInt() and 255) - 128
                                val u = (bytes[uv + 1].toInt() and 255) - 128
                                val c = yy.coerceAtLeast(0) * 298
                                val r = ((c + 409 * v + 128) shr 8).coerceIn(0, 255)
                                val g = ((c - 100 * u - 208 * v + 128) shr 8).coerceIn(0, 255)
                                val b = ((c + 516 * u + 128) shr 8).coerceIn(0, 255)
                                pixels[y * w + x] = (255 shl 24) or (r shl 16) or (g shl 8) or b
                            }
                            val original = Bitmap.createBitmap(pixels, w, h, Bitmap.Config.ARGB_8888)
                            val bitmap = if (rotation == 0) original else Bitmap.createBitmap(
                                original, 0, 0, w, h, Matrix().apply { postRotate(rotation.toFloat()) }, true)
                            try {
                                val image = BitmapImageBuilder(bitmap).build()
                                try {
                                    val faces = engine!!.detectForVideo(image, time).faceLandmarks()
                                    mapOf("run" to requested, "time" to time, "faces" to faces.size,
                                        "points" to if (faces.size == 1) faces[0].map { listOf(it.x().toDouble(), it.y().toDouble()) } else emptyList<List<Double>>())
                                } finally { image.close() }
                            } finally { if (bitmap !== original) bitmap.recycle(); original.recycle() }
                        }
                        else -> error("unknown_method")
                    }
                    main.post { reply.success(value) }
                } catch (_: Exception) {
                    main.post { reply.error("gaze_unavailable", "On-device gaze unavailable", null) }
                }
            }
        }
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        executor.execute { engine?.close(); engine = null; run = null }
        executor.shutdown()
    }
}
