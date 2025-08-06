import SwiftUI

struct StatsView: View {
    @EnvironmentObject var inventoryManager: InventoryManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Overview Cards
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        StatCard(
                            title: "Total Items",
                            value: "\(inventoryManager.totalItems)",
                            icon: "house.fill",
                            color: .blue
                        )
                        
                        StatCard(
                            title: "Low Stock",
                            value: "\(inventoryManager.lowStockItemsCount)",
                            icon: "exclamationmark.triangle.fill",
                            color: inventoryManager.lowStockItemsCount > 0 ? .red : .green
                        )
                        
                        StatCard(
                            title: "Avg Stock",
                            value: "\(Int(inventoryManager.averageStockLevel * 100))%",
                            icon: "chart.bar.fill",
                            color: .orange
                        )
                        
                        StatCard(
                            title: "Shopping Items",
                            value: "\(inventoryManager.shoppingList.items.count)",
                            icon: "cart.fill",
                            color: .purple
                        )
                    }
                    .padding(.horizontal)
                    
                    // Category Breakdown
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Category Breakdown")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        ForEach(InventoryCategory.allCases) { category in
                            CategoryStatsRow(category: category)
                        }
                    }
                    .padding(.vertical)
                    
                    // Items Needing Attention
                    let itemsNeedingAttention = inventoryManager.itemsNeedingAttention()
                    if !itemsNeedingAttention.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Items Needing Attention")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            
                            ForEach(itemsNeedingAttention.prefix(5)) { item in
                                AttentionItemRow(item: item)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Statistics")
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct CategoryStatsRow: View {
    let category: InventoryCategory
    @EnvironmentObject var inventoryManager: InventoryManager
    
    var body: some View {
        let items = inventoryManager.itemsForCategory(category)
        let lowStockCount = items.filter { $0.needsRestocking }.count
        let avgStock = items.isEmpty ? 0 : items.reduce(0) { $0 + $1.quantity } / Double(items.count)
        
        HStack {
            Image(systemName: category.icon)
                .foregroundColor(category.color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(category.rawValue)
                    .font(.headline)
                
                HStack {
                    Text("\(items.count) items")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if lowStockCount > 0 {
                        Text("• \(lowStockCount) low")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("\(Int(avgStock * 100))%")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(avgStock < 0.25 ? .red : avgStock < 0.5 ? .orange : .green)
                
                Text("avg stock")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
    }
}

struct AttentionItemRow: View {
    @ObservedObject var item: InventoryItem
    
    var body: some View {
        HStack {
            Image(systemName: item.subcategory.icon)
                .foregroundColor(item.subcategory.color)
                .frame(width: 25)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.headline)
                
                Text(item.subcategory.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("\(item.quantityPercentage)%")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
                
                Text("stock left")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

#Preview {
    StatsView()
        .environmentObject(InventoryManager())
}