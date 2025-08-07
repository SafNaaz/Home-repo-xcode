package com.homeinventory.app.ui.screens.notes

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NotesScreen(navController: NavController) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text(
            text = "Quick Notes",
            style = MaterialTheme.typography.headlineMedium,
            fontWeight = FontWeight.Bold
        )
        
        Spacer(modifier = Modifier.height(16.dp))
        
        Text(
            text = "Notes functionality will be implemented here (up to 6 notes)",
            style = MaterialTheme.typography.bodyLarge
        )
        
        Spacer(modifier = Modifier.height(32.dp))
        
        Button(
            onClick = { /* TODO: Add note */ }
        ) {
            Text("Add Note")
        }
    }
}