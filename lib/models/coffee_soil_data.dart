import 'package:cloud_firestore/cloud_firestore.dart';

class CoffeeSoilData {
  final String userId;
  final String plotId;
  final String stage;
  final String? soilType;
  final double? ph;
  final double? nitrogen;
  final double? phosphorus;
  final double? potassium;
  final double? magnesium;
  final double? calcium;
  final double? zinc;
  final double? boron;
  final int plantDensity;
  final String? interventionMethod;
  final String? interventionQuantity;
  final String? interventionUnit;
  final Timestamp? interventionFollowUpDate;
  final bool notificationTriggered;
  final Map<String, dynamic>? recommendations;
  final bool saveWithRecommendations;
  final Timestamp timestamp;
  final bool isDeleted;

  CoffeeSoilData({
    required this.userId,
    required this.plotId,
    required this.stage,
    this.soilType,
    this.ph,
    this.nitrogen,
    this.phosphorus,
    this.potassium,
    this.magnesium,
    this.calcium,
    this.zinc,
    this.boron,
    this.plantDensity = 1500,
    this.interventionMethod,
    this.interventionQuantity,
    this.interventionUnit,
    this.interventionFollowUpDate,
    this.notificationTriggered = false,
    this.recommendations,
    this.saveWithRecommendations = false,
    required this.timestamp,
    this.isDeleted = false,
  });

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'plotId': plotId,
        'stage': stage,
        'soilType': soilType,
        'ph': ph,
        'nitrogen': nitrogen,
        'phosphorus': phosphorus,
        'potassium': potassium,
        'magnesium': magnesium,
        'calcium': calcium,
        'zinc': zinc,
        'boron': boron,
        'plantDensity': plantDensity,
        'interventionMethod': interventionMethod,
        'interventionQuantity': interventionQuantity,
        'interventionUnit': interventionUnit,
        'interventionFollowUpDate': interventionFollowUpDate,
        'notificationTriggered': notificationTriggered,
        'recommendations': recommendations,
        'saveWithRecommendations': saveWithRecommendations,
        'timestamp': timestamp,
        'isDeleted': isDeleted,
      };

  factory CoffeeSoilData.fromMap(Map<String, dynamic> map) => CoffeeSoilData(
        userId: map['userId'] as String,
        plotId: map['plotId'] as String,
        stage: map['stage'] as String,
        soilType: map['soilType'] as String?,
        ph: map['ph'] is int ? (map['ph'] as int).toDouble() : map['ph'] as double?,
        nitrogen: map['nitrogen'] is int ? (map['nitrogen'] as int).toDouble() : map['nitrogen'] as double?,
        phosphorus: map['phosphorus'] is int ? (map['phosphorus'] as int).toDouble() : map['phosphorus'] as double?,
        potassium: map['potassium'] is int ? (map['potassium'] as int).toDouble() : map['potassium'] as double?,
        magnesium: map['magnesium'] is int ? (map['magnesium'] as int).toDouble() : map['magnesium'] as double?,
        calcium: map['calcium'] is int ? (map['calcium'] as int).toDouble() : map['calcium'] as double?,
        zinc: map['zinc'] is int ? (map['zinc'] as int).toDouble() : map['zinc'] as double?,
        boron: map['boron'] is int ? (map['boron'] as int).toDouble() : map['boron'] as double?,
        plantDensity: map['plantDensity'] as int? ?? 1500,
        interventionMethod: map['interventionMethod'] as String?,
        interventionQuantity: map['interventionQuantity'] as String?,
        interventionUnit: map['interventionUnit'] as String?,
        interventionFollowUpDate: map['interventionFollowUpDate'] as Timestamp?,
        notificationTriggered: map['notificationTriggered'] as bool? ?? false,
        recommendations: map['recommendations'] as Map<String, dynamic>?,
        saveWithRecommendations: map['saveWithRecommendations'] as bool? ?? false,
        timestamp: map['timestamp'] as Timestamp,
        isDeleted: map['isDeleted'] as bool? ?? false,
      );
}