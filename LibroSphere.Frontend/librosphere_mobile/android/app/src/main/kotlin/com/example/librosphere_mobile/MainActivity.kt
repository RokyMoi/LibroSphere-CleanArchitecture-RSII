package com.example.librosphere_mobile

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        installSplashScreen()
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "librosphere.reader",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "openPdf" -> {
                    val path = call.argument<String>("path")
                    val title = call.argument<String>("title").orEmpty()

                    if (path.isNullOrBlank()) {
                        result.error("invalid_path", "Missing PDF path.", null)
                        return@setMethodCallHandler
                    }

                    runCatching {
                        openPdf(path, title)
                    }.onSuccess {
                        result.success(null)
                    }.onFailure { error ->
                        result.error(
                            "open_failed",
                            error.message ?: "Unable to open PDF.",
                            null,
                        )
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun openPdf(path: String, title: String) {
        val pdfFile = File(path)
        if (!pdfFile.exists()) {
            throw IllegalStateException("The downloaded PDF file no longer exists.")
        }

        val uri: Uri = FileProvider.getUriForFile(
            this,
            "${packageName}.reader.fileprovider",
            pdfFile,
        )

        val openIntent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "application/pdf")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NO_HISTORY)
        }

        val chooserIntent = Intent.createChooser(
            openIntent,
            if (title.isBlank()) "Open book" else "Open $title",
        ).apply {
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }

        try {
            startActivity(chooserIntent)
        } catch (_: ActivityNotFoundException) {
            throw IllegalStateException(
                "No PDF app is installed on this device. Install a PDF reader and try again.",
            )
        }
    }
}
