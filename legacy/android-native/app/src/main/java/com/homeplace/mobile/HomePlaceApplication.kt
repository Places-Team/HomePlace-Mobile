package com.homeplace.mobile

import android.app.Application
import androidx.room.Room
import com.homeplace.mobile.data.HomePlaceDatabase

class HomePlaceApplication : Application() {
    val database: HomePlaceDatabase by lazy {
        Room.databaseBuilder(this, HomePlaceDatabase::class.java, "homeplace.db").build()
    }
}
