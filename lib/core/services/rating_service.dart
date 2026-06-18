import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/rating_model.dart';

class RatingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _ratingsCol = 'ratings';
  static const String _menusCol = 'menus';

  // ── Submit rating ──────────────────────────────────────────────────────────

  /// Submit rating for one menu item in an order.
  /// Returns true on success.
  /// Also recalculates and updates the menu's average rating in Firestore.
  Future<bool> submitRating({
    required String menuId,
    required String menuName,
    required String userId,
    required String userName,
    required String orderId,
    required double stars,
    required String review,
  }) async {
    try {
      // Check if user already rated this menu for this order
      final existing = await _db
          .collection(_ratingsCol)
          .where('orderId', isEqualTo: orderId)
          .where('menuId', isEqualTo: menuId)
          .where('userId', isEqualTo: userId)
          .get();

      if (existing.docs.isNotEmpty) {
        // Update existing rating
        await _db
            .collection(_ratingsCol)
            .doc(existing.docs.first.id)
            .update({'stars': stars, 'review': review});
      } else {
        // Create new rating
        final rating = Rating(
          id: '',
          menuId: menuId,
          menuName: menuName,
          userId: userId,
          userName: userName,
          orderId: orderId,
          stars: stars,
          review: review,
          createdAt: DateTime.now(),
        );
        await _db.collection(_ratingsCol).add(rating.toMap());
      }

      // Recalculate average rating for the menu
      await _recalculateMenuRating(menuId);
      return true;
    } catch (e) {
      debugPrint('RatingService.submitRating error: $e');
      return false;
    }
  }

  // ── Read helpers ───────────────────────────────────────────────────────────

  /// Get all ratings for a specific menu (for display in menu detail).
  Future<List<Rating>> getRatingsForMenu(String menuId) async {
    try {
      final snap = await _db
          .collection(_ratingsCol)
          .where('menuId', isEqualTo: menuId)
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs.map((d) => Rating.fromFirestore(d)).toList();
    } catch (e) {
      debugPrint('RatingService.getRatingsForMenu error: $e');
      return [];
    }
  }

  /// Stream ratings for a menu — used for live updates in menu detail page.
  Stream<List<Rating>> streamRatingsForMenu(String menuId) {
    return _db
        .collection(_ratingsCol)
        .where('menuId', isEqualTo: menuId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Rating.fromFirestore(d)).toList());
  }

  /// Check if a user has already rated a specific menu item for an order.
  Future<Rating?> getUserRatingForOrderItem({
    required String orderId,
    required String menuId,
    required String userId,
  }) async {
    try {
      final snap = await _db
          .collection(_ratingsCol)
          .where('orderId', isEqualTo: orderId)
          .where('menuId', isEqualTo: menuId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      return Rating.fromFirestore(snap.docs.first);
    } catch (e) {
      debugPrint('RatingService.getUserRatingForOrderItem error: $e');
      return null;
    }
  }

  /// Check which menuIds in an order have already been rated by a user.
  Future<Set<String>> getRatedMenuIdsForOrder({
    required String orderId,
    required String userId,
  }) async {
    try {
      final snap = await _db
          .collection(_ratingsCol)
          .where('orderId', isEqualTo: orderId)
          .where('userId', isEqualTo: userId)
          .get();
      return snap.docs.map((d) => d['menuId'] as String).toSet();
    } catch (e) {
      debugPrint('RatingService.getRatedMenuIdsForOrder error: $e');
      return {};
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  Future<void> _recalculateMenuRating(String menuId) async {
    try {
      final snap = await _db
          .collection(_ratingsCol)
          .where('menuId', isEqualTo: menuId)
          .get();

      if (snap.docs.isEmpty) return;

      final totalStars =
          snap.docs.fold(0.0, (sum, d) => sum + (d['stars'] as num));
      final avg = totalStars / snap.docs.length;

      await _db.collection(_menusCol).doc(menuId).update({
        'rating': double.parse(avg.toStringAsFixed(1)),
        'ratingCount': snap.docs.length,
      });
    } catch (e) {
      debugPrint('RatingService._recalculateMenuRating error: $e');
    }
  }
}
