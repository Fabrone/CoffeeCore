import 'package:cloud_firestore/cloud_firestore.dart';

class HistoricalData {
  final String activity;
  final double cost;
  final DateTime date;
  final String userId; // New field for user identification

  HistoricalData({
    required this.activity,
    required this.cost,
    required this.date,
    required this.userId,
  }) {
    if (cost < 0) {
      throw ArgumentError('Cost cannot be negative');
    }
    if (activity.isEmpty) {
      throw ArgumentError('Activity cannot be empty');
    }
  }

  // Convert from Firestore document to HistoricalData object
  factory HistoricalData.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return HistoricalData(
      activity: data['activity'] ?? '',
      cost: data['cost'] ?? 0.0,
      date: (data['date'] as Timestamp).toDate(),
      userId: data['userId'] ?? '',
    );
  }

  // Convert from a Map to HistoricalData object
  factory HistoricalData.fromMap(Map<String, dynamic> map) {
    return HistoricalData(
      activity: map['activity'] ?? '',
      cost: (map['cost'] ?? 0.0).toDouble(),
      date: DateTime.parse(map['date']),
      userId: map['userId'] ?? '',
    );
  }

  // Convert HistoricalData object to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'activity': activity,
      'cost': cost,
      'date': Timestamp.fromDate(date), // Convert DateTime to Timestamp
      'userId': userId,
    };
  }

  @override
  String toString() {
    return 'HistoricalData(activity: $activity, cost: $cost, date: $date, userId: $userId)';
  }
}
