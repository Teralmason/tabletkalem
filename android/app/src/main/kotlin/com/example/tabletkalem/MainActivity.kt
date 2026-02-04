package com.example.tabletkalem

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.PixelFormat
import android.media.ImageReader
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.view.WindowManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    
    private val CHANNEL = "screenshot_channel"
    private val REQUEST_CODE = 1001
    private val NOTIFICATION_PERMISSION_CODE = 1002
    private var resultCallback: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Android 13+ için bildirim izni iste
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(
                    this,
                    Manifest.permission.POST_NOTIFICATIONS
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                ActivityCompat.requestPermissions(
                    this,
                    arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                    NOTIFICATION_PERMISSION_CODE
                )
            }
        }
        
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "takeScreenshot" -> {
                    resultCallback = result
                    val manager = getSystemService(Activity.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
                    startActivityForResult(manager.createScreenCaptureIntent(), REQUEST_CODE)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        if (requestCode == REQUEST_CODE && resultCode == Activity.RESULT_OK && data != null) {
            try {
                val wm = getSystemService(WINDOW_SERVICE) as WindowManager
                val bounds = wm.currentWindowMetrics.bounds
                val width = bounds.width()
                val height = bounds.height()

                val reader = ImageReader.newInstance(
                    width,
                    height,
                    PixelFormat.RGBA_8888,
                    1
                )

                val projectionManager = getSystemService(Activity.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
                val projection = projectionManager.getMediaProjection(resultCode, data)

                val virtualDisplay = projection.createVirtualDisplay(
                    "screen",
                    width,
                    height,
                    resources.displayMetrics.densityDpi,
                    0,
                    reader.surface,
                    null,
                    null
                )

                reader.setOnImageAvailableListener({ imageReader ->
                    val image = imageReader.acquireLatestImage()
                    if (image != null) {
                        val buffer = image.planes[0].buffer
                        val bytes = ByteArray(buffer.remaining())
                        buffer.get(bytes)
                        image.close()
                        
                        virtualDisplay.release()
                        projection.stop()
                        
                        resultCallback?.success(bytes)
                        resultCallback = null
                    }
                }, Handler(Looper.getMainLooper()))
                
            } catch (e: Exception) {
                resultCallback?.error("SCREENSHOT_ERROR", e.message, null)
                resultCallback = null
            }
        } else {
            resultCallback?.error("CANCELLED", "Screenshot cancelled", null)
            resultCallback = null
        }
    }
}
