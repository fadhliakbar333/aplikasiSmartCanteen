import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../features/user/data/user_models.dart';
import 'firestore_service.dart';

class CartService {
  final FirestoreService _firestoreService = FirestoreService();

  // Create or update cart
  Future<String?> createCart({
    required String userId,
    required List<CartItem> items,
    required double totalPrice,
  }) async {
    try {
      final cartData = {
        'userId': userId,
        'items': items.map((item) => _cartItemToMap(item)).toList(),
        'totalPrice': totalPrice,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestoreService.addDocument(
        FirestoreService.cartCollection,
        cartData,
      );
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating cart: $e');
      return null;
    }
  }

  // Get user cart
  Future<UserCart?> getUserCart(String userId) async {
    try {
      final snapshot = await _firestoreService.getDocumentsWhere(
        collection: FirestoreService.cartCollection,
        field: 'userId',
        isEqualTo: userId,
      );

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return _cartFromFirestore(snapshot.docs.first);
    } catch (e) {
      debugPrint('Error fetching user cart: $e');
      return null;
    }
  }

  // Get cart by ID
  Future<UserCart?> getCart(String cartId) async {
    try {
      final doc = await _firestoreService.getDocument(
        FirestoreService.cartCollection,
        cartId,
      );
      if (doc.exists) {
        return _cartFromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching cart: $e');
      return null;
    }
  }

  // Update cart
  Future<bool> updateCart(
    String cartId,
    List<CartItem> items,
    double totalPrice,
  ) async {
    try {
      await _firestoreService.updateDocument(
        FirestoreService.cartCollection,
        cartId,
        {
          'items': items.map((item) => _cartItemToMap(item)).toList(),
          'totalPrice': totalPrice,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
      return true;
    } catch (e) {
      debugPrint('Error updating cart: $e');
      return false;
    }
  }

  // Add item to cart
  Future<bool> addItemToCart(
    String cartId,
    CartItem newItem,
    double totalPrice,
  ) async {
    try {
      final cart = await getCart(cartId);
      if (cart == null) return false;

      final items = cart.items;
      final existingIndex =
          items.indexWhere((item) => item.menuId == newItem.menuId);

      if (existingIndex >= 0) {
        items[existingIndex].quantity += newItem.quantity;
      } else {
        items.add(newItem);
      }

      return await updateCart(cartId, items, totalPrice);
    } catch (e) {
      debugPrint('Error adding item to cart: $e');
      return false;
    }
  }

  // Remove item from cart
  Future<bool> removeItemFromCart(
    String cartId,
    String menuId,
    double totalPrice,
  ) async {
    try {
      final cart = await getCart(cartId);
      if (cart == null) return false;

      final items = cart.items;
      items.removeWhere((item) => item.menuId == menuId);

      return await updateCart(cartId, items, totalPrice);
    } catch (e) {
      debugPrint('Error removing item from cart: $e');
      return false;
    }
  }

  // Clear cart
  Future<bool> clearCart(String cartId) async {
    try {
      await _firestoreService.updateDocument(
        FirestoreService.cartCollection,
        cartId,
        {
          'items': [],
          'totalPrice': 0,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
      return true;
    } catch (e) {
      debugPrint('Error clearing cart: $e');
      return false;
    }
  }

  // Delete cart
  Future<bool> deleteCart(String cartId) async {
    try {
      await _firestoreService.deleteDocument(
        FirestoreService.cartCollection,
        cartId,
      );
      return true;
    } catch (e) {
      debugPrint('Error deleting cart: $e');
      return false;
    }
  }

  // Stream user cart
  Stream<UserCart?> streamUserCart(String userId) {
    return _firestoreService
        .streamCollectionWhere(
          collection: FirestoreService.cartCollection,
          field: 'userId',
          isEqualTo: userId,
        )
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return null;
      }
      return _cartFromFirestore(snapshot.docs.first);
    });
  }

  // Helper methods
  UserCart _cartFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final itemsList = data['items'] as List<dynamic>? ?? [];
    final items = itemsList
        .map((item) => _cartItemFromMap(item as Map<String, dynamic>))
        .toList();

    return UserCart(
      id: doc.id,
      userId: data['userId'] ?? '',
      items: items,
      totalPrice: (data['totalPrice'] ?? 0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  CartItem _cartItemFromMap(Map<String, dynamic> map) {
    return CartItem(
      menuId: map['menuId'] ?? '',
      menuName: map['menuName'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 0,
    );
  }

  Map<String, dynamic> _cartItemToMap(CartItem item) {
    return {
      'menuId': item.menuId,
      'menuName': item.menuName,
      'price': item.price,
      'quantity': item.quantity,
    };
  }
}
