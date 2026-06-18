// User Models
class UserProfile {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String profileImage;
  final double rating;
  final int totalOrders;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.profileImage,
    required this.rating,
    required this.totalOrders,
  });
}

class UserCart {
  final String id;
  final String userId;
  final List<CartItem> items;
  final double totalPrice;
  final DateTime createdAt;

  UserCart({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalPrice,
    required this.createdAt,
  });
}

class CartItem {
  final String menuId;
  final String menuName;
  final double price;
  int quantity;

  CartItem({
    required this.menuId,
    required this.menuName,
    required this.price,
    required this.quantity,
  });
}

class UserOrder {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final double totalPrice;
  final String status; // 'pending', 'processing', 'ready', 'completed', 'cancelled'
  final DateTime orderDate;
  final DateTime? completedDate;
  final String paymentMethod;
  final String? notes;

  UserOrder({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalPrice,
    required this.status,
    required this.orderDate,
    this.completedDate,
    required this.paymentMethod,
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

class Notification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type; // 'order', 'promo', 'chat'
  final DateTime createdAt;
  final bool isRead;

  Notification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    required this.isRead,
  });
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime sentAt;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.sentAt,
    required this.isRead,
  });
}
