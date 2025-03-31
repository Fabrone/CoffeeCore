import 'package:cloud_firestore/cloud_firestore.dart';

class CoffeeSoilData {
  final String userId;
  final String plotId;
  final String stage;
  final double? ph;
  final Map<String, double?> nutrients;
  final List<Map<String, dynamic>> interventions;
  final Timestamp timestamp;
  final String structureType;

  CoffeeSoilData({
    required this.userId,
    required this.plotId,
    required this.stage,
    this.ph,
    required this.nutrients,
    required this.interventions,
    required this.timestamp,
    required this.structureType,
  });

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'plotId': plotId,
    'stage': stage,
    'ph': ph,
    'nutrients': nutrients,
    'interventions': interventions,
    'timestamp': timestamp,
    'structureType': structureType,
  };

  factory CoffeeSoilData.fromMap(Map<String, dynamic> map) => CoffeeSoilData(
    userId: map['userId'] as String,
    plotId: map['plotId'] as String,
    stage: map['stage'] as String,
    ph: map['ph'] as double?,
    nutrients: Map<String, double?>.from(map['nutrients'] as Map),
    interventions: List<Map<String, dynamic>>.from(map['interventions'] as List),
    timestamp: map['timestamp'] as Timestamp,
    structureType: map['structureType'] as String,
  );
}