package com.homeplace.mobile

import android.app.PendingIntent
import android.content.Intent
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService

class TransferTileService : TileService() {
    override fun onStartListening() {
        super.onStartListening()
        qsTile?.apply {
            state = Tile.STATE_ACTIVE
            label = getString(R.string.transfer_tile_label)
            updateTile()
        }
    }

    override fun onClick() {
        super.onClick()
        val destination = Intent(this, MainActivity::class.java).apply {
            action = ACTION_OPEN_TRANSFERS
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        if (Build.VERSION.SDK_INT >= 34) {
            val pendingIntent = PendingIntent.getActivity(
                this,
                0,
                destination,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            startActivityAndCollapse(pendingIntent)
        } else {
            @Suppress("DEPRECATION")
            startActivityAndCollapse(destination)
        }
    }

    companion object {
        const val ACTION_OPEN_TRANSFERS = "com.homeplace.mobile.OPEN_TRANSFERS"
    }
}
