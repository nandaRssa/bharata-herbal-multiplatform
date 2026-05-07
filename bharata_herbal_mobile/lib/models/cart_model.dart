class CartItem {
  final int id;
  final int productId;
  final String productName;
  final String productImage;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final bool isSelected;

  CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    required this.isSelected,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      productId: json['product_id'],
      productName: json['product_name'] ?? '',
      productImage: json['product_image'] ?? '',
      quantity: json['quantity'] ?? 1,
      unitPrice: double.tryParse(json['unit_price'].toString()) ?? 0,
      subtotal: double.tryParse(json['subtotal'].toString()) ?? 0,
      isSelected: json['is_selected'] ?? true,
    );
  }
}

class Cart {
  final int id;
  final List<CartItem> items;
  final double total;
  final int selectedCount;
  final int totalItems;
  final double minimumOrderAmount;
  final bool isMinimumMet;

  Cart({
    required this.id,
    required this.items,
    required this.total,
    required this.selectedCount,
    required this.totalItems,
    required this.minimumOrderAmount,
    required this.isMinimumMet,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      id: json['id'] ?? 0,
      items: (json['items'] as List<dynamic>? ?? [])
          .map((i) => CartItem.fromJson(i))
          .toList(),
      total: double.tryParse(json['total'].toString()) ?? 0,
      selectedCount: json['selected_count'] ?? 0,
      totalItems: json['total_items'] ?? 0,
      minimumOrderAmount:
          double.tryParse(json['minimum_order_amount'].toString()) ?? 0,
      isMinimumMet: json['is_minimum_met'] ?? false,
    );
  }
}
