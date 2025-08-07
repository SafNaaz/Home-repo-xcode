package com.homeinventory.app.ui.screens.home

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavController
import com.homeinventory.app.model.InventoryCategory
import com.homeinventory.app.ui.theme.*
import com.homeinventory.app.viewmodel.InventoryViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(
    navController: NavController,
    viewModel: InventoryViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val totalItems by viewModel.totalItemsCount.collectAsStateWithLifecycle()
    val lowStockCount by viewModel.lowStockItemsCount.collectAsStateWithLifecycle()
    val urgentItems by viewModel.urgentAttentionItems.collectAsStateWithLifecycle()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
    ) {
        // Top App Bar
        TopAppBar(
            title = {
                Text(
                    text = "Household Inventory",
                    style = MaterialTheme.typography.headlineMedium,
                    fontWeight = FontWeight.Bold
                )
            },
            actions = {
                IconButton(onClick = { /* TODO: Notifications */ }) {
                    Icon(
                        imageVector = Icons.Default.Notifications,
                        contentDescription = "Notifications",
                        tint = MaterialTheme.colorScheme.onSurface
                    )
                }
                IconButton(onClick = { /* TODO: Settings */ }) {
                    Icon(
                        imageVector = Icons.Default.Settings,
                        contentDescription = "Settings",
                        tint = MaterialTheme.colorScheme.onSurface
                    )
                }
                IconButton(onClick = { /* TODO: Dark Mode Toggle */ }) {
                    Icon(
                        imageVector = Icons.Default.DarkMode,
                        contentDescription = "Dark Mode",
                        tint = MaterialTheme.colorScheme.onSurface
                    )
                }
            },
            colors = TopAppBarDefaults.topAppBarColors(
                containerColor = MaterialTheme.colorScheme.surface
            )
        )

        // Urgent Alerts Banner (if any)
        if (urgentItems.isNotEmpty()) {
            UrgentAlertsBanner(
                urgentItems = urgentItems,
                onAlertClick = {
                    // Navigate to insights tab
                    navController.navigate("insights")
                }
            )
        }

        // Quick Stats Header
        QuickStatsHeader(
            totalItems = totalItems,
            lowStockCount = lowStockCount
        )

        // Category Grid
        LazyVerticalGrid(
            columns = GridCells.Fixed(2),
            contentPadding = PaddingValues(16.dp),
            horizontalArrangement = Arrangement.spacedBy(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
            modifier = Modifier.weight(1f)
        ) {
            items(InventoryCategory.values().toList()) { category ->
                CategoryCard(
                    category = category,
                    viewModel = viewModel,
                    onClick = {
                        viewModel.setSelectedCategory(category)
                        // TODO: Navigate to category detail
                    }
                )
            }
        }

        // Floating Action Button for Shopping List
        Box(
            modifier = Modifier.fillMaxWidth(),
            contentAlignment = Alignment.BottomEnd
        ) {
            FloatingActionButton(
                onClick = {
                    // TODO: Start shopping list generation
                    navController.navigate("shopping")
                },
                modifier = Modifier.padding(16.dp),
                containerColor = iOSBlue,
                contentColor = Color.White
            ) {
                Icon(
                    imageVector = Icons.Default.AutoAwesome,
                    contentDescription = "Generate Shopping List"
                )
            }
        }
    }
}

@Composable
fun UrgentAlertsBanner(
    urgentItems: List<com.homeinventory.app.model.InventoryItem>,
    onAlertClick: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp)
            .clickable { onAlertClick() },
        colors = CardDefaults.cardColors(
            containerColor = Color.Red.copy(alpha = 0.1f)
        ),
        shape = RoundedCornerShape(12.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = Icons.Default.Warning,
                contentDescription = "Warning",
                tint = Color.Red,
                modifier = Modifier.size(24.dp)
            )
            
            Spacer(modifier = Modifier.width(12.dp))
            
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = "🚨 URGENT: Items Need Attention",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = Color.Red
                )
                Text(
                    text = "${urgentItems.size} items need immediate attention",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                )
            }
            
            Icon(
                imageVector = Icons.Default.ChevronRight,
                contentDescription = "View Details",
                tint = Color.Red
            )
        }
    }
}

@Composable
fun QuickStatsHeader(
    totalItems: Int,
    lowStockCount: Int
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp),
        colors = CardDefaults.cardColors(
            containerColor = SystemGray6
        ),
        shape = RoundedCornerShape(12.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Column(
                horizontalAlignment = Alignment.Start
            ) {
                Text(
                    text = "Total Items",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                )
                Text(
                    text = totalItems.toString(),
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.Bold
                )
            }
            
            Column(
                horizontalAlignment = Alignment.End
            ) {
                Text(
                    text = "Low Stock",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                )
                Text(
                    text = lowStockCount.toString(),
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.Bold,
                    color = if (lowStockCount > 0) Color.Red else iOSGreen
                )
            }
        }
    }
}

@Composable
fun CategoryCard(
    category: InventoryCategory,
    viewModel: InventoryViewModel,
    onClick: () -> Unit
) {
    val items by viewModel.getItemsByCategory(category).collectAsStateWithLifecycle(initialValue = emptyList())
    val lowStockCount = items.count { it.needsRestocking }

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .height(160.dp)
            .clickable { onClick() },
        colors = CardDefaults.cardColors(
            containerColor = SystemGray6
        ),
        shape = RoundedCornerShape(16.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.SpaceEvenly
        ) {
            // Large Icon
            Box(
                modifier = Modifier
                    .size(50.dp)
                    .background(
                        color = category.color.copy(alpha = 0.2f),
                        shape = CircleShape
                    ),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = getCategoryIcon(category),
                    contentDescription = category.displayName,
                    tint = category.color,
                    modifier = Modifier.size(30.dp)
                )
            }
            
            // Category Name
            Text(
                text = category.displayName,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                textAlign = TextAlign.Center
            )
            
            // Stats
            Column(
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = "${items.size} items",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                )
                
                if (lowStockCount > 0) {
                    Text(
                        text = "$lowStockCount need restocking",
                        style = MaterialTheme.typography.bodySmall,
                        color = Color.Red
                    )
                }
            }
        }
    }
}

@Composable
fun getCategoryIcon(category: InventoryCategory) = when (category) {
    InventoryCategory.FRIDGE -> Icons.Default.Kitchen
    InventoryCategory.GROCERY -> Icons.Default.ShoppingBasket
    InventoryCategory.HYGIENE -> Icons.Default.CleaningServices
    InventoryCategory.PERSONAL_CARE -> Icons.Default.Face
}