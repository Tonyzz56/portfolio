import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/institution_model.dart';
import '../models/user_model.dart'; // For UserRole, if needed for checks

class InstitutionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'institutions';

  // Create a new institution
  Future<Institution?> createInstitution({
    required String name,
    required InstitutionType type,
    required String adminEmail, // Email for the institution admin to be created/linked
    required String adminPassword, // Password for the new institution admin
    required String adminDisplayName,
    String? address,
    String? contactEmail,
    String? contactPhone,
    // We will need AuthService to create the institution admin user
    // For simplicity in this step, we assume admin user is created separately
    // and adminUserId is provided. A more integrated approach would call AuthService here.
    required String adminUserId, // This should be the UID of an existing or newly created InstitutionAdmin
  }) async {
    try {
      DateTime now = DateTime.now();
      DocumentReference docRef = _firestore.collection(_collectionPath).doc();

      Institution newInstitution = Institution(
        id: docRef.id,
        name: name,
        type: type,
        adminUserId: adminUserId, // This admin user must exist and have InstitutionAdmin role
        address: address,
        contactEmail: contactEmail,
        contactPhone: contactPhone,
        createdAt: now,
        updatedAt: now,
        isActive: true, // Default to active
      );

      await docRef.set(newInstitution.toMap());
      // After creating the institution, you might need to update the InstitutionAdmin user
      // with this institutionId if that wasn't handled during admin user creation.
      // Example: await _firestore.collection('users').doc(adminUserId).update({'institutionId': docRef.id});

      return newInstitution;
    } catch (e) {
      print('Error creating institution: $e');
      // Consider more specific error handling or rethrowing
      return null;
    }
  }

  // Get a single institution by ID
  Future<Institution?> getInstitutionById(String id) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(_collectionPath).doc(id).get();
      if (doc.exists) {
        return Institution.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting institution by ID: $e');
      return null;
    }
  }

  // Get all institutions (stream for real-time updates)
  Stream<List<Institution>> getInstitutions() {
    return _firestore.collection(_collectionPath).orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Institution.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Get all institutions (Future for one-time fetch)
  Future<List<Institution>> fetchInstitutionsList() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection(_collectionPath).orderBy('name').get();
      return snapshot.docs.map((doc) => Institution.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    } catch (e) {
      print('Error fetching institutions list: $e');
      return [];
    }
  }


  // Update an institution
  Future<bool> updateInstitution(String id, Institution institution) async {
    try {
      Map<String, dynamic> dataToUpdate = institution.toMap();
      dataToUpdate['updatedAt'] = Timestamp.now(); // Ensure updatedAt is always current
      await _firestore.collection(_collectionPath).doc(id).update(dataToUpdate);
      return true;
    } catch (e) {
      print('Error updating institution: $e');
      return false;
    }
  }

  // Delete an institution (soft delete by marking inactive, or hard delete)
  // For this example, we'll implement a soft delete (mark as inactive)
  // and a hard delete. Super Admin should have clarity on which is being performed.
  Future<bool> toggleInstitutionStatus(String id, bool isActive) async {
    try {
      await _firestore.collection(_collectionPath).doc(id).update({
        'isActive': isActive,
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      print('Error toggling institution status: $e');
      return false;
    }
  }

  // Hard delete an institution
  // WARNING: This is destructive. Consider implications (e.g., orphaned users, data).
  // Usually, soft delete (isActive = false) is preferred.
  Future<bool> deleteInstitutionHard(String id) async {
    try {
      // Potentially add checks or related data cleanup here before deleting.
      // e.g., find all users associated with this institutionId and decide how to handle them.
      await _firestore.collection(_collectionPath).doc(id).delete();
      return true;
    } catch (e) {
      print('Error hard deleting institution: $e');
      return false;
    }
  }

  // Note: The creation of the Institution Admin user is a critical part.
  // The `createInstitution` method above assumes `adminUserId` is provided.
  // A complete solution would integrate with `AuthService` to:
  // 1. Create the Institution Admin user (e.g., `authService.signUpWithEmailPassword(role: UserRole.institutionAdmin, ...)`).
  // 2. If successful, then create the institution document with the new admin's UID.
  // 3. If institution creation fails, potentially roll back admin user creation or mark it for attention.
  // This transactional nature across Auth and Firestore can be complex and might involve Firebase Functions for atomicity.
}
