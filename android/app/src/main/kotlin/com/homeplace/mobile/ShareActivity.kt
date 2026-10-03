package com.homeplace.mobile

import io.flutter.embedding.android.FlutterActivityLaunchConfigs.BackgroundMode

class ShareActivity : MainActivity() {
    override fun getBackgroundMode(): BackgroundMode = BackgroundMode.transparent
}
