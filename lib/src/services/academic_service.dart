import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_management_system/src/models/academic_year_model.dart';
import 'package:school_management_system/src/models/term_model.dart';
import 'package:school_management_system/src/models/class_model.dart';
import 'package:school_management_system/src/models/subject_model.dart';

class AcademicService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection paths
  final String _academicYearsPath = 'academic_years';
  final String _termsPath = 'terms'; // Could be a subcollection of academic_years
  final String _classesPath = 'classes'; // Could be a subcollection of terms or academic_years
  final String _subjectsPath = 'subjects';

  // In a more complex setup, terms might be a subcollection of academic_years,
  // and classes might be a subcollection of terms or academic_years to enforce hierarchy.
  // For simplicity in this initial service, they are top-level collections filtered by institutionId and parent IDs.

  // --- Academic Year Methods ---
  Future<AcademicYearModel?> createAcademicYear(AcademicYearModel academicYear) async {
    try {
      DocumentReference docRef = _firestore.collection(_academicYearsPath).doc();
      AcademicYearModel newYear = AcademicYearModel(
        id: docRef.id,
        institutionId: academicYear.institutionId,
        name: academicYear.name,
        startDate: academicYear.startDate,
        endDate: academicYear.endDate,
        isActive: academicYear.isActive, // Consider logic to ensure only one is active
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      // If setting this year to active, ensure others are inactive (could be a cloud function trigger)
      if (newYear.isActive) {
        await _deactivateOtherAcademicYears(newYear.institutionId, newYear.id);
      }
      await docRef.set(newYear.toMap());
      return newYear;
    } catch (e) {
      print("Error creating academic year: $e");
      return null;
    }
  }

  Stream<List<AcademicYearModel>> getAcademicYears(String institutionId) {
    return _firestore
        .collection(_academicYearsPath)
        .where('institutionId', isEqualTo: institutionId)
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AcademicYearModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Future<bool> updateAcademicYear(String id, Map<String, dynamic> data, String institutionId) async {
    try {
      Map<String, dynamic> updateData = Map<String, dynamic>.from(data);
      updateData['updatedAt'] = Timestamp.now();

      if (data.containsKey('isActive') && data['isActive'] == true) {
         await _deactivateOtherAcademicYears(institutionId, id);
      }
      await _firestore.collection(_academicYearsPath).doc(id).update(updateData);
      return true;
    } catch (e) {
      print("Error updating academic year $id: $e");
      return false;
    }
  }

  Future<void> _deactivateOtherAcademicYears(String institutionId, String activeYearId) async {
    QuerySnapshot otherYears = await _firestore
        .collection(_academicYearsPath)
        .where('institutionId', isEqualTo: institutionId)
        .where('isActive', isEqualTo: true)
        .get();
    for (var doc in otherYears.docs) {
      if (doc.id != activeYearId) {
        await doc.reference.update({'isActive': false, 'updatedAt': Timestamp.now()});
      }
    }
  }

  Future<bool> deleteAcademicYear(String id) async {
    try {
      // TODO: Check for dependencies (terms, classes) before deleting.
      await _firestore.collection(_academicYearsPath).doc(id).delete();
      return true;
    } catch (e) {
      print("Error deleting academic year $id: $e");
      return false;
    }
  }


  // --- Term Methods ---
  Future<TermModel?> createTerm(TermModel term) async {
    try {
      DocumentReference docRef = _firestore.collection(_termsPath).doc();
      TermModel newTerm = TermModel(
        id: docRef.id,
        institutionId: term.institutionId,
        academicYearId: term.academicYearId,
        name: term.name,
        startDate: term.startDate,
        endDate: term.endDate,
        isCurrentTerm: term.isCurrentTerm, // Logic to ensure only one is current per institution/AY
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      if (newTerm.isCurrentTerm) {
        await _deactivateOtherTerms(newTerm.institutionId, newTerm.academicYearId, newTerm.id);
      }
      await docRef.set(newTerm.toMap());
      return newTerm;
    } catch (e) {
      print("Error creating term: $e");
      return null;
    }
  }

  Stream<List<TermModel>> getTerms(String institutionId, String academicYearId) {
    return _firestore
        .collection(_termsPath)
        .where('institutionId', isEqualTo: institutionId)
        .where('academicYearId', isEqualTo: academicYearId)
        .orderBy('startDate')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TermModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Future<bool> updateTerm(String id, Map<String, dynamic> data, String institutionId, String academicYearId) async {
    try {
      Map<String, dynamic> updateData = Map<String, dynamic>.from(data);
      updateData['updatedAt'] = Timestamp.now();
      if (data.containsKey('isCurrentTerm') && data['isCurrentTerm'] == true) {
         await _deactivateOtherTerms(institutionId, academicYearId, id);
      }
      await _firestore.collection(_termsPath).doc(id).update(updateData);
      return true;
    } catch (e) {
      print("Error updating term $id: $e");
      return false;
    }
  }

  Future<void> _deactivateOtherTerms(String institutionId, String academicYearId, String currentTermId) async {
    QuerySnapshot otherTerms = await _firestore
        .collection(_termsPath)
        .where('institutionId', isEqualTo: institutionId)
        .where('academicYearId', isEqualTo: academicYearId)
        .where('isCurrentTerm', isEqualTo: true)
        .get();
    for (var doc in otherTerms.docs) {
      if (doc.id != currentTermId) {
        await doc.reference.update({'isCurrentTerm': false, 'updatedAt': Timestamp.now()});
      }
    }
  }

  Future<bool> deleteTerm(String id) async {
    try {
      // TODO: Check dependencies
      await _firestore.collection(_termsPath).doc(id).delete();
      return true;
    } catch (e) {
      print("Error deleting term $id: $e");
      return false;
    }
  }


  // --- Class Methods ---
  Future<ClassModel?> createClass(ClassModel classModel) async {
    try {
      DocumentReference docRef = _firestore.collection(_classesPath).doc();
      ClassModel newClass = ClassModel(
        id: docRef.id,
        institutionId: classModel.institutionId,
        name: classModel.name,
        academicYearId: classModel.academicYearId,
        termId: classModel.termId,
        classTeacherUid: classModel.classTeacherUid,
        roomNumber: classModel.roomNumber,
        capacity: classModel.capacity,
        studentUids: classModel.studentUids ?? [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await docRef.set(newClass.toMap());
      return newClass;
    } catch (e) {
      print("Error creating class: $e");
      return null;
    }
  }

  Stream<List<ClassModel>> getClasses(String institutionId, {String? academicYearId, String? termId}) {
    Query query = _firestore.collection(_classesPath).where('institutionId', isEqualTo: institutionId);
    if (academicYearId != null) query = query.where('academicYearId', isEqualTo: academicYearId);
    if (termId != null) query = query.where('termId', isEqualTo: termId);

    return query.orderBy('name').snapshots().map((snapshot) => snapshot.docs
        .map((doc) => ClassModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  Future<bool> updateClass(String id, Map<String, dynamic> data) async {
    try {
      Map<String, dynamic> updateData = Map<String, dynamic>.from(data);
      updateData['updatedAt'] = Timestamp.now();
      await _firestore.collection(_classesPath).doc(id).update(updateData);
      return true;
    } catch (e) {
      print("Error updating class $id: $e");
      return false;
    }
  }

  Future<bool> deleteClass(String id) async {
    try {
      // TODO: Check dependencies (students enrolled, subjects assigned)
      await _firestore.collection(_classesPath).doc(id).delete();
      return true;
    } catch (e) {
      print("Error deleting class $id: $e");
      return false;
    }
  }

  // Method to assign/unassign students to/from a class
  Future<bool> updateClassStudentList(String classId, List<String> studentUids) async {
    try {
      await _firestore.collection(_classesPath).doc(classId).update({
        'studentUids': studentUids,
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      print("Error updating student list for class $classId: $e");
      return false;
    }
  }


  // --- Subject Methods ---
  Future<SubjectModel?> createSubject(SubjectModel subject) async {
    try {
      DocumentReference docRef = _firestore.collection(_subjectsPath).doc();
      SubjectModel newSubject = SubjectModel(
        id: docRef.id,
        institutionId: subject.institutionId,
        name: subject.name,
        code: subject.code,
        description: subject.description,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await docRef.set(newSubject.toMap());
      return newSubject;
    } catch (e) {
      print("Error creating subject: $e");
      return null;
    }
  }

  Stream<List<SubjectModel>> getSubjects(String institutionId) {
    return _firestore
        .collection(_subjectsPath)
        .where('institutionId', isEqualTo: institutionId)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SubjectModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Future<bool> updateSubject(String id, Map<String, dynamic> data) async {
    try {
      Map<String, dynamic> updateData = Map<String, dynamic>.from(data);
      updateData['updatedAt'] = Timestamp.now();
      await _firestore.collection(_subjectsPath).doc(id).update(updateData);
      return true;
    } catch (e) {
      print("Error updating subject $id: $e");
      return false;
    }
  }

  Future<bool> deleteSubject(String id) async {
    try {
      // TODO: Check dependencies (assigned to classes/teachers)
      await _firestore.collection(_subjectsPath).doc(id).delete();
      return true;
    } catch (e) {
      print("Error deleting subject $id: $e");
      return false;
    }
  }

  // --- Linking Collections (Conceptual - might need dedicated linking tables/collections) ---
  // Example: Assigning subjects to a class or teachers to a subject/class
  // This can be done by storing lists of IDs on either model, or using a separate linking collection.
  // For instance, ClassModel could have a list of subjectIds.
  // SubjectModel could have a list of teacherUids qualified to teach it.
  // A ClassSubjectTeacherLink collection could store {classId, subjectId, teacherUid, academicYearId}.
  // For now, these links are assumed to be managed by updating arrays on the primary models.
}
