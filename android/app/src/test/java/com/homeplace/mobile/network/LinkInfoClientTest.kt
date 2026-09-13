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
                """{"serverId":"home-01","serverName":"Our Home","protocolMin":1,"protocolMax":1}""",
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
                """{"serverId":"home-01","serverName":"Our Home","protocolMin":2,"protocolMax":3}""",
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
