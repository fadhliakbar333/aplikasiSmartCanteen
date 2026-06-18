// Admin Menu Models
class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String imageUrl;
  final double rating;
  final int sold;
  final bool available;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.imageUrl,
    required this.rating,
    required this.sold,
    required this.available,
  });
}

class Order {
  final String id;
  final String userId;
  final String userName;
  final String userPhone;
  final List<OrderItem> items;
  final double totalPrice;
  final String status; // 'pending', 'processing', 'ready', 'completed', 'cancelled'
  final DateTime orderDate;
  final DateTime? completedDate;
  final bool paymentVerified;
  final String? notes;

  Order({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.items,
    required this.totalPrice,
    required this.status,
    required this.orderDate,
    this.completedDate,
    this.paymentVerified = false,
    this.notes,
  });
}

class OrderItem {
  final String menuId;
  final String menuName;
  final int quantity;
  final double price;

  OrderItem({
    required this.menuId,
    required this.menuName,
    required this.quantity,
    required this.price,
  });
}

class MenuCategory {
  final String id;
  final String name;
  final String icon;

  MenuCategory({
    required this.id,
    required this.name,
    required this.icon,
  });
}
