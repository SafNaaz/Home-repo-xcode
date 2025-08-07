package com.homeinventory.app.repository

import com.homeinventory.app.data.dao.ShoppingDao
import com.homeinventory.app.model.*
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.map
import java.util.*
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class ShoppingRepository @Inject constructor(
    private val shoppingDao: ShoppingDao,
    private val inventoryRepository: InventoryRepository
) {
    
    fun getAllShoppingItems(): Flow<List<ShoppingItem>> {
        return combine(
            shoppingDao.getAllShoppingItems(),
            inventoryRepository.getAllItems()
        ) { shoppingEntities, inventoryItems ->
            shoppingEntities.map { entity ->
                val inventoryItem = if (!entity.isTemporary && entity.inventoryItemId != null) {
                    inventoryItems.find { it.id == entity.inventoryItemId }
                } else null
                ShoppingItem.fromEntity(entity, inventoryItem)
            }
        }
    }
    
    suspend fun getShoppingItemById(id: String): ShoppingItem? {
        val entity = shoppingDao.getShoppingItemById(id) ?: return null
        val inventoryItem = if (!entity.isTemporary && entity.inventoryItemId != null) {
            inventoryRepository.getItemById(entity.inventoryItemId)
        } else null
        return ShoppingItem.fromEntity(entity, inventoryItem)
    }
    
    fun getCheckedItems(): Flow<List<ShoppingItem>> {
        return combine(
            shoppingDao.getCheckedItems(),
            inventoryRepository.getAllItems()
        ) { shoppingEntities, inventoryItems ->
            shoppingEntities.map { entity ->
                val inventoryItem = if (!entity.isTemporary && entity.inventoryItemId != null) {
                    inventoryItems.find { it.id == entity.inventoryItemId }
                } else null
                ShoppingItem.fromEntity(entity, inventoryItem)
            }
        }
    }
    
    fun getUncheckedItems(): Flow<List<ShoppingItem>> {
        return combine(
            shoppingDao.getUncheckedItems(),
            inventoryRepository.getAllItems()
        ) { shoppingEntities, inventoryItems ->
            shoppingEntities.map { entity ->
                val inventoryItem = if (!entity.isTemporary && entity.inventoryItemId != null) {
                    inventoryItems.find { it.id == entity.inventoryItemId }
                } else null
                ShoppingItem.fromEntity(entity, inventoryItem)
            }
        }
    }
    
    fun getTemporaryItems(): Flow<List<ShoppingItem>> {
        return shoppingDao.getTemporaryItems().map { entities ->
            entities.map { ShoppingItem.fromEntity(it) }
        }
    }
    
    fun getInventoryItems(): Flow<List<ShoppingItem>> {
        return combine(
            shoppingDao.getInventoryItems(),
            inventoryRepository.getAllItems()
        ) { shoppingEntities, inventoryItems ->
            shoppingEntities.map { entity ->
                val inventoryItem = inventoryItems.find { it.id == entity.inventoryItemId }
                ShoppingItem.fromEntity(entity, inventoryItem)
            }
        }
    }
    
    suspend fun addShoppingItem(item: ShoppingItem) {
        shoppingDao.insertShoppingItem(item.toEntity())
    }
    
    suspend fun addTemporaryItem(name: String) {
        val item = ShoppingItemEntity(
            name = name,
            isChecked = false,
            isTemporary = true,
            inventoryItemId = null
        )
        shoppingDao.insertShoppingItem(item)
    }
    
    suspend fun addInventoryItemToShopping(inventoryItem: InventoryItem) {
        val item = ShoppingItemEntity(
            name = inventoryItem.name,
            isChecked = false,
            isTemporary = false,
            inventoryItemId = inventoryItem.id
        )
        shoppingDao.insertShoppingItem(item)
    }
    
    suspend fun updateShoppingItem(item: ShoppingItem) {
        shoppingDao.updateShoppingItem(item.toEntity())
    }
    
    suspend fun toggleItemCheckedStatus(id: String, isChecked: Boolean) {
        shoppingDao.updateItemCheckedStatus(id, isChecked)
    }
    
    suspend fun deleteShoppingItem(item: ShoppingItem) {
        shoppingDao.deleteShoppingItem(item.toEntity())
    }
    
    suspend fun clearAllShoppingItems() {
        shoppingDao.deleteAllShoppingItems()
    }
    
    // Shopping State Management
    suspend fun getCurrentShoppingState(): ShoppingState {
        return shoppingDao.getCurrentShoppingState()?.state ?: ShoppingState.EMPTY
    }
    
    suspend fun saveShoppingState(state: ShoppingState) {
        // Clear existing states
        shoppingDao.deleteAllShoppingStates()
        // Insert new state
        val stateEntity = ShoppingStateEntity(
            state = state,
            createdDate = Date()
        )
        shoppingDao.insertShoppingState(stateEntity)
    }
    
    // Shopping Flow Methods
    suspend fun startGeneratingShoppingList() {
        // Clear existing shopping list
        clearAllShoppingItems()
        
        // Get items that need attention (≤25%) - sorted by urgency
        inventoryRepository.getLowStockItems().collect { lowStockItems ->
            val sortedItems = lowStockItems.sortedBy { it.quantity }
            
            for (item in sortedItems) {
                addInventoryItemToShopping(item)
            }
        }
        
        // Set state to generating
        saveShoppingState(ShoppingState.GENERATING)
    }
    
    suspend fun finalizeShoppingList() {
        saveShoppingState(ShoppingState.LIST_READY)
    }
    
    suspend fun startShopping() {
        saveShoppingState(ShoppingState.SHOPPING)
    }
    
    suspend fun completeAndRestoreShopping() {
        // Get checked items and restore inventory
        getCheckedItems().collect { checkedItems ->
            for (item in checkedItems) {
                if (!item.isTemporary && item.inventoryItem != null) {
                    inventoryRepository.restockItem(item.inventoryItem)
                }
            }
        }
        
        // Clear shopping list and reset state
        clearAllShoppingItems()
        saveShoppingState(ShoppingState.EMPTY)
    }
    
    suspend fun cancelShopping() {
        clearAllShoppingItems()
        saveShoppingState(ShoppingState.EMPTY)
    }
    
    // Shopping Insights
    fun getEstimatedShoppingFrequency(): Flow<String> {
        return inventoryRepository.getAllItems().map { items ->
            val totalPurchases = items.sumOf { it.purchaseHistory.size }
            if (totalPurchases == 0) return@map "No data yet"
            
            val itemsWithMultiplePurchases = items.filter { it.purchaseHistory.size > 1 }
            if (itemsWithMultiplePurchases.isEmpty()) return@map "Weekly"
            
            val totalDaysBetweenPurchases = itemsWithMultiplePurchases.sumOf { item ->
                val sortedHistory = item.purchaseHistory.sorted()
                var totalDays = 0
                for (i in 1 until sortedHistory.size) {
                    val days = ((sortedHistory[i].time - sortedHistory[i-1].time) / (1000 * 60 * 60 * 24)).toInt()
                    totalDays += days
                }
                totalDays / (sortedHistory.size - 1)
            }
            
            val avgDays = totalDaysBetweenPurchases / itemsWithMultiplePurchases.size
            
            when {
                avgDays <= 7 -> "Weekly"
                avgDays <= 14 -> "Bi-weekly"
                avgDays <= 30 -> "Monthly"
                else -> "Rarely"
            }
        }
    }
    
    fun getEstimatedNextShoppingTrip(): Flow<String> {
        return inventoryRepository.getAllItems().map { items ->
            val lowStockItems = items.filter { it.needsRestocking }
            val criticalItems = items.filter { it.quantity <= 0.1f }
            
            when {
                criticalItems.isNotEmpty() -> "Now (critical items)"
                lowStockItems.size >= 5 -> "This week"
                lowStockItems.isNotEmpty() -> "Next week"
                else -> "No rush"
            }
        }
    }
    
    fun getShoppingEfficiencyTip(): Flow<String> {
        return inventoryRepository.getLowStockItems().map { lowStockItems ->
            val categoryGroups = lowStockItems.groupBy { it.category }
            val maxCategory = categoryGroups.maxByOrNull { it.value.size }
            
            if (maxCategory != null && maxCategory.value.size > 1) {
                "Focus on ${maxCategory.key.displayName} section"
            } else {
                "Spread across categories"
            }
        }
    }
}