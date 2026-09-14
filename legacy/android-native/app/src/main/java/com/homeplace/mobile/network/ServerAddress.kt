package com.homeplace.mobile.network

import java.net.Inet6Address
import java.net.InetAddress
import okhttp3.HttpUrl
import okhttp3.HttpUrl.Companion.toHttpUrlOrNull

data class ServerAddress(
    val url: HttpUrl,
    val isSecure: Boolean,
    val isLocal: Boolean,
)

sealed class AddressResult {
    data class Valid(val address: ServerAddress) : AddressResult()
    data class Invalid(val message: String) : AddressResult()
}

object ServerAddressNormalizer {
    fun normalize(input: String): AddressResult {
        val raw = input.trim().trimEnd('/')
        if (raw.isEmpty()) return AddressResult.Invalid("Enter a server address.")
        if (raw.any(Char::isWhitespace)) return AddressResult.Invalid("The address cannot contain spaces.")

        val explicitScheme = raw.substringBefore(":", missingDelimiterValue = "").lowercase()
        if (explicitScheme.isNotEmpty() && explicitScheme !in setOf("http", "https") && "://" in raw) {
            return AddressResult.Invalid("Use an HTTP or HTTPS address.")
        }

        val candidate = if ("://" in raw) raw else "http://$raw"
        val parsed = candidate.toHttpUrlOrNull()
            ?: return AddressResult.Invalid("Check the server name, IP address, and port.")

        if (parsed.encodedUsername.isNotEmpty() || parsed.encodedPassword.isNotEmpty()) {
            return AddressResult.Invalid("Credentials cannot be included in the server address.")
        }
        if (parsed.encodedPath != "/" || parsed.query != null || parsed.fragment != null) {
            return AddressResult.Invalid("Enter the HomePlace server address without a path, query, or fragment.")
        }

        val local = isLocalHost(parsed.host)
        val scheme = when {
            "://" in raw -> parsed.scheme
            local -> "http"
            else -> "https"
        }
        if (scheme == "http" && !local) {
            return AddressResult.Invalid("Public server addresses must use HTTPS.")
        }

        val normalized = parsed.newBuilder().scheme(scheme).build()
        return AddressResult.Valid(ServerAddress(normalized, scheme == "https", local))
    }

    private fun isLocalHost(host: String): Boolean {
        val value = host.lowercase().removeSurrounding("[", "]")
        if (value == "localhost" || value.endsWith(".local") || "." !in value && ":" !in value) return true
        parseIpv4(value)?.let { octets ->
            return octets[0] == 10 ||
                octets[0] == 127 ||
                octets[0] == 192 && octets[1] == 168 ||
                octets[0] == 172 && octets[1] in 16..31 ||
                octets[0] == 169 && octets[1] == 254
        }
        if (":" in value) {
            val address = runCatching { InetAddress.getByName(value) }.getOrNull()
            if (address is Inet6Address) {
                val first = address.address[0].toInt() and 0xff
                val second = address.address[1].toInt() and 0xff
                return address.isLoopbackAddress || first and 0xfe == 0xfc || first == 0xfe && second and 0xc0 == 0x80
            }
        }
        return false
    }

    private fun parseIpv4(host: String): List<Int>? {
        val parts = host.split('.')
        if (parts.size != 4) return null
        val octets = parts.map { it.toIntOrNull() ?: return null }
        return octets.takeIf { values -> values.all { it in 0..255 } }
    }
}
