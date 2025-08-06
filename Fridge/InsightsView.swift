import SwiftUI

// MARK: - Insights View
struct InsightsView: View {
    @EnvironmentObject var inventoryManager: InventoryManager
    @State private var refreshTrigger = UUID()
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Overview Cards
                    OverviewCardsSection()
                    
                    // Usage Patterns
                    UsagePatternsSection()
                    
                    // Category Analysis
                    CategoryAnalysisSection()
                    
                    // Shopping Insights
                    ShoppingInsightsSection()
                    
                    // Recommendations
                    RecommendationsSection()
                }
                .padding()
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
            .id(refreshTrigger)
            .onReceive(inventoryManager.objectWillChange) { _ in
                refreshTrigger = UUID()
            }
        }
    }
}

// MARK: - Overview Cards Section
struct OverviewCardsSection: View {
    @EnvironmentObject var inventoryManager: InventoryManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overview")
                .font(.title2)
                .fontWeight(.bold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                InsightCard(
                    title: "Total Items",
                    value: "\(inventoryManager.totalItems)",
                    icon: "cube.box.fill",
                    color: .blue
                )
                
                InsightCard(
                    title: "Low Stock",
                    value: "\(inventoryManager.lowStockItemsCount)",
                    icon: "exclamationmark.triangle.fill",
                    color: inventoryManager.lowStockItemsCount > 0 ? .red : .green
                )
                
                InsightCard(
                    title: "Avg Stock",
                    value: "\(Int(inventoryManager.averageStockLevel * 100))%",
                    icon: "chart.bar.fill",
                    color: .orange
                )
                
                InsightCard(
                    title: "Categories",
                    value: "\(inventoryManager.activeCategoriesCount)",
                    icon: "folder.fill",
                    color: .purple
                )
            }
        }
    }
}

// MARK: - Usage Patterns Section
struct UsagePatternsSection: View {
    @EnvironmentObject var inventoryManager: InventoryManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Usage Patterns")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                // Most Frequently Restocked
                InsightRowCard(
                    title: "Most Restocked",
                    subtitle: inventoryManager.mostFrequentlyRestockedItem?.name ?? "No data yet",
                    value: inventoryManager.mostFrequentlyRestockedItem != nil ? "\(inventoryManager.mostFrequentlyRestockedItem!.purchaseHistory.count) times" : "",
                    icon: "arrow.clockwise.circle.fill",
                    color: .green
                )
                
                // Least Used Items
                InsightRowCard(
                    title: "Least Used",
                    subtitle: inventoryManager.leastUsedItem?.name ?? "No data yet",
                    value: inventoryManager.leastUsedItem != nil ? "Last updated \(inventoryManager.daysSinceLastUpdate(inventoryManager.leastUsedItem!)) days ago" : "",
                    icon: "clock.fill",
                    color: .gray
                )
                
                // Items Needing Attention
                InsightRowCard(
                    title: "Need Attention",
                    subtitle: "\(inventoryManager.itemsNeedingAttention().count) items below 25%",
                    value: inventoryManager.itemsNeedingAttention().isEmpty ? "All good!" : "Check inventory",
                    icon: "eye.fill",
                    color: inventoryManager.itemsNeedingAttention().isEmpty ? .green : .orange
                )
            }
        }
    }
}

// MARK: - Category Analysis Section
struct CategoryAnalysisSection: View {
    @EnvironmentObject var inventoryManager: InventoryManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category Analysis")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 8) {
                ForEach(InventoryCategory.allCases) { category in
                    let items = inventoryManager.itemsForCategory(category)
                    if !items.isEmpty {
                        CategoryInsightRow(category: category, items: items)
                    }
                }
            }
        }
    }
}

// MARK: - Shopping Insights Section
struct ShoppingInsightsSection: View {
    @EnvironmentObject var inventoryManager: InventoryManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Shopping Insights")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                InsightRowCard(
                    title: "Shopping Frequency",
                    subtitle: "Based on restock patterns",
                    value: inventoryManager.estimatedShoppingFrequency,
                    icon: "cart.fill",
                    color: .blue
                )
                
                InsightRowCard(
                    title: "Next Shopping Trip",
                    subtitle: "Estimated based on current stock levels",
                    value: inventoryManager.estimatedNextShoppingTrip,
                    icon: "calendar.circle.fill",
                    color: .indigo
                )
                
                InsightRowCard(
                    title: "Shopping Efficiency",
                    subtitle: "Items typically bought together",
                    value: inventoryManager.shoppingEfficiencyTip,
                    icon: "lightbulb.fill",
                    color: .yellow
                )
            }
        }
    }
}

// MARK: - Recommendations Section
struct RecommendationsSection: View {
    @EnvironmentObject var inventoryManager: InventoryManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Smart Recommendations")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                ForEach(inventoryManager.getSmartRecommendations(), id: \.title) { recommendation in
                    RecommendationCard(recommendation: recommendation)
                }
            }
        }
    }
}

// MARK: - Supporting Views
struct InsightCard: View {
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
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 100)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct InsightRowCard: View {
    let title: String
    let subtitle: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
                .multilineTextAlignment(.trailing)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct CategoryInsightRow: View {
    let category: InventoryCategory
    let items: [InventoryItem]
    
    var lowStockCount: Int {
        items.filter { $0.needsRestocking }.count
    }
    
    var averageStock: Double {
        guard !items.isEmpty else { return 0 }
        return items.reduce(0) { $0 + $1.quantity } / Double(items.count)
    }
    
    var body: some View {
        HStack {
            Image(systemName: category.icon)
                .foregroundColor(category.color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(category.rawValue)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("\(items.count) items • \(Int(averageStock * 100))% avg stock")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if lowStockCount > 0 {
                VStack(alignment: .trailing) {
                    Text("\(lowStockCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    
                    Text("low stock")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            } else {
                VStack(alignment: .trailing) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                    
                    Text("all good")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct RecommendationCard: View {
    let recommendation: SmartRecommendation
    
    var body: some View {
        HStack {
            Image(systemName: recommendation.icon)
                .font(.title2)
                .foregroundColor(recommendation.color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(recommendation.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(recommendation.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if recommendation.priority == .high {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(recommendation.priority == .high ? Color.red.opacity(0.1) : Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(recommendation.priority == .high ? Color.red.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

#Preview {
    InsightsView()
        .environmentObject(InventoryManager())
}