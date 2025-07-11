import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_management_system/src/models/payment_transaction_model.dart';
// For Daraja API integration (conceptual - actual calls via Firebase Functions)
// import 'package:http/http.dart' as http;
// import 'dart:convert';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _transactionsCollection = 'payment_transactions';

  // Record a manual payment (e.g., cash, bank transfer recorded by accounts staff)
  Future<PaymentTransactionModel?> recordManualPayment({
    required String institutionId,
    required String studentUid,
    required double amountPaid,
    required String currency,
    required DateTime paymentDate,
    required PaymentMethod paymentMethod,
    required String recordedByUid, // Staff who recorded it
    List<String>? feeStructureIds, // Optional: if payment is for specific fee items
    String? invoiceId,             // Optional: if paying against an invoice
    String? transactionReference,  // e.g., slip number
    String? notes,
  }) async {
    if (paymentMethod == PaymentMethod.mpesa) {
      // Mpesa payments should ideally go through the Daraja flow, not manually recorded this way
      // unless it's reconciling an already completed Mpesa payment not auto-captured.
      print("Warning: Recording Mpesa payment manually. Ensure this is for reconciliation.");
    }
    try {
      DocumentReference docRef = _firestore.collection(_transactionsCollection).doc();
      PaymentTransactionModel transaction = PaymentTransactionModel(
        id: docRef.id,
        institutionId: institutionId,
        studentUid: studentUid,
        feeStructureIds: feeStructureIds,
        invoiceId: invoiceId,
        amountPaid: amountPaid,
        currency: currency,
        paymentDate: paymentDate,
        paymentMethod: paymentMethod,
        status: PaymentStatus.successful, // Manual payments are typically successful upon recording
        transactionReference: transactionReference,
        recordedByUid: recordedByUid,
        notes: notes,
        createdAt: DateTime.now(), // Will be server timestamped
        updatedAt: DateTime.now(), // Will be server timestamped
      );
      await docRef.set(transaction.toMap());
      // TODO: After successful payment, update student's balance.
      // This could be a Cloud Function trigger on create of payment_transactions.
      return transaction;
    } catch (e) {
      print("Error recording manual payment: $e");
      return null;
    }
  }

  // Initiate Mpesa STK Push (Conceptual - Actual Call via Firebase Function)
  // This client-side method would call a Firebase Function which then calls Daraja API.
  Future<Map<String, dynamic>?> initiateMpesaStkPush({
    required String institutionId, // For context, might influence business shortcode used
    required String studentUid,    // To link payment back
    required double amount,
    required String phoneNumber, // M-Pesa registered phone number in format 254xxxxxxxxx
    required String accountReference, // e.g., Student Admission Number or Invoice ID
    String transactionDesc = "School Fee Payment",
  }) async {
    // In a real app, this would call a Firebase Callable Function:
    // final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('initiateMpesaPayment');
    // final response = await callable.call(<String, dynamic>{
    //   'amount': amount,
    //   'phoneNumber': phoneNumber,
    //   'accountReference': accountReference,
    //   'transactionDesc': transactionDesc,
    //   'studentUid': studentUid,
    //   'institutionId': institutionId,
    // });
    // return response.data as Map<String, dynamic>?; // e.g., {'success': true, 'checkoutRequestId': 'ws_...'}

    print("CONCEPTUAL: Initiating Mpesa STK Push via Firebase Function...");
    print("Amount: $amount, Phone: $phoneNumber, AccountRef: $accountReference, Student: $studentUid");
    // Simulate a successful initiation response for UI testing
    await Future.delayed(const Duration(seconds: 2)); // Simulate network delay
    String mockCheckoutRequestId = "ws_CO_DUMMY_${DateTime.now().millisecondsSinceEpoch}";

    // Create a PENDING transaction locally immediately after STK push is initiated
    // The status will be updated by a Firebase Function listening to Daraja callback.
    try {
      DocumentReference docRef = _firestore.collection(_transactionsCollection).doc();
      PaymentTransactionModel pendingTransaction = PaymentTransactionModel(
        id: docRef.id,
        institutionId: institutionId,
        studentUid: studentUid,
        amountPaid: amount, // The amount for which STK was pushed
        currency: "KES", // Assuming KES for Mpesa
        paymentDate: DateTime.now(), // Date of initiation
        paymentMethod: PaymentMethod.mpesa,
        status: PaymentStatus.pending, // Initially pending
        paymentGatewayCheckoutId: mockCheckoutRequestId, // Store Daraja's CheckoutRequestID
        recordedByUid: "system_stk_push", // Indicates system initiated
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await docRef.set(pendingTransaction.toMap());
      print("Pending Mpesa transaction ${docRef.id} recorded for CheckoutID: $mockCheckoutRequestId");
      return {'success': true, 'checkoutRequestId': mockCheckoutRequestId, 'transactionId': docRef.id};
    } catch (e) {
      print("Error creating pending Mpesa transaction: $e");
      return {'success': false, 'error': 'Failed to record pending transaction.'};
    }
  }

  // Handle Daraja Callback (Conceptual - This is a Firebase Function Task)
  // A Firebase HTTP Function would receive the callback from Daraja.
  // It would then find the pending transaction using CheckoutRequestID and update its status,
  // add MpesaReceiptNumber, and then trigger student balance update.
  //
  // Future<void> handleDarajaCallback(Map<String, dynamic> callbackData) async {
  //   String checkoutRequestId = callbackData['Body']['stkCallback']['CheckoutRequestID'];
  //   int resultCode = callbackData['Body']['stkCallback']['ResultCode'];
  //
  //   QuerySnapshot pendingTxQuery = await _firestore.collection(_transactionsCollection)
  //       .where('paymentGatewayCheckoutId', isEqualTo: checkoutRequestId)
  //       .where('status', isEqualTo: paymentStatusToString(PaymentStatus.pending))
  //       .limit(1).get();
  //
  //   if (pendingTxQuery.docs.isNotEmpty) {
  //     DocumentReference txDocRef = pendingTxQuery.docs.first.reference;
  //     if (resultCode == 0) { // Success
  //       String mpesaReceiptNumber = "";
  //       // Extract MpesaReceiptNumber and other details from callbackData.Item list
  //       // ...
  //       await txDocRef.update({
  //         'status': paymentStatusToString(PaymentStatus.successful),
  //         'transactionReference': mpesaReceiptNumber,
  //         'updatedAt': FieldValue.serverTimestamp(),
  //         'notes': 'Mpesa payment confirmed via callback.'
  //       });
  //       // TODO: Trigger student balance update
  //     } else { // Failed or Cancelled
  //       await txDocRef.update({
  //         'status': paymentStatusToString(PaymentStatus.failed),
  //         'updatedAt': FieldValue.serverTimestamp(),
  //         'notes': 'Mpesa payment failed/cancelled. ResultCode: $resultCode. Reason: ${callbackData['Body']['stkCallback']['ResultDesc']}'
  //       });
  //     }
  //   } else {
  //     print("Error: No matching pending Mpesa transaction found for CheckoutRequestID: $checkoutRequestId");
  //   }
  // }

  // Get payment history for a student
  Stream<List<PaymentTransactionModel>> getPaymentHistoryForStudent({
    required String studentUid,
    required String institutionId,
    int limit = 50,
  }) {
    return _firestore
        .collection(_transactionsCollection)
        .where('institutionId', isEqualTo: institutionId)
        .where('studentUid', isEqualTo: studentUid)
        .orderBy('paymentDate', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentTransactionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Get all payment transactions for an institution (Admin view)
   Stream<List<PaymentTransactionModel>> getAllTransactionsForInstitution({
    required String institutionId,
    int limit = 100, // Add pagination for real app
    DateTime? startDate,
    DateTime? endDate,
    PaymentStatus? status,
  }) {
    Query query = _firestore.collection(_transactionsCollection)
        .where('institutionId', isEqualTo: institutionId);

    if (startDate != null) query = query.where('paymentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    if (endDate != null) query = query.where('paymentDate', isLessThanOrEqualTo: Timestamp.fromDate(DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59)));
    if (status != null) query = query.where('status', isEqualTo: paymentStatusToString(status));

    return query.orderBy('paymentDate', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentTransactionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }
}
