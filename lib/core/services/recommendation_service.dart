import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../features/admin/data/admin_models.dart';

/// Simple content-based + collaborative filtering recommendation engine.
///
/// Strategy (serverless, no ML backend needed):
/// 1. Collect user's order history → extract most-ordered categories & menu IDs.
/// 2. Collect ratings submitted by the user → weight menus rated ≥ 4 stars.
/// 3. Score every available menu and return top-N sorted by score.
///
/// Scoring formula per menu:
///   score = (category_match * 3)
///         + (previously_ordered_bonus * 2)
///         + (high_rating_bonus * 4)
///         + (global_popularity * 1)   // normalized sold count
///
/// Cached in Firestore under users/{uid}/recommendations for 30 minutes.
class RecommendationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _menusCol = 'menus';
  static const String _ordersCol = 'orders';
  static const String _ratingsCol = 'ratings';

  static const int _cacheMinutes = 30;
  static const int _topN = 10;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns up to [_topN] recommended MenuItems for [userId].
  /// Uses a Firestore cache — only recalculates when cache is stale.
  Future<List<MenuItem>> getRecommendations(String userId) async {
    try {
      // 1. Try cache first
      final cached = await _getCachedRecommendations(userId);
      if (cached != null) return cached;

      // 2. Gather data in parallel
      final results = await Future.wait([
        _getUserOrderHistory(userId),
        _getUserRatings(userId),
        _getAllMenus(),
      ]);

      final orderHistory = results[0] as List<_OrderFact>;
      final userRatings = results[1] as Map<String, double>;
      final allMenus = results[2] as List<MenuItem>;

      if (allMenus.isEmpty) return [];

      // 3. Build user preference profile
      final categoryFreq = <String, int>{};
      final orderedMenuIds = <String>{};

      for (final fact in orderHistory) {
        orderedMenuIds.add(fact.menuId);
        categoryFreq[fact.category] =
            (categoryFreq[fact.category] ?? 0) + fact.quantity;
      }

      final maxSold =
          allMenus.map((m) => m.sold).fold(1, (a, b) => a > b ? a : b);

      // 4. Score every menu
      final scored = <_ScoredMenu>[];
      for (final menu in allMenus) {
        if (!menu.available) continue;

        double score = 0;

        // Category match bonus (weighted by how often user orders from that category)
        final catFreq = categoryFreq[menu.category] ?? 0;
        score += catFreq * 3.0;

        // Previously ordered (user knows & likes it)
        if (orderedMenuIds.contains(menu.id)) score += 2.0;

        // High user rating bonus
        final userStar = userRatings[menu.id];
        if (userStar != null) {
          if (userStar >= 4.5)
            score += 5.0;
          else if (userStar >= 4.0)
            score += 3.0;
          else if (userStar >= 3.0)
            score += 1.0;
          else
            score -= 2.0; // penalize low-rated menus
        }

        // Global popularity (normalized)
        score += (menu.sold / maxSold) * 2.0;

        // Global rating boost
        score += menu.rating * 0.5;

        scored.add(_ScoredMenu(menu: menu, score: score));
      }

      scored.sort((a, b) => b.score.compareTo(a.score));
      final recommendations = scored.take(_topN).map((s) => s.menu).toList();

      // 5. Cache result
      await _cacheRecommendations(userId, recommendations);

      return recommendations;
    } catch (e) {
      debugPrint('RecommendationService.getRecommendations error: $e');
      // Fallback: return top menus by sold count
      return _getFallbackRecommendations();
    }
  }

  /// Invalidate cache — call after user submits a new rating or order.
  Future<void> invalidateCache(String userId) async {
    try {
      await _db.collection('users').doc(userId).update({
        'recommendationCacheExpiry': FieldValue.delete(),
        'recommendationCache': FieldValue.delete(),
      });
    } catch (_) {}
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  Future<List<MenuItem>?> _getCachedRecommendations(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      final data = doc.data()!;

      final expiry =
          (data['recommendationCacheExpiry'] as Timestamp?)?.toDate();
      if (expiry == null || DateTime.now().isAfter(expiry)) return null;

      final cachedIds = List<String>.from(data['recommendationCache'] ?? []);
      if (cachedIds.isEmpty) return null;

      // Fetch menus by cached IDs
      final menus = <MenuItem>[];
      for (final id in cachedIds) {
        final snap = await _db.collection(_menusCol).doc(id).get();
        if (snap.exists) menus.add(_menuFromDoc(snap));
      }
      return menus.isEmpty ? null : menus;
    } catch (_) {
      return null;
    }
  }

  Future<void> _cacheRecommendations(
      String userId, List<MenuItem> menus) async {
    try {
      await _db.collection('users').doc(userId).set(
        {
          'recommendationCache': menus.map((m) => m.id).toList(),
          'recommendationCacheExpiry': Timestamp.fromDate(
              DateTime.now().add(const Duration(minutes: _cacheMinutes))),
        },
        SetOptions(merge: true),
      );
    } catch (_) {}
  }

  Future<List<_OrderFact>> _getUserOrderHistory(String userId) async {
    try {
      final snap = await _db
          .collection(_ordersCol)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .get();

      final facts = <_OrderFact>[];
      for (final doc in snap.docs) {
        final data = doc.data();
        final items = (data['items'] as List<dynamic>? ?? []);
        for (final item in items) {
          final itemMap = item as Map<String, dynamic>;
          // We need the category — fetch from menu (cached by Firestore)
          final menuId = itemMap['menuId'] as String? ?? '';
          final category = await _getMenuCategory(menuId);
          facts.add(_OrderFact(
            menuId: menuId,
            category: category,
            quantity: (itemMap['quantity'] as int? ?? 1),
          ));
        }
      }
      return facts;
    } catch (e) {
      debugPrint('_getUserOrderHistory error: $e');
      return [];
    }
  }

  final _categoryCache = <String, String>{};

  Future<String> _getMenuCategory(String menuId) async {
    if (_categoryCache.containsKey(menuId)) return _categoryCache[menuId]!;
    try {
      final doc = await _db.collection(_menusCol).doc(menuId).get();
      final cat = (doc.data()?['category'] as String?) ?? '';
      _categoryCache[menuId] = cat;
      return cat;
    } catch (_) {
      return '';
    }
  }

  Future<Map<String, double>> _getUserRatings(String userId) async {
    try {
      final snap = await _db
          .collection(_ratingsCol)
          .where('userId', isEqualTo: userId)
          .get();

      return {
        for (final doc in snap.docs)
          (doc.data()['menuId'] as String? ?? ''):
              (doc.data()['stars'] as num? ?? 0).toDouble()
      };
    } catch (_) {
      return {};
    }
  }

  Future<List<MenuItem>> _getAllMenus() async {
    try {
      final snap = await _db.collection(_menusCol).get();
      return snap.docs.map((d) => _menuFromDoc(d)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<MenuItem>> _getFallbackRecommendations() async {
    try {
      final snap = await _db
          .collection(_menusCol)
          .where('available', isEqualTo: true)
          .orderBy('sold', descending: true)
          .limit(_topN)
          .get();
      return snap.docs.map((d) => _menuFromDoc(d)).toList();
    } catch (_) {
      return [];
    }
  }

  MenuItem _menuFromDoc(DocumentSnapshot doc) {
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
}

class _OrderFact {
  final String menuId;
  final String category;
  final int quantity;
  _OrderFact(
      {required this.menuId, required this.category, required this.quantity});
}

class _ScoredMenu {
  final MenuItem menu;
  final double score;
  _ScoredMenu({required this.menu, required this.score});
}
