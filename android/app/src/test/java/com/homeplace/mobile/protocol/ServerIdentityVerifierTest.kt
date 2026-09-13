package com.homeplace.mobile.protocol

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class ServerIdentityVerifierTest {
    private val info = ServerInfo("server-new", "Home", 1, 1)

    @Test
    fun acceptsStoredIdentity() {
        assertEquals(IdentityCheck.Match, ServerIdentityVerifier.verify("server-new", info))
    }

    @Test
    fun rejectsDifferentServerAtSameAddress() {
        val result = ServerIdentityVerifier.verify("server-old", info)

        assertTrue(result is IdentityCheck.Mismatch)
    }
}
