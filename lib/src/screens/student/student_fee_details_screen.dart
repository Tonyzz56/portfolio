import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:school_management_system/src/models/user_model.dart';
import 'package:school_management_system/src/models/student_fee_status_model.dart';
import 'package:school_management_system/src/models/payment_transaction_model.dart';
import 'package:school_management_system/src/services/fee_service.dart';
import 'package:school_management_system/src/services/payment_service.dart';

class StudentFeeDetailsScreen extends StatefulWidget {
  final String? targetChildUidFromRoute;
  final String? childNameForParentView;

  const StudentFeeDetailsScreen({
    super.key,
    this.targetChildUidFromRoute,
    this.childNameForParentView,
  });

  @override
  State<StudentFeeDetailsScreen> createState() => _StudentFeeDetailsScreenState();
}

class _StudentFeeDetailsScreenState extends State<StudentFeeDetailsScreen> {
  final FeeService _feeService = FeeService();
  final PaymentService _paymentService = PaymentService();

  UserModel? _currentUser;
  String? _effectiveStudentUid;
  String _screenTitle = "My Fee Details";

  Map<String, double> _feeSummary = {'totalDue': 0, 'totalPaid': 0, 'balance': 0};
  List<StudentFeeStatusModel> _detailedFeeItems = [];
  List<PaymentTransactionModel> _paymentHistory = [];

  bool _isLoadingSummary = true;
  bool _isLoadingDetails = true;
  bool _isLoadingHistory = true;
  String? _error;

