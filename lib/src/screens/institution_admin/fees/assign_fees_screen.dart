import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:school_management_system/src/models/user_model.dart';
import 'package:school_management_system/src/models/academic_year_model.dart';
import 'package:school_management_system/src/models/term_model.dart';
import 'package:school_management_system/src/models/class_model.dart';
import 'package:school_management_system/src/models/fee_structure_model.dart';
import 'package:school_management_system/src/services/academic_service.dart';
import 'package:school_management_system/src/services/fee_service.dart';
import 'package:intl/intl.dart';


class AssignFeesScreen extends StatefulWidget {
  // final String institutionId; // Will get from currentUser
  const AssignFeesScreen({super.key});

  @override
  State<AssignFeesScreen> createState() => _AssignFeesScreenState();
}

enum AssignToType { classSelection, individualStudent } // Changed 'class' to 'classSelection' to avoid conflict

class _AssignFeesScreenState extends State<AssignFeesScreen> {
  final AcademicService _academicService = AcademicService();
  final FeeService _feeService = FeeService();
  UserModel? _currentUser;

  AssignToType _assignToType = AssignToType.classSelection;

  List<AcademicYearModel> _academicYears = [];
  AcademicYearModel? _selectedAcademicYear;

  List<TermModel> _terms = [];
  TermModel? _selectedTerm;

  List<ClassModel> _classes = [];
  ClassModel? _selectedClass;

  List<FeeStructureModel> _availableFeeStructures = [];
  Set<String> _selectedFeeStructureIds = {};

