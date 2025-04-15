import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'constants.dart';

class DataManager {
  final BuildContext context;
  final TextEditingController labourActivityController;
  final TextEditingController labourCostController;
  final TextEditingController equipmentUsedController;
  final TextEditingController equipmentCostController;
  final TextEditingController inputUsedController;
  final TextEditingController inputCostController;
  final TextEditingController miscellaneousDescController;
  final TextEditingController miscellaneousCostController;
  final TextEditingController coffeeVarietyController;
  final TextEditingController yieldController;
  final TextEditingController revenueController;
  final TextEditingController totalProductionCostController;
  final TextEditingController profitLossController;
  final TextEditingController loanSourceController;
  final TextEditingController loanAmountController;
  final TextEditingController interestRateController;
  final TextEditingController loanInterestController;
  final TextEditingController totalRepaymentController;
  final TextEditingController remainingBalanceController;
  final TextEditingController paymentAmountController;
  final VoidCallback onDataChanged;

  late SharedPreferences _prefs;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Data lists
  List<Map<String, dynamic>> labourActivities = [];
  List<Map<String, dynamic>> mechanicalCosts = [];
  List<Map<String, dynamic>> inputCosts = [];
  List<Map<String, dynamic>> miscellaneousCosts = [];
  List<Map<String, dynamic>> revenues = [];
  List<Map<String, dynamic>> paymentHistory = [];

  // Dates (made public, removed getters/setters)
  DateTime labourActivityDate = DateTime.now();
  DateTime equipmentUsedDate = DateTime.now();
  DateTime inputUsedDate = DateTime.now();
  DateTime miscellaneousDate = DateTime.now();
  DateTime paymentDate = DateTime.now();

  // Cycle management
  String _currentCycle = 'Current Cycle';
  List<String> _pastCycles = [];
  String? _retrievedCycle;

  DataManager({
    required this.context,
    required this.labourActivityController,
    required this.labourCostController,
    required this.equipmentUsedController,
    required this.equipmentCostController,
    required this.inputUsedController,
    required this.inputCostController,
    required this.miscellaneousDescController,
    required this.miscellaneousCostController,
    required this.coffeeVarietyController,
    required this.yieldController,
    required this.revenueController,
    required this.totalProductionCostController,
    required this.profitLossController,
    required this.loanSourceController,
    required this.loanAmountController,
    required this.interestRateController,
    required this.loanInterestController,
    required this.totalRepaymentController,
    required this.remainingBalanceController,
    required this.paymentAmountController,
    required this.onDataChanged,
  });

  String get currentCycle => _currentCycle;
  List<String> get pastCycles => _pastCycles;
  String? get retrievedCycle => _retrievedCycle;

