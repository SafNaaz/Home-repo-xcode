# Home Inventory App - Android

A complete Android version of the iOS Home Inventory App with identical functionality and design.

## Features

### 🏠 Inventory Management
- **4 Main Categories**: Fridge, Grocery, Hygiene, Personal Care
- **Multiple Subcategories**: Each category has 5-6 specific subcategories
- **Stock Level Tracking**: Visual sliders to track item quantities (0-100%)
- **Custom Items**: Add your own items to any subcategory
- **Smart Alerts**: Automatic notifications for items needing attention

### 🛒 Smart Shopping Lists
- **Auto-Generation**: Automatically creates shopping lists from low-stock items
- **Multiple States**: Empty → Generating → Ready → Shopping
- **Mixed Items**: Support for both inventory items and misc items
- **Plan Changes**: Add items while shopping
- **Inventory Sync**: Purchased items automatically restock to 100%

### 📊 Insights & Analytics
- **Usage Patterns**: Track most/least used items
- **Smart Recommendations**: AI-powered suggestions based on usage
- **Urgent Alerts**: Critical items needing immediate attention
- **Category Analysis**: Breakdown by category with statistics
- **Shopping Insights**: Frequency patterns and efficiency tips

### 📝 Quick Notes
- **Up to 6 Notes**: Simple note-taking functionality
- **Rich Editing**: Title and content support
- **Auto-Save**: Automatic saving of changes
- **Grid Layout**: iOS-inspired card-based layout

### ⚙️ Settings & Security
- **Dark Mode**: System-wide dark/light theme toggle
- **Biometric Lock**: Secure app with fingerprint/face unlock
- **Notifications**: Customizable inventory reminders
- **Data Management**: Clear all data functionality

## Technical Architecture

### 🏗️ Architecture Pattern
- **MVVM**: Model-View-ViewModel architecture
- **Repository Pattern**: Clean separation of data sources
- **Dependency Injection**: Hilt for dependency management

### 🗄️ Database
- **Room Database**: Local SQLite database with Room ORM
- **Type Converters**: Custom converters for complex data types
- **Flow Integration**: Reactive data streams with Kotlin Flow

### 🎨 UI Framework
- **Jetpack Compose**: Modern declarative UI toolkit
- **Material 3**: Latest Material Design components
- **iOS-Inspired Design**: Colors and layouts matching the original iOS app

### 📱 Key Components
- **Navigation**: Bottom tab navigation with 4 main screens
- **State Management**: Reactive UI with StateFlow and Compose
- **Data Persistence**: Room database with automatic migrations
- **Background Tasks**: WorkManager for notifications

## Project Structure

```
app/src/main/java/com/homeinventory/app/
├── data/
│   ├── dao/                    # Database access objects
│   └── HomeInventoryDatabase.kt
├── di/                         # Dependency injection modules
├── model/                      # Data models and entities
├── repository/                 # Data repositories
├── ui/
│   ├── navigation/            # Navigation setup
│   ├── screens/               # Screen composables
│   │   ├── home/
│   │   ├── shopping/
│   │   ├── insights/
│   │   └── notes/
│   └── theme/                 # App theming
├── viewmodel/                 # ViewModels for state management
├── MainActivity.kt
└── HomeInventoryApplication.kt
```

## Key Features Matching iOS App

### 🎯 Exact Feature Parity
- ✅ Same 4 categories with identical subcategories
- ✅ Same sample items for each subcategory
- ✅ Identical shopping list workflow (4 states)
- ✅ Same smart recommendation algorithms
- ✅ Matching color scheme and icons
- ✅ Same urgent alert system (14 days for kitchen, 60 days for others)
- ✅ Identical notes limit (6 notes maximum)
- ✅ Same settings and security features

### 🎨 Design Consistency
- **Colors**: iOS-inspired color palette (SF Symbols colors)
- **Typography**: Material 3 typography matching iOS hierarchy
- **Layout**: Grid-based layouts matching iOS design
- **Icons**: Material Icons chosen to match iOS SF Symbols
- **Spacing**: Consistent padding and margins

## Getting Started

### Prerequisites
- Android Studio Arctic Fox or later
- Android SDK 24+ (Android 7.0)
- Kotlin 1.9.22+

### Building the App
1. Clone the repository
2. Open in Android Studio
3. Sync Gradle files
4. Run on device or emulator

### Dependencies
- **Jetpack Compose**: UI framework
- **Room**: Database
- **Hilt**: Dependency injection
- **Navigation Compose**: Navigation
- **WorkManager**: Background tasks
- **Biometric**: Authentication
- **DataStore**: Preferences

## Future Enhancements
- [ ] Cloud sync between devices
- [ ] Barcode scanning for items
- [ ] Shopping list sharing
- [ ] Advanced analytics dashboard
- [ ] Voice commands integration
- [ ] Widget support

## License
This project matches the functionality of the original iOS Home Inventory App.