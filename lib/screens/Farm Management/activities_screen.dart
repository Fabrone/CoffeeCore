import 'package:flutter/material.dart';

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

  const ActivitiesScreen({
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Coffee Farm Activities')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
                child: ListTile(
                    title: const Text('Total Costs'), subtitle: Text('KSH $totalCosts'))),
            Card(
                child: ListTile(
                    title: const Text('Profit/Loss'), subtitle: Text('KSH $profitLoss'))),
            const SizedBox(height: 20),
            const Text('Coffee Farm Activities',
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
                  onPressed: () => onDelete('labour', index),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Coffee Farm Equipment Costs',
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
                  onPressed: () => onDelete('mechanical', index),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Coffee Farm Input Costs',
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
                  onPressed: () => onDelete('input', index),
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
                  onPressed: () => onDelete('miscellaneous', index),
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
                    '${revenues[index]['crop']} - KSH ${revenues[index]['amount']}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => onDelete('revenue', index),
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
                  onPressed: () => onDelete('payment', index),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}