  Future<void> loadData(Function(bool, String?) callback) async {
    _prefs = await SharedPreferences.getInstance();

    bool hasShownPopup = _prefs.getBool('hasShownStoragePopup') ?? false;
    bool isFirstLaunch = _prefs.getBool('isFirstLaunch') ?? true;
    _currentCycle = _prefs.getString('currentCycle') ?? 'Current Cycle';
    _pastCycles = _prefs.getStringList('pastCycles') ?? [];
    _loadCycleData(_currentCycle);
    callback(isFirstLaunch, _retrievedCycle);

    if (!hasShownPopup) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showStoragePopup();
      });
    }
  }

  void _loadCycleData(String cycle) {
    labourActivities = (_prefs.getString('labourActivities_$cycle') != null)
        ? List<Map<String, dynamic>>.from(
            jsonDecode(_prefs.getString('labourActivities_$cycle')!))
        : [];
    mechanicalCosts = (_prefs.getString('mechanicalCosts_$cycle') != null)
        ? List<Map<String, dynamic>>.from(
            jsonDecode(_prefs.getString('mechanicalCosts_$cycle')!))
        : [];
    inputCosts = (_prefs.getString('inputCosts_$cycle') != null)
        ? List<Map<String, dynamic>>.from(
            jsonDecode(_prefs.getString('inputCosts_$cycle')!))
        : [];
    miscellaneousCosts = (_prefs.getString('miscellaneousCosts_$cycle') != null)
        ? List<Map<String, dynamic>>.from(
            jsonDecode(_prefs.getString('miscellaneousCosts_$cycle')!))
        : [];
    revenues = (_prefs.getString('revenues_$cycle') != null)
        ? List<Map<String, dynamic>>.from(
            jsonDecode(_prefs.getString('revenues_$cycle')!))
        : [];
    paymentHistory = (_prefs.getString('paymentHistory_$cycle') != null)
        ? List<Map<String, dynamic>>.from(
            jsonDecode(_prefs.getString('paymentHistory_$cycle')!))
        : [];
    _loadLoanData(cycle);
    calculateTotalProductionCost();
  }

  void calculateTotalProductionCost() {
    double totalCost = 0;
    for (var item in labourActivities) {
      totalCost += double.tryParse(item['cost'] ?? '0') ?? 0;
    }
    for (var item in mechanicalCosts) {
      totalCost += double.tryParse(item['cost'] ?? '0') ?? 0;
    }
    for (var item in inputCosts) {
      totalCost += double.tryParse(item['cost'] ?? '0') ?? 0;
    }
    for (var item in miscellaneousCosts) {
      totalCost += double.tryParse(item['cost'] ?? '0') ?? 0;
    }
    totalProductionCostController.text = totalCost.toStringAsFixed(2);
    _calculateProfitLoss();
  }

  void _calculateProfitLoss() {
    double totalCost = double.tryParse(totalProductionCostController.text) ?? 0;
    double totalRevenue = revenues.fold(
        0, (total, rev) => total + (double.tryParse(rev['amount'] ?? '0') ?? 0));
    double profitLoss = totalRevenue - totalCost;
    profitLossController.text = profitLoss.toStringAsFixed(2);
  }

  void updateLoanCalculations() {
    double loanAmount = double.tryParse(loanAmountController.text) ?? 0;
    double interestRate = double.tryParse(interestRateController.text) ?? 0;
    double interest = (loanAmount * interestRate) / 100;
    double totalRepayment = loanAmount + interest;

    double paymentsMade = paymentHistory.fold(
        0.0,
        (total, payment) =>
            total + (double.tryParse(payment['amount'] ?? '0') ?? 0));
    double remainingBalance = totalRepayment - paymentsMade;

    loanInterestController.text = interest.toStringAsFixed(2);
    totalRepaymentController.text = totalRepayment.toStringAsFixed(2);
    remainingBalanceController.text = remainingBalance.toStringAsFixed(2);

    _saveLoanData(_currentCycle, loanAmount, interestRate, interest,
        totalRepayment, remainingBalance);
  }

  void _saveLoanData(String cycle, double loanAmount, double interestRate,
      double interest, double totalRepayment, double remainingBalance) {
    _prefs.setString(
        'loanData_$cycle',
        jsonEncode({
          'loanAmount': loanAmount,
          'interestRate': interestRate,
          'interest': interest,
          'totalRepayment': totalRepayment,
          'remainingBalance': remainingBalance,
          'loanSource': loanSourceController.text,
        }));
    _saveDataOnChange();
  }

  void _loadLoanData(String cycle) {
    String? savedLoanData = _prefs.getString('loanData_$cycle');
    if (savedLoanData != null) {
      Map<String, dynamic> loanData = jsonDecode(savedLoanData);
      loanAmountController.text = (loanData['loanAmount'] ?? 0).toString();
      interestRateController.text = (loanData['interestRate'] ?? 0).toString();
      loanInterestController.text =
          (loanData['interest'] ?? 0).toStringAsFixed(2);
      totalRepaymentController.text =
          (loanData['totalRepayment'] ?? 0).toStringAsFixed(2);
      remainingBalanceController.text =
          (loanData['remainingBalance'] ?? (loanData['totalRepayment'] ?? 0))
              .toStringAsFixed(2);
      loanSourceController.text = loanData['loanSource'] ?? '';
    } else {
      loanAmountController.clear();
      interestRateController.clear();
      loanInterestController.clear();
      totalRepaymentController.clear();
      remainingBalanceController.clear();
      loanSourceController.clear();
    }
  }

  void recordPayment() {
    double paymentAmount = double.tryParse(paymentAmountController.text) ?? 0;
    double remainingBalance =
        double.tryParse(remainingBalanceController.text) ?? 0;

    if (paymentAmount > 0 && paymentAmount <= remainingBalance) {
      remainingBalance -= paymentAmount;
      remainingBalanceController.text = remainingBalance.toStringAsFixed(2);

      final newPayment = {
        'date': paymentDate.toIso8601String().substring(0, 10),
        'amount': paymentAmount.toString(),
        'remainingBalance': remainingBalance.toString(),
      };
      paymentHistory.insert(0, newPayment);
      _saveDataOnChange();
      paymentAmountController.clear();
      paymentDate = DateTime.now();
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid payment amount')));
      }
    }
  }

  Future<void> _saveDataOnChange() async {
    _prefs.setString(
        'labourActivities_$_currentCycle', jsonEncode(labourActivities));
    _prefs.setString(
        'mechanicalCosts_$_currentCycle', jsonEncode(mechanicalCosts));
    _prefs.setString('inputCosts_$_currentCycle', jsonEncode(inputCosts));
    _prefs.setString(
        'miscellaneousCosts_$_currentCycle', jsonEncode(miscellaneousCosts));
    _prefs.setString('revenues_$_currentCycle', jsonEncode(revenues));
    _prefs.setString(
        'paymentHistory_$_currentCycle', jsonEncode(paymentHistory));
    _prefs.setStringList('pastCycles', _pastCycles);
    _prefs.setString('currentCycle', _currentCycle);

    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not logged in. Data saved locally only.')),
        );
      }
      return;
    }

    try {
      await _firestore.collection('farm_data').doc(userId).set({
        'currentCycle': _currentCycle,
        'pastCycles': _pastCycles,
        'cycles': {
          _currentCycle: {
            'labourActivities': labourActivities,
            'mechanicalCosts': mechanicalCosts,
            'inputCosts': inputCosts,
            'miscellaneousCosts': miscellaneousCosts,
            'revenues': revenues,
            'paymentHistory': paymentHistory,
            'loanData': {
              'loanAmount': loanAmountController.text,
              'interestRate': interestRateController.text,
              'interest': loanInterestController.text,
              'totalRepayment': totalRepaymentController.text,
              'remainingBalance': remainingBalanceController.text,
              'loanSource': loanSourceController.text,
            },
          },
        },
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data synced to Firebase')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        String errorMessage = e is FirebaseException
            ? 'Firebase Error: ${e.code} - ${e.message}'
            : 'Unexpected error: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sync with Firebase: $errorMessage')),
        );
      }
    }
  }

  void saveForm() {
    if (labourActivities.isEmpty &&
        mechanicalCosts.isEmpty &&
        inputCosts.isEmpty &&
        miscellaneousCosts.isEmpty &&
        revenues.isEmpty &&
        paymentHistory.isEmpty &&
        loanAmountController.text.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter some data before saving')));
      }
    } else {
      _saveDataOnChange();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data Saved Successfully')));
      }
      _resetForm();
    }
  }

  void _resetForm() {
    labourActivityController.clear();
    labourCostController.clear();
    labourActivityDate = DateTime.now();
    equipmentUsedController.clear();
    equipmentCostController.clear();
    equipmentUsedDate = DateTime.now();
    inputUsedController.clear();
    inputCostController.clear();
    inputUsedDate = DateTime.now();
    miscellaneousDescController.clear();
    miscellaneousCostController.clear();
    miscellaneousDate = DateTime.now();
    coffeeVarietyController.clear();
    yieldController.clear();
    revenueController.clear();
    paymentAmountController.clear();
    paymentDate = DateTime.now();
    loanSourceController.clear();
  }

  Future<void> startNewCycle() async {
    String? selectedCycleName;
    String customCycleName = '';
    int? selectedYear;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start New Cycle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Predefined Cycle Name'),
              items: [
                const DropdownMenuItem(value: '', child: Text('Custom')),
                ...predefinedCycleNames
                    .map((name) => DropdownMenuItem(value: name, child: Text(name)))
              ],
              onChanged: (value) => selectedCycleName = value,
            ),
            if (selectedCycleName == '')
              TextFormField(
                decoration: const InputDecoration(labelText: 'Custom Cycle Name'),
                onChanged: (value) => customCycleName = value,
              ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Year'),
              keyboardType: TextInputType.number,
              onChanged: (value) => selectedYear = int.tryParse(value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if ((selectedCycleName != null && selectedYear != null) &&
                  ((selectedCycleName!.isNotEmpty) || customCycleName.isNotEmpty)) {
                String newCycleName = selectedCycleName!.isEmpty
                    ? '$customCycleName $selectedYear'
                    : '$selectedCycleName $selectedYear';
                _saveCurrentCycle(newCycleName);
                Navigator.pop(context);
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Please enter a cycle name and year')));
                }
              }
            },
            child: const Text('Start New'),
          ),
        ],
      ),
    );
  }

  void _saveCurrentCycle(String newCycleName) {
    _saveDataOnChange();
    _pastCycles.add(newCycleName);
    _prefs.setStringList('pastCycles', _pastCycles);

    _currentCycle = 'Current Cycle';
    _prefs.setString('currentCycle', _currentCycle);
    labourActivities.clear();
    mechanicalCosts.clear();
    inputCosts.clear();
    miscellaneousCosts.clear();
    revenues.clear();
    paymentHistory.clear();
    _prefs.remove('labourActivities_$_currentCycle');
    _prefs.remove('mechanicalCosts_$_currentCycle');
    _prefs.remove('inputCosts_$_currentCycle');
    _prefs.remove('miscellaneousCosts_$_currentCycle');
    _prefs.remove('revenues_$_currentCycle');
    _prefs.remove('paymentHistory_$_currentCycle');
    _prefs.remove('loanData_$_currentCycle');

    _resetForm();
    calculateTotalProductionCost();
    _retrievedCycle = null;
    _saveDataOnChange();
    onDataChanged();
  }

  Future<void> retrievePastCycle() async {
    String? selectedCycleName;
    int? selectedYear;
    List<String> recentCycles = _pastCycles.take(3).toList();
    TextEditingController searchController = TextEditingController();
    bool useFirebase = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter dialogSetState) {
          return AlertDialog(
            title: const Text('Retrieve Past Cycle'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Cycle Name'),
                    items: predefinedCycleNames
                        .map((name) => DropdownMenuItem(value: name, child: Text(name)))
                        .toList(),
                    onChanged: (value) => selectedCycleName = value,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Year'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => selectedYear = int.tryParse(value),
                  ),
                  CheckboxListTile(
                    title: const Text('Fetch from Firebase if not local'),
                    value: useFirebase,
                    onChanged: (value) {
                      dialogSetState(() {
                        useFirebase = value ?? false;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  const Text('Recent Cycles:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...recentCycles.map((cycle) => ListTile(
                        title: Text(cycle),
                        onTap: () {
                          Navigator.pop(context);
                          _retrievedCycle = cycle;
                          _loadCycleData(cycle);
                          onDataChanged();
                        },
                      )),
                  TextField(
                    controller: searchController,
                    decoration: const InputDecoration(labelText: 'Search by Name'),
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        String closestMatch = _pastCycles.firstWhere(
                          (cycle) => cycle.toLowerCase().contains(value.toLowerCase()),
                          orElse: () => '',
                        );
                        if (closestMatch.isNotEmpty && closestMatch != value) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Text('Did you mean '),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.pop(context);
                                        _retrievedCycle = closestMatch;
                                        _loadCycleData(closestMatch);
                                        onDataChanged();
                                      },
                                      child: Text('"$closestMatch"?',
                                          style: const TextStyle(color: Colors.blue)),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  if (selectedCycleName != null && selectedYear != null) {
                    String cycleToRetrieve = '$selectedCycleName $selectedYear';
                    Navigator.pop(context);

                    if (_pastCycles.contains(cycleToRetrieve)) {
                      _retrievedCycle = cycleToRetrieve;
                      _loadCycleData(cycleToRetrieve);
                      onDataChanged();
                    } else if (useFirebase) {
                      String? userId = FirebaseAuth.instance.currentUser?.uid;
                      if (userId == null) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('You must be logged in to fetch from Firebase')),
                          );
                        }
                        return;
                      }

                      try {
                        DocumentSnapshot doc = await _firestore
                            .collection('farm_data')
                            .doc(userId)
                            .get();
                        if (!doc.exists) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('No data found for this user')),
                            );
                          }
                          return;
                        }
                        Map<String, dynamic>? data =
                            doc.data() as Map<String, dynamic>?;
                        if (data == null || !data.containsKey('cycles')) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('No cycle data available')),
                            );
                          }
                          return;
                        }
                        Map<String, dynamic> cycles = data['cycles'];
                        if (cycles.containsKey(cycleToRetrieve)) {
                          _retrievedCycle = cycleToRetrieve;
                          labourActivities = List<Map<String, dynamic>>.from(
                              cycles[cycleToRetrieve]['labourActivities'] ?? []);
                          mechanicalCosts = List<Map<String, dynamic>>.from(
                              cycles[cycleToRetrieve]['mechanicalCosts'] ?? []);
                          inputCosts = List<Map<String, dynamic>>.from(
                              cycles[cycleToRetrieve]['inputCosts'] ?? []);
                          miscellaneousCosts = List<Map<String, dynamic>>.from(
                              cycles[cycleToRetrieve]['miscellaneousCosts'] ?? []);
                          revenues = List<Map<String, dynamic>>.from(
                              cycles[cycleToRetrieve]['revenues'] ?? []);
                          paymentHistory = List<Map<String, dynamic>>.from(
                              cycles[cycleToRetrieve]['paymentHistory'] ?? []);
                          _loadLoanData(cycleToRetrieve);
                          calculateTotalProductionCost();
                          _pastCycles.add(cycleToRetrieve);
                          _prefs.setStringList('pastCycles', _pastCycles);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Data retrieved from Firebase')),
                            );
                          }
                          onDataChanged();
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Cycle "$cycleToRetrieve" not found')),
                            );
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          String errorMessage = e is FirebaseException
                              ? 'Firebase Error: ${e.code} - ${e.message}'
                              : 'Unexpected error: $e';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('Error fetching from Firebase: $errorMessage')),
                          );
                        }
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Cycle not found locally')),
                        );
                      }
                    }
                  }
                },
                child: const Text('Retrieve'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showStoragePopup() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              const Icon(Icons.lock, color: customBrown, size: 24),
              const SizedBox(width: 8),
              Text(
                'Your Data Stays Safe',
                style: TextStyle(
                    color: customBrown, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good news! Your financial info is stored only on this device and synced to Firebase for admin access.',
                style: TextStyle(fontSize: 16, height: 1.4),
              ),
              SizedBox(height: 8),
              Text(
                'Keep your device secure to protect it!',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _prefs.setBool('hasShownStoragePopup', true);
              },
              child: Text('Got It',
                  style:
                      TextStyle(color: customBrown, fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('More Info'),
                    content: const Text(
                      'Your costs, revenues, and loans are saved locally using SharedPreferences and synced to Firebase. '
                      'No data is shared beyond this unless you choose to. '
                      'For security, avoid lending your device or use a passcode.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('OK', style: TextStyle(color: customBrown)),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Learn More', style: TextStyle(color: Colors.grey)),
            ),
          ],
        );
      },
    );
  }

  List<String> getEquipmentSuggestions() {
    return mechanicalCosts
        .map((cost) => cost['equipment'] as String)
        .toSet()
        .toList();
  }

  List<String> getInputSuggestions() {
    return inputCosts.map((cost) => cost['input'] as String).toSet().toList();
  }

  Future<void> editCycleName(VoidCallback onCycleChanged) async {
    String? selectedCycleName;
    String customCycleName = '';
    int? selectedYear;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Cycle Name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Predefined Cycle Name'),
              items: [
                const DropdownMenuItem(value: '', child: Text('Custom')),
                ...predefinedCycleNames
                    .map((name) => DropdownMenuItem(value: name, child: Text(name)))
              ],
              onChanged: (value) => selectedCycleName = value,
            ),
            if (selectedCycleName == '')
              TextFormField(
                decoration: const InputDecoration(labelText: 'Custom Cycle Name'),
                onChanged: (value) => customCycleName = value,
              ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Year'),
              keyboardType: TextInputType.number,
              onChanged: (value) => selectedYear = int.tryParse(value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if ((selectedCycleName != null && selectedYear != null) &&
                  (selectedCycleName!.isNotEmpty || customCycleName.isNotEmpty)) {
                _currentCycle = selectedCycleName!.isEmpty
                    ? '$customCycleName $selectedYear'
                    : '$selectedCycleName $selectedYear';
                _prefs.setString('currentCycle', _currentCycle);
                _prefs.setBool('isFirstLaunch', false);
                _saveDataOnChange();
                onCycleChanged();
                Navigator.pop(context);
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Please enter a cycle name and year')));
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void addLabourCost() {
    if (labourActivityController.text.isNotEmpty &&
        labourCostController.text.isNotEmpty) {
      final newActivity = {
        'activity': labourActivityController.text,
        'cost': labourCostController.text,
        'date': labourActivityDate.toIso8601String().substring(0, 10),
      };
      labourActivities.insert(0, newActivity);
      _saveDataOnChange();
      labourActivityController.clear();
      labourCostController.clear();
      labourActivityDate = DateTime.now();
      calculateTotalProductionCost();
      onDataChanged();
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please fill in all labour fields')));
      }
    }
  }

  void addMechanicalCost() {
    if (equipmentUsedController.text.isNotEmpty &&
        equipmentCostController.text.isNotEmpty) {
      final newCost = {
        'equipment': equipmentUsedController.text,
        'cost': equipmentCostController.text,
        'date': equipmentUsedDate.toIso8601String().substring(0, 10),
      };
      mechanicalCosts.insert(0, newCost);
      _saveDataOnChange();
      equipmentUsedController.clear();
      equipmentCostController.clear();
      equipmentUsedDate = DateTime.now();
      calculateTotalProductionCost();
      onDataChanged();
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please fill in all equipment fields')));
      }
    }
  }

  void addInputCost() {
    if (inputUsedController.text.isNotEmpty &&
        inputCostController.text.isNotEmpty) {
      final newCost = {
        'input': inputUsedController.text,
        'cost': inputCostController.text,
        'date': inputUsedDate.toIso8601String().substring(0, 10),
      };
      inputCosts.insert(0, newCost);
      _saveDataOnChange();
      inputUsedController.clear();
      inputCostController.clear();
      inputUsedDate = DateTime.now();
      calculateTotalProductionCost();
      onDataChanged();
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please fill in all input fields')));
      }
    }
  }

  void addMiscellaneousCost() {
    if (miscellaneousDescController.text.isNotEmpty &&
        miscellaneousCostController.text.isNotEmpty) {
      final newCost = {
        'description': miscellaneousDescController.text,
        'cost': miscellaneousCostController.text,
        'date': miscellaneousDate.toIso8601String().substring(0, 10),
      };
      miscellaneousCosts.insert(0, newCost);
      _saveDataOnChange();
      miscellaneousDescController.clear();
      miscellaneousCostController.clear();
      miscellaneousDate = DateTime.now();
      calculateTotalProductionCost();
      onDataChanged();
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please fill in all miscellaneous fields')));
      }
    }
  }

  void addRevenue() {
    if (coffeeVarietyController.text.isNotEmpty &&
        yieldController.text.isNotEmpty &&
        revenueController.text.isNotEmpty) {
      final newRevenue = {
        'coffeeVariety': coffeeVarietyController.text,
        'yield': yieldController.text,
        'amount': revenueController.text,
        'date': DateTime.now().toIso8601String().substring(0, 10),
      };
      revenues.insert(0, newRevenue);
      _saveDataOnChange();
      coffeeVarietyController.clear();
      yieldController.clear();
      revenueController.clear();
      calculateTotalProductionCost();
      onDataChanged();
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please fill in all revenue fields')));
      }
    }
  }

  void deleteActivity(String category, int index) {
    switch (category) {
      case 'labour':
        labourActivities.removeAt(index);
        break;
      case 'mechanical':
        mechanicalCosts.removeAt(index);
        break;
      case 'input':
        inputCosts.removeAt(index);
        break;
      case 'miscellaneous':
        miscellaneousCosts.removeAt(index);
        break;
      case 'revenue':
        revenues.removeAt(index);
        break;
      case 'payment':
        paymentHistory.removeAt(index);
        updateLoanCalculations();
        break;
    }
    _saveDataOnChange();
    calculateTotalProductionCost();
    onDataChanged();
  }
}