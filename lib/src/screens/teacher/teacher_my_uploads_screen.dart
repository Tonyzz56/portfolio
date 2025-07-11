import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:school_management_system/src/models/user_model.dart';
import 'package:school_management_system/src/models/file_asset_model.dart';
import 'package:school_management_system/src/services/file_asset_service.dart';
// For selecting context (e.g., class, subject - these would be more complex UI in reality)
// import 'package:school_management_system/src/models/class_model.dart';
// import 'package:school_management_system/src/models/subject_model.dart';
// import 'package:school_management_system/src/services/academic_service.dart';
import 'package:intl/intl.dart'; // For date display

class TeacherMyUploadsScreen extends StatefulWidget {
  const TeacherMyUploadsScreen({super.key});

  @override
  State<TeacherMyUploadsScreen> createState() => _TeacherMyUploadsScreenState();
}

class _TeacherMyUploadsScreenState extends State<TeacherMyUploadsScreen> {
  final FileAssetService _fileAssetService = FileAssetService();
  UserModel? _currentUser;
  bool _isLoading = false;

  // For simplicity, we'll assume uploads are general for the teacher for now.
  // In a full implementation, UI would allow selecting Class/Subject context.
  String _relatedEntityType = 'teacher_material'; // Example type

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_currentUser == null) {
      _currentUser = Provider.of<UserModel?>(context);
    }
  }

  Future<void> _uploadNewMaterial() async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User not available.")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final Map<String, dynamic>? fileData = await _fileAssetService.pickFileAndConvertToBase64(
        allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'txt', 'jpg', 'png', 'jpeg'],
      );

      if (fileData != null) {
        String? description = await _showDescriptionDialog(); // Optional description

        await _fileAssetService.uploadFileAsset(
          fileName: fileData['fileName'],
          base64Data: fileData['base64Data'],
          mimeType: fileData['mimeType'],
          assetType: FileAssetType.document, // Could be 'image' if specifically picking images
          uploadedByUid: _currentUser!.uid,
          uploadedByName: _currentUser!.displayName ?? _currentUser!.email,
          description: description,
          relatedToId: _currentUser!.uid, // Link to the teacher for now
          relatedToType: _relatedEntityType,
        );
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Material uploaded successfully!'), backgroundColor: Colors.green),
        );
        setState((){}); // Refresh stream
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading material: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  Future<String?> _showDescriptionDialog() {
    TextEditingController descriptionController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Material Description (Optional)'),
          content: TextField(
            controller: descriptionController,
            decoration: const InputDecoration(hintText: "Enter a brief description..."),
            maxLines: 2,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.of(context).pop(descriptionController.text.trim()), child: const Text('OK')),
          ],
        );
      },
    );
  }

  Future<void> _confirmDelete(FileAsset asset) async {
     bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext ctx) {
            return AlertDialog(
                title: const Text('Confirm Delete'),
                content: Text('Are you sure you want to delete "${asset.fileName}"?'),
                actions: <Widget>[
                    TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                    TextButton(style: TextButton.styleFrom(foregroundColor: Colors.red), onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
                ],
            );
        });
    if (confirm == true) {
        bool success = await _fileAssetService.deleteFileAsset(asset.id);
         if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'File deleted.' : 'Failed to delete file.'), backgroundColor: success ? Colors.green : Colors.red));
        // Stream will update the list
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_currentUser == null || _currentUser!.role != UserRole.teacher) {
      return Scaffold(
        appBar: AppBar(title: const Text("Access Denied")),
        body: const Center(child: Text("You do not have permission to view this page.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Uploaded Materials'),
      ),
      body: Column(
        children: [
          if (_isLoading) const LinearProgressIndicator(),
          Expanded(
            child: StreamBuilder<List<FileAsset>>(
              stream: _fileAssetService.getFileAssetsForRelatedEntity(
                relatedToId: _currentUser!.uid, // Show files uploaded by this teacher
                relatedToType: _relatedEntityType, // Filter by the type we set during upload
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !_isLoading) { // Show loader only if not already loading from FAB action
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No materials uploaded yet.'));
                }

                List<FileAsset> materials = snapshot.data!;
                return ListView.builder(
                  itemCount: materials.length,
                  itemBuilder: (context, index) {
                    FileAsset material = materials[index];
                    IconData docIcon = Icons.article_outlined;
                    if (material.mimeType.startsWith('image/')) docIcon = Icons.image_outlined;
                    if (material.mimeType == 'application/pdf') docIcon = Icons.picture_as_pdf_outlined;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: Icon(docIcon, size: 30),
                        title: Text(material.fileName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (material.description != null && material.description!.isNotEmpty)
                              Text(material.description!),
                            Text('Uploaded: ${DateFormat.yMMMd().add_jm().format(material.uploadedAt.toLocal())}'),
                            Text('Type: ${material.mimeType}, Size: ${(material.base64Data.length * 0.75 / 1024).toStringAsFixed(2)} KB approx.', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          tooltip: "Delete Material",
                          onPressed: () => _confirmDelete(material),
                        ),
                        onTap: () {
                          // TODO: Implement viewing/downloading logic
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('View/Download "${material.fileName}" (Not Implemented)')),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _uploadNewMaterial,
        label: const Text('Upload Material'),
        icon: const Icon(Icons.upload_file),
      ),
    );
  }
}
