import 'package:cloud_firestore/cloud_firestore.dart';

class FarmCycleData {
  final String cycleName;
  final List<Map<String, dynamic>> labourActivities;
  final List<Map<String, dynamic>> mechanicalCosts;
  final List<Map<String, dynamic>> inputCosts;
  final List<Map<String, dynamic>> miscellaneousCosts;
  final List<Map<String, dynamic>> revenues;
  final List<Map<String, dynamic>> paymentHistory;
  final Map<String, dynamic> loanData;

  FarmCycleData({
    required this.cycleName,
    required this.labourActivities,
    required this.mechanicalCosts,
    required this.inputCosts,
    required this.miscellaneousCosts,
    required this.revenues,
    required this.paymentHistory,
    required this.loanData,
  });

  Map<String, dynamic> toMap() {
    return {
      'cycleName': cycleName,
      'labourActivities': labourActivities,
      'mechanicalCosts': mechanicalCosts,
      'inputCosts': inputCosts,
      'miscellaneousCosts': miscellaneousCosts,
      'revenues': revenues,
      'paymentHistory': paymentHistory,
      'loanData': loanData,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  factory FarmCycleData.fromMap(Map<String, dynamic> map) {
    return FarmCycleData(
      cycleName: map['cycleName'] ?? '',
      labourActivities: List<Map<String, dynamic>>.from(map['labourActivities'] ?? []),
      mechanicalCosts: List<Map<String, dynamic>>.from(map['mechanicalCosts'] ?? []),
      inputCosts: List<Map<String, dynamic>>.from(map['inputCosts'] ?? []),
      miscellaneousCosts: List<Map<String, dynamic>>.from(map['miscellaneousCosts'] ?? []),
      revenues: List<Map<String, dynamic>>.from(map['revenues'] ?? []),
      paymentHistory: List<Map<String, dynamic>>.from(map['paymentHistory'] ?? []),
      loanData: Map<String, dynamic>.from(map['loanData'] ?? {}),
    );
  }
}