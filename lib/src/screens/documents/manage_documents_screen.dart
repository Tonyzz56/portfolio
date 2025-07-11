import 'dart:convert'; // For base64Decode
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:school_management_system/src/models/file_asset_model.dart';
import 'package:school_management_system/src/models/user_model.dart';
import 'package:school_management_system/src/services/file_asset_service.dart';
import 'package:school_management_system/src/config/permissions.dart'; // For permission checks
import 'package:school_management_system/src/services/role_permission_service.dart';
import 'package:intl/intl.dart';
// For opening files (add to pubspec.yaml if not already there and configure platforms)
// import 'package:open_filex/open_filex.dart'; // More up-to-date version of open_file
// import 'package:path_provider/path_provider.dart';
// import 'dart:io';
// import 'package:url_launcher/url_launcher_string.dart';


class ManageDocumentsScreen extends StatefulWidget {
  final UserModel currentUser; // User viewing/managing documents
  // Context for the documents being displayed
  final String relatedEntityId;
  final String relatedEntityType;
  final String screenTitle;
  final bool allowUploads; // Control if upload FAB is shown based on context/permissions

  const ManageDocumentsScreen({
    super.key,
    required this.currentUser,
    required this.relatedEntityId,
    required this.relatedEntityType,
    this.screenTitle = "Manage Documents",
    this.allowUploads = true, // Default to allow if not specified
  });

  @override
  State<ManageDocumentsScreen> createState() => _ManageDocumentsScreenState();
}

class _ManageDocumentsScreenState extends State<ManageDocumentsScreen> {
  final FileAssetService _fileAssetService = FileAssetService();
  bool _isLoading = false; // For upload action

