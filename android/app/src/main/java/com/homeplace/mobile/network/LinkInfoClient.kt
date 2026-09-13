package com.homeplace.mobile.network

import com.homeplace.mobile.protocol.ServerInfo
import com.homeplace.mobile.protocol.supportsClient
import java.io.IOException
import java.time.Duration
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.SerializationException
import kotlinx.serialization.json.Json
import okhttp3.OkHttpClient
import okhttp3.Request

sealed class ServerInfoResult {
    data class Success(val info: ServerInfo) : ServerInfoResult()
    data class Failure(val kind: FailureKind, val message: String) : ServerInfoResult()
}

enum class FailureKind { NETWORK, TLS, INVALID_RESPONSE, INCOMPATIBLE }

interface ServerInfoService {
    suspend fun fetch(address: ServerAddress): ServerInfoResult
}

class LinkInfoClient(
    private val client: OkHttpClient = defaultClient(),
    private val json: Json = Json { ignoreUnknownKeys = true },
) : ServerInfoService {
    override suspend fun fetch(address: ServerAddress): ServerInfoResult = withContext(Dispatchers.IO) {
        val infoUrl = address.url.resolve("/api/link/info")
            ?: return@withContext ServerInfoResult.Failure(FailureKind.INVALID_RESPONSE, "The server address is invalid.")
        val request = Request.Builder().url(infoUrl).header("Accept", "application/json").get().build()

        try {
            client.newCall(request).execute().use { response ->
                if (!response.isSuccessful) {
                    return@withContext ServerInfoResult.Failure(
                        FailureKind.INVALID_RESPONSE,
                        "HomePlace returned HTTP ${response.code} for /api/link/info.",
                    )
                }
                val body = response.body?.string().orEmpty()
                val info = json.decodeFromString<ServerInfo>(body)
                if (!info.supportsClient()) {
                    return@withContext ServerInfoResult.Failure(
                        FailureKind.INCOMPATIBLE,
                        "This HomePlace server does not support Link protocol 1.",
                    )
                }
                ServerInfoResult.Success(info)
            }
        } catch (error: javax.net.ssl.SSLException) {
            ServerInfoResult.Failure(FailureKind.TLS, "The server certificate could not be verified.")
        } catch (error: SerializationException) {
            ServerInfoResult.Failure(FailureKind.INVALID_RESPONSE, "The server returned invalid HomePlace Link information.")
        } catch (error: IOException) {
            ServerInfoResult.Failure(FailureKind.NETWORK, "HomePlace could not be reached. Check the address and network.")
        }
    }

    companion object {
        private fun defaultClient(): OkHttpClient = OkHttpClient.Builder()
            .connectTimeout(Duration.ofSeconds(10))
            .readTimeout(Duration.ofSeconds(10))
            .followRedirects(false)
            .followSslRedirects(false)
            .build()
    }
}
