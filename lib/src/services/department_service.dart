import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_management_system/src/models/department_model.dart';

class DepartmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'departments'; // Collection to store Department documents

  // Create a new department for a specific institution
  Future<DepartmentModel?> createDepartment({
    required String name,
    required String institutionId,
    String? description,
    String? headOfDepartmentUid,
  }) async {
    if (name.trim().isEmpty) throw ArgumentError("Department name cannot be empty.");
    if (institutionId.trim().isEmpty) throw ArgumentError("Institution ID is required.");

    try {
      DateTime now = DateTime.now();
      DocumentReference docRef = _firestore.collection(_collectionPath).doc();

      DepartmentModel newDepartment = DepartmentModel(
        id: docRef.id,
        name: name.trim(),
        institutionId: institutionId,
        description: description?.trim(),
        headOfDepartmentUid: headOfDepartmentUid,
        createdAt: now,
        updatedAt: now,
      );

      await docRef.set(newDepartment.toMap());
      return newDepartment;
    } catch (e) {
      print('Error creating department: $e');
      // Consider more specific error handling
      return null;
    }
  }

  // Get all departments for a specific institution
  Stream<List<DepartmentModel>> getDepartmentsForInstitution(String institutionId) {
    return _firestore
        .collection(_collectionPath)
        .where('institutionId', isEqualTo: institutionId)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DepartmentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  // Get a single department by ID
  Future<DepartmentModel?> getDepartmentById(String id) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(_collectionPath).doc(id).get();
      if (doc.exists) {
        return DepartmentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting department by ID $id: $e');
      return null;
    }
  }

  // Update an existing department
  Future<bool> updateDepartment(String id, {
    required String name, // Name is typically required
    String? description,
    String? headOfDepartmentUid, // Use FieldValue.delete() to remove HOD
  }) async {
     if (name.trim().isEmpty) throw ArgumentError("Department name cannot be empty.");
    try {
      Map<String, dynamic> dataToUpdate = {
        'name': name.trim(),
        'description': description?.trim(), // Will set to null if description is null
        'headOfDepartmentUid': headOfDepartmentUid, // Will set to null if HOD is null
        'updatedAt': Timestamp.now(),
      };
      // Remove fields if explicitly passed as null to allow clearing them,
      // or use FieldValue.delete() if you want to remove the field itself.
      // For simplicity, null will just set the field to null.
      // If headOfDepartmentUid is an empty string, it might be better to store null.
      if (headOfDepartmentUid != null && headOfDepartmentUid.isEmpty) {
          dataToUpdate['headOfDepartmentUid'] = null;
      }


      await _firestore.collection(_collectionPath).doc(id).update(dataToUpdate);
      return true;
    } catch (e) {
      print('Error updating department $id: $e');
      return false;
    }
  }

  // Delete a department
  // Consider implications: what happens to staff assigned to this department?
  // Should probably prevent deletion if staff are assigned, or reassign them first.
  Future<bool> deleteDepartment(String id) async {
    try {
      // TODO: Add pre-deletion checks:
      // 1. Query 'users' collection for any staff assigned to this departmentId.
      //    final staffInDepartment = await _firestore.collection('users').where('departmentId', isEqualTo: id).limit(1).get();
      //    if (staffInDepartment.docs.isNotEmpty) {
      //      throw Exception("Cannot delete department: Staff members are still assigned to it. Please reassign them first.");
      //    }
      await _firestore.collection(_collectionPath).doc(id).delete();
      return true;
    } catch (e) {
      print('Error deleting department $id: $e');
      if (e.toString().contains("Cannot delete department")) throw e; // Rethrow specific controlled error
      return false;
    }
  }
}
