package com.homeplace.mobile.protocol

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class ServerIdentityVerifierTest {
    private val serverId = "9d55059f-5a47-4f23-a778-5714c6744907"
    private val info = ServerInfo(
        product = "HomePlace",
        server = LinkServer(serverId, "Home"),
        protocol = LinkProtocolRange(1, 1),
        serverTime = "2026-09-13T12:00:00Z",
        features = LinkFeatures(pairing = false, realtime = false),
    )

    @Test
    fun acceptsStoredIdentity() {
        assertEquals(IdentityCheck.Match, ServerIdentityVerifier.verify(serverId, info))
    }

    @Test
    fun rejectsDifferentServerAtSameAddress() {
        val result = ServerIdentityVerifier.verify("018f2b5c-7d9a-7e11-8a22-123456789abc", info)

        assertTrue(result is IdentityCheck.Mismatch)
    }
}
