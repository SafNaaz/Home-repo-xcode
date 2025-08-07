package com.homeinventory.app.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.homeinventory.app.model.*
import com.homeinventory.app.repository.InventoryRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class InventoryViewModel @Inject constructor(
    private val inventoryRepository: InventoryRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(InventoryUiState())
    val uiState: StateFlow<InventoryUiState> = _uiState.asStateFlow()

    val allItems = inventoryRepository.getAllItems()
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = emptyList()
        )

    val totalItemsCount = inventoryRepository.getTotalItemsCount()
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = 0
        )

    val lowStockItemsCount = inventoryRepository.getLowStockItemsCount()
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = 0
        )

    val averageStockLevel = inventoryRepository.getAverageStockLevel()
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = 0f
        )

    val lowStockItems = inventoryRepository.getLowStockItems()
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = emptyList()
        )

    val activeCategoriesCount = inventoryRepository.getActiveCategoriesCount()
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = 0
        )

    val mostFrequentlyRestockedItem = inventoryRepository.getMostFrequentlyRestockedItem()
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = null
        )

    val leastUsedItem = inventoryRepository.getLeastUsedItem()
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = null
        )

    val itemsNeedingAttention = inventoryRepository.getItemsNeedingAttention()
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = emptyList()
        )

    val expiredItems = inventoryRepository.getExpiredItems()
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = emptyList()
        )

    val nearExpiryItems = inventoryRepository.getNearExpiryItems()
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = emptyList()
        )

    val criticalKitchenItems = inventoryRepository.getCriticalKitchenItems()
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = emptyList()
        )

    val staleOtherItems = inventoryRepository.getStaleOtherItems()
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = emptyList()
        )

    val urgentAttentionItems = inventoryRepository.getUrgentAttentionItems()
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = emptyList()
        )

    fun getItemsByCategory(category: InventoryCategory): Flow<List<InventoryItem>> {
        return inventoryRepository.getItemsByCategory(category)
    }

    fun getItemsBySubcategory(subcategory: InventorySubcategory): Flow<List<InventoryItem>> {
        return inventoryRepository.getItemsBySubcategory(subcategory)
    }

    fun addCustomItem(name: String, subcategory: InventorySubcategory) {
        viewModelScope.launch {
            inventoryRepository.addCustomItem(name, subcategory)
        }
    }

    fun updateItemQuantity(id: String, quantity: Float) {
        viewModelScope.launch {
            inventoryRepository.updateItemQuantity(id, quantity)
        }
    }

    fun updateItemName(id: String, name: String) {
        viewModelScope.launch {
            inventoryRepository.updateItemName(id, name)
        }
    }

    fun deleteItem(item: InventoryItem) {
        viewModelScope.launch {
            inventoryRepository.deleteItem(item)
        }
    }

    fun restockItem(item: InventoryItem) {
        viewModelScope.launch {
            inventoryRepository.restockItem(item)
        }
    }

    fun createSampleItems() {
        viewModelScope.launch {
            inventoryRepository.createSampleItems()
        }
    }

    fun clearAllData() {
        viewModelScope.launch {
            inventoryRepository.deleteAllItems()
        }
    }

    fun daysSinceLastUpdate(item: InventoryItem): Int {
        return inventoryRepository.daysSinceLastUpdate(item)
    }

    fun getExpiryThreshold(item: InventoryItem): Int {
        return inventoryRepository.getExpiryThreshold(item)
    }

    fun isItemExpired(item: InventoryItem): Boolean {
        return inventoryRepository.isItemExpired(item)
    }

    fun isItemNearExpiry(item: InventoryItem): Boolean {
        return inventoryRepository.isItemNearExpiry(item)
    }

    fun getSmartRecommendations(): Flow<List<SmartRecommendation>> {
        return combine(
            criticalKitchenItems,
            staleOtherItems,
            nearExpiryItems,
            allItems
        ) { critical, stale, nearExpiry, items ->
            val recommendations = mutableListOf<SmartRecommendation>()

            // HIGHEST PRIORITY: Expired Kitchen Items (14+ days)
            if (critical.isNotEmpty()) {
                recommendations.add(
                    SmartRecommendation(
                        title = "🚨 URGENT: Kitchen Items Expired",
                        description = "${critical.size} kitchen items haven't been updated in 2+ weeks. Check for spoilage immediately!",
                        icon = "error",
                        color = androidx.compose.ui.graphics.Color.Red,
                        priority = RecommendationPriority.HIGH
                    )
                )
            }

            // HIGH PRIORITY: Expired Other Items (60+ days)
            if (stale.isNotEmpty()) {
                recommendations.add(
                    SmartRecommendation(
                        title = "⚠️ Stale Items Alert",
                        description = "${stale.size} items haven't been updated in 2+ months. Time to review and update!",
                        icon = "schedule",
                        color = androidx.compose.ui.graphics.Color(0xFFFF9500),
                        priority = RecommendationPriority.HIGH
                    )
                )
            }

            // MEDIUM PRIORITY: Near Expiry Items
            if (nearExpiry.isNotEmpty()) {
                recommendations.add(
                    SmartRecommendation(
                        title = "Items Need Attention Soon",
                        description = "${nearExpiry.size} items are approaching their update deadline. Check them this week.",
                        icon = "update",
                        color = androidx.compose.ui.graphics.Color(0xFFFFD60A),
                        priority = RecommendationPriority.MEDIUM
                    )
                )
            }

            // Critical stock recommendation
            val criticalItems = items.filter { it.quantity <= 0.1f }
            if (criticalItems.isNotEmpty()) {
                recommendations.add(
                    SmartRecommendation(
                        title = "Critical Stock Alert",
                        description = "${criticalItems.size} items are critically low (≤10%). Consider shopping soon.",
                        icon = "warning",
                        color = androidx.compose.ui.graphics.Color.Red,
                        priority = RecommendationPriority.HIGH
                    )
                )
            }

            // Category balance recommendation
            val categoryDistribution = items.groupBy { it.category }
            val imbalancedCategories = categoryDistribution.filter { it.value.size < 2 }
            if (imbalancedCategories.isNotEmpty()) {
                recommendations.add(
                    SmartRecommendation(
                        title = "Expand Your Inventory",
                        description = "Some categories have very few items. Consider adding more items for better tracking.",
                        icon = "add_circle",
                        color = androidx.compose.ui.graphics.Color(0xFF007AFF),
                        priority = RecommendationPriority.LOW
                    )
                )
            }

            // Shopping efficiency recommendation
            val lowStockByCategory = items.filter { it.needsRestocking }.groupBy { it.category }
            if (lowStockByCategory.size > 2) {
                recommendations.add(
                    SmartRecommendation(
                        title = "Optimize Shopping Route",
                        description = "You have low stock items across ${lowStockByCategory.size} categories. Plan your store route efficiently.",
                        icon = "map",
                        color = androidx.compose.ui.graphics.Color(0xFF34C759),
                        priority = RecommendationPriority.MEDIUM
                    )
                )
            }

            // Frequent restocking recommendation
            val frequentItems = items.filter { it.purchaseHistory.size > 5 }
            if (frequentItems.isNotEmpty()) {
                recommendations.add(
                    SmartRecommendation(
                        title = "Consider Bulk Buying",
                        description = "${frequentItems.size} items are restocked frequently. Consider buying in bulk to save trips.",
                        icon = "shopping_cart",
                        color = androidx.compose.ui.graphics.Color(0xFF5856D6),
                        priority = RecommendationPriority.LOW
                    )
                )
            }

            // Default recommendation if no specific insights
            if (recommendations.isEmpty()) {
                recommendations.add(
                    SmartRecommendation(
                        title = "Great Job!",
                        description = "Your inventory is well-maintained. Keep tracking your items for better insights.",
                        icon = "check_circle",
                        color = androidx.compose.ui.graphics.Color(0xFF34C759),
                        priority = RecommendationPriority.LOW
                    )
                )
            }

            recommendations.sortedByDescending { it.priority == RecommendationPriority.HIGH }
        }
    }

    fun setSelectedCategory(category: InventoryCategory?) {
        _uiState.value = _uiState.value.copy(selectedCategory = category)
    }

    fun setSelectedSubcategory(subcategory: InventorySubcategory?) {
        _uiState.value = _uiState.value.copy(selectedSubcategory = subcategory)
    }

    fun setShowingAddItem(showing: Boolean) {
        _uiState.value = _uiState.value.copy(showingAddItem = showing)
    }

    fun setShowingEditItem(item: InventoryItem?) {
        _uiState.value = _uiState.value.copy(editingItem = item)
    }
}

data class InventoryUiState(
    val selectedCategory: InventoryCategory? = null,
    val selectedSubcategory: InventorySubcategory? = null,
    val showingAddItem: Boolean = false,
    val editingItem: InventoryItem? = null,
    val isLoading: Boolean = false,
    val errorMessage: String? = null
)