package com.homeplace.mobile.data

import androidx.room.Dao
import androidx.room.Database
import androidx.room.Entity
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.PrimaryKey
import androidx.room.Query
import androidx.room.RoomDatabase
import kotlinx.coroutines.flow.Flow

@Entity(tableName = "connection_profiles")
data class ConnectionProfile(
    @PrimaryKey val serverId: String,
    val name: String,
    val preferredUrl: String,
    val credentialAlias: String? = null,
)

@Dao
interface ConnectionProfileDao {
    @Query("SELECT * FROM connection_profiles ORDER BY name")
    fun observeAll(): Flow<List<ConnectionProfile>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun save(profile: ConnectionProfile)

    @Query("DELETE FROM connection_profiles WHERE serverId = :serverId")
    suspend fun delete(serverId: String)
}

@Database(entities = [ConnectionProfile::class], version = 1, exportSchema = true)
abstract class HomePlaceDatabase : RoomDatabase() {
    abstract fun connectionProfiles(): ConnectionProfileDao
}
