enum InstitutionType {
  university,
  college,
  primarySchool,
  seniorSchool,
  highSchool,
  eLearning,
  other
}

class Institution {
  final String id; // Document ID from Firestore
  String name;
  InstitutionType type;
  String? address;
  String? contactEmail;
  String? contactPhone;
  String adminUserId; // UID of the Institution Admin
  DateTime createdAt;
  DateTime updatedAt;
  bool isActive; // For activating/deactivating institutions

  // Subscription related fields
  String? activeSubscriptionPackageId;
  DateTime? subscriptionStartDate;
  DateTime? subscriptionEndDate;
  String subscriptionStatus; // e.g., 'active', 'grace_period', 'suspended', 'lapsed', 'trial'

  Institution({
    required this.id,
    required this.name,
    required this.type,
    this.address,
    this.contactEmail,
    this.contactPhone,
    required this.adminUserId,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.activeSubscriptionPackageId,
    this.subscriptionStartDate,
    this.subscriptionEndDate,
    this.subscriptionStatus = 'trial', // Default status for new institutions
  });

  factory Institution.fromMap(Map<String, dynamic> data, String documentId) {
    return Institution(
      id: documentId,
      name: data['name'] ?? 'Unknown Name',
      type: institutionTypeFromString(data['type'] as String?),
      address: data['address'] as String?,
      contactEmail: data['contactEmail'] as String?,
      contactPhone: data['contactPhone'] as String?,
      adminUserId: data['adminUserId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
      activeSubscriptionPackageId: data['activeSubscriptionPackageId'] as String?,
      subscriptionStartDate: (data['subscriptionStartDate'] as Timestamp?)?.toDate(),
      subscriptionEndDate: (data['subscriptionEndDate'] as Timestamp?)?.toDate(),
      subscriptionStatus: data['subscriptionStatus'] ?? 'trial',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type.toString().split('.').last, // e.g., "university"
      'address': address,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'adminUserId': adminUserId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'activeSubscriptionPackageId': activeSubscriptionPackageId,
      'subscriptionStartDate': subscriptionStartDate != null ? Timestamp.fromDate(subscriptionStartDate!) : null,
      'subscriptionEndDate': subscriptionEndDate != null ? Timestamp.fromDate(subscriptionEndDate!) : null,
      'subscriptionStatus': subscriptionStatus,
      // id is not stored in the map as it's the document ID
    };
  }
}

InstitutionType institutionTypeFromString(String? typeString) {
  if (typeString == null) return InstitutionType.other;
  switch (typeString.toLowerCase()) {
    case 'university':
      return InstitutionType.university;
    case 'college':
      return InstitutionType.college;
    case 'primaryschool':
      return InstitutionType.primarySchool;
    case 'seniorschool':
      return InstitutionType.seniorSchool;
    case 'highschool':
      return InstitutionType.highSchool;
    case 'elearning':
      return InstitutionType.eLearning;
    default:
      return InstitutionType.other;
  }
}

String institutionTypeToString(InstitutionType type) {
  return type.toString().split('.').last;
}

List<InstitutionType> getAllInstitutionTypes() {
  return InstitutionType.values;
}
