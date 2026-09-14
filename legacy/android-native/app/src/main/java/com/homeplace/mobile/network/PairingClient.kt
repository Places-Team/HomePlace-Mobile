package com.homeplace.mobile.network

import com.homeplace.mobile.protocol.Capability
import com.homeplace.mobile.protocol.SUPPORTED_LINK_PROTOCOL
import java.io.IOException
import java.time.Duration
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.Serializable
import kotlinx.serialization.SerializationException
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody

@Serializable
data class PairDevice(val name: String, val platform: String, val platformVersion: String, val appVersion: String)

@Serializable
data class PairRequest(
    val protocol: Int = SUPPORTED_LINK_PROTOCOL,
    val device: PairDevice,
    val publicKey: String,
    val capabilities: List<Capability>,
)

@Serializable
data class PairingSession(
    val id: String,
    val code: String,
    val claimSecret: String,
    val expiresAt: String,
    val pollAfterSeconds: Int,
)

@Serializable
private data class PairResponse(val protocol: Int, val pairing: PairingSession)

@Serializable
private data class ClaimRequest(val claimSecret: String)

@Serializable
private data class ClaimResponse(val protocol: Int, val pairing: ClaimResult)

@Serializable
data class ClaimResult(
    val status: String,
    val serverId: String? = null,
    val deviceId: String? = null,
    val credential: String? = null,
)

sealed class PairingResult<out T> {
    data class Success<T>(val value: T) : PairingResult<T>()
    data class Failure(val message: String, val retryable: Boolean = false) : PairingResult<Nothing>()
}

interface PairingService {
    suspend fun start(address: ServerAddress, request: PairRequest): PairingResult<PairingSession>
    suspend fun claim(address: ServerAddress, session: PairingSession): PairingResult<ClaimResult>
}

class PairingClient(
    private val client: OkHttpClient = defaultClient(),
    private val json: Json = Json { ignoreUnknownKeys = true },
) : PairingService {
    override suspend fun start(address: ServerAddress, request: PairRequest): PairingResult<PairingSession> =
        post(address, "/api/link/pair", json.encodeToString(request)) { body ->
            json.decodeFromString<PairResponse>(body).pairing
        }

    override suspend fun claim(address: ServerAddress, session: PairingSession): PairingResult<ClaimResult> =
        post(address, "/api/link/pairing/${session.id}/claim", json.encodeToString(ClaimRequest(session.claimSecret))) { body ->
            json.decodeFromString<ClaimResponse>(body).pairing
        }

    private suspend fun <T> post(
        address: ServerAddress,
        path: String,
        body: String,
        decode: (String) -> T,
    ): PairingResult<T> = withContext(Dispatchers.IO) {
        val url = address.url.resolve(path)
            ?: return@withContext PairingResult.Failure("The pairing address is invalid.")
        val request = Request.Builder()
            .url(url)
            .header("Accept", "application/json")
            .post(body.toRequestBody(JSON_MEDIA_TYPE))
            .build()
        try {
            client.newCall(request).execute().use { response ->
                if (!response.isSuccessful) {
                    return@withContext PairingResult.Failure(
                        "HomePlace returned HTTP ${response.code} during pairing.",
                        response.code >= 500,
                    )
                }
                PairingResult.Success(decode(response.body?.string().orEmpty()))
            }
        } catch (_: javax.net.ssl.SSLException) {
            PairingResult.Failure("The server certificate could not be verified.")
        } catch (_: SerializationException) {
            PairingResult.Failure("HomePlace returned an invalid pairing response.")
        } catch (_: IOException) {
            PairingResult.Failure("HomePlace could not be reached during pairing.", true)
        }
    }

    companion object {
        private val JSON_MEDIA_TYPE = "application/json; charset=utf-8".toMediaType()
        private fun defaultClient() = OkHttpClient.Builder()
            .connectTimeout(Duration.ofSeconds(10))
            .readTimeout(Duration.ofSeconds(10))
            .followRedirects(false)
            .followSslRedirects(false)
            .build()
    }
}
