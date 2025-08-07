package com.homeinventory.app.data.dao

import androidx.room.*
import com.homeinventory.app.model.InventoryItemEntity
import com.homeinventory.app.model.InventorySubcategory
import kotlinx.coroutines.flow.Flow

@Dao
interface InventoryDao {
    
    @Query("SELECT * FROM inventory_items ORDER BY name ASC")
    fun getAllItems(): Flow<List<InventoryItemEntity>>
    
    @Query("SELECT * FROM inventory_items WHERE id = :id")
    suspend fun getItemById(id: String): InventoryItemEntity?
    
    @Query("SELECT * FROM inventory_items WHERE subcategory = :subcategory ORDER BY name ASC")
    fun getItemsBySubcategory(subcategory: InventorySubcategory): Flow<List<InventoryItemEntity>>
    
    @Query("SELECT * FROM inventory_items WHERE quantity <= 0.25 ORDER BY quantity ASC")
    fun getLowStockItems(): Flow<List<InventoryItemEntity>>
    
    @Query("SELECT COUNT(*) FROM inventory_items")
    fun getTotalItemsCount(): Flow<Int>
    
    @Query("SELECT COUNT(*) FROM inventory_items WHERE quantity <= 0.25")
    fun getLowStockItemsCount(): Flow<Int>
    
    @Query("SELECT AVG(quantity) FROM inventory_items")
    fun getAverageStockLevel(): Flow<Float>
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertItem(item: InventoryItemEntity)
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertItems(items: List<InventoryItemEntity>)
    
    @Update
    suspend fun updateItem(item: InventoryItemEntity)
    
    @Delete
    suspend fun deleteItem(item: InventoryItemEntity)
    
    @Query("DELETE FROM inventory_items")
    suspend fun deleteAllItems()
    
    @Query("UPDATE inventory_items SET quantity = :quantity, lastUpdated = :lastUpdated WHERE id = :id")
    suspend fun updateItemQuantity(id: String, quantity: Float, lastUpdated: Long)
    
    @Query("UPDATE inventory_items SET name = :name, lastUpdated = :lastUpdated WHERE id = :id")
    suspend fun updateItemName(id: String, name: String, lastUpdated: Long)
}