  final TextEditingController _mpesaPhoneNumberController = TextEditingController();
  final TextEditingController _mpesaAmountController = TextEditingController();
  bool _isProcessingMpesa = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_currentUser == null) {
      _currentUser = Provider.of<UserModel?>(context);
      _initializeTargetStudentAndFetchData();
    }
  }

  void _initializeTargetStudentAndFetchData() {
    if (_currentUser == null) {
      setStateIfMounted(() { _error = "User not authenticated."; _isLoadingSummary = _isLoadingDetails = _isLoadingHistory = false; });
      return;
    }

    if (widget.targetChildUidFromRoute != null && _currentUser!.role == UserRole.parent) {
      _effectiveStudentUid = widget.targetChildUidFromRoute;
      _screenTitle = "Fee Details: ${widget.childNameForParentView ?? 'Child'}";
      // Pre-fill phone number if parent has one and child doesn't for convenience
      _mpesaPhoneNumberController.text = _currentUser!.toMap()['phoneNumber'] ?? ''; // Assuming UserModel has phoneNumber
    } else if (_currentUser!.role == UserRole.student) {
      _effectiveStudentUid = _currentUser!.uid;
      _screenTitle = "My Fee Details";
      _mpesaPhoneNumberController.text = _currentUser!.toMap()['phoneNumber'] ?? '';
    } else {
      setStateIfMounted(() {
        _error = _currentUser!.role == UserRole.parent
            ? "Please select a child from 'My Children' to view their fees."
            : "Access Denied. This view is for students or parents viewing a child.";
        _isLoadingSummary = _isLoadingDetails = _isLoadingHistory = false;
      });
      return;
    }
    _fetchAllData();
  }

  void _fetchAllData(){
    if(_effectiveStudentUid != null){
      _fetchFeeSummary();
      _fetchDetailedFeeItems();
      _fetchPaymentHistory();
    }
  }

  Future<void> _fetchFeeSummary() async {
    if (_effectiveStudentUid == null || _currentUser?.institutionId == null) return;
    setStateIfMounted(() => _isLoadingSummary = true);
    try {
      final summary = await _feeService.getStudentFeeSummary(
        studentUid: _effectiveStudentUid!,
        institutionId: _currentUser!.institutionId!,
      );
      if (mounted) setStateIfMounted(() => _feeSummary = summary);
    } catch (e) {
      if (mounted) setStateIfMounted(() => _error = (_error ?? "") + "\nError fetching fee summary: $e");
    } finally {
      if (mounted) setStateIfMounted(() => _isLoadingSummary = false);
    }
  }

  Future<void> _fetchDetailedFeeItems() async {
    if (_effectiveStudentUid == null || _currentUser?.institutionId == null) return;
    setStateIfMounted(() => _isLoadingDetails = true);
    try {
      _feeService.getStudentFeeStatuses(
        studentUid: _effectiveStudentUid!,
        institutionId: _currentUser!.institutionId!,
      ).listen((items) {
        if (mounted) setStateIfMounted(() => _detailedFeeItems = items.where((item) => item.paymentStatus != FeePaymentStatus.paid && item.paymentStatus != FeePaymentStatus.cancelled && item.paymentStatus != FeePaymentStatus.waived).toList());
      }, onError: (e) {
         if (mounted) setStateIfMounted(() => _error = (_error ?? "") + "\nError fetching detailed fees: $e");
      });
    } catch (e) {
      if (mounted) setStateIfMounted(() => _error = (_error ?? "") + "\nFailed to initiate detailed fee fetching: $e");
    } finally {
      // Stream will continue, initial load flag is enough
      if (mounted) setStateIfMounted(() => _isLoadingDetails = false);
    }
  }

  Future<void> _fetchPaymentHistory() async {
    if (_effectiveStudentUid == null || _currentUser?.institutionId == null) return;
    setStateIfMounted(() => _isLoadingHistory = true);
    try {
      _paymentService.getPaymentHistoryForStudent(
        studentUid: _effectiveStudentUid!,
        institutionId: _currentUser!.institutionId!,
      ).listen((history) {
        if (mounted) setStateIfMounted(() => _paymentHistory = history);
      }, onError: (e){
         if (mounted) setStateIfMounted(() => _error = (_error ?? "") + "\nError fetching payment history: $e");
      });
    } catch (e) {
      if (mounted) setStateIfMounted(() => _error = (_error ?? "") + "\nFailed to initiate payment history fetching: $e");
    } finally {
      if (mounted) setStateIfMounted(() => _isLoadingHistory = false);
    }
  }

  void setStateIfMounted(VoidCallback f) {
    if (mounted) setState(f);
  }


  Future<void> _initiateMpesaPayment() async {
    if (_currentUser == null || _currentUser!.institutionId == null || _effectiveStudentUid == null) return;
    final String phone = _mpesaPhoneNumberController.text.trim();
    final double? amount = double.tryParse(_mpesaAmountController.text.trim());

    if (phone.isEmpty || !RegExp(r'^(254)\d{9}$').hasMatch(phone)) { // Basic Kenyan phone validation
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Valid Kenyan phone number required (e.g., 2547...)."), backgroundColor: Colors.red));
      return;
    }
     if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Valid amount required."), backgroundColor: Colors.red));
      return;
    }

    setStateIfMounted(() => _isProcessingMpesa = true);
    try {
      final result = await _paymentService.initiateMpesaStkPush(
        institutionId: _currentUser!.institutionId!,
        studentUid: _effectiveStudentUid!,
        amount: amount,
        phoneNumber: phone,
        accountReference: _currentUser!.customLoginId ?? _effectiveStudentUid!,
      );
      if (mounted) {
        if (result != null && result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("M-PESA STK Push initiated (CheckoutID: ${result['checkoutRequestId']}). Please complete payment on your phone."), backgroundColor: Colors.green, duration: const Duration(seconds: 7)),
          );
          // UI should ideally show a pending state for this transaction.
          // Refreshing data after a delay or via a listener for payment status updates.
           Future.delayed(Duration(seconds: 10), () => _fetchAllData()); // Optimistic refresh
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("M-PESA STK Push failed: ${result?['error'] ?? 'Unknown error'}"), backgroundColor: Colors.red, duration: const Duration(seconds: 5)),
          );
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error initiating M-PESA payment: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setStateIfMounted(() => _isProcessingMpesa = false);
    }
  }


  @override
  void dispose() {
    _mpesaPhoneNumberController.dispose();
    _mpesaAmountController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final NumberFormat currencyFormatter = NumberFormat.currency(symbol: 'KES ');

    Widget buildLoadingOrError() {
       if (_isLoadingSummary || _isLoadingDetails || _isLoadingHistory && _error == null) {
        return const Center(child: CircularProgressIndicator());
      }
      if (_error != null) {
        return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 16), textAlign: TextAlign.center)));
      }
      if (_effectiveStudentUid == null) {
         return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(_error ?? "Student context not set.", style: TextStyle(color: Colors.orange.shade700, fontSize: 16), textAlign: TextAlign.center)));
      }
      return const SizedBox.shrink(); // Should not reach here if error/loading/no target UID
    }


    return Scaffold(
      appBar: AppBar(title: Text(_screenTitle)),
      body: (_isLoadingSummary || (_effectiveStudentUid == null && _error != null)) // Initial check for error or if still loading summary
          ? buildLoadingOrError()
          : RefreshIndicator(
              onRefresh: _fetchAllData,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Fee Summary", style: Theme.of(context).textTheme.titleLarge),
                          const Divider(),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Total Due:"), Text(currencyFormatter.format(_feeSummary['totalDue']), style: const TextStyle(fontWeight: FontWeight.bold))]),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Total Paid:"), Text(currencyFormatter.format(_feeSummary['totalPaid']), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))]),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Balance:"), Text(currencyFormatter.format(_feeSummary['balance']), style: TextStyle(color: (_feeSummary['balance'] ?? 0) > 0 ? Colors.red : Colors.green, fontWeight: FontWeight.bold))]),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  if ((_feeSummary['balance'] ?? 0) > 0)
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Pay Fees via M-PESA", style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _mpesaPhoneNumberController,
                              decoration: const InputDecoration(labelText: "M-PESA Phone (e.g. 2547...)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone_android)),
                              keyboardType: TextInputType.phone,
                               validator: (val) => (val == null || !RegExp(r'^(254)\d{9}$').hasMatch(val)) ? "Enter valid Kenyan phone no." : null,
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _mpesaAmountController,
                              decoration: InputDecoration(labelText: "Amount to Pay (${_feeSummary['currency'] ?? 'KES'})", border: const OutlineInputBorder(), prefixIcon: Icon(Icons.attach_money)),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                              validator: (val) => (val == null || val.isEmpty || (double.tryParse(val) ?? 0) <=0) ? "Enter valid amount" : null,
                            ),
                            const SizedBox(height: 16),
                            _isProcessingMpesa
                              ? const Center(child: CircularProgressIndicator())
                              : ElevatedButton.icon(
                                  icon: const Icon(Icons.payment), // Could use an M-PESA specific icon if available
                                  label: const Text("Initiate M-PESA Payment"),
                                  onPressed: _initiateMpesaPayment,
                                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 45)),
                                )
                          ],
                        ),
                      )
                    ),
                  const SizedBox(height: 20),

                  Text("Outstanding Fee Items", style: Theme.of(context).textTheme.titleLarge),
                  _isLoadingDetails ? const Center(child: CircularProgressIndicator()) :
                  _detailedFeeItems.isEmpty
                      ? const Padding(padding: EdgeInsets.symmetric(vertical: 16.0), child: Text("No outstanding fee items found or all fees are paid up!"))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _detailedFeeItems.length,
                          itemBuilder: (context, index) {
                            final item = _detailedFeeItems[index];
                            return Card(
                              child: ListTile(
                                title: Text(item.feeItemName),
                                subtitle: Text("Due: ${DateFormat.yMMMd().format(item.originalDueDate)}\nBalance: ${currencyFormatter.format(item.balance)}"),
                                trailing: Text(feePaymentStatusToString(item.paymentStatus).toUpperCase(), style: TextStyle(color: item.paymentStatus == FeePaymentStatus.overdue ? Colors.red : Colors.orange)),
                              ),
                            );
                          },
                        ),
                  const SizedBox(height: 20),

                  Text("Payment History", style: Theme.of(context).textTheme.titleLarge),
                  _isLoadingHistory ? const Center(child: CircularProgressIndicator()) :
                  _paymentHistory.isEmpty
                      ? const Padding(padding: EdgeInsets.symmetric(vertical: 16.0),child: Text("No payment history found."))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _paymentHistory.length,
                          itemBuilder: (context, index) {
                            final tx = _paymentHistory[index];
                            return Card(
                              child: ListTile(
                                leading: Icon(tx.status == PaymentStatus.successful ? Icons.check_circle_outline : (tx.status == PaymentStatus.pending ? Icons.hourglass_empty_outlined : Icons.error_outline), color: tx.status == PaymentStatus.successful ? Colors.green : (tx.status == PaymentStatus.pending ? Colors.orange : Colors.red)),
                                title: Text("${paymentMethodToString(tx.paymentMethod)} - ${currencyFormatter.format(tx.amountPaid)}"),
                                subtitle: Text("Date: ${DateFormat.yMMMd().add_jm().format(tx.paymentDate)}\nRef: ${tx.transactionReference ?? tx.paymentGatewayCheckoutId ?? 'N/A'}\nStatus: ${paymentStatusToString(tx.status)}"),
                                isThreeLine: true,
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }
}
