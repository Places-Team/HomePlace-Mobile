package com.homeplace.mobile.protocol

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class AndroidCapabilitiesTest {
    @Test
    fun unavailableFeaturesAreNotAdvertised() {
        val names = AndroidCapabilities.available(AndroidFeatures()).map { it.name }

        assertTrue(names.isEmpty())
    }

    @Test
    fun implementedFeaturesAreAdvertisedPrecisely() {
        val names = AndroidCapabilities.available(
            AndroidFeatures(notificationReceive = true, presence = true),
        ).map { it.name }

        assertTrue("notification.receive" in names)
        assertTrue("device.presence" in names)
        assertFalse("clipboard.receive" in names)
        assertFalse("app.open" in names)
    }
}
