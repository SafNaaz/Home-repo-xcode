package com.homeinventory.app.model

import androidx.compose.ui.graphics.Color
import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.TypeConverter
import androidx.room.TypeConverters
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import java.util.*

// Enums for Categories and Subcategories
enum class InventoryCategory(val displayName: String, val icon: String, val color: Color) {
    FRIDGE("Fridge", "kitchen", Color(0xFF007AFF)),
    GROCERY("Grocery", "shopping_basket", Color(0xFF34C759)),
    HYGIENE("Hygiene", "cleaning_services", Color(0xFF00C7BE)),
    PERSONAL_CARE("Personal Care", "face", Color(0xFFFF2D92));

    val subcategories: List<InventorySubcategory>
        get() = when (this) {
            FRIDGE -> listOf(
                InventorySubcategory.DOOR_BOTTLES,
                InventorySubcategory.TRAY,
                InventorySubcategory.MAIN,
                InventorySubcategory.VEGETABLE,
                InventorySubcategory.FREEZER,
                InventorySubcategory.MINI_COOLER
            )
            GROCERY -> listOf(
                InventorySubcategory.RICE,
                InventorySubcategory.PULSES,
                InventorySubcategory.CEREALS,
                InventorySubcategory.CONDIMENTS,
                InventorySubcategory.OILS
            )
            HYGIENE -> listOf(
                InventorySubcategory.WASHING,
                InventorySubcategory.DISHWASHING,
                InventorySubcategory.TOILET_CLEANING,
                InventorySubcategory.KIDS,
                InventorySubcategory.GENERAL_CLEANING
            )
            PERSONAL_CARE -> listOf(
                InventorySubcategory.FACE,
                InventorySubcategory.BODY,
                InventorySubcategory.HEAD
            )
        }
}

enum class InventorySubcategory(
    val displayName: String,
    val icon: String,
    val color: Color,
    val category: InventoryCategory
) {
    // Fridge subcategories
    DOOR_BOTTLES("Door Bottles", "water_bottle", Color(0xFF007AFF), InventoryCategory.FRIDGE),
    TRAY("Tray Section", "restaurant", Color(0xFFFF9500), InventoryCategory.FRIDGE),
    MAIN("Main Section", "kitchen", Color(0xFF34C759), InventoryCategory.FRIDGE),
    VEGETABLE("Vegetable Section", "eco", Color(0xFF30D158), InventoryCategory.FRIDGE),
    FREEZER("Freezer", "ac_unit", Color(0xFF00C7BE), InventoryCategory.FRIDGE),
    MINI_COOLER("Mini Cooler", "kitchen", Color(0xFF5856D6), InventoryCategory.FRIDGE),

    // Grocery subcategories
    RICE("Rice Items", "grain", Color(0xFF8E4EC6), InventoryCategory.GROCERY),
    PULSES("Pulses", "circle", Color(0xFFFFD60A), InventoryCategory.GROCERY),
    CEREALS("Cereals", "breakfast_dining", Color(0xFFFF9500), InventoryCategory.GROCERY),
    CONDIMENTS("Condiments", "water_drop", Color(0xFFFF3B30), InventoryCategory.GROCERY),
    OILS("Oils", "opacity", Color(0xFFFFD60A), InventoryCategory.GROCERY),

    // Hygiene subcategories
    WASHING("Washing", "local_laundry_service", Color(0xFF007AFF), InventoryCategory.HYGIENE),
    DISHWASHING("Dishwashing", "restaurant", Color(0xFF34C759), InventoryCategory.HYGIENE),
    TOILET_CLEANING("Toilet Cleaning", "wc", Color(0xFF00C7BE), InventoryCategory.HYGIENE),
    KIDS("Kids", "child_care", Color(0xFFFF2D92), InventoryCategory.HYGIENE),
    GENERAL_CLEANING("General Cleaning", "cleaning_services", Color(0xFF5856D6), InventoryCategory.HYGIENE),

    // Personal Care subcategories
    FACE("Face", "face", Color(0xFFFF2D92), InventoryCategory.PERSONAL_CARE),
    BODY("Body", "accessibility", Color(0xFF30D158), InventoryCategory.PERSONAL_CARE),
    HEAD("Head", "face", Color(0xFF5856D6), InventoryCategory.PERSONAL_CARE);

    val sampleItems: List<String>
        get() = when (this) {
            // Fridge sample items
            DOOR_BOTTLES -> listOf("Water Bottles", "Juice", "Milk", "Soft Drinks")
            TRAY -> listOf("Eggs", "Butter", "Cheese", "Yogurt")
            MAIN -> listOf("Leftovers", "Cooked Food", "Fruits", "Vegetables")
            VEGETABLE -> listOf("Onions", "Tomatoes", "Potatoes", "Leafy Greens")
            FREEZER -> listOf("Ice Cream", "Frozen Vegetables", "Meat", "Ice Cubes")
            MINI_COOLER -> listOf("Cold Drinks", "Snacks", "Chocolates")

            // Grocery sample items
            RICE -> listOf("Basmati Rice", "Brown Rice", "Jasmine Rice", "Wild Rice")
            PULSES -> listOf("Lentils", "Chickpeas", "Black Beans", "Kidney Beans")
            CEREALS -> listOf("Oats", "Cornflakes", "Wheat Flakes", "Muesli")
            CONDIMENTS -> listOf("Salt", "Sugar", "Spices", "Sauces")
            OILS -> listOf("Cooking Oil", "Olive Oil", "Coconut Oil", "Ghee")

            // Hygiene sample items
            WASHING -> listOf("Detergent", "Fabric Softener", "Stain Remover")
            DISHWASHING -> listOf("Dish Soap", "Dishwasher Tablets", "Sponges")
            TOILET_CLEANING -> listOf("Toilet Cleaner", "Toilet Paper", "Air Freshener")
            KIDS -> listOf("Diapers", "Baby Wipes", "Baby Shampoo")
            GENERAL_CLEANING -> listOf("All-Purpose Cleaner", "Floor Cleaner", "Glass Cleaner")

            // Personal Care sample items
            FACE -> listOf("CC Cream", "Powder", "Face Wash", "Moisturizer")
            BODY -> listOf("Lotion", "Deodorant", "Bathing Soap", "Body Wash")
            HEAD -> listOf("Shampoo", "Conditioner", "Hair Oil", "Hair Gel")
        }
}

