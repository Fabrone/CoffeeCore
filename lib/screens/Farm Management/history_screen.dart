import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'data_manager.dart';
import 'constants.dart';

class HistoryScreen extends StatefulWidget {
  final String cycleName;
  final List<String> pastCycles;
  final DataManager dataManager;

  const HistoryScreen({
    super.key,
    required this.cycleName,
    required this.pastCycles,
    required this.dataManager,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final Logger _logger = Logger();
  String selectedCycle = '';
  bool _isLoading = false;
  Map<String, dynamic> cycles = {};
  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    selectedCycle = widget.cycleName;
    _loadHistoryData();
  }

  Future<bool> _checkConnectivity() async {
    _logger.i('Checking network connectivity...');
    var connectivityResult = await Connectivity().checkConnectivity();
    if (!connectivityResult.contains(ConnectivityResult.none)) {
      _logger.i('Internet connection available');
      return true;
    }
    _logger.w('No internet connection');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No internet connection')));
    }
    return false;
  }

  Future<void> _loadHistoryData() async {
    _logger.i('Loading history data for cycle: $selectedCycle');
    if (!await _checkConnectivity()) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }
    if (mounted) {
      setState(() => _isLoading = true);
    }
    try {
      Map<String, dynamic>? data = await widget.dataManager.loadFromFirestore();
      if (data == null || !data.containsKey('cycles')) {
        _logger.w('No cycle data found in Firestore');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No historical data found')));
        }
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      setState(() {
        cycles = data['cycles'] ?? {};
        _isLoading = false;
      });
      _logger.i('History data loaded successfully');
    } catch (e) {
      _logger.e('Error loading history: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading history: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> _filterByDate(List<Map<String, dynamic>> data) {
    if (startDate == null || endDate == null) return data;
    return data.where((item) {
      DateTime itemDate =
          DateTime.parse(item['date'] ?? DateTime.now().toIso8601String());
      return itemDate.isAfter(startDate!.subtract(const Duration(days: 1))) &&
          itemDate.isBefore(endDate!.add(const Duration(days: 1)));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    List<String> cycleNames = cycles.keys.toList();
    Map<String, dynamic> cycleData = cycles[selectedCycle] ?? {};
    List<Map<String, dynamic>> labourActivities = widget.dataManager
        .validateJsonList(jsonEncode(cycleData['labourActivities'] ?? []));
    List<Map<String, dynamic>> mechanicalCosts = widget.dataManager
        .validateJsonList(jsonEncode(cycleData['mechanicalCosts'] ?? []));
    List<Map<String, dynamic>> inputCosts = widget.dataManager
        .validateJsonList(jsonEncode(cycleData['inputCosts'] ?? []));
    List<Map<String, dynamic>> miscellaneousCosts = widget.dataManager
        .validateJsonList(jsonEncode(cycleData['miscellaneousCosts'] ?? []));
    List<Map<String, dynamic>> revenues = widget.dataManager
        .validateJsonList(jsonEncode(cycleData['revenues'] ?? []));
    List<Map<String, dynamic>> paymentHistory = widget.dataManager
        .validateJsonList(jsonEncode(cycleData['paymentHistory'] ?? []));

    double totalCost = labourActivities.fold<double>(
            0.0, (total, item) => total + (double.tryParse(item['cost'].toString()) ?? 0)) +
        mechanicalCosts.fold<double>(
            0.0, (total, item) => total + (double.tryParse(item['cost'].toString()) ?? 0)) +
        inputCosts.fold<double>(
            0.0, (total, item) => total + (double.tryParse(item['cost'].toString()) ?? 0)) +
        miscellaneousCosts.fold<double>(
            0.0, (total, item) => total + (double.tryParse(item['cost'].toString()) ?? 0));
    double totalRevenue = revenues.fold<double>(
        0.0, (total, item) => total + (double.tryParse(item['amount'].toString()) ?? 0));
    double profitLoss = totalRevenue - totalCost;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          tooltip: 'Back to Management',
          onPressed: () {
            _logger.i('Back button pressed');
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Historical Farm Data',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: customBrown,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: customBrown),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        alignment: WrapAlignment.center,
                        children: [
                          SizedBox(
                            width: 200, // Constrain dropdown width
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedCycle.isNotEmpty ? selectedCycle : null,
                              decoration: InputDecoration(
                                labelText: 'Select Cycle',
                                labelStyle: TextStyle(color: customBrown),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: customBrown),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: customBrown, width: 2),
                                ),
                              ),
                              items: cycleNames
                                  .map((cycle) => DropdownMenuItem(
                                        value: cycle,
                                        child: Container(
                                          constraints: const BoxConstraints(maxWidth: 180),
                                          child: Text(
                                            cycle,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (value) async {
                                if (value != null) {
                                  setState(() {
                                    selectedCycle = value;
                                  });
                                  await _loadHistoryData();
                                }
                              },
                            ),
                          ),
                          SizedBox(
                            width: 140, // Constrain button width
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: customBrown,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              onPressed: () async {
                                DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: ColorScheme.light(
                                          primary: customBrown,
                                          onPrimary: Colors.white,
                                          onSurface: Colors.black,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null) setState(() => startDate = picked);
                              },
                              child: Text(
                                startDate == null
                                    ? 'Start Date'
                                    : startDate!.toString().substring(0, 10),
                                style: const TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 140, // Constrain button width
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: customBrown,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              onPressed: () async {
                                DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: ColorScheme.light(
                                          primary: customBrown,
                                          onPrimary: Colors.white,
                                          onSurface: Colors.black,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null) setState(() => endDate = picked);
                              },
                              child: Text(
                                endDate == null
                                    ? 'End Date'
                                    : endDate!.toString().substring(0, 10),
                                style: const TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (cycleData.isNotEmpty) ...[
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ExpansionTile(
                        leading: Icon(Icons.folder, color: customBrown),
                        title: Text(
                          selectedCycle,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: customBrown),
                        ),
                        children: [
                          ListTile(
                            leading:
                                Icon(Icons.account_balance_wallet, color: customBrown),
                            title: Text(
                                'Total Costs: KSH ${totalCost.toStringAsFixed(2)}'),
                          ),
                          ListTile(
                            leading: Icon(Icons.monetization_on, color: customBrown),
                            title: Text(
                                'Total Revenue: KSH ${totalRevenue.toStringAsFixed(2)}'),
                          ),
                          ListTile(
                            leading: Icon(
                                profitLoss >= 0
                                    ? Icons.trending_up
                                    : Icons.trending_down,
                                color: profitLoss >= 0 ? Colors.green : Colors.red),
                            title: Text(
                                'Profit/Loss: KSH ${profitLoss.toStringAsFixed(2)}'),
                          ),
                          if (labourActivities.isNotEmpty)
                            _buildSection(
                              'Labour Activities',
                              _filterByDate(labourActivities),
                              'labour',
                              icon: Icons.person,
                              itemBuilder: (item) =>
                                  '${item['activity']} - KSH ${item['cost']}',
                              subtitleBuilder: (item) => 'Date: ${item['date']}',
                            ),
                          if (mechanicalCosts.isNotEmpty)
                            _buildSection(
                              'Mechanical Costs',
                              _filterByDate(mechanicalCosts),
                              'mechanical',
                              icon: Icons.build,
                              itemBuilder: (item) =>
                                  '${item['equipment']} - KSH ${item['cost']}',
                              subtitleBuilder: (item) => 'Date: ${item['date']}',
                            ),
                          if (inputCosts.isNotEmpty)
                            _buildSection(
                              'Input Costs',
                              _filterByDate(inputCosts),
                              'input',
                              icon: Icons.agriculture,
                              itemBuilder: (item) =>
                                  '${item['input']} - KSH ${item['cost']}',
                              subtitleBuilder: (item) => 'Date: ${item['date']}',
                            ),
                          if (miscellaneousCosts.isNotEmpty)
                            _buildSection(
                              'Miscellaneous Costs',
                              _filterByDate(miscellaneousCosts),
                              'miscellaneous',
                              icon: Icons.miscellaneous_services,
                              itemBuilder: (item) =>
                                  '${item['description']} - KSH ${item['cost']}',
                              subtitleBuilder: (item) => 'Date: ${item['date']}',
                            ),
                          if (revenues.isNotEmpty)
                            _buildSection(
                              'Revenues',
                              _filterByDate(revenues),
                              'revenue',
                              icon: Icons.monetization_on,
                              itemBuilder: (item) =>
                                  '${item['coffeeVariety']} - KSH ${item['amount']}',
                              subtitleBuilder: (item) =>
                                  'Yield: ${item['yield'] ?? 'N/A'} kg - Date: ${item['date']}',
                            ),
                          if (paymentHistory.isNotEmpty)
                            _buildSection(
                              'Loan Payments',
                              _filterByDate(paymentHistory),
                              'payment',
                              icon: Icons.payment,
                              itemBuilder: (item) =>
                                  '${item['date']} - KSH ${item['amount']}',
                              subtitleBuilder: (item) =>
                                  'Remaining: KSH ${item['remainingBalance']}',
                            ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: const ListTile(
                        title: Text(
                          'No data available for the selected cycle',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildSection(
    String title,
    List<Map<String, dynamic>> items,
    String type, {
    required IconData icon,
    required String Function(Map<String, dynamic>) itemBuilder,
    required String Function(Map<String, dynamic>) subtitleBuilder,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Icon(icon, color: customBrown),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: customBrown,
          ),
        ),
        children: items.isEmpty
            ? [
                const ListTile(
                  title: Text(
                    'No data available',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ]
            : items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Column(
                  children: [
                    ListTile(
                      title: Text(itemBuilder(item)),
                      subtitle: Text(subtitleBuilder(item)),
                    ),
                    if (index < items.length - 1)
                      const Divider(height: 1, indent: 16, endIndent: 16),
                  ],
                );
              }).toList(),
      ),
    );
  }
}