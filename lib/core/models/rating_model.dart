import 'package:cloud_firestore/cloud_firestore.dart';

class Rating {
  final String id;
  final String menuId;
  final String menuName;
  final String userId;
  final String userName;
  final String orderId;
  final double stars; // 1.0 – 5.0
  final String review;
  final DateTime createdAt;

  Rating({
    required this.id,
    required this.menuId,
    required this.menuName,
    required this.userId,
    required this.userName,
    required this.orderId,
    required this.stars,
    required this.review,
    required this.createdAt,
  });

  factory Rating.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Rating(
      id: doc.id,
      menuId: d['menuId'] ?? '',
      menuName: d['menuName'] ?? '',
      userId: d['userId'] ?? '',
      userName: d['userName'] ?? '',
      orderId: d['orderId'] ?? '',
      stars: (d['stars'] ?? 0).toDouble(),
      review: d['review'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'menuId': menuId,
        'menuName': menuName,
        'userId': userId,
        'userName': userName,
        'orderId': orderId,
        'stars': stars,
        'review': review,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
