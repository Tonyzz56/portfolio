import 'package:cloud_firestore/cloud_firestore.dart';

enum BillingCycle { monthly, annually, custom }

class SubscriptionPackageModel {
  final String id;
  String name;
  double price;
  String currency;
  BillingCycle billingCycle;
  List<String> features;
  int? maxStudents;
  int? maxStaff;
  bool isActive;
  DateTime createdAt;
  DateTime updatedAt;

  SubscriptionPackageModel({
    required this.id,
    required this.name,
    required this.price,
    this.currency = 'KES', // Default currency
    required this.billingCycle,
    required this.features,
    this.maxStudents,
    this.maxStaff,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SubscriptionPackageModel.fromMap(Map<String, dynamic> data, String documentId) {
    return SubscriptionPackageModel(
      id: documentId,
      name: data['name'] ?? 'Unknown Package',
      price: (data['price'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? 'KES',
      billingCycle: billingCycleFromString(data['billingCycle'] as String?),
      features: List<String>.from(data['features'] ?? []),
      maxStudents: data['maxStudents'] as int?,
      maxStaff: data['maxStaff'] as int?,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'currency': currency,
      'billingCycle': billingCycle.toString().split('.').last,
      'features': features,
      'maxStudents': maxStudents,
      'maxStaff': maxStaff,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

BillingCycle billingCycleFromString(String? cycleString) {
  if (cycleString == null) return BillingCycle.custom;
  switch (cycleString.toLowerCase()) {
    case 'monthly':
      return BillingCycle.monthly;
    case 'annually':
      return BillingCycle.annually;
    default:
      return BillingCycle.custom;
  }
}

String billingCycleToString(BillingCycle cycle) {
  return cycle.toString().split('.').last;
}
