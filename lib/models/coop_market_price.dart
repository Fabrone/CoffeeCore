// File: lib/models/coop_market_price.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CoopMarketPrice {
  final String? id;
  final String cooperative;
  final String variety;
  final double price;
  final String updatedBy;
  final Timestamp timestamp;

  CoopMarketPrice({
    this.id,
    required this.cooperative,
    required this.variety,
    required this.price,
    required this.updatedBy,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'cooperative': cooperative,
      'variety': variety,
      'price': price,
      'updatedBy': updatedBy,
      'timestamp': timestamp,
    };
  }

  factory CoopMarketPrice.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data()!;
    return CoopMarketPrice(
      id: snapshot.id,
      cooperative: data['cooperative'] as String? ?? 'Unknown',
      variety: data['variety'] as String? ?? 'Unknown',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      updatedBy: data['updatedBy'] as String? ?? 'Unknown',
      timestamp: data['timestamp'] as Timestamp? ?? Timestamp.now(),
    );
  }
}