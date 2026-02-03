package com.example.tabletkalem

import android.app.Activity
import android.content.Intent
import android.graphics.PixelFormat
import android.media.ImageReader
import android.media.projection.MediaProjectionManager
import android.os.Bundle
import android.util.DisplayMetrics
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "screenshot_channel"
    private val REQUEST_CODE = 1001
    private var resultCallback: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            if (call.method == "takeScreenshot") {
                resultCallback = result
                val manager =
                    getSystemService(Activity.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
                startActivityForResult(
                    manager.createScreenCaptureIntent(),
                    REQUEST_CODE
                )
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == REQUEST_CODE && resultCode == Activity.RESULT_OK) {
            val metrics = DisplayMetrics()
            windowManager.defaultDisplay.getMetrics(metrics)

            val reader = ImageReader.newInstance(
                metrics.widthPixels,
                metrics.heightPixels,
                PixelFormat.RGBA_8888,
                1
            )

            val projectionManager =
                getSystemService(Activity.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
            val projection =
                projectionManager.getMediaProjection(resultCode, data!!)

            val virtualDisplay = projection.createVirtualDisplay(
                "screen",
                metrics.widthPixels,
                metrics.heightPixels,
                metrics.densityDpi,
                0,
                reader.surface,
                null,
                null
            )

            reader.setOnImageAvailableListener({
                val image = it.acquireLatestImage()
                val buffer = image.planes[0].buffer
                val bytes = ByteArray(buffer.remaining())
                buffer.get(bytes)
                image.close()
                virtualDisplay.release()
                projection.stop()
                resultCallback?.success(bytes)
            }, null)
        }
        super.onActivityResult(requestCode, resultCode, data)
    }
}
