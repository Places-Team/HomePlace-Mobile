package com.homeplace.mobile.protocol

import kotlinx.serialization.Serializable

const val SUPPORTED_LINK_PROTOCOL = 1

@Serializable
data class ServerInfo(
    val product: String,
    val server: LinkServer,
    val protocol: LinkProtocolRange,
    val serverTime: String,
    val features: LinkFeatures,
)

@Serializable
data class LinkServer(val id: String, val name: String)

@Serializable
data class LinkProtocolRange(val min: Int, val max: Int)

@Serializable
data class LinkFeatures(val pairing: Boolean, val realtime: Boolean)

val ServerInfo.serverId: String get() = server.id
val ServerInfo.serverName: String get() = server.name
val ServerInfo.protocolMin: Int get() = protocol.min
val ServerInfo.protocolMax: Int get() = protocol.max

fun ServerInfo.supportsClient(): Boolean =
    product == "HomePlace" &&
        UUID_PATTERN.matches(server.id) &&
        server.name.isNotBlank() &&
        protocol.min <= protocol.max &&
        SUPPORTED_LINK_PROTOCOL in protocol.min..protocol.max

private val UUID_PATTERN = Regex(
    "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89aAbB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$",
)

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
