import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  static const String usersCollection = 'users';
  static const String menusCollection = 'menus';
  static const String categoriesCollection = 'categories';
  static const String ordersCollection = 'orders';
  static const String cartCollection = 'carts';
  static const String chatsCollection = 'chats';
  static const String notificationsCollection = 'notifications';

  // Generic get document
  Future<DocumentSnapshot> getDocument(
    String collection,
    String documentId,
  ) async {
    try {
      return await _firestore.collection(collection).doc(documentId).get();
    } catch (e) {
      debugPrint('Error getting document: $e');
      rethrow;
    }
  }

  // Generic get all documents
  Future<QuerySnapshot> getAllDocuments(String collection) async {
    try {
      return await _firestore.collection(collection).get();
    } catch (e) {
      debugPrint('Error getting all documents: $e');
      rethrow;
    }
  }

  // Generic get documents with query
  Future<QuerySnapshot> getDocumentsWhere({
    required String collection,
    required String field,
    required dynamic isEqualTo,
  }) async {
    try {
      return await _firestore
          .collection(collection)
          .where(field, isEqualTo: isEqualTo)
          .get();
    } catch (e) {
      debugPrint('Error querying documents: $e');
      rethrow;
    }
  }

  // Generic create/add document
  Future<DocumentReference> addDocument(
    String collection,
    Map<String, dynamic> data,
  ) async {
    try {
      return await _firestore.collection(collection).add(data);
    } catch (e) {
      debugPrint('Error adding document: $e');
      rethrow;
    }
  }

  // Generic set document with custom ID
  Future<void> setDocument(
    String collection,
    String documentId,
    Map<String, dynamic> data, {
    bool merge = false,
  }) async {
    try {
      await _firestore
          .collection(collection)
          .doc(documentId)
          .set(data, SetOptions(merge: merge));
    } catch (e) {
      debugPrint('Error setting document: $e');
      rethrow;
    }
  }

  // Generic update document
  Future<void> updateDocument(
    String collection,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection(collection).doc(documentId).update(data);
    } catch (e) {
      debugPrint('Error updating document: $e');
      rethrow;
    }
  }

  // Generic delete document
  Future<void> deleteDocument(String collection, String documentId) async {
    try {
      await _firestore.collection(collection).doc(documentId).delete();
    } catch (e) {
      debugPrint('Error deleting document: $e');
      rethrow;
    }
  }

  // Generic stream listener
  Stream<DocumentSnapshot> streamDocument(
    String collection,
    String documentId,
  ) {
    return _firestore.collection(collection).doc(documentId).snapshots();
  }

  // Generic collection stream
  Stream<QuerySnapshot> streamCollection(String collection) {
    return _firestore.collection(collection).snapshots();
  }

  // Generic collection stream with query
  Stream<QuerySnapshot> streamCollectionWhere({
    required String collection,
    required String field,
    required dynamic isEqualTo,
  }) {
    return _firestore
        .collection(collection)
        .where(field, isEqualTo: isEqualTo)
        .snapshots();
  }


  // Batch operations
  Future<void> batch(Function(WriteBatch) batchFn) async {
    try {
      final batch = _firestore.batch();
      await batchFn(batch);
      await batch.commit();
    } catch (e) {
      debugPrint('Error in batch operation: $e');
      rethrow;
    }
  }
}
