import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'historical_data.dart'; // Import your HistoricalData model

class HistoryScreen extends StatefulWidget {
  final String cycleName;
  final List<String> pastCycles;

  const HistoryScreen({
    super.key,
    required this.cycleName,
    required this.pastCycles, required List<Map<String, dynamic>> labourActivities, required List<Map<String, dynamic>> mechanicalCosts, required List<Map<String, dynamic>> inputCosts, required List<Map<String, dynamic>> miscellaneousCosts, required List<Map<String, dynamic>> revenues, required List<Map<String, dynamic>> paymentHistory,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime? startDate;
  DateTime? endDate;
  String selectedCycle;
  late SharedPreferences _prefs;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool useFirebase = false;
  List<HistoricalData> labourActivities = [];
  List<HistoricalData> mechanicalCosts = [];
  List<HistoricalData> inputCosts = [];
  List<HistoricalData> miscellaneousCosts = [];
  List<HistoricalData> revenues = [];
  List<HistoricalData> paymentHistory = [];

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
      labourActivities.clear();
      mechanicalCosts.clear();
      inputCosts.clear();
      miscellaneousCosts.clear();
      revenues.clear();
      paymentHistory.clear();

      if (!useFirebase) {
        // Load from SharedPreferences
        labourActivities.addAll(_loadFromPrefs('labourActivities_$cycle'));
        mechanicalCosts.addAll(_loadFromPrefs('mechanicalCosts_$cycle'));
        inputCosts.addAll(_loadFromPrefs('inputCosts_$cycle'));
        miscellaneousCosts.addAll(_loadFromPrefs('miscellaneousCosts_$cycle'));
        revenues.addAll(_loadFromPrefs('revenues_$cycle'));
        paymentHistory.addAll(_loadFromPrefs('paymentHistory_$cycle'));
      }
    });
  }

  List<HistoricalData> _loadFromPrefs(String key) {
    final jsonString = _prefs.getString(key);
    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => HistoricalData.fromMap(json)).toList();
    }
    return [];
  }

  Future<void> _loadFromFirebase(String cycle) async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    String? message;

    if (userId == null) {
      message = 'You must be logged in to fetch from Firebase';
    } else {
      try {
        DocumentSnapshot doc = await _firestore.collection('farm_data').doc(userId).get();
        if (!doc.exists) {
          message = 'No data found for this user in Firebase';
        } else {
          Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
          if (data == null || data['cycles'] == null) {
            message = 'No cycle data found in Firebase document';
          } else {
            Map<String, dynamic> cycles = data['cycles'];
            if (cycles.containsKey(cycle)) {
              setState(() {
                labourActivities.clear();
                mechanicalCosts.clear();
                inputCosts.clear();
                miscellaneousCosts.clear();
                revenues.clear();
                paymentHistory.clear();

                labourActivities.addAll(_mapHistoricalData(cycles[cycle]['labourActivities']));
                mechanicalCosts.addAll(_mapHistoricalData(cycles[cycle]['mechanicalCosts']));
                inputCosts.addAll(_mapHistoricalData(cycles[cycle]['inputCosts']));
                miscellaneousCosts.addAll(_mapHistoricalData(cycles[cycle]['miscellaneousCosts']));
                revenues.addAll(_mapHistoricalData(cycles[cycle]['revenues']));
                paymentHistory.addAll(_mapHistoricalData(cycles[cycle]['paymentHistory']));
              });
              message = 'Data retrieved from Firebase successfully';
            } else {
              message = 'Cycle "$cycle" not found in Firebase';
            }
          }
        }
      } catch (e) {
        message = e is FirebaseException
            ? 'Firebase Error: ${e.code} - ${e.message}'
            : 'Unexpected error: $e';
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  List<HistoricalData> _mapHistoricalData(List<dynamic>? data) {
    if (data != null) {
      return data.map((item) => HistoricalData.fromMap(item)).toList();
    }
    return [];
  }

  List<HistoricalData> filterByDate(List<HistoricalData> data) {
    if (startDate == null || endDate == null) return data;
    return data.where((item) {
      return item.date.isAfter(startDate!.subtract(const Duration(days: 1))) &&
             item.date.isBefore(endDate!.add(const Duration(days: 1)));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    var filteredLabour = filterByDate(labourActivities);
    var filteredMechanical = filterByDate(mechanicalCosts);
    var filteredInputs = filterByDate(inputCosts);
    var filteredMisc = filterByDate(miscellaneousCosts);
    var filteredRevenues = filterByDate(revenues);
    var filteredPayments = filterByDate(paymentHistory);

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
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
                      .map((cycle) => DropdownMenuItem(value: cycle, child: Text(cycle)))
                      .toList(),
                  onChanged: (value) async {
                    if (value != null) {
                      setState(() {
                        selectedCycle = value;
                        _loadCycleData(value);
                      });
                      if (useFirebase) {
                        await _loadFromFirebase(value);
                      }
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
            CheckboxListTile(
              title: const Text('Use Firebase Data'),
              value: useFirebase,
              onChanged: (value) async {
                setState(() {
                  useFirebase = value ?? false;
                });
                if (useFirebase) {
                  await _loadFromFirebase(selectedCycle);
                } else {
                  _loadCycleData(selectedCycle);
                }
              },
            ),
            const SizedBox(height: 20),
            if (filteredLabour.isNotEmpty) ...[
              const Text('Labour Activities',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredLabour.length,
                itemBuilder: (context, index) {
                  final item = filteredLabour[index];
                  return ListTile(
                    title: Text('${item.activity} - KSH ${item.cost}'),
                    subtitle: Text('Date: ${item.date.toIso8601String().substring(0, 10)}'),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
            if (filteredMechanical.isNotEmpty) ...[
              const Text('Mechanical Costs',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredMechanical.length,
                itemBuilder: (context, index) {
                  final item = filteredMechanical[index];
                  return ListTile(
                    title: Text('${item.activity} - KSH ${item.cost}'),
                    subtitle: Text('Date: ${item.date.toIso8601String().substring(0, 10)}'),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
            if (filteredInputs.isNotEmpty) ...[
              const Text('Input Costs',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredInputs.length,
                itemBuilder: (context, index) {
                  final item = filteredInputs[index];
                  return ListTile(
                    title: Text('${item.activity} - KSH ${item.cost}'),
                    subtitle: Text('Date: ${item.date.toIso8601String().substring(0, 10)}'),
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
                    title: Text('${item.activity} - KSH ${item.cost}'),
                    subtitle: Text('Date: ${item.date.toIso8601String().substring(0, 10)}'),
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
                    title: Text('${item.activity} - KSH ${item.cost}'),
                    subtitle: Text('Date: ${item.date.toIso8601String().substring(0, 10)}'),
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
                    title: Text('${item.date.toIso8601String().substring(0, 10)} - KSH ${item.cost}'),
                    subtitle: Text('Remaining: KSH ${item.cost}'),
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
