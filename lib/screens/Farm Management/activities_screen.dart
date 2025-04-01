import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
  final String cycleName;

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
    required this.cycleName,
  });

  static const Color customBrown = Color(0xFF4E2D00);

  Future<Map<String, dynamic>> _loadHeader() async {
    final prefs = await SharedPreferences.getInstance();
    String? cycleJson = prefs.getString('cycle_$cycleName');
    if (cycleJson != null) {
      Map<String, dynamic> structuredData = jsonDecode(cycleJson);
      return structuredData['header'] as Map<String, dynamic>? ?? {};
    }
    return {};
  }

  Widget _buildHeaderSection(Map<String, dynamic> header) {
    return Card(
      elevation: 4,
      color: customBrown.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(
                  'assets/icons/icon.png',
                  width: 24,
                  height: 24,
                  color: customBrown,
                ),
                const SizedBox(width: 8),
                Text(
                  header['appName'] ?? 'CoffeeCore',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: customBrown,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Theme: ${header['themeColor'] ?? '#4E2D00'}',
              style: const TextStyle(color: customBrown),
            ),
            Text(
              'Saved: ${header['saveDate'] ?? header['downloadDate'] ?? 'Unknown'}',
              style: const TextStyle(color: customBrown),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Map<String, dynamic>> items, String category, BuildContext context) {
    if (items.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: customBrown),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('No entries yet.', style: TextStyle(color: Colors.grey)),
          ),
          const SizedBox(height: 20),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: customBrown),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              child: ListTile(
                title: Text(
                  _getItemTitle(item, category),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: _getItemSubtitle(item, category),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => onDelete(category, index),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  String _getItemTitle(Map<String, dynamic> item, String category) {
    switch (category) {
      case 'labour':
        return '${item['activity'] ?? 'Unnamed Activity'} - KSH ${item['cost'] ?? '0'}';
      case 'mechanical':
        return '${item['equipment'] ?? 'Unnamed Equipment'} - KSH ${item['cost'] ?? '0'}';
      case 'input':
        return '${item['input'] ?? 'Unnamed Input'} - KSH ${item['cost'] ?? '0'}';
      case 'miscellaneous':
        return '${item['description'] ?? 'Unnamed Misc'} - KSH ${item['cost'] ?? '0'}';
      case 'revenue':
        return '${item['crop'] ?? 'Unnamed Crop'} - KSH ${item['amount'] ?? '0'}';
      case 'payment':
        return '${item['date'] ?? 'Unknown Date'} - KSH ${item['amount'] ?? '0'}';
      default:
        return 'Unknown Item';
    }
  }

  Widget? _getItemSubtitle(Map<String, dynamic> item, String category) {
    switch (category) {
      case 'labour':
      case 'mechanical':
      case 'input':
      case 'miscellaneous':
        return Text('Date: ${item['date'] ?? 'No date'}');
      case 'payment':
        return Text('Remaining: KSH ${item['remainingBalance'] ?? '0'}');
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'All Coffee Farm Activities - $cycleName',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: customBrown,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<Map<String, dynamic>>(
              future: _loadHeader(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  return _buildHeaderSection(snapshot.data!);
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 4,
              child: ListTile(
                title: const Text('Total Costs', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('KSH $totalCosts'),
                leading: const Icon(Icons.money_off, color: customBrown),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 4,
              child: ListTile(
                title: const Text('Profit/Loss', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('KSH $profitLoss'),
                leading: Icon(
                  Icons.account_balance,
                  color: (double.tryParse(profitLoss) ?? 0) >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildSection('Coffee Farm Activities', labourActivities, 'labour', context),
            _buildSection('Coffee Farm Equipment Costs', mechanicalCosts, 'mechanical', context),
            _buildSection('Coffee Farm Input Costs', inputCosts, 'input', context),
            _buildSection('Miscellaneous Costs', miscellaneousCosts, 'miscellaneous', context),
            _buildSection('Revenues', revenues, 'revenue', context),
            _buildSection('Loan Payments', paymentHistory, 'payment', context),
          ],
        ),
      ),
    );
  }
}