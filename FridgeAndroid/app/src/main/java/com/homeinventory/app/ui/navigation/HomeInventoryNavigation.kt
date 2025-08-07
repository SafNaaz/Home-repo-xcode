package com.homeinventory.app.ui.navigation

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.homeinventory.app.R
import com.homeinventory.app.ui.screens.home.HomeScreen
import com.homeinventory.app.ui.screens.insights.InsightsScreen
import com.homeinventory.app.ui.screens.notes.NotesScreen
import com.homeinventory.app.ui.screens.shopping.ShoppingScreen

sealed class Screen(val route: String, val title: String, val icon: ImageVector) {
    object Home : Screen("home", "Home", Icons.Filled.Home)
    object Shopping : Screen("shopping", "Shopping", Icons.Filled.ShoppingCart)
    object Insights : Screen("insights", "Insights", Icons.Filled.Analytics)
    object Notes : Screen("notes", "Notes", Icons.Filled.Note)
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeInventoryNavigation() {
    val navController = rememberNavController()
    val items = listOf(
        Screen.Home,
        Screen.Shopping,
        Screen.Insights,
        Screen.Notes
    )

    Scaffold(
        bottomBar = {
            NavigationBar {
                val navBackStackEntry by navController.currentBackStackEntryAsState()
                val currentDestination = navBackStackEntry?.destination
                
                items.forEach { screen ->
                    NavigationBarItem(
                        icon = { Icon(screen.icon, contentDescription = screen.title) },
                        label = { Text(screen.title) },
                        selected = currentDestination?.hierarchy?.any { it.route == screen.route } == true,
                        onClick = {
                            navController.navigate(screen.route) {
                                // Pop up to the start destination of the graph to
                                // avoid building up a large stack of destinations
                                // on the back stack as users select items
                                popUpTo(navController.graph.findStartDestination().id) {
                                    saveState = true
                                }
                                // Avoid multiple copies of the same destination when
                                // reselecting the same item
                                launchSingleTop = true
                                // Restore state when reselecting a previously selected item
                                restoreState = true
                            }
                        }
                    )
                }
            }
        }
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = Screen.Home.route,
            modifier = Modifier.padding(innerPadding)
        ) {
            composable(Screen.Home.route) {
                HomeScreen(navController = navController)
            }
            composable(Screen.Shopping.route) {
                ShoppingScreen(navController = navController)
            }
            composable(Screen.Insights.route) {
                InsightsScreen(navController = navController)
            }
            composable(Screen.Notes.route) {
                NotesScreen(navController = navController)
            }
        }
    }
}