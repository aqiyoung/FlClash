package com.follow.clash.plugins

import android.app.DownloadManager
import android.content.Context
import android.net.Uri
import android.os.Build
import android.os.Environment
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class DownloadPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    private lateinit var context: Context

    private lateinit var methodChannel: MethodChannel

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        methodChannel = MethodChannel(binding.binaryMessenger, CHANNEL)
        methodChannel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "supportedAbi" -> result.success(supportedAbi())
            "download" -> {
                val url = call.argument<String>("url")
                val fileName = call.argument<String>("fileName")
                if (url.isNullOrBlank() || fileName.isNullOrBlank()) {
                    result.error("bad_arguments", "url and fileName are required", null)
                } else {
                    try {
                        result.success(download(url, fileName))
                    } catch (error: Exception) {
                        result.error("download_failed", error.message, null)
                    }
                }
            }
            else -> result.notImplemented()
        }
    }

    /// The ABI the device runs, which names the package that fits it.
    private fun supportedAbi(): String {
        return Build.SUPPORTED_ABIS.firstOrNull() ?: "arm64-v8a"
    }

    /// Hands the file to the system download manager, which keeps it in the
    /// device's Downloads folder and shows its own progress.
    private fun download(url: String, fileName: String): Long {
        val manager = context.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
        val request = DownloadManager.Request(Uri.parse(url))
            .setTitle(fileName)
            .setDescription(fileName)
            .setMimeType("application/vnd.android.package-archive")
            .setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
            .setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, fileName)
            .setAllowedOverMetered(true)
            .setAllowedOverRoaming(true)
        return manager.enqueue(request)
    }

    companion object {
        const val CHANNEL = "com.follow.clash/download"
    }
}
