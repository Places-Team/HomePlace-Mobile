package com.homeplace.mobile.network

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class ServerAddressNormalizerTest {
    @Test
    fun publicDomainDefaultsToHttps() {
        val result = ServerAddressNormalizer.normalize("home.example.net") as AddressResult.Valid

        assertEquals("https://home.example.net/", result.address.url.toString())
        assertTrue(result.address.isSecure)
        assertFalse(result.address.isLocal)
    }

    @Test
    fun localIpv4WithPortAllowsHttp() {
        val result = ServerAddressNormalizer.normalize("192.168.1.20:3200") as AddressResult.Valid

        assertEquals("http://192.168.1.20:3200/", result.address.url.toString())
        assertTrue(result.address.isLocal)
        assertFalse(result.address.isSecure)
    }

    @Test
    fun localHostnameAllowsHttp() {
        val result = ServerAddressNormalizer.normalize("homeplace.local") as AddressResult.Valid

        assertEquals("http://homeplace.local/", result.address.url.toString())
    }

    @Test
    fun publicHttpIsRejected() {
        val result = ServerAddressNormalizer.normalize("http://home.example.net")

        assertTrue(result is AddressResult.Invalid)
    }

    @Test
    fun credentialsAreRejected() {
        val result = ServerAddressNormalizer.normalize("https://user:secret@home.example.net")

        assertTrue(result is AddressResult.Invalid)
    }

    @Test
    fun pathsAreRejected() {
        val result = ServerAddressNormalizer.normalize("https://home.example.net/admin")

        assertTrue(result is AddressResult.Invalid)
    }

    @Test
    fun uniqueLocalIpv6AllowsHttp() {
        val result = ServerAddressNormalizer.normalize("http://[fd00::20]:3200") as AddressResult.Valid

        assertTrue(result.address.isLocal)
    }
}