  bool _isLoadingContext = true;
  bool _isLoadingFeeStructures = false;
  bool _isAssigning = false;

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
    setStateIfMounted(() => _isLoadingContext = true);
    try {
      _academicService.getAcademicYears(_currentUser!.institutionId!).listen((years) {
        if (mounted) {
          setStateIfMounted(() {
            _academicYears = years;
            _selectedAcademicYear = years.firstWhere((y) => y.isActive, orElse: () => years.isNotEmpty ? years.first : null);
            if (_selectedAcademicYear != null) _fetchTerms(); else _isLoadingContext = false;
          });
        }
      });
    } catch (e) {
      handleError("Error fetching academic years: $e");
    }
  }

  Future<void> _fetchTerms() async {
    if (_currentUser == null || _selectedAcademicYear == null) return;
    setStateIfMounted(() => _isLoadingContext = true);
    try {
       _academicService.getTerms(_currentUser!.institutionId!, _selectedAcademicYear!.id).listen((terms) {
          if (mounted) {
            setStateIfMounted(() {
              _terms = terms;
              _selectedTerm = terms.firstWhere((t) => t.isCurrentTerm, orElse: () => terms.isNotEmpty ? terms.first : null);
              _fetchClasses();
            });
          }
       });
    } catch (e) {
      handleError("Error fetching terms: $e");
    }
  }

  Future<void> _fetchClasses() async {
    if (_currentUser == null || _selectedAcademicYear == null) return;
    setStateIfMounted(() => _isLoadingContext = true);
    try {
      _academicService.getClasses(
        _currentUser!.institutionId!,
        academicYearId: _selectedAcademicYear!.id,
        termId: _selectedTerm?.id,
      ).listen((classes) {
        if (mounted) {
          setStateIfMounted(() {
            _classes = classes;
            _selectedClass = classes.isNotEmpty ? classes.first : null;
            _isLoadingContext = false;
            if (_selectedClass != null || _assignToType == AssignToType.individualStudent) {
              _fetchFeeStructures();
            }
          });
        }
      });
    } catch (e) {
       handleError("Error fetching classes: $e");
    }
  }

  Future<void> _fetchFeeStructures() async {
    if (_currentUser == null || _selectedAcademicYear == null) return;
    setStateIfMounted(() => _isLoadingFeeStructures = true);
    try {
      _feeService.getFeeStructures(
        institutionId: _currentUser!.institutionId!,
        academicYearId: _selectedAcademicYear!.id,
        termId: _selectedTerm?.id,
        classId: _assignToType == AssignToType.classSelection ? _selectedClass?.id : null,
        isActive: true,
      ).listen((structures) {
        if (mounted) {
          setStateIfMounted(() {
            _availableFeeStructures = structures;
            _isLoadingFeeStructures = false;
          });
        }
      });
    } catch (e) {
      handleError("Error fetching fee structures: $e");
    }
  }

  void handleError(String message) {
    if(mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
      setStateIfMounted(() {
        _isLoadingContext = false;
        _isLoadingFeeStructures = false;
        _isAssigning = false;
      });
    }
  }

  void setStateIfMounted(VoidCallback f) {
    if (mounted) setState(f);
  }


  Future<void> _assignFees() async {
    if (_currentUser == null || _selectedAcademicYear == null || _selectedFeeStructureIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select academic year and at least one fee structure."), backgroundColor: Colors.red));
      return;
    }
    if (_assignToType == AssignToType.classSelection && _selectedClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a class to assign fees to."), backgroundColor: Colors.red));
      return;
    }

    setStateIfMounted(() => _isAssigning = true);
    try {
      List<String> processedInfo = []; // To store info about assignments
      if (_assignToType == AssignToType.classSelection) {
        processedInfo = await _feeService.assignFeesToClass(
          classIdToAssign: _selectedClass!.id,
          feeStructureIdsToAssign: _selectedFeeStructureIds.toList(),
          institutionId: _currentUser!.institutionId!,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Individual student assignment not fully implemented yet."), backgroundColor: Colors.orange));
      }

      if (mounted) {
        String message = processedInfo.isNotEmpty
            ? 'Fees assigned to ${processedInfo.length} students in class.'
            : (_assignToType == AssignToType.classSelection ? 'No students found in class or fees already assigned.' : 'Assignment process completed.');
        if (_assignToType == AssignToType.individualStudent && processedInfo.isEmpty) message = 'Individual assignment not implemented.';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: processedInfo.isNotEmpty ? Colors.green : Colors.orange),
        );
        if (processedInfo.isNotEmpty) {
          setStateIfMounted(() => _selectedFeeStructureIds.clear());
        }
      }
    } catch (e) {
      handleError("Error assigning fees: ${e.toString()}");
    } finally {
      setStateIfMounted(() => _isAssigning = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_currentUser == null || _currentUser!.institutionId == null) {
      return Scaffold(appBar: AppBar(title: const Text("Assign Fees")), body: const Center(child: Text("User data not available.")));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Assign Fees to Students/Classes")),
      body: _isLoadingContext
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("1. Select Academic Context", style: Theme.of(context).textTheme.titleLarge),
                  DropdownButtonFormField<AcademicYearModel?>(
                    value: _selectedAcademicYear,
                    hint: const Text("Select Academic Year"),
                    items: _academicYears.map((ay) => DropdownMenuItem(value: ay, child: Text(ay.name))).toList(),
                    onChanged: (ay) {
                      setStateIfMounted(() {
                        _selectedAcademicYear = ay;
                        _selectedTerm = null; _terms = [];
                        _selectedClass = null; _classes = [];
                        _availableFeeStructures = []; _selectedFeeStructureIds.clear();
                        if (ay != null) _fetchTerms(); else _fetchClasses(); // Fetch classes if AY is chosen but no terms (year-long classes)
                      });
                    },
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                     validator: (value) => value == null ? 'Academic Year is required' : null,
                  ),
                  if (_selectedAcademicYear != null && _terms.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    DropdownButtonFormField<TermModel?>(
                      value: _selectedTerm,
                      hint: const Text("Select Term (Optional)"),
                      items: [
                        const DropdownMenuItem<TermModel?>(value: null, child: Text("Whole Academic Year / N/A")),
                        ..._terms.map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                      ],
                      onChanged: (term) {
                        setStateIfMounted(() {
                          _selectedTerm = term;
                           _selectedClass = null; _classes = [];
                           _availableFeeStructures = []; _selectedFeeStructureIds.clear();
                          _fetchClasses();
                        });
                      },
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    ),
                  ],
                  const SizedBox(height: 20),

                  Text("2. Assign Fees To:", style: Theme.of(context).textTheme.titleLarge),
                  RadioListTile<AssignToType>(
                    title: const Text('Entire Class'),
                    value: AssignToType.classSelection,
                    groupValue: _assignToType,
                    onChanged: (AssignToType? value) {
                      if (value != null) setStateIfMounted(() { _assignToType = value; _fetchFeeStructures(); });
                    },
                  ),
                  RadioListTile<AssignToType>(
                    title: const Text('Individual Student(s) (UI Placeholder)'),
                    value: AssignToType.individualStudent,
                    groupValue: _assignToType,
                     onChanged: (AssignToType? value) {
                      if (value != null) {
                         setStateIfMounted(() { _assignToType = value; _fetchFeeStructures(); });
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Individual student selection UI is a future enhancement.")));
                      }
                    },
                  ),
                  if (_assignToType == AssignToType.classSelection) ...[
                    const SizedBox(height: 10),
                    DropdownButtonFormField<ClassModel?>(
                      value: _selectedClass,
                      hint: const Text("Select Class"),
                      items: _classes.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                      onChanged: (cls) {
                        setStateIfMounted(() {
                            _selectedClass = cls;
                            _availableFeeStructures = []; _selectedFeeStructureIds.clear();
                            if(cls != null) _fetchFeeStructures();
                        });
                      },
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      validator: (value) => _assignToType == AssignToType.classSelection && value == null ? 'Class is required' : null,
                    ),
                  ],
                  const SizedBox(height: 20),

                  Text("3. Select Fee Structures to Assign", style: Theme.of(context).textTheme.titleLarge),
                  _isLoadingFeeStructures
                    ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
                    : _availableFeeStructures.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Text(_selectedAcademicYear == null ? "Select academic context first." : "No active fee structures found for the selected context. Define them in 'Manage Fee Structures'."),
                          )
                        : Column(
                            children: _availableFeeStructures.map((fs) {
                              return CheckboxListTile(
                                title: Text("${fs.name} (${fs.feeItemName})"),
                                subtitle: Text("${fs.currency} ${fs.amount.toStringAsFixed(2)} - Due: ${DateFormat.yMd().format(fs.dueDate)}"),
                                value: _selectedFeeStructureIds.contains(fs.id),
                                onChanged: (bool? selected) {
                                  setStateIfMounted(() {
                                    if (selected == true) {
                                      _selectedFeeStructureIds.add(fs.id);
                                    } else {
                                      _selectedFeeStructureIds.remove(fs.id);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: _isAssigning ? const SizedBox(width:20, height:20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.assignment_turned_in_outlined),
                    label: Text(_isAssigning ? "Assigning..." : "Assign Selected Fees"),
                    onPressed: (_isAssigning || _selectedFeeStructureIds.isEmpty || (_assignToType == AssignToType.classSelection && _selectedClass == null) ) ? null : _assignFees,
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                  )
                ],
              ),
            ),
    );
  }
}