  Future<void> _uploadNewDocument() async {
    // Permission check should ideally happen before even showing the upload button
    final rolePermissionService = Provider.of<RolePermissionService>(context, listen: false);
    if (!rolePermissionService.can(AppPermissions.filesUpload)) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("You don't have permission to upload files."), backgroundColor: Colors.red));
        return;
    }


    setState(() => _isLoading = true);
    try {
      final Map<String, dynamic>? fileData = await _fileAssetService.pickFileAndConvertToBase64(
        // Allowed extensions can be customized based on relatedEntityType or passed as param
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'png', 'xls', 'xlsx', 'ppt', 'pptx'],
      );

      if (fileData != null) {
        String? description = await _showDescriptionDialog();

        await _fileAssetService.uploadFileAsset(
          fileName: fileData['fileName'],
          base64Data: fileData['base64Data'],
          mimeType: fileData['mimeType'],
          assetType: _determineAssetType(fileData['mimeType']),
          uploadedByUid: widget.currentUser.uid,
          uploadedByName: widget.currentUser.displayName ?? widget.currentUser.email,
          description: description,
          relatedToId: widget.relatedEntityId,
          relatedToType: widget.relatedEntityType,
        );
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document uploaded successfully!'), backgroundColor: Colors.green),
        );
        // StreamBuilder will refresh the list
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading document: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  FileAssetType _determineAssetType(String mimeType) {
    if (mimeType.startsWith('image/')) return FileAssetType.image;
    // Add more checks if needed, e.g., for specific document types if relevant
    return FileAssetType.document;
  }

  Future<String?> _showDescriptionDialog() {
    TextEditingController descriptionController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Document Description (Optional)'),
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
    final rolePermissionService = Provider.of<RolePermissionService>(context, listen: false);
    bool canDelete = false;
    if (widget.currentUser.uid == asset.uploadedByUid && rolePermissionService.can(AppPermissions.filesDeleteOwn)) {
        canDelete = true;
    } else if (widget.currentUser.role == UserRole.institutionAdmin && rolePermissionService.can(AppPermissions.filesDeleteAnyInInstitution)) {
        // Further check if asset belongs to this admin's institution
        if (asset.toMap()['institutionId'] == widget.currentUser.institutionId) { // Assuming FileAssetModel has institutionId
            canDelete = true;
        }
    } else if (widget.currentUser.role == UserRole.superAdmin && rolePermissionService.can(AppPermissions.filesDeleteAnySystem)) {
        canDelete = true;
    }


    if (!canDelete) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("You don't have permission to delete this file."), backgroundColor: Colors.red));
        return;
    }


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
    }
  }

  void _viewDocument(FileAsset doc) async {
    // Placeholder: Actual implementation is complex due to Base64 and platform differences.
    // For web, a data URI might work for some types.
    // For mobile, saving to a temp file and using open_filex or similar is needed.
    // This requires platform-specific code or plugins like `open_filex` and `path_provider`.

    // Example: Show a dialog with file info and a placeholder message
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
            title: Text("View: ${doc.fileName}"),
            content: SingleChildScrollView(
                child: ListBody(
                    children: <Widget>[
                        Text("MIME Type: ${doc.mimeType}"),
                        Text("Size (approx Base64): ${(doc.base64Data.length * 0.75 / 1024).toStringAsFixed(2)} KB"),
                        const SizedBox(height: 20),
                        const Text("File viewing/download from Base64 is complex and not fully implemented in this placeholder. "
                            "Requires platform-specific handling or plugins like 'open_filex' and 'path_provider' for mobile, "
                            "and careful data URI construction for web."),
                        // if (kIsWeb && (doc.mimeType.startsWith('image/') || doc.mimeType == 'application/pdf')) ...[
                        //   const SizedBox(height: 10),
                        //   ElevatedButton(
                        //     onPressed: () async {
                        //       final String dataUri = 'data:${doc.mimeType};base64,${doc.base64Data}';
                        //       if (!await launchUrlString(dataUri, mode: LaunchMode.externalApplication)) {
                        //         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open file.')));
                        //       }
                        //     },
                        //     child: const Text("Try Open in Browser (Web Only)"),
                        //   )
                        // ]
                    ],
                ),
            ),
            actions: [TextButton(child: const Text("Close"), onPressed: () => Navigator.of(context).pop())],
        ),
    );
}


  @override
  Widget build(BuildContext context) {
    final rolePermissionService = Provider.of<RolePermissionService>(context, listen: false);
    // Determine if upload FAB should be shown based on context AND user permission
    bool canUploadBasedOnPermission = rolePermissionService.can(AppPermissions.filesUpload);
    bool showUploadFab = widget.allowUploads && canUploadBasedOnPermission;


    return Scaffold(
      appBar: AppBar(
        title: Text(widget.screenTitle),
      ),
      body: Column(
        children: [
          if (_isLoading) const LinearProgressIndicator(),
          Expanded(
            child: StreamBuilder<List<FileAsset>>(
              stream: _fileAssetService.getFileAssetsForRelatedEntity(
                relatedToId: widget.relatedEntityId,
                relatedToType: widget.relatedEntityType,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !_isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No documents found for "${widget.relatedEntityType}/${widget.relatedEntityId}".'));
                }

                List<FileAsset> documents = snapshot.data!;
                return ListView.builder(
                  itemCount: documents.length,
                  itemBuilder: (context, index) {
                    FileAsset doc = documents[index];
                    IconData docIcon = Icons.article_outlined;
                    if (doc.mimeType.startsWith('image/')) docIcon = Icons.image_outlined;
                    if (doc.mimeType == 'application/pdf') docIcon = Icons.picture_as_pdf_outlined;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: Icon(docIcon, size: 30),
                        title: Text(doc.fileName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (doc.description != null && doc.description!.isNotEmpty)
                              Text(doc.description!),
                            Text('By: ${doc.uploadedByName} on ${DateFormat.yMMMd().format(doc.uploadedAt.toLocal())}'),
                            Text('Type: ${doc.mimeType}', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                          ],
                        ),
                        trailing: (widget.currentUser.uid == doc.uploadedByUid || widget.currentUser.role == UserRole.superAdmin || (widget.currentUser.role == UserRole.institutionAdmin && widget.currentUser.institutionId == doc.toMap()['institutionId'])) // Basic delete permission check
                            ? IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                tooltip: "Delete Document",
                                onPressed: () => _confirmDelete(doc),
                              )
                            : null,
                        onTap: () => _viewDocument(doc),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: showUploadFab
          ? FloatingActionButton.extended(
              onPressed: _isLoading ? null : _uploadNewDocument,
              label: const Text('Upload Document'),
              icon: const Icon(Icons.upload_file),
            )
          : null,
    );
  }
}
