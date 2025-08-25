import 'package:coffeecore/screens/Farm Management/firestore_service.dart';
import 'package:coffeecore/screens/Farm Management/historical_data.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart'; // Import logging package

class ActivitiesScreen extends StatelessWidget {
  final List<Map<String, dynamic>> labourActivities;
  final List<Map<String, dynamic>> mechanicalCosts;
  final List<Map<String, dynamic>> inputCosts;
  final List<Map<String, dynamic>> miscellaneousCosts;
  final List<Map<String, dynamic>> revenues;
  final List<Map<String, dynamic>> paymentHistory;
  final String totalCosts;
  final String profitLoss;
  final Function(String, int) onDelete;

  ActivitiesScreen({
    super.key,
    required this.labourActivities,
    required this.mechanicalCosts,
    required this.inputCosts,
    required this.miscellaneousCosts,
    required this.revenues,
    required this.paymentHistory,
    required this.totalCosts,
    required this.profitLoss,
    required this.onDelete,
  });

  final FirestoreService _firestoreService = FirestoreService();
  final String userUid = FirebaseAuth.instance.currentUser!.uid; // Get current user's UID
  final Logger logger = Logger(); // Initialize logger

  // Function to delete activity and save historical data
  Future<void> _deleteActivity(BuildContext context, String type, int index) async {
    try {
      logger.i('Attempting to delete $type activity at index $index'); // Log the activity type and index
      Map<String, dynamic> activityData;

      switch (type) {
        case 'labour':
          activityData = labourActivities[index];
          break;
        case 'mechanical':
          activityData = mechanicalCosts[index];
          break;
        case 'input':
          activityData = inputCosts[index];
          break;
        case 'miscellaneous':
          activityData = miscellaneousCosts[index];
          break;
        case 'revenue':
          activityData = revenues[index];
          break;
        case 'payment':
          activityData = paymentHistory[index];
          break;
        default:
          logger.e('Unknown activity type: $type'); // Log unknown type
          throw Exception('Unknown activity type');
      }

      HistoricalData historicalData = HistoricalData(
        activity: activityData['activity'] ?? activityData['description'] ?? activityData['coffeeVariety'],
        cost: activityData['cost'],
        date: activityData['date'],
        userId: userUid, // Use the user's UID
      );

      logger.i('Deleting activity: ${historicalData.activity}, Cost: ${historicalData.cost}'); // Log activity details
      await _firestoreService.deleteFarmData(userUid, historicalData); // Call to delete from Firestore
      onDelete(type, index); // Call the onDelete function passed in

      logger.i('Activity deleted successfully!'); // Log success message
    } catch (error) {
      logger.e('Failed to delete activity: $error'); // Log error
      _showErrorDialog(context, 'Error Deleting Activity', 'Could not delete the activity. Please try again later.'); // Pass context
    }
  }

  // Function to show error dialog
  void _showErrorDialog(BuildContext context, String title, String message) {
    logger.w('Showing error dialog: $title - $message'); // Log error dialog details
    showDialog(
      context: context, // Use the context from the build method
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    logger.i('Building ActivitiesScreen'); // Log when the screen is built
    return Scaffold(
      appBar: AppBar(title: const Text('All Farm Activities')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: ListTile(
                title: const Text('Total Costs'),
                subtitle: Text('KSH $totalCosts'),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('Profit/Loss'),
                subtitle: Text('KSH $profitLoss'),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Labour Activities',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: labourActivities.length,
              itemBuilder: (context, index) => ListTile(
                title: Text(
                    '${labourActivities[index]['activity']} - KSH ${labourActivities[index]['cost']}'),
                subtitle: Text('Date: ${labourActivities[index]['date']}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteActivity(context, 'labour', index), // Pass context here
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Mechanical Costs',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: mechanicalCosts.length,
              itemBuilder: (context, index) => ListTile(
                title: Text(
                    '${mechanicalCosts[index]['equipment']} - KSH ${mechanicalCosts[index]['cost']}'),
                subtitle: Text('Date: ${mechanicalCosts[index]['date']}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteActivity(context, 'mechanical', index), // Pass context here
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Input Costs',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: inputCosts.length,
              itemBuilder: (context, index) => ListTile(
                title: Text(
                    '${inputCosts[index]['input']} - KSH ${inputCosts[index]['cost']}'),
                subtitle: Text('Date: ${inputCosts[index]['date']}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteActivity(context, 'input', index), // Pass context here
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Miscellaneous Costs',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: miscellaneousCosts.length,
              itemBuilder: (context, index) => ListTile(
                title: Text(
                    '${miscellaneousCosts[index]['description']} - KSH ${miscellaneousCosts[index]['cost']}'),
                subtitle: Text('Date: ${miscellaneousCosts[index]['date']}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteActivity(context, 'miscellaneous', index), // Pass context here
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Revenues',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: revenues.length,
              itemBuilder: (context, index) => ListTile(
                title: Text(
                    '${revenues[index]['coffeeVariety']} - KSH ${revenues[index]['amount']}'),
                subtitle: Text(
                    'Yield: ${revenues[index]['yield']} kg - Date: ${revenues[index]['date']}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteActivity(context, 'revenue', index), // Pass context here
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Loan Payments',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: paymentHistory.length,
              itemBuilder: (context, index) => ListTile(
                title: Text(
                    '${paymentHistory[index]['date']} - KSH ${paymentHistory[index]['amount']}'),
                subtitle: Text(
                    'Remaining: KSH ${paymentHistory[index]['remainingBalance']}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteActivity(context, 'payment', index), // Pass context here
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
