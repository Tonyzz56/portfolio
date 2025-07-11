import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_management_system/src/models/fee_structure_model.dart';
import 'package:school_management_system/src/models/student_fee_status_model.dart';
import 'package:school_management_system/src/models/class_model.dart'; // For fetching studentUids from a class
// import 'package:school_management_system/src/services/academic_service.dart'; // Not directly used here, but class data needed

class FeeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // final AcademicService _academicService = AcademicService(); // If needed to fetch class details internally

  final String _feeStructuresPath = 'fee_structures';
  final String _studentFeeStatusPath = 'student_fee_status';
  final String _classesPath = 'classes'; // Path to classes collection

  // --- Fee Structure Methods (Managed by Institution Admin) ---

  Future<FeeStructureModel?> createFeeStructure(FeeStructureModel feeStructure) async {
    try {
      DocumentReference docRef = _firestore.collection(_feeStructuresPath).doc();
      FeeStructureModel newStructure = FeeStructureModel(
        id: docRef.id,
        institutionId: feeStructure.institutionId,
        name: feeStructure.name,
        description: feeStructure.description,
        academicYearId: feeStructure.academicYearId,
        termId: feeStructure.termId,
        classId: feeStructure.classId,
        feeItemName: feeStructure.feeItemName,
        amount: feeStructure.amount,
        currency: feeStructure.currency,
        dueDate: feeStructure.dueDate,
        isActive: feeStructure.isActive,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      // Let toMap handle server timestamps for createdAt and updatedAt
      await docRef.set(newStructure.toMap());
      // Fetch the document to get server-generated timestamps if needed, or adjust model
      // For now, returning client-side generated model with new ID.
      return newStructure.copyWith(id: docRef.id); // Return with actual ID
    } catch (e) {
      print("Error creating fee structure: $e");
      return null;
    }
  }

  Stream<List<FeeStructureModel>> getFeeStructures({
    required String institutionId,
    String? academicYearId,
    String? termId,
    String? classId,
    bool? isActive,
  }) {
    Query query = _firestore.collection(_feeStructuresPath).where('institutionId', isEqualTo: institutionId);

    if (academicYearId != null) query = query.where('academicYearId', isEqualTo: academicYearId);
    if (termId != null) query = query.where('termId', isEqualTo: termId);
    if (classId != null) query = query.where('classId', isEqualTo: classId);
    if (isActive != null) query = query.where('isActive', isEqualTo: isActive);

    return query.orderBy('name').snapshots().map((snapshot) => snapshot.docs
        .map((doc) => FeeStructureModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  Future<bool> updateFeeStructure(String id, Map<String, dynamic> data) async {
    try {
      Map<String, dynamic> updateData = Map.from(data);
      // Ensure server timestamp is used for updatedAt
      updateData['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection(_feeStructuresPath).doc(id).update(updateData);
      return true;
    } catch (e) {
      print("Error updating fee structure $id: $e");
      return false;
    }
  }

  Future<bool> deleteFeeStructure(String id) async {
    try {
      QuerySnapshot assignments = await _firestore.collection(_studentFeeStatusPath)
                                      .where('feeStructureId', isEqualTo: id)
                                      .limit(1).get();
      if (assignments.docs.isNotEmpty) {
        throw Exception("Cannot delete fee structure: It has active assignments to students. Please deactivate it instead or resolve assignments.");
      }
      await _firestore.collection(_feeStructuresPath).doc(id).delete();
      return true;
    } catch (e) {
      print("Error deleting fee structure $id: $e");
      if (e.toString().contains("Cannot delete fee structure")) throw e;
      return false;
    }
  }

  // --- Student Fee Assignment & Status Methods ---

  Future<StudentFeeStatusModel?> assignFeeToStudent({
    required String studentUid,
    required FeeStructureModel feeStructure,
    String? specificClassId,
  }) async {
    try {
      final String classIdForAssignment = specificClassId ?? feeStructure.classId ?? ''; // Ensure classId is not null if required by your logic

      QuerySnapshot existingAssignment = await _firestore.collection(_studentFeeStatusPath)
          .where('studentUid', isEqualTo: studentUid)
          .where('feeStructureId', isEqualTo: feeStructure.id)
          .where('academicYearId', isEqualTo: feeStructure.academicYearId)
          .where('termId', isEqualTo: feeStructure.termId)
          .where('classId', isEqualTo: classIdForAssignment)
          .limit(1)
          .get();

      if (existingAssignment.docs.isNotEmpty) {
        print("Fee ${feeStructure.name} already assigned to student $studentUid for this context.");
        return StudentFeeStatusModel.fromMap(existingAssignment.docs.first.data() as Map<String, dynamic>, existingAssignment.docs.first.id);
      }

      DocumentReference docRef = _firestore.collection(_studentFeeStatusPath).doc();
      StudentFeeStatusModel newAssignment = StudentFeeStatusModel(
        id: docRef.id,
        institutionId: feeStructure.institutionId,
        studentUid: studentUid,
        feeStructureId: feeStructure.id,
        academicYearId: feeStructure.academicYearId,
        termId: feeStructure.termId,
        classId: classIdForAssignment,
        feeItemName: feeStructure.feeItemName,
        amountDue: feeStructure.amount,
        originalDueDate: feeStructure.dueDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await docRef.set(newAssignment.toMap()); // .toMap() uses server timestamps
      return newAssignment.copyWith(id: docRef.id);
    } catch (e) {
      print("Error assigning fee ${feeStructure.name} to student $studentUid: $e");
      return null;
    }
  }

  Future<List<String>> assignFeesToClass({ // Returns list of student UIDs successfully processed or batch ID
    required String classIdToAssign,
    required List<String> feeStructureIdsToAssign, // IDs of FeeStructureModels
    // institutionId is part of FeeStructureModel
  }) async {
    if (feeStructureIdsToAssign.isEmpty) return [];

    List<String> processedStudentUids = [];
    try {
      DocumentSnapshot classDoc = await _firestore.collection(_classesPath).doc(classIdToAssign).get();
      if (!classDoc.exists) throw Exception("Class $classIdToAssign not found.");
      ClassModel classModel = ClassModel.fromMap(classDoc.data() as Map<String,dynamic>, classDoc.id);
      List<String> studentUids = classModel.studentUids ?? [];

      if (studentUids.isEmpty) {
        print("No students in class $classIdToAssign to assign fees to.");
        return [];
      }

      List<FeeStructureModel> feeStructures = [];
      for (String fsId in feeStructureIdsToAssign) {
        DocumentSnapshot fsDoc = await _firestore.collection(_feeStructuresPath).doc(fsId).get();
        if (fsDoc.exists) {
          feeStructures.add(FeeStructureModel.fromMap(fsDoc.data() as Map<String, dynamic>, fsDoc.id));
        } else {
          print("Warning: FeeStructure with ID $fsId not found. Skipping.");
        }
      }
      if(feeStructures.isEmpty) throw Exception("None of the selected Fee Structures were found.");

      WriteBatch batch = _firestore.batch();
      DateTime now = DateTime.now(); // Consistent timestamp for batch

      for (String studentUid in studentUids) {
        for (FeeStructureModel feeStructure in feeStructures) {
          if (!feeStructure.isActive) {
            print("Skipping inactive fee structure: ${feeStructure.name}");
            continue;
          }

          // Simplified: Assume no existing assignment for batch operation.
          // For robust duplicate prevention in batch, would need more complex logic or Cloud Function.
          DocumentReference docRef = _firestore.collection(_studentFeeStatusPath).doc();
          StudentFeeStatusModel newAssignment = StudentFeeStatusModel(
            id: docRef.id,
            institutionId: feeStructure.institutionId,
            studentUid: studentUid,
            feeStructureId: feeStructure.id,
            academicYearId: feeStructure.academicYearId,
            termId: feeStructure.termId,
            classId: classIdToAssign,
            feeItemName: feeStructure.feeItemName,
            amountDue: feeStructure.amount,
            originalDueDate: feeStructure.dueDate,
            createdAt: now,
            updatedAt: now,
          );
          batch.set(docRef, newAssignment.toMap());
        }
        processedStudentUids.add(studentUid);
      }
      await batch.commit();
      return processedStudentUids;
    } catch (e) {
      print("Error assigning fees to class $classIdToAssign: $e");
      throw e; // Rethrow to be handled by UI
    }
  }

  Stream<List<StudentFeeStatusModel>> getStudentFeeStatuses({
    required String studentUid,
    required String institutionId,
    String? academicYearId,
    String? termId,
    FeePaymentStatus? paymentStatus,
  }) {
    Query query = _firestore.collection(_studentFeeStatusPath)
        .where('institutionId', isEqualTo: institutionId)
        .where('studentUid', isEqualTo: studentUid);

    if (academicYearId != null) query = query.where('academicYearId', isEqualTo: academicYearId);
    if (termId != null) query = query.where('termId', isEqualTo: termId);
    if (paymentStatus != null) query = query.where('paymentStatus', isEqualTo: feePaymentStatusToString(paymentStatus));

    return query.orderBy('originalDueDate').snapshots().map((snapshot) => snapshot.docs
        .map((doc) => StudentFeeStatusModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  Future<Map<String, double>> getStudentFeeSummary({
    required String studentUid,
    required String institutionId,
    String? academicYearId,
    String? termId,
  }) async {
    double totalDue = 0;
    double totalPaid = 0;

    Query query = _firestore.collection(_studentFeeStatusPath)
        .where('institutionId', isEqualTo: institutionId)
        .where('studentUid', isEqualTo: studentUid);

    if (academicYearId != null) query = query.where('academicYearId', isEqualTo: academicYearId);
    if (termId != null) query = query.where('termId', isEqualTo: termId);

    QuerySnapshot snapshot = await query.get();
    for (var doc in snapshot.docs) {
      StudentFeeStatusModel status = StudentFeeStatusModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      if (status.paymentStatus != FeePaymentStatus.cancelled && status.paymentStatus != FeePaymentStatus.waived) {
        totalDue += status.amountDue;
      }
      // Only sum successful payments towards totalPaid effectively
      if(status.paymentStatus == FeePaymentStatus.paid || status.paymentStatus == FeePaymentStatus.partiallyPaid) {
         totalPaid += status.amountPaid;
      }
    }
    return {
      'totalDue': totalDue,
      'totalPaid': totalPaid,
      'balance': totalDue - totalPaid,
    };
  }

  Future<bool> updateStudentFeeStatus(String studentFeeStatusId, {
    double? amountPaidIncrement,
    FeePaymentStatus? newPaymentStatus,
    String? paymentTransactionId,
  }) async {
    try {
      DocumentReference docRef = _firestore.collection(_studentFeeStatusPath).doc(studentFeeStatusId);
      Map<String, dynamic> updateData = {'updatedAt': FieldValue.serverTimestamp()};

      if (amountPaidIncrement != null && amountPaidIncrement > 0) {
        updateData['amountPaid'] = FieldValue.increment(amountPaidIncrement);
      }
      if (newPaymentStatus != null) {
        updateData['paymentStatus'] = feePaymentStatusToString(newPaymentStatus);
      }
      if (paymentTransactionId != null) {
        updateData['paymentTransactionIds'] = FieldValue.arrayUnion([paymentTransactionId]);
        updateData['actualPaymentDate'] = FieldValue.serverTimestamp();
      }

      // Transactional update to ensure status is correctly set to 'paid' if balance is zero
      return _firestore.runTransaction((transaction) async {
        DocumentSnapshot currentSnap = await transaction.get(docRef);
        if (!currentSnap.exists) throw Exception("StudentFeeStatus document not found!");

        StudentFeeStatusModel currentStatus = StudentFeeStatusModel.fromMap(currentSnap.data() as Map<String,dynamic>, currentSnap.id);
        double currentAmountPaid = currentStatus.amountPaid;
        if (amountPaidIncrement != null) {
            currentAmountPaid += amountPaidIncrement;
        }

        if (newPaymentStatus == null && // Only auto-set to paid if status isn't being explicitly set to something else
            currentAmountPaid >= currentStatus.amountDue &&
            currentStatus.paymentStatus != FeePaymentStatus.paid &&
            currentStatus.paymentStatus != FeePaymentStatus.waived &&
            currentStatus.paymentStatus != FeePaymentStatus.cancelled) {
          updateData['paymentStatus'] = feePaymentStatusToString(FeePaymentStatus.paid);
        }
        transaction.update(docRef, updateData);
      }).then((_) => true).catchError((e) {
        print("Error in transaction for student fee status $studentFeeStatusId: $e");
        return false;
      });
    } catch (e) {
      print("Error updating student fee status $studentFeeStatusId: $e");
      return false;
    }
  }
}

// Helper extension for StudentFeeStatusModel to use copyWith pattern
extension StudentFeeStatusModelCopyWith on StudentFeeStatusModel {
  StudentFeeStatusModel copyWith({
    String? id,
    String? institutionId,
    String? studentUid,
    String? feeStructureId,
    String? academicYearId,
    String? termId,
    String? classId,
    String? feeItemName,
    double? amountDue,
    double? amountPaid,
    DateTime? originalDueDate,
    DateTime? actualPaymentDate,
    FeePaymentStatus? paymentStatus,
    List<String>? paymentTransactionIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudentFeeStatusModel(
      id: id ?? this.id,
      institutionId: institutionId ?? this.institutionId,
      studentUid: studentUid ?? this.studentUid,
      feeStructureId: feeStructureId ?? this.feeStructureId,
      academicYearId: academicYearId ?? this.academicYearId,
      termId: termId ?? this.termId,
      classId: classId ?? this.classId,
      feeItemName: feeItemName ?? this.feeItemName,
      amountDue: amountDue ?? this.amountDue,
      amountPaid: amountPaid ?? this.amountPaid,
      originalDueDate: originalDueDate ?? this.originalDueDate,
      actualPaymentDate: actualPaymentDate ?? this.actualPaymentDate,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentTransactionIds: paymentTransactionIds ?? this.paymentTransactionIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Helper extension for FeeStructureModel to use copyWith pattern
extension FeeStructureModelCopyWith on FeeStructureModel {
    FeeStructureModel copyWith({
    String? id,
    String? institutionId,
    String? name,
    String? description,
    String? academicYearId,
    String? termId,
    String? classId,
    String? feeItemName,
    double? amount,
    String? currency,
    DateTime? dueDate,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    }) {
        return FeeStructureModel(
        id: id ?? this.id,
        institutionId: institutionId ?? this.institutionId,
        name: name ?? this.name,
        description: description ?? this.description,
        academicYearId: academicYearId ?? this.academicYearId,
        termId: termId ?? this.termId,
        classId: classId ?? this.classId,
        feeItemName: feeItemName ?? this.feeItemName,
        amount: amount ?? this.amount,
        currency: currency ?? this.currency,
        dueDate: dueDate ?? this.dueDate,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        );
    }
}
