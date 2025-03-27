import 'package:cloud_firestore/cloud_firestore.dart';

class MarketPrice {
  final String? id;
  final String region;
  final String variety;
  final double price;
  final String updatedBy;
  final Timestamp timestamp;

  MarketPrice({
    this.id,
    required this.region,
    required this.variety,
    required this.price,
    required this.updatedBy,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'region': region,
      'variety': variety,
      'price': price,
      'updatedBy': updatedBy,
      'timestamp': timestamp,
    };
  }

  factory MarketPrice.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data()!;
    return MarketPrice(
      id: snapshot.id,
      region: data['region'] as String? ?? 'Unknown',
      variety: data['variety'] as String? ?? 'Unknown',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      updatedBy: data['updatedBy'] as String? ?? 'Unknown',
      timestamp: data['timestamp'] as Timestamp? ?? Timestamp.now(),
    );
  }
}