import 'package:cloud_firestore/cloud_firestore.dart';

enum FileAssetType {
  document, // General documents
  image,    // Specifically images (e.g., profile photo, event photo)
  report,   // Generated reports
  other,
}

class FileAsset {
  final String id; // Firestore document ID
  String fileName;
  String? description;
  FileAssetType assetType;
  String mimeType; // e.g., 'image/jpeg', 'application/pdf'
  String base64Data; // The Base64 encoded string of the file

  String uploadedByUid;
  String uploadedByName;
  DateTime uploadedAt;

  String? relatedToId; // Optional: ID of related entity (e.g., userId for profile pic, courseId for material)
  String? relatedToType; // Optional: Type of related entity (e.g., 'user_profile', 'course_material')

  FileAsset({
    required this.id,
    required this.fileName,
    this.description,
    required this.assetType,
    required this.mimeType,
    required this.base64Data,
    required this.uploadedByUid,
    required this.uploadedByName,
    required this.uploadedAt,
    this.relatedToId,
    this.relatedToType,
  });

  factory FileAsset.fromMap(Map<String, dynamic> data, String documentId) {
    return FileAsset(
      id: documentId,
      fileName: data['fileName'] ?? 'untitled',
      description: data['description'] as String?,
      assetType: fileAssetTypeFromString(data['assetType'] as String?),
      mimeType: data['mimeType'] ?? 'application/octet-stream',
      base64Data: data['base64Data'] ?? '', // Should ideally not be empty if document exists
      uploadedByUid: data['uploadedByUid'] ?? '',
      uploadedByName: data['uploadedByName'] ?? 'Unknown User',
      uploadedAt: (data['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      relatedToId: data['relatedToId'] as String?,
      relatedToType: data['relatedToType'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fileName': fileName,
      'description': description,
      'assetType': assetType.toString().split('.').last,
      'mimeType': mimeType,
      'base64Data': base64Data, // This can be very large
      'uploadedByUid': uploadedByUid,
      'uploadedByName': uploadedByName,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'relatedToId': relatedToId,
      'relatedToType': relatedToType,
    };
  }
}

FileAssetType fileAssetTypeFromString(String? typeString) {
  if (typeString == null) return FileAssetType.other;
  switch (typeString.toLowerCase()) {
    case 'document':
      return FileAssetType.document;
    case 'image':
      return FileAssetType.image;
    case 'report':
      return FileAssetType.report;
    default:
      return FileAssetType.other;
  }
}
