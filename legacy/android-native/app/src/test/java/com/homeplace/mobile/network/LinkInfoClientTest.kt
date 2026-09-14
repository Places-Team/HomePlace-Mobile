package com.homeplace.mobile.network

import kotlinx.coroutines.test.runTest
import okhttp3.OkHttpClient
import okhttp3.mockwebserver.MockResponse
import okhttp3.mockwebserver.MockWebServer
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

class LinkInfoClientTest {
    private lateinit var server: MockWebServer

    @Before
    fun startServer() {
        server = MockWebServer()
        server.start()
    }

    @After
    fun stopServer() = server.shutdown()

    @Test
    fun readsCompatibleServerInfo() = runTest {
        server.enqueue(
            MockResponse().setResponseCode(200).setHeader("Content-Type", "application/json").setBody(
                """{"product":"HomePlace","server":{"id":"9d55059f-5a47-4f23-a778-5714c6744907","name":"Our Home"},"protocol":{"min":1,"max":1},"serverTime":"2026-09-13T12:00:00Z","features":{"pairing":false,"realtime":false}}""",
            ),
        )

        val result = LinkInfoClient(OkHttpClient()).fetch(
            ServerAddress(server.url("/"), isSecure = false, isLocal = true),
        )

        assertTrue(result is ServerInfoResult.Success)
        assertEquals("/api/link/info", server.takeRequest().path)
    }

    @Test
    fun rejectsUnsupportedProtocol() = runTest {
        server.enqueue(
            MockResponse().setResponseCode(200).setBody(
                """{"product":"HomePlace","server":{"id":"9d55059f-5a47-4f23-a778-5714c6744907","name":"Our Home"},"protocol":{"min":2,"max":3},"serverTime":"2026-09-13T12:00:00Z","features":{"pairing":false,"realtime":false}}""",
            ),
        )

        val result = LinkInfoClient(OkHttpClient()).fetch(
            ServerAddress(server.url("/"), isSecure = false, isLocal = true),
        )

        assertTrue(result is ServerInfoResult.Failure && result.kind == FailureKind.INCOMPATIBLE)
    }

    @Test
    fun doesNotFollowRedirects() = runTest {
        server.enqueue(MockResponse().setResponseCode(302).setHeader("Location", "https://example.net/api/link/info"))

        val result = LinkInfoClient().fetch(ServerAddress(server.url("/"), false, true))

        assertTrue(result is ServerInfoResult.Failure)
        assertEquals(1, server.requestCount)
    }
}
