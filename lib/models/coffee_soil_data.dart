import 'package:cloud_firestore/cloud_firestore.dart';

class CoffeeSoilData {
  final String userId;
  final String plotId;
  final String stage;
  final double? ph;
  final double? nitrogen;
  final double? phosphorus;
  final double? potassium;
  final double? magnesium;
  final double? calcium;
  final String? interventionMethod;
  final String? interventionQuantity;
  final String? interventionUnit;
  final Timestamp? interventionFollowUpDate;
  final Timestamp timestamp;
  final String structureType;
  final bool isDeleted;

  CoffeeSoilData({
    required this.userId,
    required this.plotId,
    required this.stage,
    this.ph,
    this.nitrogen,
    this.phosphorus,
    this.potassium,
    this.magnesium,
    this.calcium,
    this.interventionMethod,
    this.interventionQuantity,
    this.interventionUnit,
    this.interventionFollowUpDate,
    required this.timestamp,
    required this.structureType,
    this.isDeleted = false,
  });

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'plotId': plotId,
        'stage': stage,
        'ph': ph,
        'nitrogen': nitrogen,
        'phosphorus': phosphorus,
        'potassium': potassium,
        'magnesium': magnesium,
        'calcium': calcium,
        'interventionMethod': interventionMethod,
        'interventionQuantity': interventionQuantity,
        'interventionUnit': interventionUnit,
        'interventionFollowUpDate': interventionFollowUpDate,
        'timestamp': timestamp,
        'structureType': structureType,
        'isDeleted': isDeleted,
      };

  factory CoffeeSoilData.fromMap(Map<String, dynamic> map) => CoffeeSoilData(
        userId: map['userId'] as String,
        plotId: map['plotId'] as String,
        stage: map['stage'] as String,
        ph: map['ph'] as double?,
        nitrogen: map['nitrogen'] as double?,
        phosphorus: map['phosphorus'] as double?,
        potassium: map['potassium'] as double?,
        magnesium: map['magnesium'] as double?,
        calcium: map['calcium'] as double?,
        interventionMethod: map['interventionMethod'] as String?,
        interventionQuantity: map['interventionQuantity'] as String?,
        interventionUnit: map['interventionUnit'] as String?,
        interventionFollowUpDate: map['interventionFollowUpDate'] as Timestamp?,
        timestamp: map['timestamp'] as Timestamp,
        structureType: map['structureType'] as String,
        isDeleted: map['isDeleted'] as bool? ?? false,
      );
}