import 'package:cloud_firestore/cloud_firestore.dart';

class ProduceSubmission {
  final String userId; // User UID
  final double totalAmount; // Total amount of produce in kg
  final DateTime lastSubmissionTimestamp; // Timestamp of the last submission

  ProduceSubmission({
    required this.userId,
    required this.totalAmount,
    required this.lastSubmissionTimestamp,
  });

  // Convert a Firestore document to a ProduceSubmission object
  factory ProduceSubmission.fromFirestore(Map<String, dynamic> data, String userId) {
    return ProduceSubmission(
      userId: userId,
      totalAmount: data['totalAmount'] ?? 0.0,
      lastSubmissionTimestamp: (data['lastSubmissionTimestamp'] as Timestamp).toDate(),
    );
  }

  // Convert a ProduceSubmission object to a Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'totalAmount': totalAmount,
      'lastSubmissionTimestamp': Timestamp.fromDate(lastSubmissionTimestamp),
    };
  }
}
