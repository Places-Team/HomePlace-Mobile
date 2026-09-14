package com.homeplace.mobile.network

import com.homeplace.mobile.protocol.SUPPORTED_LINK_PROTOCOL
import java.io.IOException
import java.time.Duration
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.Serializable
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonElement
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody

@Serializable
private data class HeartbeatRequest(
    val protocol: Int = SUPPORTED_LINK_PROTOCOL,
    val acknowledgedEventIds: List<String>,
)

@Serializable
data class DeviceEvent(
    val protocol: Int,
    val id: String,
    val type: String,
    val deviceId: String,
    val sentAt: String,
    val payload: JsonElement,
)

@Serializable
data class HeartbeatResponse(
    val protocol: Int,
    val serverId: String,
    val serverTime: String,
    val events: List<DeviceEvent>,
)

sealed class DeviceResult<out T> {
    data class Success<T>(val value: T) : DeviceResult<T>()
    data object Unauthorized : DeviceResult<Nothing>()
    data class Failure(val message: String) : DeviceResult<Nothing>()
}

interface DeviceService {
    suspend fun heartbeat(address: ServerAddress, credential: String, acknowledged: List<String>): DeviceResult<HeartbeatResponse>
    suspend fun revoke(address: ServerAddress, credential: String): DeviceResult<Unit>
}

class DeviceClient(
    private val client: OkHttpClient = defaultClient(),
    private val json: Json = Json { ignoreUnknownKeys = true },
) : DeviceService {
    override suspend fun heartbeat(
        address: ServerAddress,
        credential: String,
        acknowledged: List<String>,
    ): DeviceResult<HeartbeatResponse> = request(
        address = address,
        path = "/api/link/heartbeat",
        credential = credential,
        method = "POST",
        body = json.encodeToString(HeartbeatRequest(acknowledgedEventIds = acknowledged)),
    ) { json.decodeFromString<HeartbeatResponse>(it) }

    override suspend fun revoke(address: ServerAddress, credential: String): DeviceResult<Unit> = request(
        address = address,
        path = "/api/link/device",
        credential = credential,
        method = "DELETE",
    ) { Unit }

    private suspend fun <T> request(
        address: ServerAddress,
        path: String,
        credential: String,
        method: String,
        body: String? = null,
        decode: (String) -> T,
    ): DeviceResult<T> = withContext(Dispatchers.IO) {
        val url = address.url.resolve(path) ?: return@withContext DeviceResult.Failure("The device endpoint is invalid.")
        val builder = Request.Builder().url(url).header("Accept", "application/json").header("Authorization", "Bearer $credential")
        if (method == "DELETE") builder.delete() else builder.post(requireNotNull(body).toRequestBody(JSON_MEDIA_TYPE))
        try {
            client.newCall(builder.build()).execute().use { response ->
                if (response.code == 401) return@withContext DeviceResult.Unauthorized
                if (!response.isSuccessful) return@withContext DeviceResult.Failure("HomePlace returned HTTP ${response.code}.")
                DeviceResult.Success(decode(response.body?.string().orEmpty()))
            }
        } catch (_: IOException) {
            DeviceResult.Failure("HomePlace could not be reached.")
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
