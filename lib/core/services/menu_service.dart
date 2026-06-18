import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../features/admin/data/admin_models.dart';
import 'firestore_service.dart';

class MenuService {
  final FirestoreService _firestoreService = FirestoreService();

  // Get all menu items
  Future<List<MenuItem>> getAllMenus() async {
    try {
      final snapshot = await _firestoreService
          .getAllDocuments(FirestoreService.menusCollection);
      return snapshot.docs.map((doc) => _menuFromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error fetching menus: $e');
      return [];
    }
  }

  // Get menus by category
  Future<List<MenuItem>> getMenusByCategory(String category) async {
    try {
      final snapshot = await _firestoreService.getDocumentsWhere(
        collection: FirestoreService.menusCollection,
        field: 'category',
        isEqualTo: category,
      );
      return snapshot.docs.map((doc) => _menuFromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error fetching menus by category: $e');
      return [];
    }
  }

  // Get single menu
  Future<MenuItem?> getMenu(String menuId) async {
    try {
      final doc = await _firestoreService.getDocument(
        FirestoreService.menusCollection,
        menuId,
      );
      if (doc.exists) {
        return _menuFromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching menu: $e');
      return null;
    }
  }

  // Add new menu
  Future<String?> addMenu(MenuItem menu) async {
    try {
      final docRef = await _firestoreService.addDocument(
        FirestoreService.menusCollection,
        _menuToFirestore(menu),
      );
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding menu: $e');
      return null;
    }
  }

  // Update menu
  Future<bool> updateMenu(String menuId, MenuItem menu) async {
    try {
      await _firestoreService.updateDocument(
        FirestoreService.menusCollection,
        menuId,
        _menuToFirestore(menu),
      );
      return true;
    } catch (e) {
      debugPrint('Error updating menu: $e');
      return false;
    }
  }

  // Delete menu
  Future<bool> deleteMenu(String menuId) async {
    try {
      await _firestoreService.deleteDocument(
        FirestoreService.menusCollection,
        menuId,
      );
      return true;
    } catch (e) {
      debugPrint('Error deleting menu: $e');
      return false;
    }
  }

  // Stream all menus
  Stream<List<MenuItem>> streamAllMenus() {
    return _firestoreService
        .streamCollection(FirestoreService.menusCollection)
        .map((snapshot) =>
            snapshot.docs.map((doc) => _menuFromFirestore(doc)).toList());
  }

  // Stream all categories
  Stream<List<MenuCategory>> streamAllCategories() {
    return _firestoreService
        .streamCollection(FirestoreService.categoriesCollection)
        .map((snapshot) =>
            snapshot.docs.map((doc) => _categoryFromFirestore(doc)).toList());
  }

  // Get all categories
  Future<List<MenuCategory>> getAllCategories() async {
    try {
      final snapshot = await _firestoreService
          .getAllDocuments(FirestoreService.categoriesCollection);
      return snapshot.docs.map((doc) => _categoryFromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      return [];
    }
  }

  // Add category
  Future<String?> addCategory(MenuCategory category) async {
    try {
      final docRef = await _firestoreService.addDocument(
        FirestoreService.categoriesCollection,
        _categoryToFirestore(category),
      );
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding category: $e');
      return null;
    }
  }

  // Update category
  Future<bool> updateCategory(String categoryId, MenuCategory category) async {
    try {
      await _firestoreService.updateDocument(
        FirestoreService.categoriesCollection,
        categoryId,
        _categoryToFirestore(category),
      );
      return true;
    } catch (e) {
      debugPrint('Error updating category: $e');
      return false;
    }
  }

  // Delete category
  Future<bool> deleteCategory(String categoryId) async {
    try {
      await _firestoreService.deleteDocument(
        FirestoreService.categoriesCollection,
        categoryId,
      );
      return true;
    } catch (e) {
      debugPrint('Error deleting category: $e');
      return false;
    }
  }

  // Helper methods
  MenuItem _menuFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MenuItem(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      category: data['category'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      sold: data['sold'] ?? 0,
      available: data['available'] ?? true,
    );
  }

  Map<String, dynamic> _menuToFirestore(MenuItem menu) {
    return {
      'name': menu.name,
      'description': menu.description,
      'price': menu.price,
      'category': menu.category,
      'imageUrl': menu.imageUrl,
      'rating': menu.rating,
      'sold': menu.sold,
      'available': menu.available,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  MenuCategory _categoryFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MenuCategory(
      id: doc.id,
      name: data['name'] ?? '',
      icon: data['icon'] ?? '',
    );
  }

  Map<String, dynamic> _categoryToFirestore(MenuCategory category) {
    return {
      'name': category.name,
      'icon': category.icon,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
