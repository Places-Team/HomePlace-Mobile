package com.homeplace.mobile

import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.spec.ECGenParameterSpec

class MainActivity : FlutterActivity() {
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
    }

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
        private val SERVER_ID = Regex("^[0-9a-fA-F-]{36}$")
    }
}
