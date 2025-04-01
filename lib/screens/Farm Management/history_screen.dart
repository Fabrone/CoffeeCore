import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:coffeecore/models/farm_cycle_data.dart';

class HistoryScreen extends StatefulWidget {
  final List<Map<String, dynamic>> labourActivities;
  final List<Map<String, dynamic>> mechanicalCosts;
  final List<Map<String, dynamic>> inputCosts;
  final List<Map<String, dynamic>> miscellaneousCosts;
  final List<Map<String, dynamic>> revenues;
  final List<Map<String, dynamic>> paymentHistory;
  final String cycleName;
  final List<String> pastCycles;

  const HistoryScreen({
    super.key,
    required this.labourActivities,
    required this.mechanicalCosts,
    required this.inputCosts,
    required this.miscellaneousCosts,
    required this.revenues,
    required this.paymentHistory,
    required this.cycleName,
    required this.pastCycles,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime? startDate;
  DateTime? endDate;
  String selectedCycle;

  _HistoryScreenState() : selectedCycle = '';

  @override
  void initState() {
    super.initState();
    selectedCycle = widget.cycleName;
  }

  Future<List<Map<String, dynamic>>> _fetchCycleData(String cycle) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    String uid = user.uid;
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(uid)
        .collection('FarmCycles')
        .doc(cycle)
        .get();

    if (doc.exists) {
      FarmCycleData cycleData = FarmCycleData.fromMap(doc.data() as Map<String, dynamic>);
      return [
        ...cycleData.labourActivities,
        ...cycleData.mechanicalCosts,
        ...cycleData.inputCosts,
        ...cycleData.miscellaneousCosts,
        ...cycleData.revenues,
        ...cycleData.paymentHistory,
      ];
    }
    return [];
  }

  List<Map<String, dynamic>> filterByDate(List<Map<String, dynamic>> data) {
    if (startDate == null || endDate == null) return data;
    return data.where((item) {
      if (!item.containsKey('date')) return true;
      DateTime itemDate = DateTime.parse(item['date']);
      return itemDate.isAfter(startDate!.subtract(const Duration(days: 1))) &&
          itemDate.isBefore(endDate!.add(const Duration(days: 1)));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Coffee Farm History')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchCycleData(selectedCycle),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return const Center(child: Text('Error loading history'));

          var filteredData = filterByDate(snapshot.data ?? []);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    DropdownButton<String>(
                      value: selectedCycle,
                      items: [widget.cycleName, ...widget.pastCycles]
                          .map((cycle) => DropdownMenuItem(value: cycle, child: Text(cycle)))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedCycle = value;
                            startDate = null;
                            endDate = null;
                          });
                        }
                      },
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) setState(() => startDate = picked);
                      },
                      child: Text(startDate == null ? 'Start Date' : startDate!.toString().substring(0, 10)),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) setState(() => endDate = picked);
                      },
                      child: Text(endDate == null ? 'End Date' : endDate!.toString().substring(0, 10)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (filteredData.isNotEmpty) ...[
                  const Text('Coffee Farm Activities', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredData.length,
                    itemBuilder: (context, index) {
                      final item = filteredData[index];
                      return ListTile(
                        title: Text(item.containsKey('activity')
                            ? '${item['activity']} - KSH ${item['cost']}'
                            : item.containsKey('equipment')
                                ? '${item['equipment']} - KSH ${item['cost']}'
                                : item.containsKey('input')
                                    ? '${item['input']} - KSH ${item['cost']}'
                                    : item.containsKey('description')
                                        ? '${item['description']} - KSH ${item['cost']}'
                                        : item.containsKey('crop')
                                            ? '${item['crop']} - KSH ${item['amount']}'
                                            : '${item['date']} - KSH ${item['amount']}'),
                        subtitle: item.containsKey('date') ? Text('Date: ${item['date']}') : item.containsKey('remainingBalance') ? Text('Remaining: KSH ${item['remainingBalance']}') : null,
                      );
                    },
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}