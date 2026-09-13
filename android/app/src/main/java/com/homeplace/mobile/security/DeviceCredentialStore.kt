package com.homeplace.mobile.security

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

class DeviceCredentialStore(context: Context) {
    private val preferences = context.getSharedPreferences("device_credentials", Context.MODE_PRIVATE)
    private val keyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }

    fun store(serverId: String, token: ByteArray) {
        val alias = aliasFor(serverId)
        val key = getOrCreateKey(alias)
        val cipher = Cipher.getInstance("AES/GCM/NoPadding").apply { init(Cipher.ENCRYPT_MODE, key) }
        val encrypted = cipher.doFinal(token)
        preferences.edit()
            .putString("$alias.iv", android.util.Base64.encodeToString(cipher.iv, android.util.Base64.NO_WRAP))
            .putString("$alias.data", android.util.Base64.encodeToString(encrypted, android.util.Base64.NO_WRAP))
            .apply()
        token.fill(0)
    }

    fun read(serverId: String): ByteArray? {
        val alias = aliasFor(serverId)
        val key = keyStore.getKey(alias, null) as? SecretKey ?: return null
        val iv = preferences.getString("$alias.iv", null)?.decode() ?: return null
        val encrypted = preferences.getString("$alias.data", null)?.decode() ?: return null
        return Cipher.getInstance("AES/GCM/NoPadding").run {
            init(Cipher.DECRYPT_MODE, key, GCMParameterSpec(128, iv))
            doFinal(encrypted)
        }
    }

    fun remove(serverId: String) {
        val alias = aliasFor(serverId)
        preferences.edit().remove("$alias.iv").remove("$alias.data").apply()
        if (keyStore.containsAlias(alias)) keyStore.deleteEntry(alias)
    }

    private fun getOrCreateKey(alias: String): SecretKey {
        (keyStore.getKey(alias, null) as? SecretKey)?.let { return it }
        return KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore").run {
            init(
                KeyGenParameterSpec.Builder(alias, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                    .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                    .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                    .build(),
            )
            generateKey()
        }
    }

    private fun aliasFor(serverId: String): String = "homeplace.device.${serverId.hashCode().toUInt()}"
    private fun String.decode(): ByteArray = android.util.Base64.decode(this, android.util.Base64.NO_WRAP)
}
