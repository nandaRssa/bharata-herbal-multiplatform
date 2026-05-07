import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../services/product_service.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _service = ProductService();

  List<Product> _allProducts = [];
  List<Product> products = [];
  List<Category> categories = [];

  bool isLoading = false;

  String selectedCategory = '';
  String searchKeyword = '';

  Future<void> loadInitialData() async {
    isLoading = true;
    notifyListeners();

    try {
      // Load categories
      final categoryData = await _service.getCategories();
      categories = categoryData
          .whereType<Map<String, dynamic>>()
          .map((item) => Category.fromJson(item))
          .toList();

      // Load all products
      final productData = await _service.getProducts();
      _allProducts = productData
          .whereType<Map<String, dynamic>>()
          .map((item) => Product.fromJson(item))
          .toList();

      _applyFilters();

      debugPrint(
        'Loaded ${products.length} products, ${categories.length} categories',
      );
    } catch (e) {
      debugPrint('Load error: $e');
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> filterProducts({String? category, String? keyword}) async {
    if (category != null) selectedCategory = category;
    if (keyword != null) searchKeyword = keyword;

    isLoading = true;
    notifyListeners();

    try {
      if (selectedCategory.isNotEmpty || searchKeyword.isNotEmpty) {
        // Server-side filter if backend supports
        final filteredData = await _service.getProducts(
          category: selectedCategory.isEmpty ? null : selectedCategory,
          search: searchKeyword.isEmpty ? null : searchKeyword,
        );
        _allProducts = filteredData
            .whereType<Map<String, dynamic>>()
            .map((item) => Product.fromJson(item))
            .toList();
      } else {
        // Reload all
        final productData = await _service.getProducts();
        _allProducts = productData
            .whereType<Map<String, dynamic>>()
            .map((item) => Product.fromJson(item))
            .toList();
      }
      _applyFilters();
    } catch (e) {
      debugPrint('Filter error: $e');
    }

    isLoading = false;
    notifyListeners();
  }

  void _applyFilters() {
    products = _allProducts.where((product) {
      final matchesCategory =
          selectedCategory.isEmpty ||
          categories.any((cat) => cat.slug == selectedCategory) ||
          product.slug.startsWith(selectedCategory);
      final matchesSearch =
          searchKeyword.isEmpty ||
          product.name.toLowerCase().contains(searchKeyword.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

}
