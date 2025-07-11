import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:school_management_system/src/models/user_model.dart';
import 'package:school_management_system/src/models/fee_structure_model.dart';
import 'package:school_management_system/src/services/fee_service.dart';
import 'package:school_management_system/src/models/academic_year_model.dart'; // For context
import 'package:school_management_system/src/services/academic_service.dart'; // To fetch AYs for filter
import 'package:intl/intl.dart';
import 'fee_structure_form_screen.dart';

class ManageFeeStructuresScreen extends StatefulWidget {
  // final String institutionId; // Will get from currentUser
  const ManageFeeStructuresScreen({super.key});

  @override
  State<ManageFeeStructuresScreen> createState() => _ManageFeeStructuresScreenState();
}

class _ManageFeeStructuresScreenState extends State<ManageFeeStructuresScreen> {
  final FeeService _feeService = FeeService();
  final AcademicService _academicService = AcademicService();
  UserModel? _currentUser;

  List<AcademicYearModel> _academicYears = [];
  AcademicYearModel? _selectedAcademicYear; // Filter by this
  // TODO: Add filters for Term, Class if needed

  bool _isLoadingYears = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_currentUser == null) {
      _currentUser = Provider.of<UserModel?>(context);
      if (_currentUser != null && _currentUser!.institutionId != null) {
        _fetchAcademicYears();
      }
    }
  }

  Future<void> _fetchAcademicYears() async {
    if (_currentUser == null || _currentUser!.institutionId == null) return;
    setState(() => _isLoadingYears = true);
    try {
      _academicService.getAcademicYears(_currentUser!.institutionId!).listen((years) {
        if (mounted) {
          setState(() {
            _academicYears = years;
            // Auto-select the active year or the first one if none is active
            _selectedAcademicYear = years.firstWhere((y) => y.isActive, orElse: () => years.isNotEmpty ? years.first : null);
            _isLoadingYears = false;
          });
        }
      });
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error fetching academic years: $e")));
        setState(() => _isLoadingYears = false);
      }
    }
  }


  void _navigateToForm({FeeStructureModel? feeStructure}) {
    if (_currentUser == null || _currentUser!.institutionId == null || _selectedAcademicYear == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select an academic year first or ensure user data is loaded.")));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FeeStructureFormScreen(
          institutionId: _currentUser!.institutionId!,
          academicYearId: _selectedAcademicYear!.id, // Pass selected AY context
          // termId, classId can be passed if form supports them for more specific structures
          feeStructure: feeStructure,
        ),
      ),
    ).then((_) => setState(() {})); // Refresh list
  }

  Future<void> _toggleActiveStatus(FeeStructureModel feeStructure) async {
    Map<String, dynamic> updateData = {'isActive': !feeStructure.isActive};
    bool success = await _feeService.updateFeeStructure(feeStructure.id, updateData);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fee Structure "${feeStructure.name}" status updated.'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      if (success) setState(() {});
    }
  }

  Future<void> _confirmDelete(FeeStructureModel feeStructure) async {
     bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to permanently delete fee structure "${feeStructure.name}"? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete Permanently'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      bool success = await _feeService.deleteFeeStructure(feeStructure.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fee Structure "${feeStructure.name}" ${success ? "deleted" : "deletion failed"}.'), backgroundColor: success ? Colors.green : Colors.red),
        );
        if (success) setState(() {});
      }
    }
  }


  @override
  Widget build(BuildContext context) {
     if (_currentUser == null || _currentUser!.institutionId == null) {
      return Scaffold(appBar: AppBar(title: const Text("Manage Fee Structures")), body: const Center(child: Text("User data not available.")));
    }


    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Fee Structures'),
        actions: [
          if (_selectedAcademicYear != null) // Only allow add if AY is selected
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Add New Fee Structure',
              onPressed: () => _navigateToForm(),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _isLoadingYears
              ? const Center(child: CircularProgressIndicator())
              : (_academicYears.isEmpty
                  ? const Text("No academic years found. Please create one first.")
                  : DropdownButtonFormField<AcademicYearModel?>(
                      value: _selectedAcademicYear,
                      hint: const Text("Select Academic Year to View Fees"),
                      items: _academicYears.map((ay) => DropdownMenuItem(value: ay, child: Text(ay.name))).toList(),
                      onChanged: (ay) => setState(() => _selectedAcademicYear = ay),
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    )
                ),
          ),
          if (_selectedAcademicYear == null && !_isLoadingYears)
            const Expanded(child: Center(child: Text("Please select an Academic Year."))),
          if (_selectedAcademicYear != null)
            Expanded(
              child: StreamBuilder<List<FeeStructureModel>>(
                stream: _feeService.getFeeStructures(
                  institutionId: _currentUser!.institutionId!,
                  academicYearId: _selectedAcademicYear!.id,
                  // TODO: Add termId, classId filters here if UI supports them
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No fee structures found for the selected academic year. Add one!'));
                  }

                  List<FeeStructureModel> feeStructures = snapshot.data!;

                  return ListView.builder(
                    itemCount: feeStructures.length,
                    itemBuilder: (context, index) {
                      FeeStructureModel fs = feeStructures[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        child: ListTile(
                          leading: Icon(fs.isActive ? Icons.check_circle : Icons.cancel_outlined, color: fs.isActive ? Colors.green : Colors.grey),
                          title: Text(fs.name, style: TextStyle(fontWeight: fs.isActive ? FontWeight.bold : FontWeight.normal)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("${fs.feeItemName}: ${fs.currency} ${fs.amount.toStringAsFixed(2)}"),
                              Text("Due: ${DateFormat.yMMMd().format(fs.dueDate)}"),
                              if (fs.classId != null) Text("For Class ID: ${fs.classId!.substring(0,5)}..."), // TODO: Show Class Name
                            ],
                          ),
                          isThreeLine: fs.classId != null,
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') _navigateToForm(feeStructure: fs);
                              else if (value == 'toggle_active') _toggleActiveStatus(fs);
                              else if (value == 'delete') _confirmDelete(fs);
                            },
                            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                              const PopupMenuItem<String>(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('Edit'))),
                              PopupMenuItem<String>(value: 'toggle_active', child: ListTile(leading: Icon(fs.isActive ? Icons.visibility_off : Icons.visibility), title: Text(fs.isActive ? 'Deactivate' : 'Activate'))),
                              const PopupMenuDivider(),
                              const PopupMenuItem<String>(value: 'delete', child: ListTile(leading: Icon(Icons.delete_forever, color: Colors.red), title: Text('Delete', style: TextStyle(color: Colors.red)))),
                            ],
                          ),
                          onTap: () => _navigateToForm(feeStructure: fs),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
