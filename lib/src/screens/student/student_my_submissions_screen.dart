import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:school_management_system/src/models/user_model.dart';
import 'package:school_management_system/src/models/file_asset_model.dart';
import 'package:school_management_system/src/services/file_asset_service.dart';
import 'package:intl/intl.dart';

class StudentMySubmissionsScreen extends StatefulWidget {
  const StudentMySubmissionsScreen({super.key});

  @override
  State<StudentMySubmissionsScreen> createState() => _StudentMySubmissionsScreenState();
}

class _StudentMySubmissionsScreenState extends State<StudentMySubmissionsScreen> {
  final FileAssetService _fileAssetService = FileAssetService();
  UserModel? _currentUser;
  bool _isLoading = false;

  // For simplicity, submissions are general for the student.
  // In a full app, UI would allow selecting an Assignment context.
  String _relatedEntityType = 'student_submission';
  // String? _selectedAssignmentId; // For future when assignments exist

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_currentUser == null) {
      _currentUser = Provider.of<UserModel?>(context);
    }
  }

  Future<void> _uploadNewSubmission() async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User not available.")));
      return;
    }
    // TODO: In future, prompt student to select which Assignment this submission is for.
    // For now, it's a general upload linked to the student.

    setState(() => _isLoading = true);
    try {
      final Map<String, dynamic>? fileData = await _fileAssetService.pickFileAndConvertToBase64(
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'png', 'zip'], // Common submission types
      );

      if (fileData != null) {
        String? description = await _showDescriptionDialog(); // Optional description/title for submission

        await _fileAssetService.uploadFileAsset(
          fileName: fileData['fileName'],
          base64Data: fileData['base64Data'],
          mimeType: fileData['mimeType'],
          assetType: FileAssetType.document,
          uploadedByUid: _currentUser!.uid,
          uploadedByName: _currentUser!.displayName ?? _currentUser!.email,
          description: description,
          relatedToId: _currentUser!.uid, // Link to the student
          // relatedToId: _selectedAssignmentId, // In future, link to specific assignment
          relatedToType: _relatedEntityType,
        );
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Submission uploaded successfully!'), backgroundColor: Colors.green),
        );
        setState((){}); // Refresh stream
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading submission: ${e.toString()}'), backgroundColor: Colors.red),
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
          title: const Text('Submission Title/Description (Optional)'),
          content: TextField(
            controller: descriptionController,
            decoration: const InputDecoration(hintText: "e.g., Maths Homework 1, Physics Lab Report..."),
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
     // TODO: Add logic to check if submission can be deleted (e.g., before due date, if not graded)
     bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext ctx) {
            return AlertDialog(
                title: const Text('Confirm Delete Submission'),
                content: Text('Are you sure you want to delete "${asset.fileName}"? This action might not be reversible if the due date has passed or it has been graded.'),
                actions: <Widget>[
                    TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                    TextButton(style: TextButton.styleFrom(foregroundColor: Colors.red), onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
                ],
            );
        });
    if (confirm == true) {
        bool success = await _fileAssetService.deleteFileAsset(asset.id);
         if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'Submission deleted.' : 'Failed to delete submission.'), backgroundColor: success ? Colors.green : Colors.red));
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_currentUser == null || _currentUser!.role != UserRole.student) {
      return Scaffold(
        appBar: AppBar(title: const Text("Access Denied")),
        body: const Center(child: Text("You do not have permission to view this page.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Submissions'),
      ),
      body: Column(
        children: [
          // TODO: Add UI to select an assignment if not a general submission box
          // Padding(
          //   padding: const EdgeInsets.all(8.0),
          //   child: DropdownButtonFormField( ... items: assignmentsList ... onChanged: (val) => _selectedAssignmentId = val),
          // ),
          if (_isLoading) const LinearProgressIndicator(),
          Expanded(
            child: StreamBuilder<List<FileAsset>>(
              stream: _fileAssetService.getFileAssetsForRelatedEntity(
                relatedToId: _currentUser!.uid,
                relatedToType: _relatedEntityType,
                // Could also filter by _selectedAssignmentId if implemented
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !_isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No submissions uploaded yet.'));
                }

                List<FileAsset> submissions = snapshot.data!;
                return ListView.builder(
                  itemCount: submissions.length,
                  itemBuilder: (context, index) {
                    FileAsset submission = submissions[index];
                    IconData docIcon = Icons.article_outlined;
                    if (submission.mimeType.startsWith('image/')) docIcon = Icons.image_outlined;
                    if (submission.mimeType == 'application/pdf') docIcon = Icons.picture_as_pdf_outlined;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: Icon(docIcon, size: 30),
                        title: Text(submission.fileName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (submission.description != null && submission.description!.isNotEmpty)
                              Text(submission.description!),
                            Text('Uploaded: ${DateFormat.yMMMd().add_jm().format(submission.uploadedAt.toLocal())}'),
                            // TODO: Add submission status (e.g., "Graded", "Pending") once grades/assignments module is fuller
                          ],
                        ),
                         trailing: IconButton( // Students can delete their own submissions (if allowed by rules/policy)
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          tooltip: "Delete Submission",
                          onPressed: () => _confirmDelete(submission),
                        ),
                        onTap: () {
                          // TODO: Implement viewing/downloading logic
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('View/Download "${submission.fileName}" (Not Implemented)')),
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
        onPressed: _isLoading ? null : _uploadNewSubmission,
        label: const Text('Upload Submission'),
        icon: const Icon(Icons.upload_file),
      ),
    );
  }
}
