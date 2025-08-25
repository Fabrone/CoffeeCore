import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coffeecore/screens/Farm Management/historical_data.dart';
import 'package:logger/logger.dart'; 

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger logger = Logger(); // Initialize logger

  // Save farm data to Firestore
  Future<void> saveFarmData(String userUid, HistoricalData data) async {
    try {
      logger.i('Saving farm data for user: $userUid, Activity: ${data.activity}, Cost: ${data.cost}, Date: ${data.date}'); // Log details
      await _firestore.collection('users').doc(userUid).collection('activities').add({
        'activity': data.activity,
        'cost': data.cost,
        'date': data.date,
      });
      logger.i('Farm data saved successfully!'); // Log success message
    } catch (e) {
      logger.e('Failed to save activity: $e'); // Log error
      throw Exception('Failed to save activity: $e');
    }
  }

  // Delete farm data from Firestore
  Future<void> deleteFarmData(String userUid, HistoricalData data) async {
    try {
      logger.i('Attempting to delete activity for user: $userUid, Activity: ${data.activity}, Cost: ${data.cost}, Date: ${data.date}'); // Log details
      // Find the document to delete
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .doc(userUid)
          .collection('activities')
          .where('activity', isEqualTo: data.activity)
          .where('cost', isEqualTo: data.cost)
          .where('date', isEqualTo: data.date)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        for (var doc in querySnapshot.docs) {
          await doc.reference.delete();
          logger.i('Deleted activity document with ID: ${doc.id}'); // Log each deletion
        }
        logger.i('Activity deleted successfully!'); // Log success message
      } else {
        logger.w('No matching activity found to delete'); // Log warning
        throw Exception('No matching activity found to delete');
      }
    } catch (e) {
      logger.e('Failed to delete activity: $e'); // Log error
      throw Exception('Failed to delete activity: $e');
    }
  }

  // Optionally, you can add methods to retrieve data
  Future<List<HistoricalData>> getFarmActivities(String userUid) async {
    try {
      logger.i('Retrieving farm activities for user: $userUid'); // Log retrieval attempt
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .doc(userUid)
          .collection('activities')
          .get();

      List<HistoricalData> activities = querySnapshot.docs.map((doc) {
        return HistoricalData(
          activity: doc['activity'],
          cost: doc['cost'],
          date: doc['date'],
          userId: '', // Assuming you want to keep this empty
        );
      }).toList();
      logger.i('Retrieved ${activities.length} activities successfully!'); // Log successful retrieval
      return activities;
    } catch (e) {
      logger.e('Failed to retrieve activities: $e'); // Log error
      throw Exception('Failed to retrieve activities: $e');
    }
  }
}
