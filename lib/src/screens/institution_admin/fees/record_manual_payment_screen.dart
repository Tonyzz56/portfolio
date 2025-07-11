import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:school_management_system/src/models/user_model.dart';
import 'package:school_management_system/src/models/payment_transaction_model.dart';
import 'package:school_management_system/src/services/payment_service.dart';
import 'package:school_management_system/src/services/auth_service.dart'; // Or UserService for student search

class RecordManualPaymentScreen extends StatefulWidget {
  // final String institutionId; // From currentUser
  const RecordManualPaymentScreen({super.key});

  @override
  State<RecordManualPaymentScreen> createState() => _RecordManualPaymentScreenState();
}

class _RecordManualPaymentScreenState extends State<RecordManualPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final PaymentService _paymentService = PaymentService();
  final AuthService _authService = AuthService(); // Example for searching students

  UserModel? _currentUser; // Staff recording payment
  bool _isLoading = false;

  TextEditingController _studentSearchController = TextEditingController();
  UserModel? _selectedStudent; // Student for whom payment is being made
  List<UserModel> _searchedStudents = [];
  bool _isSearchingStudent = false;

  late TextEditingController _amountPaidController;
  late TextEditingController _transactionRefController;
  late TextEditingController _notesController;
  DateTime _paymentDate = DateTime.now();
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;
  String _currency = "KES"; // Default or from institution settings

  // TODO: Add fields for selecting specific fee items this payment applies to.
  // List<String> _selectedFeeStructureIdsForPayment = [];

  @override
  void initState() {
    super.initState();
    _amountPaidController = TextEditingController();
    _transactionRefController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_currentUser == null) {
      _currentUser = Provider.of<UserModel?>(context);
    }
  }


  @override
  void dispose() {
    _studentSearchController.dispose();
    _amountPaidController.dispose();
    _transactionRefController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _searchStudent() async {
    if (_currentUser == null || _currentUser!.institutionId == null || _studentSearchController.text.trim().isEmpty) return;
    setState(() => _isSearchingStudent = true);
    try {
      // This is a simplified search. In a real app, AuthService/UserService would have a proper search method.
      // Searching by customLoginId or part of displayName.
      // For now, assume it fetches users and we filter client-side (inefficient for many users).
      _authService.getUsersForInstitution(_currentUser!.institutionId!).first.then((users) {
        if(mounted){
          setState(() {
            _searchedStudents = users.where((user) =>
              user.role == UserRole.student &&
              ((user.displayName?.toLowerCase().contains(_studentSearchController.text.trim().toLowerCase()) ?? false) ||
               (user.customLoginId?.toLowerCase().contains(_studentSearchController.text.trim().toLowerCase()) ?? false) ||
               (user.email.toLowerCase().contains(_studentSearchController.text.trim().toLowerCase())))
            ).toList();
            _isSearchingStudent = false;
          });
        }
      });
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error searching students: $e")));
        setState(() => _isSearchingStudent = false);
      }
    }
  }

  Future<void> _pickPaymentDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _paymentDate) {
      setState(() => _paymentDate = picked);
    }
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentUser == null || _currentUser!.institutionId == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Current user or institution context missing.")));
       return;
    }
    if (_selectedStudent == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a student.")));
      return;
    }
    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    try {
      PaymentTransactionModel? transaction = await _paymentService.recordManualPayment(
        institutionId: _currentUser!.institutionId!,
        studentUid: _selectedStudent!.uid,
        amountPaid: double.parse(_amountPaidController.text.trim()),
        currency: _currency, // Get from institution settings later
        paymentDate: _paymentDate,
        paymentMethod: _selectedPaymentMethod,
        recordedByUid: _currentUser!.uid,
        transactionReference: _transactionRefController.text.trim(),
        notes: _notesController.text.trim(),
        // feeStructureIds: _selectedFeeStructureIdsForPayment, // TODO
      );

      if (transaction != null) {
        // IMPORTANT: After successful payment, trigger update of StudentFeeStatusModel(s)
        // This might involve calling FeeService.updateStudentFeeStatus or a Cloud Function.
        // For now, just a success message.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment of ${transaction.currency} ${transaction.amountPaid} recorded successfully for ${ _selectedStudent!.displayName}!'), backgroundColor: Colors.green),
        );
        // Clear form or navigate away
        _formKey.currentState?.reset();
        _studentSearchController.clear();
        setState(() {
           _selectedStudent = null;
           _searchedStudents = [];
           _amountPaidController.clear();
           _transactionRefController.clear();
           _notesController.clear();
           _paymentDate = DateTime.now();
        });

      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to record payment.'), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Record Manual Payment")),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Student Selection
                  Text("1. Find Student", style: Theme.of(context).textTheme.titleLarge),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _studentSearchController,
                          decoration: const InputDecoration(labelText: "Search Student (Name/ID/Email)", border: OutlineInputBorder()),
                           onFieldSubmitted: (_) => _searchStudent(),
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.search), onPressed: _searchStudent, tooltip: "Search"),
                    ],
                  ),
                  if (_isSearchingStudent) const Padding(padding: EdgeInsets.all(8.0), child: Center(child: CircularProgressIndicator())),
                  if (_searchedStudents.isNotEmpty && !_isSearchingStudent)
                    SizedBox(
                      height: 150, // Limit height of search results
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchedStudents.length,
                        itemBuilder: (context, index) {
                          UserModel student = _searchedStudents[index];
                          return ListTile(
                            title: Text(student.displayName ?? student.customLoginId ?? student.email),
                            subtitle: Text("ID: ${student.customLoginId ?? student.uid.substring(0,6)}..."),
                            onTap: () {
                              setState(() {
                                _selectedStudent = student;
                                _studentSearchController.text = student.displayName ?? student.customLoginId ?? student.email; // Fill search bar
                                _searchedStudents = []; // Clear results
                              });
                            },
                          );
                        },
                      ),
                    ),
                  if (_selectedStudent != null) Padding(
                    padding: const EdgeInsets.symmetric(vertical:8.0),
                    child: Chip(label: Text("Selected: ${_selectedStudent!.displayName ?? _selectedStudent!.customLoginId}"),
                      onDeleted: () => setState(() { _selectedStudent = null; _studentSearchController.clear(); }),
                    ),
                  ),
                  const Divider(height: 30),

                  // Payment Details
                  Text("2. Payment Details", style: Theme.of(context).textTheme.titleLarge),
                  TextFormField(
                    controller: _amountPaidController,
                    decoration: InputDecoration(labelText: 'Amount Paid ($_currency)', border: const OutlineInputBorder()),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                    validator: (v) => (v == null || v.isEmpty || (double.tryParse(v) ?? 0) <= 0) ? "Valid amount required" : null,
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => _pickPaymentDate(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Payment Date', border: OutlineInputBorder()),
                      child: Text(DateFormat.yMMMd().format(_paymentDate)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<PaymentMethod>(
                    value: _selectedPaymentMethod,
                    decoration: const InputDecoration(labelText: 'Payment Method', border: OutlineInputBorder()),
                    items: PaymentMethod.values.map((method) => DropdownMenuItem(
                      value: method,
                      child: Text(paymentMethodToString(method)),
                    )).toList(),
                    onChanged: (val) => setState(() => _selectedPaymentMethod = val ?? PaymentMethod.cash),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _transactionRefController,
                    decoration: const InputDecoration(labelText: 'Transaction Reference (Optional)', border: OutlineInputBorder(), hintText: "e.g., Slip No, M-PESA Code"),
                  ),
                  const SizedBox(height: 16),
                   TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(labelText: 'Notes (Optional)', border: OutlineInputBorder()),
                    maxLines: 2,
                  ),
                  // TODO: UI to select specific fee items this payment applies to (from StudentFeeStatus)
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save_alt),
                    label: const Text("Record Payment"),
                    onPressed: _isLoading ? null : _submitPayment,
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                  )
                ],
              ),
            ),
          ),
    );
  }
}
