package com.homeplace.mobile

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.provider.OpenableColumns
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.spec.ECGenParameterSpec
import java.io.File
import java.io.FileOutputStream
import java.net.URI
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private var shareChannel: MethodChannel? = null
    private var pendingShare: Map<String, Any>? = null
    private val shareExecutor = Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, IDENTITY_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method != "publicKey") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val serverId = call.argument<String>("serverId")
            if (serverId == null || !SERVER_ID.matches(serverId)) {
                result.error("invalid_server_id", "A valid HomePlace server ID is required.", null)
                return@setMethodCallHandler
            }
            runCatching { publicKey(serverId) }
                .onSuccess(result::success)
                .onFailure { result.error("keystore_unavailable", "Android Keystore is unavailable.", null) }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CLIPBOARD_CHANNEL).setMethodCallHandler { call, result ->
            val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
            when (call.method) {
                "readText" -> result.success(
                    if (hasWindowFocus()) clipboard.primaryClip?.getItemAt(0)?.coerceToText(this)?.toString() else null,
                )
                "writeText" -> {
                    val text = call.argument<String>("text")
                    if (text == null || text.length > 8000) {
                        result.error("invalid_text", "Clipboard text must contain at most 8000 characters.", null)
                    } else {
                        clipboard.setPrimaryClip(ClipData.newPlainText("HomePlace", text))
                        result.success(null)
                    }
                }
                else -> result.notImplemented()
            }
        }
        shareChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SHARE_CHANNEL).also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "takePending" -> result.success(pendingShare.also { pendingShare = null })
                    "openUrl" -> {
                        val value = call.argument<String>("url")
                        if (value == null || !isSafeWebUrl(value)) {
                            result.error("invalid_url", "Only safe HTTP and HTTPS links can be opened.", null)
                        } else {
                            startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(value)))
                            result.success(null)
                        }
                    }
                    "saveFilePath" -> saveReceivedFilePath(call.arguments as? Map<*, *>, result)
                    else -> result.notImplemented()
                }
            }
        }
        captureShareIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        captureShareIntent(intent)
    }

    private fun captureShareIntent(incoming: Intent?) {
        if (incoming?.action != Intent.ACTION_SEND) return
        val stream = if (Build.VERSION.SDK_INT >= 33) {
            incoming.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
        } else {
            @Suppress("DEPRECATION") incoming.getParcelableExtra(Intent.EXTRA_STREAM) as? Uri
        }
        val announcedType = incoming.type
        val textContent = if (stream == null) captureText(incoming) else null
        incoming.action = null
        incoming.removeExtra(Intent.EXTRA_TEXT)
        incoming.removeExtra(Intent.EXTRA_STREAM)
        if (stream == null) {
            deliverShare(textContent)
            return
        }
        shareExecutor.execute {
            val content = copyIncomingFile(stream, announcedType)
            runOnUiThread { deliverShare(content) }
        }
    }

    private fun deliverShare(content: Map<String, Any>?) {
        if (content == null) return
        pendingShare = content
        shareChannel?.invokeMethod("shareReceived", content)
    }

    private fun captureText(incoming: Intent): Map<String, Any>? {
        val text = incoming.getCharSequenceExtra(Intent.EXTRA_TEXT)?.toString()?.trim() ?: return null
        if (text.isEmpty() || text.length > MAX_TEXT_LENGTH) return null
        val type = if (text.length <= MAX_URL_LENGTH && isSafeWebUrl(text)) "url" else "text"
        return mapOf("type" to type, "value" to text)
    }

    private fun copyIncomingFile(uri: Uri, announcedType: String?): Map<String, Any>? = runCatching {
        var filename = "shared-file"
        var announcedSize = -1L
        contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE), null, null, null)?.use { cursor ->
            if (cursor.moveToFirst()) {
                filename = cursor.getString(0)?.take(180) ?: filename
                if (!cursor.isNull(1)) announcedSize = cursor.getLong(1)
            }
        }
        if (announcedSize > MAX_FILE_BYTES) return null
        filename = filename.replace(Regex("[\\\\/\\x00-\\x1f\\x7f]"), "_")
        val target = File.createTempFile("share-", ".bin", cacheDir)
        var total = 0L
        contentResolver.openInputStream(uri)?.use { input ->
            FileOutputStream(target).use { output ->
                val buffer = ByteArray(64 * 1024)
                while (true) {
                    val count = input.read(buffer)
                    if (count < 0) break
                    total += count
                    if (total > MAX_FILE_BYTES) {
                        target.delete()
                        return null
                    }
                    output.write(buffer, 0, count)
                }
            }
        } ?: return null
        if (total == 0L) {
            target.delete()
            return null
        }
        mapOf(
            "type" to "file",
            "path" to target.absolutePath,
            "filename" to filename,
            "mimeType" to (announcedType ?: contentResolver.getType(uri) ?: "application/octet-stream"),
            "size" to total,
        )
    }.getOrNull()

    private fun saveReceivedFilePath(arguments: Map<*, *>?, result: MethodChannel.Result) {
        val rawPath = arguments?.get("path") as? String
        val rawName = arguments?.get("filename") as? String
        val mimeType = arguments?.get("mimeType") as? String ?: "application/octet-stream"
        val source = rawPath?.let(::File)
        val cacheRoot = cacheDir.canonicalFile
        val safeSource = runCatching { source?.canonicalFile }.getOrNull()
        if (safeSource == null ||
            !safeSource.path.startsWith(cacheRoot.path + File.separator) ||
            !safeSource.isFile || safeSource.length() < 1 ||
            safeSource.length() > MAX_FILE_BYTES || rawName == null) {
            result.error("invalid_file", "The received file is invalid.", null)
            return
        }
        val filename = rawName.replace(Regex("[\\\\/\\x00-\\x1f\\x7f]"), "_").take(180)
        shareExecutor.execute { runCatching {
            if (Build.VERSION.SDK_INT >= 29) {
                val values = ContentValues().apply {
                    put(MediaStore.Downloads.DISPLAY_NAME, filename)
                    put(MediaStore.Downloads.MIME_TYPE, mimeType)
                    put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS + "/HomePlace")
                    put(MediaStore.Downloads.IS_PENDING, 1)
                }
                val uri = contentResolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                    ?: error("Could not create download")
                try {
                    contentResolver.openOutputStream(uri)?.use { output ->
                        safeSource.inputStream().use { input -> input.copyTo(output, 64 * 1024) }
                    } ?: error("Could not write download")
                    values.clear()
                    values.put(MediaStore.Downloads.IS_PENDING, 0)
                    contentResolver.update(uri, values, null, null)
                } catch (error: Throwable) {
                    contentResolver.delete(uri, null, null)
                    throw error
                }
            } else {
                val directory = File(getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS), "HomePlace").apply { mkdirs() }
                safeSource.inputStream().use { input ->
                    FileOutputStream(File(directory, filename)).use { output -> input.copyTo(output, 64 * 1024) }
                }
            }
        }.onSuccess { runOnUiThread { result.success(null) } }
            .onFailure { runOnUiThread { result.error("save_failed", "The file could not be saved.", null) } }
        }
    }

    override fun onDestroy() {
        shareExecutor.shutdownNow()
        super.onDestroy()
    }

    private fun isSafeWebUrl(value: String): Boolean = runCatching {
        val uri = URI(value)
        (uri.scheme.equals("http", true) || uri.scheme.equals("https", true)) && uri.userInfo == null && uri.host != null
    }.getOrDefault(false)

    private fun publicKey(serverId: String): String {
        val alias = "homeplace.identity.$serverId"
        val keyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        val existing = keyStore.getCertificate(alias)?.publicKey
        val publicKey = existing ?: KeyPairGenerator.getInstance(KeyProperties.KEY_ALGORITHM_EC, "AndroidKeyStore").run {
            initialize(
                KeyGenParameterSpec.Builder(alias, KeyProperties.PURPOSE_SIGN or KeyProperties.PURPOSE_VERIFY)
                    .setAlgorithmParameterSpec(ECGenParameterSpec("secp256r1"))
                    .setDigests(KeyProperties.DIGEST_SHA256)
                    .build(),
            )
            generateKeyPair().public
        }
        return Base64.encodeToString(publicKey.encoded, Base64.NO_WRAP)
    }

    companion object {
        private const val IDENTITY_CHANNEL = "com.homeplace.mobile/identity"
        private const val CLIPBOARD_CHANNEL = "com.homeplace.mobile/clipboard"
        private const val SHARE_CHANNEL = "com.homeplace.mobile/share"
        private const val MAX_TEXT_LENGTH = 8000
        private const val MAX_URL_LENGTH = 4096
        private const val MAX_FILE_BYTES = 500 * 1024 * 1024L
        private val SERVER_ID = Regex("^[0-9a-fA-F-]{36}$")
    }
}
