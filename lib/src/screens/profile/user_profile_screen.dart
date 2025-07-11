import 'dart:convert'; // For base64 encoding/decoding
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:school_management_system/src/models/user_model.dart';
import 'package:school_management_system/src/services/auth_service.dart';
import 'package:school_management_system/src/services/file_asset_service.dart'; // Import FileAssetService

class UserProfileScreen extends StatefulWidget {
  final UserModel currentUser;

  const UserProfileScreen({super.key, required this.currentUser});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final FileAssetService _fileAssetService = FileAssetService(); // Instantiate FileAssetService
  bool _isLoading = false;

  late TextEditingController _displayNameController;
  String? _profileImageBase64; // To hold base64 string of selected image for preview
  String? _profileImageMimeType;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(text: widget.currentUser.displayName);
    _profileImageBase64 = widget.currentUser.photoBase64; // Initialize with current photo
    _profileImageMimeType = widget.currentUser.photoMimeType;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    setState(() => _isLoading = true);
    try {
      final Map<String, dynamic>? imageData = await _fileAssetService.pickImageAndConvertToBase64(
        source: ImageSource.gallery,
        imageQuality: 50, // Compress a bit for profile pics
        maxHeight: 400, // Smaller dimensions for profile pics
        maxWidth: 400
      );

      if (imageData != null) {
        setState(() {
          _profileImageBase64 = imageData['base64Data'];
          _profileImageMimeType = imageData['mimeType'];
        });
      }
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    Map<String, dynamic> updatedData = {
      'displayName': _displayNameController.text.trim(),
      // Only include photo fields if a new photo was picked or existing one is there
      // If user wants to remove photo, _profileImageBase64 should be set to null explicitly by another action
      'photoBase64': _profileImageBase64,
      'photoMimeType': _profileImageMimeType,
    };

    try {
      bool success = await _authService.updateUserProfile(widget.currentUser.uid, updatedData);
      if (success) {
        // Update local current user model if possible (e.g., if using Provider for state management)
        // This ensures the UI reflects the change immediately without waiting for Firestore stream to update.
        widget.currentUser.displayName = _displayNameController.text.trim();
        widget.currentUser.photoBase64 = _profileImageBase64;
        widget.currentUser.photoMimeType = _profileImageMimeType;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? profileImageProvider;
    if (_profileImageBase64 != null && _profileImageBase64!.isNotEmpty) {
        try {
            profileImageProvider = MemoryImage(base64Decode(_profileImageBase64!));
        } catch (e) {
            print("Error decoding base64 profile image: $e");
            profileImageProvider = null; // Fallback if decoding fails
        }
    }


    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    GestureDetector(
                      onTap: _pickProfileImage,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey.shade300,
                        backgroundImage: profileImageProvider,
                        child: profileImageProvider == null
                            ? Icon(Icons.camera_alt, size: 50, color: Colors.grey.shade700)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(onPressed: _pickProfileImage, child: const Text("Change Profile Photo")),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _displayNameController,
                      decoration: const InputDecoration(labelText: 'Display Name', border: OutlineInputBorder()),
                      validator: (value) => value == null || value.isEmpty ? 'Display name cannot be empty' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: widget.currentUser.email,
                      decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder()),
                      readOnly: true,
                    ),
                    const SizedBox(height: 16),
                     TextFormField(
                      initialValue: userRoleToString(widget.currentUser.role),
                      decoration: const InputDecoration(labelText: 'My Role', border: OutlineInputBorder()),
                      readOnly: true,
                    ),
                    if (widget.currentUser.institutionId != null) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: widget.currentUser.institutionId,
                        decoration: const InputDecoration(labelText: 'My Institution ID', border: OutlineInputBorder()),
                        readOnly: true,
                      ),
                    ],
                    if (widget.currentUser.staffId != null) ...[
                        const SizedBox(height: 16),
                        TextFormField(initialValue: widget.currentUser.staffId, decoration: const InputDecoration(labelText: 'Staff ID', border: OutlineInputBorder()), readOnly: true),
                    ],
                     if (widget.currentUser.admissionNumber != null) ...[
                        const SizedBox(height: 16),
                        TextFormField(initialValue: widget.currentUser.admissionNumber, decoration: const InputDecoration(labelText: 'Admission Number', border: OutlineInputBorder()), readOnly: true),
                    ],
                    if (widget.currentUser.department != null) ...[
                        const SizedBox(height: 16),
                        TextFormField(initialValue: widget.currentUser.department, decoration: const InputDecoration(labelText: 'Department', border: OutlineInputBorder()), readOnly: true),
                    ],
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _updateProfile,
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                      child: const Text('Save Changes'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