// Shopping States
enum class ShoppingState {
    EMPTY,           // No shopping list
    GENERATING,      // Generating/editing list
    LIST_READY,      // List created, not editable
    SHOPPING         // Shopping in progress, checklist unlocked
}

// Type Converters for Room
class Converters {
    @TypeConverter
    fun fromDateList(value: List<Date>): String {
        return Gson().toJson(value)
    }

    @TypeConverter
    fun toDateList(value: String): List<Date> {
        val listType = object : TypeToken<List<Date>>() {}.type
        return Gson().fromJson(value, listType) ?: emptyList()
    }

    @TypeConverter
    fun fromDate(date: Date?): Long? {
        return date?.time
    }

    @TypeConverter
    fun toDate(timestamp: Long?): Date? {
        return timestamp?.let { Date(it) }
    }

    @TypeConverter
    fun fromInventoryCategory(category: InventoryCategory): String {
        return category.name
    }

    @TypeConverter
    fun toInventoryCategory(categoryName: String): InventoryCategory {
        return InventoryCategory.valueOf(categoryName)
    }

    @TypeConverter
    fun fromInventorySubcategory(subcategory: InventorySubcategory): String {
        return subcategory.name
    }

    @TypeConverter
    fun toInventorySubcategory(subcategoryName: String): InventorySubcategory {
        return InventorySubcategory.valueOf(subcategoryName)
    }

    @TypeConverter
    fun fromShoppingState(state: ShoppingState): String {
        return state.name
    }

    @TypeConverter
    fun toShoppingState(stateName: String): ShoppingState {
        return ShoppingState.valueOf(stateName)
    }
}

