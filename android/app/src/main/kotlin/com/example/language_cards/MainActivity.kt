package com.example.language_cards

import android.webkit.MimeTypeMap;
import android.os.Environment
import android.os.Build.VERSION
import android.os.Build.VERSION_CODES
import androidx.annotation.NonNull

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "io_context_provider"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
        call, result ->
            when (call.method) {
                "getDownloadsDirectoryPath" ->
                    result.success(Environment.getExternalStoragePublicDirectory("Download").toString());
                "isStoragePermissionRequired" -> result.success(VERSION.SDK_INT < VERSION_CODES.Q);
                "isFileExtensionSupported" -> {
                    var ext = call.argument<String>("ext");
                    result.success(MimeTypeMap.getSingleton().hasExtension(ext));
                }
                else -> result.notImplemented()
            }
        }
    }
}
