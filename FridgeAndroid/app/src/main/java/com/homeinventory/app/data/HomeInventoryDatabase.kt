package com.homeinventory.app.data

import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import android.content.Context
import com.homeinventory.app.data.dao.InventoryDao
import com.homeinventory.app.data.dao.NotesDao
import com.homeinventory.app.data.dao.ShoppingDao
import com.homeinventory.app.model.*

@Database(
    entities = [
        InventoryItemEntity::class,
        ShoppingItemEntity::class,
        ShoppingStateEntity::class,
        NoteEntity::class
    ],
    version = 1,
    exportSchema = false
)
@TypeConverters(Converters::class)
abstract class HomeInventoryDatabase : RoomDatabase() {
    
    abstract fun inventoryDao(): InventoryDao
    abstract fun shoppingDao(): ShoppingDao
    abstract fun notesDao(): NotesDao
    
    companion object {
        @Volatile
        private var INSTANCE: HomeInventoryDatabase? = null
        
        fun getDatabase(context: Context): HomeInventoryDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    HomeInventoryDatabase::class.java,
                    "home_inventory_database"
                )
                .fallbackToDestructiveMigration()
                .build()
                INSTANCE = instance
                instance
            }
        }
    }
}