package com.homeplace.mobile.protocol

sealed class IdentityCheck {
    data object Match : IdentityCheck()
    data class Mismatch(val expected: String, val actual: String) : IdentityCheck()
}

object ServerIdentityVerifier {
    fun verify(expectedServerId: String, info: ServerInfo): IdentityCheck =
        if (expectedServerId == info.serverId) {
            IdentityCheck.Match
        } else {
            IdentityCheck.Mismatch(expectedServerId, info.serverId)
        }
}
