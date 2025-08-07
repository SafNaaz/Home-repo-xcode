package com.homeinventory.app.repository

import com.homeinventory.app.data.dao.InventoryDao
import com.homeinventory.app.model.*
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import java.util.*
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class InventoryRepository @Inject constructor(
    private val inventoryDao: InventoryDao
) {
    
    fun getAllItems(): Flow<List<InventoryItem>> {
        return inventoryDao.getAllItems().map { entities ->
            entities.map { InventoryItem.fromEntity(it) }
        }
    }
    
    suspend fun getItemById(id: String): InventoryItem? {
        return inventoryDao.getItemById(id)?.let { InventoryItem.fromEntity(it) }
    }
    
    fun getItemsBySubcategory(subcategory: InventorySubcategory): Flow<List<InventoryItem>> {
        return inventoryDao.getItemsBySubcategory(subcategory).map { entities ->
            entities.map { InventoryItem.fromEntity(it) }
        }
    }
    
    fun getItemsByCategory(category: InventoryCategory): Flow<List<InventoryItem>> {
        return getAllItems().map { items ->
            items.filter { it.category == category }
        }
    }
    
    fun getLowStockItems(): Flow<List<InventoryItem>> {
        return inventoryDao.getLowStockItems().map { entities ->
            entities.map { InventoryItem.fromEntity(it) }
        }
    }
    
    fun getTotalItemsCount(): Flow<Int> {
        return inventoryDao.getTotalItemsCount()
    }
    
    fun getLowStockItemsCount(): Flow<Int> {
        return inventoryDao.getLowStockItemsCount()
    }
    
    fun getAverageStockLevel(): Flow<Float> {
        return inventoryDao.getAverageStockLevel()
    }
    
    suspend fun addItem(item: InventoryItem) {
        inventoryDao.insertItem(item.toEntity())
    }
    
    suspend fun addCustomItem(name: String, subcategory: InventorySubcategory) {
        val item = InventoryItemEntity(
            name = name,
            quantity = 0.0f,
            subcategory = subcategory,
            isCustom = true,
            purchaseHistory = emptyList(),
            lastUpdated = Date()
        )
        inventoryDao.insertItem(item)
    }
    
    suspend fun updateItem(item: InventoryItem) {
        inventoryDao.updateItem(item.toEntity())
    }
    
    suspend fun updateItemQuantity(id: String, quantity: Float) {
        inventoryDao.updateItemQuantity(id, quantity, Date().time)
    }
    
    suspend fun updateItemName(id: String, name: String) {
        inventoryDao.updateItemName(id, name, Date().time)
    }
    
    suspend fun restockItem(item: InventoryItem) {
        val updatedItem = item.toEntity().restockToFull()
        inventoryDao.updateItem(updatedItem)
    }
    
    suspend fun deleteItem(item: InventoryItem) {
        inventoryDao.deleteItem(item.toEntity())
    }
    
    suspend fun deleteAllItems() {
        inventoryDao.deleteAllItems()
    }
    
    suspend fun createSampleItems() {
        val sampleItems = mutableListOf<InventoryItemEntity>()
        
        InventorySubcategory.values().forEach { subcategory ->
            subcategory.sampleItems.forEach { itemName ->
                val item = InventoryItemEntity(
                    name = itemName,
                    quantity = (0.2f..1.0f).random(),
                    subcategory = subcategory,
                    isCustom = false,
                    purchaseHistory = emptyList(),
                    lastUpdated = Date()
                )
                sampleItems.add(item)
            }
        }
        
        inventoryDao.insertItems(sampleItems)
    }
    
    // Analytics methods
    fun getItemsNeedingAttention(): Flow<List<InventoryItem>> {
        return getLowStockItems().map { items ->
            items.sortedBy { it.quantity }
        }
    }
    
    fun getMostFrequentlyRestockedItem(): Flow<InventoryItem?> {
        return getAllItems().map { items ->
            items.maxByOrNull { it.purchaseHistory.size }
        }
    }
    
    fun getLeastUsedItem(): Flow<InventoryItem?> {
        return getAllItems().map { items ->
            items.minByOrNull { it.lastUpdated.time }
        }
    }
    
    fun getActiveCategoriesCount(): Flow<Int> {
        return getAllItems().map { items ->
            items.map { it.category }.distinct().size
        }
    }
    
    fun daysSinceLastUpdate(item: InventoryItem): Int {
        val now = Date()
        val diffInMillis = now.time - item.lastUpdated.time
        return (diffInMillis / (1000 * 60 * 60 * 24)).toInt()
    }
    
    fun getExpiryThreshold(item: InventoryItem): Int {
        return if (item.category == InventoryCategory.FRIDGE) 14 else 60
    }
    
    fun isItemExpired(item: InventoryItem): Boolean {
        val daysSince = daysSinceLastUpdate(item)
        val threshold = getExpiryThreshold(item)
        return daysSince >= threshold
    }
    
    fun isItemNearExpiry(item: InventoryItem): Boolean {
        val daysSince = daysSinceLastUpdate(item)
        val threshold = getExpiryThreshold(item)
        val warningThreshold = (threshold * 0.8).toInt()
        return daysSince >= warningThreshold && daysSince < threshold
    }
    
    fun getExpiredItems(): Flow<List<InventoryItem>> {
        return getAllItems().map { items ->
            items.filter { isItemExpired(it) }
        }
    }
    
    fun getNearExpiryItems(): Flow<List<InventoryItem>> {
        return getAllItems().map { items ->
            items.filter { isItemNearExpiry(it) }
        }
    }
    
    fun getCriticalKitchenItems(): Flow<List<InventoryItem>> {
        return getAllItems().map { items ->
            items.filter { item ->
                item.category == InventoryCategory.FRIDGE && daysSinceLastUpdate(item) >= 14
            }
        }
    }
    
    fun getStaleOtherItems(): Flow<List<InventoryItem>> {
        return getAllItems().map { items ->
            items.filter { item ->
                item.category != InventoryCategory.FRIDGE && daysSinceLastUpdate(item) >= 60
            }
        }
    }
    
    fun getUrgentAttentionItems(): Flow<List<InventoryItem>> {
        return getAllItems().map { items ->
            val expired = items.filter { isItemExpired(it) }
            val nearExpiry = items.filter { isItemNearExpiry(it) }
            (expired + nearExpiry).distinct()
        }
    }
}