// Database Entities
@Entity(tableName = "inventory_items")
@TypeConverters(Converters::class)
data class InventoryItemEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val name: String,
    val quantity: Float, // 0.0 to 1.0 (0% to 100%)
    val subcategory: InventorySubcategory,
    val isCustom: Boolean,
    val purchaseHistory: List<Date> = emptyList(),
    val lastUpdated: Date = Date()
) {
    val category: InventoryCategory
        get() = subcategory.category

    val quantityPercentage: Int
        get() = (quantity * 100).toInt()

    val needsRestocking: Boolean
        get() = quantity <= 0.25f

    fun updateQuantity(newQuantity: Float): InventoryItemEntity {
        return copy(
            quantity = newQuantity.coerceIn(0f, 1f),
            lastUpdated = Date()
        )
    }

    fun restockToFull(): InventoryItemEntity {
        return copy(
            quantity = 1.0f,
            purchaseHistory = purchaseHistory + Date(),
            lastUpdated = Date()
        )
    }
}

@Entity(tableName = "shopping_items")
@TypeConverters(Converters::class)
data class ShoppingItemEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val name: String,
    val isChecked: Boolean = false,
    val isTemporary: Boolean = false, // For misc items that don't update inventory
    val inventoryItemId: String? = null // Reference to inventory item if not temporary
)

@Entity(tableName = "shopping_state")
@TypeConverters(Converters::class)
data class ShoppingStateEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val state: ShoppingState,
    val createdDate: Date = Date()
)

@Entity(tableName = "notes")
@TypeConverters(Converters::class)
data class NoteEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val title: String,
    val content: String,
    val createdDate: Date = Date(),
    val lastModified: Date = Date()
)

// UI Models
data class InventoryItem(
    val id: String,
    val name: String,
    val quantity: Float,
    val subcategory: InventorySubcategory,
    val isCustom: Boolean,
    val purchaseHistory: List<Date>,
    val lastUpdated: Date
) {
    val category: InventoryCategory
        get() = subcategory.category

    val quantityPercentage: Int
        get() = (quantity * 100).toInt()

    val needsRestocking: Boolean
        get() = quantity <= 0.25f

    companion object {
        fun fromEntity(entity: InventoryItemEntity): InventoryItem {
            return InventoryItem(
                id = entity.id,
                name = entity.name,
                quantity = entity.quantity,
                subcategory = entity.subcategory,
                isCustom = entity.isCustom,
                purchaseHistory = entity.purchaseHistory,
                lastUpdated = entity.lastUpdated
            )
        }
    }

    fun toEntity(): InventoryItemEntity {
        return InventoryItemEntity(
            id = id,
            name = name,
            quantity = quantity,
            subcategory = subcategory,
            isCustom = isCustom,
            purchaseHistory = purchaseHistory,
            lastUpdated = lastUpdated
        )
    }
}

data class ShoppingItem(
    val id: String,
    val name: String,
    val isChecked: Boolean,
    val isTemporary: Boolean,
    val inventoryItem: InventoryItem?
) {
    val category: InventoryCategory?
        get() = inventoryItem?.category

    companion object {
        fun fromEntity(entity: ShoppingItemEntity, inventoryItem: InventoryItem? = null): ShoppingItem {
            return ShoppingItem(
                id = entity.id,
                name = entity.name,
                isChecked = entity.isChecked,
                isTemporary = entity.isTemporary,
                inventoryItem = inventoryItem
            )
        }
    }

    fun toEntity(): ShoppingItemEntity {
        return ShoppingItemEntity(
            id = id,
            name = name,
            isChecked = isChecked,
            isTemporary = isTemporary,
            inventoryItemId = inventoryItem?.id
        )
    }
}

data class Note(
    val id: String,
    val title: String,
    val content: String,
    val createdDate: Date,
    val lastModified: Date
) {
    companion object {
        fun fromEntity(entity: NoteEntity): Note {
            return Note(
                id = entity.id,
                title = entity.title,
                content = entity.content,
                createdDate = entity.createdDate,
                lastModified = entity.lastModified
            )
        }
    }

    fun toEntity(): NoteEntity {
        return NoteEntity(
            id = id,
            title = title,
            content = content,
            createdDate = createdDate,
            lastModified = lastModified
        )
    }
}

// Smart Recommendation Model
data class SmartRecommendation(
    val title: String,
    val description: String,
    val icon: String,
    val color: Color,
    val priority: RecommendationPriority
)

enum class RecommendationPriority {
    LOW, MEDIUM, HIGH
}