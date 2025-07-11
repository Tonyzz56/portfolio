import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_management_system/src/models/subscription_package_model.dart';

class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'subscription_packages';

  Future<SubscriptionPackageModel?> createPackage(SubscriptionPackageModel package) async {
    try {
      DocumentReference docRef = _firestore.collection(_collectionPath).doc();
      // Create a new package with a new ID and current timestamps
      SubscriptionPackageModel newPackage = SubscriptionPackageModel(
        id: docRef.id,
        name: package.name,
        price: package.price,
        currency: package.currency,
        billingCycle: package.billingCycle,
        features: package.features,
        maxStudents: package.maxStudents,
        maxStaff: package.maxStaff,
        isActive: package.isActive,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await docRef.set(newPackage.toMap());
      return newPackage;
    } catch (e) {
      print('Error creating subscription package: $e');
      return null;
    }
  }

  Stream<List<SubscriptionPackageModel>> getPackages() {
    return _firestore
        .collection(_collectionPath)
        .orderBy('price') // Example: order by price
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SubscriptionPackageModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  Future<SubscriptionPackageModel?> getPackageById(String id) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(_collectionPath).doc(id).get();
      if (doc.exists) {
        return SubscriptionPackageModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting package by ID $id: $e');
      return null;
    }
  }


  Future<bool> updatePackage(String id, Map<String, dynamic> data) async {
    try {
      Map<String, dynamic> updateData = Map<String, dynamic>.from(data); // Create a mutable copy
      updateData['updatedAt'] = Timestamp.now();
      await _firestore.collection(_collectionPath).doc(id).update(updateData);
      return true;
    } catch (e) {
      print('Error updating subscription package $id: $e');
      return false;
    }
  }

  // Soft delete by marking as inactive
  Future<bool> togglePackageActiveStatus(String id, bool isActive) async {
    try {
      await _firestore.collection(_collectionPath).doc(id).update({
        'isActive': isActive,
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      print('Error toggling package active status for $id: $e');
      return false;
    }
  }

  // Hard delete - use with caution, especially if institutions are linked to this package.
  // Consider checking for dependencies before allowing deletion.
  Future<bool> deletePackageHard(String id) async {
    try {
      // TODO: Add check for institutions currently subscribed to this package.
      // If in use, prevent deletion or prompt for migration.
      // final institutionsUsingPackage = await _firestore.collection('institutions').where('subscriptionPackageId', isEqualTo: id).limit(1).get();
      // if (institutionsUsingPackage.docs.isNotEmpty) {
      //   throw Exception("Cannot delete package: It is currently assigned to one or more institutions.");
      // }
      await _firestore.collection(_collectionPath).doc(id).delete();
      return true;
    } catch (e) {
      print('Error hard deleting subscription package $id: $e');
      // Rethrow specific errors if needed
      if (e is Exception && e.toString().contains("Cannot delete package")) throw e;
      return false;
    }
  }
}
