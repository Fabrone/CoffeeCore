import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
  late SharedPreferences _prefs;

  _HistoryScreenState() : selectedCycle = '';

  @override
  void initState() {
    super.initState();
    selectedCycle = widget.cycleName;
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _loadCycleData(selectedCycle);
  }

  void _loadCycleData(String cycle) {
    setState(() {
      widget.labourActivities.clear();
      widget.labourActivities.addAll(
        (_prefs.getString('labourActivities_$cycle') != null)
            ? List<Map<String, dynamic>>.from(
                jsonDecode(_prefs.getString('labourActivities_$cycle')!))
            : [],
      );
      widget.mechanicalCosts.clear();
      widget.mechanicalCosts.addAll(
        (_prefs.getString('mechanicalCosts_$cycle') != null)
            ? List<Map<String, dynamic>>.from(
                jsonDecode(_prefs.getString('mechanicalCosts_$cycle')!))
            : [],
      );
      widget.inputCosts.clear();
      widget.inputCosts.addAll(
        (_prefs.getString('inputCosts_$cycle') != null)
            ? List<Map<String, dynamic>>.from(
                jsonDecode(_prefs.getString('inputCosts_$cycle')!))
            : [],
      );
      widget.miscellaneousCosts.clear();
      widget.miscellaneousCosts.addAll(
        (_prefs.getString('miscellaneousCosts_$cycle') != null)
            ? List<Map<String, dynamic>>.from(
                jsonDecode(_prefs.getString('miscellaneousCosts_$cycle')!))
            : [],
      );
      widget.revenues.clear();
      widget.revenues.addAll(
        (_prefs.getString('revenues_$cycle') != null)
            ? List<Map<String, dynamic>>.from(
                jsonDecode(_prefs.getString('revenues_$cycle')!))
            : [],
      );
      widget.paymentHistory.clear();
      widget.paymentHistory.addAll(
        (_prefs.getString('paymentHistory_$cycle') != null)
            ? List<Map<String, dynamic>>.from(
                jsonDecode(_prefs.getString('paymentHistory_$cycle')!))
            : [],
      );
    });
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
    var filteredLabour = filterByDate(widget.labourActivities);
    var filteredMechanical = filterByDate(widget.mechanicalCosts);
    var filteredInputs = filterByDate(widget.inputCosts);
    var filteredMisc = filterByDate(widget.miscellaneousCosts);
    var filteredRevenues = filterByDate(widget.revenues);
    var filteredPayments = filterByDate(widget.paymentHistory);

    return Scaffold(
      appBar: AppBar(title: const Text('Coffee Farm History')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                DropdownButton<String>(
                  value: selectedCycle,
                  items: [widget.cycleName, ...widget.pastCycles]
                      .map((cycle) =>
                          DropdownMenuItem(value: cycle, child: Text(cycle)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedCycle = value;
                        _loadCycleData(value);
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
                  child: Text(startDate == null
                      ? 'Start Date'
                      : startDate.toString().substring(0, 10)),
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
                  child: Text(endDate == null
                      ? 'End Date'
                      : endDate.toString().substring(0, 10)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (filteredLabour.isNotEmpty) ...[
              const Text('Coffee Farm Activities',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredLabour.length,
                itemBuilder: (context, index) {
                  final item = filteredLabour[index];
                  return ListTile(
                    title: Text('${item['activity']} - KSH ${item['cost']}'),
                    subtitle: Text('Date: ${item['date']}'),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
            if (filteredMechanical.isNotEmpty) ...[
              const Text('Coffee Farm Equipment Costs',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredMechanical.length,
                itemBuilder: (context, index) {
                  final item = filteredMechanical[index];
                  return ListTile(
                    title: Text('${item['equipment']} - KSH ${item['cost']}'),
                    subtitle: Text('Date: ${item['date']}'),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
            if (filteredInputs.isNotEmpty) ...[
              const Text('Coffee Farm Input Costs',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredInputs.length,
                itemBuilder: (context, index) {
                  final item = filteredInputs[index];
                  return ListTile(
                    title: Text('${item['input']} - KSH ${item['cost']}'),
                    subtitle: Text('Date: ${item['date']}'),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
            if (filteredMisc.isNotEmpty) ...[
              const Text('Miscellaneous Costs',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredMisc.length,
                itemBuilder: (context, index) {
                  final item = filteredMisc[index];
                  return ListTile(
                    title: Text('${item['description']} - KSH ${item['cost']}'),
                    subtitle: Text('Date: ${item['date']}'),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
            if (filteredRevenues.isNotEmpty) ...[
              const Text('Revenues',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredRevenues.length,
                itemBuilder: (context, index) {
                  final item = filteredRevenues[index];
                  return ListTile(
                    title: Text('${item['crop']} - KSH ${item['amount']}'),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
            if (filteredPayments.isNotEmpty) ...[
              const Text('Loan Payments',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredPayments.length,
                itemBuilder: (context, index) {
                  final item = filteredPayments[index];
                  return ListTile(
                    title: Text('${item['date']} - KSH ${item['amount']}'),
                    subtitle:
                        Text('Remaining: KSH ${item['remainingBalance']}'),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}