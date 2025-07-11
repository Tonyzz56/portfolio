import 'dart:convert'; // For base64
import 'dart:io'; // For File
import 'package:flutter/foundation.dart' show kIsWeb; // For web platform check
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_management_system/src/models/file_asset_model.dart';
import 'package:mime/mime.dart'; // For detecting mime types, add to pubspec if not there

// Reminder: Add 'mime: ^1.0.4' (or latest) to pubspec.yaml

class FileAssetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'fileAssets'; // Collection to store FileAsset documents

  // --- File Picking and Conversion ---

  Future<Map<String, dynamic>?> pickImageAndConvertToBase64({ImageSource source = ImageSource.gallery, int imageQuality = 70, double maxHeight = 1024, double maxWidth = 1024}) async {
    final ImagePicker picker = ImagePicker();
    final XFile? imageFile = await picker.pickImage(
        source: source,
        imageQuality: imageQuality,
        maxHeight: maxHeight, // Limit image dimensions to reduce Base64 string size
        maxWidth: maxWidth,
    );

    if (imageFile == null) return null;

    List<int> fileBytes;
    if (kIsWeb) {
      fileBytes = await imageFile.readAsBytes();
    } else {
      File file = File(imageFile.path);
      fileBytes = await file.readAsBytes();
    }

    // Firestore 1MB limit. Base64 increases size by ~33%. So raw bytes should be < ~750KB.
    if (fileBytes.length > 750 * 1024) {
        throw Exception('Image is too large (max ~750KB). Please choose a smaller image or compress it further.');
    }

    String base64String = base64Encode(fileBytes);
    String? mimeType = lookupMimeType(imageFile.name, headerBytes: fileBytes.sublist(0, (fileBytes.length > 100 ? 100: fileBytes.length) )); // Get MimeType

    return {
      'fileName': imageFile.name,
      'base64Data': base64String,
      'mimeType': mimeType ?? 'image/jpeg', // Default if lookup fails
    };
  }

  Future<Map<String, dynamic>?> pickFileAndConvertToBase64({List<String>? allowedExtensions}) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions ?? ['pdf', 'doc', 'docx', 'txt', 'jpg', 'png'], // Example default extensions
    );

    if (result == null || result.files.single.path == null && !kIsWeb) return null; // No file picked or path is null on non-web
    if (result == null || result.files.single.bytes == null && kIsWeb) return null; // No file picked or bytes are null on web

    PlatformFile platformFile = result.files.single;
    List<int> fileBytes;

    if (kIsWeb) {
        fileBytes = platformFile.bytes!;
    } else {
        File file = File(platformFile.path!);
        fileBytes = await file.readAsBytes();
    }

    if (fileBytes.length > 750 * 1024) { // ~750KB limit for raw bytes
        throw Exception('File is too large (max ~750KB). Please choose a smaller file.');
    }

    String base64String = base64Encode(fileBytes);
    String? mimeType = lookupMimeType(platformFile.name, headerBytes: fileBytes.sublist(0, (fileBytes.length > 100 ? 100: fileBytes.length) ));

    return {
      'fileName': platformFile.name,
      'base64Data': base64String,
      'mimeType': mimeType ?? 'application/octet-stream', // Default MIME type
    };
  }

  // --- Firestore Operations ---

  Future<FileAsset?> uploadFileAsset({
    required String fileName,
    required String base64Data,
    required String mimeType,
    required FileAssetType assetType,
    required String uploadedByUid,
    required String uploadedByName,
    String? description,
    String? relatedToId,
    String? relatedToType,
  }) async {
    try {
      DocumentReference docRef = _firestore.collection(_collectionPath).doc();
      FileAsset newAsset = FileAsset(
        id: docRef.id,
        fileName: fileName,
        description: description,
        assetType: assetType,
        mimeType: mimeType,
        base64Data: base64Data, // The large string
        uploadedByUid: uploadedByUid,
        uploadedByName: uploadedByName,
        uploadedAt: DateTime.now(),
        relatedToId: relatedToId,
        relatedToType: relatedToType,
      );
      await docRef.set(newAsset.toMap());
      return newAsset;
    } catch (e) {
      print('Error uploading FileAsset: $e');
      // Consider specific error handling, e.g., if base64Data is too large for Firestore.
      // Firestore client might throw error before even sending if doc size is too big.
      if (e.toString().contains('RESOURCE_EXHAUSTED') || e.toString().contains('payload is too large')) {
          throw Exception('File is too large to save. Firestore document size limit exceeded.');
      }
      return null;
    }
  }

  // Get a single FileAsset by ID
  Future<FileAsset?>getFileAssetById(String id) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(_collectionPath).doc(id).get();
      if (doc.exists) {
        return FileAsset.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting FileAsset by ID $id: $e');
      return null;
    }
  }

  // Get FileAssets related to a specific entity (e.g., all documents for a course)
  Stream<List<FileAsset>> getFileAssetsForRelatedEntity({
    required String relatedToId,
    String? relatedToType, // Optional: further filter by type if one ID can have multiple asset types
  }) {
    Query query = _firestore.collection(_collectionPath).where('relatedToId', isEqualTo: relatedToId);
    if (relatedToType != null) {
      query = query.where('relatedToType', isEqualTo: relatedToType);
    }
    return query.orderBy('uploadedAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => FileAsset.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    });
  }

  // Delete a FileAsset
  Future<bool> deleteFileAsset(String id) async {
    try {
      await _firestore.collection(_collectionPath).doc(id).delete();
      return true;
    } catch (e) {
      print('Error deleting FileAsset $id: $e');
      return false;
    }
  }

  // Update FileAsset metadata (not usually for changing base64Data itself due to size)
  Future<bool> updateFileAssetMetadata(String id, {String? fileName, String? description}) async {
    if (fileName == null && description == null) return true; // Nothing to update
    Map<String, dynamic> dataToUpdate = {};
    if (fileName != null) dataToUpdate['fileName'] = fileName;
    if (description != null) dataToUpdate['description'] = description;

    try {
      await _firestore.collection(_collectionPath).doc(id).update(dataToUpdate);
      return true;
    } catch (e) {
      print('Error updating FileAsset metadata $id: $e');
      return false;
    }
  }
}
