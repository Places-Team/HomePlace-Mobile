package com.homeplace.mobile.protocol

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

const val SUPPORTED_LINK_PROTOCOL = 1

@Serializable
data class ServerInfo(
    val serverId: String,
    val serverName: String,
    @SerialName("protocolMin") val protocolMin: Int,
    @SerialName("protocolMax") val protocolMax: Int,
    val serverTime: String? = null,
)

fun ServerInfo.supportsClient(): Boolean =
    serverId.isNotBlank() &&
        serverName.isNotBlank() &&
        SUPPORTED_LINK_PROTOCOL in protocolMin..protocolMax

@Serializable
data class Capability(
    val name: String,
    val version: Int = 1,
    val constraints: Map<String, String> = emptyMap(),
)

data class AndroidFeatures(
    val notificationReceive: Boolean = false,
    val urlOpen: Boolean = false,
    val textReceive: Boolean = false,
    val fileReceive: Boolean = false,
    val shareSend: Boolean = false,
    val batteryReporting: Boolean = false,
    val networkReporting: Boolean = false,
    val presence: Boolean = false,
)

object AndroidCapabilities {
    fun available(features: AndroidFeatures): List<Capability> = buildList {
        if (features.notificationReceive) add(Capability("notification.receive"))
        if (features.urlOpen) add(Capability("url.open"))
        if (features.textReceive) add(Capability("text.receive"))
        if (features.fileReceive) {
            add(Capability("file.receive", constraints = mapOf("requiresConfirmation" to "true")))
        }
        if (features.shareSend) add(Capability("share.send"))
        if (features.batteryReporting) add(Capability("device.battery"))
        if (features.networkReporting) add(Capability("device.network"))
        if (features.presence) add(Capability("device.presence"))
    }
}
