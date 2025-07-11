import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  superAdmin,
  institutionAdmin,
  teacher,
  student,
  nonTeachingStaff,
  parent, // Added Parent role
  vendor, // Added Vendor role
  unknown
}

class UserModel {
  final String uid; // Firebase Auth UID and Firestore Document ID
  String email; // Email used for Firebase Auth; might be system-generated/hidden for custom ID login
  String? customLoginId; // The user-facing login ID (e.g., student ID, staff ID, parent ID)
  String? displayName;
  UserRole role;
  String? institutionId;
  bool isActive;
  DateTime createdAt;
  DateTime updatedAt;

  String? photoBase64;
  String? photoMimeType;

  // Role-specific fields
  String? admissionNumber; // Student
  String? currentClassId;  // Student
  List<String>? parentUids; // Student: list of linked parent UIDs

  String? staffId;           // Teacher, Non-Teaching Staff
  List<String>? subjectIds;  // Teacher
  String? department;        // Non-Teaching Staff

  List<String>? childUids; // Parent: list of linked child UIDs

  String? vendorCompanyName; // Vendor


  UserModel({
    required this.uid,
    required this.email,
    this.customLoginId,
    this.displayName,
    required this.role,
    this.institutionId,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.photoBase64,
    this.photoMimeType,
    // Role-specific
    this.admissionNumber,
    this.currentClassId,
    this.parentUids,
    this.staffId,
    this.subjectIds,
    this.department,
    this.childUids,
    this.vendorCompanyName,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      uid: documentId,
      email: data['email'] ?? '',
      customLoginId: data['customLoginId'] as String?,
      displayName: data['displayName'] as String?,
      role: userRoleFromString(data['role'] as String?),
      institutionId: data['institutionId'] as String?,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      photoBase64: data['photoBase64'] as String?,
      photoMimeType: data['photoMimeType'] as String?,
      // Role-specific
      admissionNumber: data['admissionNumber'] as String?,
      currentClassId: data['currentClassId'] as String?,
      parentUids: (data['parentUids'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      staffId: data['staffId'] as String?,
      subjectIds: (data['subjectIds'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      department: data['department'] as String?,
      childUids: (data['childUids'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      vendorCompanyName: data['vendorCompanyName'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      if (customLoginId != null) 'customLoginId': customLoginId,
      'displayName': displayName,
      'role': userRoleToString(role), // Use helper
      'institutionId': institutionId,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (photoBase64 != null) 'photoBase64': photoBase64,
      if (photoMimeType != null) 'photoMimeType': photoMimeType,
      // Role-specific
      if (admissionNumber != null) 'admissionNumber': admissionNumber,
      if (currentClassId != null) 'currentClassId': currentClassId,
      if (parentUids != null && parentUids!.isNotEmpty) 'parentUids': parentUids,
      if (staffId != null) 'staffId': staffId,
      if (subjectIds != null && subjectIds!.isNotEmpty) 'subjectIds': subjectIds,
      if (department != null) 'department': department,
      if (childUids != null && childUids!.isNotEmpty) 'childUids': childUids,
      if (vendorCompanyName != null) 'vendorCompanyName': vendorCompanyName,
    };
  }
}

UserRole userRoleFromString(String? roleString) {
  if (roleString == null) return UserRole.unknown;
  switch (roleString) {
    case 'superAdmin': return UserRole.superAdmin;
    case 'institutionAdmin': return UserRole.institutionAdmin;
    case 'teacher': return UserRole.teacher;
    case 'student': return UserRole.student;
    case 'nonTeachingStaff': return UserRole.nonTeachingStaff;
    case 'parent': return UserRole.parent;
    case 'vendor': return UserRole.vendor;
    default: return UserRole.unknown;
  }
}

String userRoleToString(UserRole role) {
  return role.toString().split('.').last;
}

// Roles an Institution Admin can typically create/manage
List<UserRole> getManagableUserRolesByInstitutionAdmin() {
  return [UserRole.teacher, UserRole.student, UserRole.nonTeachingStaff, UserRole.parent];
}

// All user-facing roles (excluding superAdmin and unknown)
List<UserRole> getAllAssignableUserRoles() {
    return UserRole.values.where((role) => role != UserRole.superAdmin && role != UserRole.unknown).toList();
}
