package com.homeinventory.app.di

import android.content.Context
import androidx.room.Room
import com.homeinventory.app.data.HomeInventoryDatabase
import com.homeinventory.app.data.dao.InventoryDao
import com.homeinventory.app.data.dao.NotesDao
import com.homeinventory.app.data.dao.ShoppingDao
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object DatabaseModule {
    
    @Provides
    @Singleton
    fun provideHomeInventoryDatabase(
        @ApplicationContext context: Context
    ): HomeInventoryDatabase {
        return Room.databaseBuilder(
            context.applicationContext,
            HomeInventoryDatabase::class.java,
            "home_inventory_database"
        )
        .fallbackToDestructiveMigration()
        .build()
    }
    
    @Provides
    fun provideInventoryDao(database: HomeInventoryDatabase): InventoryDao {
        return database.inventoryDao()
    }
    
    @Provides
    fun provideShoppingDao(database: HomeInventoryDatabase): ShoppingDao {
        return database.shoppingDao()
    }
    
    @Provides
    fun provideNotesDao(database: HomeInventoryDatabase): NotesDao {
        return database.notesDao()
    }
}