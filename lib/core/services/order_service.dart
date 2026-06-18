import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../features/admin/data/admin_models.dart' as admin_models;
import 'firestore_service.dart';

class OrderService {
  final FirestoreService _firestoreService = FirestoreService();

  // Get all orders (admin)
  Future<List<admin_models.Order>> getAllOrders() async {
    try {
      final snapshot = await _firestoreService.getAllDocuments(
        FirestoreService.ordersCollection,
      );
      return snapshot.docs.map((doc) => _orderFromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error fetching all orders: $e');
      return [];
    }
  }

  // Get user orders
  Future<List<admin_models.Order>> getUserOrders(String userId) async {
    try {
      final snapshot = await _firestoreService.getDocumentsWhere(
        collection: FirestoreService.ordersCollection,
        field: 'userId',
        isEqualTo: userId,
      );
      return snapshot.docs.map((doc) => _orderFromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error fetching user orders: $e');
      return [];
    }
  }

  // Get orders by status
  Future<List<admin_models.Order>> getOrdersByStatus(String status) async {
    try {
      final snapshot = await _firestoreService.getDocumentsWhere(
        collection: FirestoreService.ordersCollection,
        field: 'status',
        isEqualTo: status,
      );
      return snapshot.docs.map((doc) => _orderFromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error fetching orders by status: $e');
      return [];
    }
  }

  // Get single order
  Future<admin_models.Order?> getOrder(String orderId) async {
    try {
      final doc = await _firestoreService.getDocument(
        FirestoreService.ordersCollection,
        orderId,
      );
      if (doc.exists) {
        return _orderFromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching order: $e');
      return null;
    }
  }

  // Create new order
  Future<String?> createOrder({
    required String userId,
    required String userName,
    required String userPhone,
    required List<admin_models.OrderItem> items,
    required double totalPrice,
    String status = 'pending',
    String? notes,
  }) async {
    try {
      final orderData = {
        'userId': userId,
        'userName': userName,
        'userPhone': userPhone,
        'items': items.map((item) => _orderItemToMap(item)).toList(),
        'totalPrice': totalPrice,
        'status': status,
        'orderDate': FieldValue.serverTimestamp(),
        'completedDate': null,
        'notes': notes,
        'paymentVerified': false,
      };

      final docRef = await _firestoreService.addDocument(
        FirestoreService.ordersCollection,
        orderData,
      );
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating order: $e');
      return null;
    }
  }

  // Update order status
  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    try {
      final updateData = {
        'status': newStatus,
        if (newStatus == 'completed')
          'completedDate': FieldValue.serverTimestamp(),
      };

      await _firestoreService.updateDocument(
        FirestoreService.ordersCollection,
        orderId,
        updateData,
      );
      return true;
    } catch (e) {
      debugPrint('Error updating order status: $e');
      return false;
    }
  }

  // Update payment verification status
  Future<bool> updatePaymentVerification(String orderId, bool verified) async {
    try {
      await _firestoreService.updateDocument(
        FirestoreService.ordersCollection,
        orderId,
        {'paymentVerified': verified},
      );
      return true;
    } catch (e) {
      debugPrint('Error updating payment verification: $e');
      return false;
    }
  }

  // Update order
  Future<bool> updateOrder(String orderId, admin_models.Order order) async {
    try {
      await _firestoreService.updateDocument(
        FirestoreService.ordersCollection,
        orderId,
        _orderToFirestore(order),
      );
      return true;
    } catch (e) {
      debugPrint('Error updating order: $e');
      return false;
    }
  }

  // Cancel order
  Future<bool> cancelOrder(String orderId) async {
    try {
      await _firestoreService.updateDocument(
        FirestoreService.ordersCollection,
        orderId,
        {'status': 'cancelled'},
      );
      return true;
    } catch (e) {
      debugPrint('Error cancelling order: $e');
      return false;
    }
  }

  // Delete order
  Future<bool> deleteOrder(String orderId) async {
    try {
      await _firestoreService.deleteDocument(
        FirestoreService.ordersCollection,
        orderId,
      );
      return true;
    } catch (e) {
      debugPrint('Error deleting order: $e');
      return false;
    }
  }

  // Stream all orders
  Stream<List<admin_models.Order>> streamAllOrders() {
    return _firestoreService
        .streamCollection(FirestoreService.ordersCollection)
        .map((snapshot) =>
            snapshot.docs.map((doc) => _orderFromFirestore(doc)).toList());
  }

  // Stream user orders
  Stream<List<admin_models.Order>> streamUserOrders(String userId) {
    return _firestoreService
        .streamCollectionWhere(
          collection: FirestoreService.ordersCollection,
          field: 'userId',
          isEqualTo: userId,
        )
        .map((snapshot) => snapshot.docs
            .map((doc) => _orderFromFirestore(doc))
            .toList());
  }

  // Helper methods
  admin_models.Order _orderFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final itemsList = data['items'] as List<dynamic>? ?? [];
    final items = itemsList
        .map((item) => _orderItemFromMap(item as Map<String, dynamic>))
        .toList();

    return admin_models.Order(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhone: data['userPhone'] ?? '',
      items: items,
      totalPrice: (data['totalPrice'] ?? 0).toDouble(),
      status: data['status'] ?? 'pending',
      orderDate: (data['orderDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedDate: (data['completedDate'] as Timestamp?)?.toDate(),
      paymentVerified: data['paymentVerified'] ?? false,
      notes: data['notes'],
    );
  }

  Map<String, dynamic> _orderToFirestore(admin_models.Order order) {
    return {
      'userId': order.userId,
      'userName': order.userName,
      'userPhone': order.userPhone,
      'items': order.items.map((item) => _orderItemToMap(item)).toList(),
      'totalPrice': order.totalPrice,
      'status': order.status,
      'orderDate': order.orderDate,
      'completedDate': order.completedDate,
      'paymentVerified': order.paymentVerified,
      'notes': order.notes,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  admin_models.OrderItem _orderItemFromMap(Map<String, dynamic> map) {
    return admin_models.OrderItem(
      menuId: map['menuId'] ?? '',
      menuName: map['menuName'] ?? '',
      quantity: map['quantity'] ?? 0,
      price: (map['price'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> _orderItemToMap(admin_models.OrderItem item) {
    return {
      'menuId': item.menuId,
      'menuName': item.menuName,
      'quantity': item.quantity,
      'price': item.price,
    };
  }
}
