package com.homeplace.mobile.backgroundfiles

import android.content.ContentValues
import android.content.Context
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class HomePlaceBackgroundFilesPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var context: Context
    private lateinit var channel: MethodChannel
    private var executor: ExecutorService = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
        if (executor.isShutdown) executor = Executors.newSingleThreadExecutor()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "createTemporaryFile" -> runCatching {
                File.createTempFile("background-received-", ".bin", context.cacheDir).absolutePath
            }.onSuccess(result::success).onFailure {
                result.error("temporary_file_unavailable", "A protected temporary file could not be created.", null)
            }
            "saveFilePath" -> saveFile(call.arguments as? Map<*, *>, result)
            else -> result.notImplemented()
        }
    }

    private fun saveFile(arguments: Map<*, *>?, result: MethodChannel.Result) {
        val rawPath = arguments?.get("path") as? String
        val rawName = arguments?.get("filename") as? String
        val requestedMimeType = arguments?.get("mimeType") as? String
        val mimeType = requestedMimeType?.takeIf { SAFE_MIME_TYPE.matches(it) }
            ?: "application/octet-stream"
        val source = rawPath?.let(::File)
        val cacheRoot = context.cacheDir.canonicalFile
        val safeSource = runCatching { source?.canonicalFile }.getOrNull()
        if (safeSource == null ||
            !safeSource.path.startsWith(cacheRoot.path + File.separator) ||
            !safeSource.isFile || safeSource.length() < 1 ||
            safeSource.length() > MAX_FILE_BYTES || rawName == null) {
            result.error("invalid_file", "The received file is invalid.", null)
            return
        }
        val filename = rawName.replace(Regex("[\\\\/\\x00-\\x1f\\x7f]"), "_").take(180)
        executor.execute {
            runCatching { saveVerifiedFile(safeSource, filename, mimeType) }
                .onSuccess { location -> mainHandler.post { result.success(location) } }
                .onFailure {
                    mainHandler.post {
                        result.error("save_failed", it.message ?: "The file could not be saved.", null)
                    }
                }
        }
    }

    private fun saveVerifiedFile(source: File, filename: String, mimeType: String): String {
        val savedUri: Uri
        if (Build.VERSION.SDK_INT >= 29) {
            val values = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, filename)
                put(MediaStore.Downloads.MIME_TYPE, mimeType)
                put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS + "/HomePlace")
                put(MediaStore.Downloads.IS_PENDING, 1)
            }
            val uri = context.contentResolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                ?: error("Could not create download")
            try {
                context.contentResolver.openOutputStream(uri)?.use { output ->
                    source.inputStream().use { input -> input.copyTo(output, BUFFER_SIZE) }
                } ?: error("Could not write download")
                values.clear()
                values.put(MediaStore.Downloads.IS_PENDING, 0)
                context.contentResolver.update(uri, values, null, null)
                savedUri = uri
            } catch (error: Throwable) {
                context.contentResolver.delete(uri, null, null)
                throw error
            }
        } else {
            val directory = File(
                context.getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS),
                "HomePlace",
            ).apply { mkdirs() }
            val target = uniqueTarget(directory, filename)
            source.inputStream().use { input ->
                FileOutputStream(target).use { output -> input.copyTo(output, BUFFER_SIZE) }
            }
            savedUri = FileProvider.getUriForFile(context, "${context.packageName}.files", target)
        }
        return savedUri.toString()
    }

    private fun uniqueTarget(directory: File, filename: String): File {
        var target = File(directory, filename)
        if (!target.exists()) return target
        val dot = filename.lastIndexOf('.')
        val base = if (dot > 0) filename.substring(0, dot) else filename
        val extension = if (dot > 0) filename.substring(dot) else ""
        var index = 1
        while (target.exists()) {
            target = File(directory, "$base ($index)$extension")
            index++
        }
        return target
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        executor.shutdown()
    }

    companion object {
        private const val CHANNEL = "com.homeplace.mobile/background_files"
        private const val MAX_FILE_BYTES = 500L * 1024L * 1024L
        private const val BUFFER_SIZE = 64 * 1024
        private val SAFE_MIME_TYPE = Regex(
            "^[A-Za-z0-9][A-Za-z0-9!#$&^_.+-]*/[A-Za-z0-9][A-Za-z0-9!#$&^_.+-]{0,99}$",
        )
    }
}
