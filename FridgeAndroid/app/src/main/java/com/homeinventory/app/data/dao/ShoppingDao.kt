package com.homeinventory.app.data.dao

import androidx.room.*
import com.homeinventory.app.model.ShoppingItemEntity
import com.homeinventory.app.model.ShoppingStateEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface ShoppingDao {
    
    @Query("SELECT * FROM shopping_items ORDER BY name ASC")
    fun getAllShoppingItems(): Flow<List<ShoppingItemEntity>>
    
    @Query("SELECT * FROM shopping_items WHERE id = :id")
    suspend fun getShoppingItemById(id: String): ShoppingItemEntity?
    
    @Query("SELECT * FROM shopping_items WHERE isChecked = 1")
    fun getCheckedItems(): Flow<List<ShoppingItemEntity>>
    
    @Query("SELECT * FROM shopping_items WHERE isChecked = 0")
    fun getUncheckedItems(): Flow<List<ShoppingItemEntity>>
    
    @Query("SELECT * FROM shopping_items WHERE isTemporary = 1")
    fun getTemporaryItems(): Flow<List<ShoppingItemEntity>>
    
    @Query("SELECT * FROM shopping_items WHERE isTemporary = 0")
    fun getInventoryItems(): Flow<List<ShoppingItemEntity>>
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertShoppingItem(item: ShoppingItemEntity)
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertShoppingItems(items: List<ShoppingItemEntity>)
    
    @Update
    suspend fun updateShoppingItem(item: ShoppingItemEntity)
    
    @Delete
    suspend fun deleteShoppingItem(item: ShoppingItemEntity)
    
    @Query("DELETE FROM shopping_items")
    suspend fun deleteAllShoppingItems()
    
    @Query("UPDATE shopping_items SET isChecked = :isChecked WHERE id = :id")
    suspend fun updateItemCheckedStatus(id: String, isChecked: Boolean)
    
    // Shopping State methods
    @Query("SELECT * FROM shopping_state ORDER BY createdDate DESC LIMIT 1")
    suspend fun getCurrentShoppingState(): ShoppingStateEntity?
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertShoppingState(state: ShoppingStateEntity)
    
    @Query("DELETE FROM shopping_state")
    suspend fun deleteAllShoppingStates()
}