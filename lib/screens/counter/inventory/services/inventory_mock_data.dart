import '../models/inventory_models.dart';

/// Purged mock data repository.
/// All inventory operations now strictly use live backend endpoints:
/// - Categories: /api/restaurant/inventory/categories
/// - Ingredients: /api/restaurant/inventory/ingredients
/// - Suppliers: /api/admin/distributors/
/// - Purchase Orders: /api/admin/purchases/
/// - Stock Adjustments: /api/restaurant/inventory/adjustments
abstract class InventoryMockData {
  static const List<IngredientCategory> categories = [];
  static const List<Ingredient> ingredients = [];
  static const List<Supplier> suppliers = [];
}
