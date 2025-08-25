import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
//import 'constants.dart';

class DataManager {
  final Logger _logger = Logger();
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

  // Dates
  DateTime labourActivityDate = DateTime.now();
  DateTime equipmentUsedDate = DateTime.now();
  DateTime inputUsedDate = DateTime.now();
  DateTime miscellaneousDate = DateTime.now();
  DateTime paymentDate = DateTime.now();

  // Cycle management
  String _currentCycle = 'Current Cycle';
  List<String> _pastCycles = [];
  String? _retrievedCycle;

  // Predefined cycle names
  static const List<String> predefinedCycleNames = ['Coffee Season'];

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

  Future<bool> hasShownStoragePopup() async {
    _prefs = await SharedPreferences.getInstance();
    return _prefs.getBool('hasShownStoragePopup') ?? false;
  }

  void setStoragePopupShown() async {
    _prefs = await SharedPreferences.getInstance();
    await _prefs.setBool('hasShownStoragePopup', true);
    _logger.i('Storage popup shown flag set to true');
  }

  Future<void> loadData(Function(bool, String?) callback) async {
    _logger.i('Starting loadData...');
    _prefs = await SharedPreferences.getInstance();

    bool isFirstLaunch = _prefs.getBool('isFirstLaunch') ?? true;
    _currentCycle = _prefs.getString('currentCycle') ?? 'Current Cycle';
    _pastCycles = _prefs.getStringList('pastCycles') ?? [];
    _logger.i('Loaded from SharedPreferences: currentCycle=$_currentCycle, pastCycles=$_pastCycles, isFirstLaunch=$isFirstLaunch');
    _loadCycleData(_currentCycle);
    callback(isFirstLaunch, _retrievedCycle);
  }

  void _loadCycleData(String cycle) {
    _logger.i('Loading cycle data for: $cycle');
    labourActivities = (_prefs.getString('labourActivities_$cycle') != null)
        ? List<Map<String, dynamic>>.from(jsonDecode(_prefs.getString('labourActivities_$cycle')!))
        : [];
    mechanicalCosts = (_prefs.getString('mechanicalCosts_$cycle') != null)
        ? List<Map<String, dynamic>>.from(jsonDecode(_prefs.getString('mechanicalCosts_$cycle')!))
        : [];
    inputCosts = (_prefs.getString('inputCosts_$cycle') != null)
        ? List<Map<String, dynamic>>.from(jsonDecode(_prefs.getString('inputCosts_$cycle')!))
        : [];
    miscellaneousCosts = (_prefs.getString('miscellaneousCosts_$cycle') != null)
        ? List<Map<String, dynamic>>.from(jsonDecode(_prefs.getString('miscellaneousCosts_$cycle')!))
        : [];
    revenues = (_prefs.getString('revenues_$cycle') != null)
        ? List<Map<String, dynamic>>.from(jsonDecode(_prefs.getString('revenues_$cycle')!))
        : [];
    paymentHistory = (_prefs.getString('paymentHistory_$cycle') != null)
        ? List<Map<String, dynamic>>.from(jsonDecode(_prefs.getString('paymentHistory_$cycle')!))
        : [];
    _logger.d('Cycle data loaded: labourActivities=${labourActivities.length}, mechanicalCosts=${mechanicalCosts.length}, inputCosts=${inputCosts.length}, miscellaneousCosts=${miscellaneousCosts.length}, revenues=${revenues.length}, paymentHistory=${paymentHistory.length}');
    _loadLoanData(cycle);
    calculateTotalProductionCost();
  }

  void calculateTotalProductionCost() {
    _logger.i('Calculating total production cost...');
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
    _logger.i('Total production cost: $totalCost');
    _calculateProfitLoss();
  }

  void _calculateProfitLoss() {
    _logger.i('Calculating profit/loss...');
    double totalCost = double.tryParse(totalProductionCostController.text) ?? 0;
    double totalRevenue = revenues.fold(
        0, (total, rev) => total + (double.tryParse(rev['amount'] ?? '0') ?? 0));
    double profitLoss = totalRevenue - totalCost;
    profitLossController.text = profitLoss.toStringAsFixed(2);
    _logger.i('Profit/Loss: $profitLoss');
  }

  void updateLoanCalculations() {
    _logger.i('Updating loan calculations...');
    double loanAmount = double.tryParse(loanAmountController.text) ?? 0;
    double interestRate = double.tryParse(interestRateController.text) ?? 0;
    double interest = (loanAmount * interestRate) / 100;
    double totalRepayment = loanAmount + interest;

    double paymentsMade = paymentHistory.fold(
        0.0, (total, payment) => total + (double.tryParse(payment['amount'] ?? '0') ?? 0));
    double remainingBalance = totalRepayment - paymentsMade;

    loanInterestController.text = interest.toStringAsFixed(2);
    totalRepaymentController.text = totalRepayment.toStringAsFixed(2);
    remainingBalanceController.text = remainingBalance.toStringAsFixed(2);

    _saveLoanData(_currentCycle, loanAmount, interestRate, interest, totalRepayment, remainingBalance);
    _logger.i('Loan calculations updated: loanAmount=$loanAmount, interest=$interest, totalRepayment=$totalRepayment, remainingBalance=$remainingBalance');
  }

  void _saveLoanData(String cycle, double loanAmount, double interestRate, double interest, double totalRepayment, double remainingBalance) {
    _logger.i('Saving loan data for cycle: $cycle');
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
    _logger.i('Loading loan data for cycle: $cycle');
    String? savedLoanData = _prefs.getString('loanData_$cycle');
    if (savedLoanData != null) {
      Map<String, dynamic> loanData = jsonDecode(savedLoanData);
      loanAmountController.text = (loanData['loanAmount'] ?? 0).toString();
      interestRateController.text = (loanData['interestRate'] ?? 0).toString();
      loanInterestController.text = (loanData['interest'] ?? 0).toStringAsFixed(2);
      totalRepaymentController.text = (loanData['totalRepayment'] ?? 0).toStringAsFixed(2);
      remainingBalanceController.text = (loanData['remainingBalance'] ?? (loanData['totalRepayment'] ?? 0)).toStringAsFixed(2);
      loanSourceController.text = loanData['loanSource'] ?? '';
      _logger.i('Loan data loaded: $loanData');
    } else {
      loanAmountController.clear();
      interestRateController.clear();
      loanInterestController.clear();
      totalRepaymentController.clear();
      remainingBalanceController.clear();
      loanSourceController.clear();
      _logger.i('No loan data found for cycle: $cycle');
    }
  }

  Future<void> syncToFirestore() async {
    _logger.i('Starting syncToFirestore...');
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      _logger.w('No user logged in. Cannot sync to Firestore.');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in to sync data')));
      }
      return;
    }

    _logger.i('User logged in with UID: $userId');
    try {
      WriteBatch batch = _firestore.batch();
      DocumentReference userDocRef = _firestore.collection('FarmData').doc(userId);

      // Validate JSON data before syncing
      Map<String, dynamic> cycleData = {
        'labourActivities': _validateJson(jsonEncode(labourActivities)),
        'mechanicalCosts': _validateJson(jsonEncode(mechanicalCosts)),
        'inputCosts': _validateJson(jsonEncode(inputCosts)),
        'miscellaneousCosts': _validateJson(jsonEncode(miscellaneousCosts)),
        'revenues': _validateJson(jsonEncode(revenues)),
        'paymentHistory': _validateJson(jsonEncode(paymentHistory)),
        'loanData': _validateJson(jsonEncode({
          'loanAmount': loanAmountController.text,
          'interestRate': interestRateController.text,
          'interest': loanInterestController.text,
          'totalRepayment': totalRepaymentController.text,
          'remainingBalance': remainingBalanceController.text,
          'loanSource': loanSourceController.text,
        })),
      };
      _logger.d('Cycle data for $_currentCycle: $cycleData');

      // Save user-level data
      batch.set(
          userDocRef,
          {
            'currentCycle': _currentCycle,
            'pastCycles': _pastCycles,
            'timestamp': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true));
      _logger.i('User-level data prepared for batch write');

      // Save cycle data
      List<String> allCycles = [_currentCycle, ..._pastCycles];
      for (String cycle in allCycles) {
        _logger.i('Preparing data for cycle: $cycle');
        Map<String, dynamic> cycleDataToSave = {
          'labourActivities': _validateJson(_prefs.getString('labourActivities_$cycle') ?? '[]'),
          'mechanicalCosts': _validateJson(_prefs.getString('mechanicalCosts_$cycle') ?? '[]'),
          'inputCosts': _validateJson(_prefs.getString('inputCosts_$cycle') ?? '[]'),
          'miscellaneousCosts': _validateJson(_prefs.getString('miscellaneousCosts_$cycle') ?? '[]'),
          'revenues': _validateJson(_prefs.getString('revenues_$cycle') ?? '[]'),
          'paymentHistory': _validateJson(_prefs.getString('paymentHistory_$cycle') ?? '[]'),
          'loanData': _validateJson(_prefs.getString('loanData_$cycle') ?? '{}'),
        };
        batch.set(
            userDocRef,
            {
              'cycles': {cycle: cycleDataToSave}
            },
            SetOptions(merge: true));
        _logger.i('Cycle data for $cycle added to batch');
      }

      await batch.commit();
      _logger.i('Batch write to Firestore completed successfully');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data synced to Firestore successfully')));
      }
    } catch (e, stackTrace) {
      String errorMessage = e is FirebaseException
          ? 'Firebase Error: ${e.code} - ${e.message}'
          : 'Unexpected error: $e';
      _logger.e('Error syncing to Firestore: $errorMessage', error: e, stackTrace: stackTrace);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to sync data: $errorMessage')));
      }
    }
  }

  Future<void> loadFromFirestore() async {
    _logger.i('Starting loadFromFirestore...');
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      _logger.w('No user logged in. Cannot load from Firestore.');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in to load data')));
      }
      return;
    }

    _logger.i('User logged in with UID: $userId');
    try {
      DocumentSnapshot doc = await _firestore.collection('FarmData').doc(userId).get();
      if (!doc.exists) {
        _logger.w('No data found in Firestore for UID: $userId');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No data found in Firestore')));
        }
        return;
      }

      Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
      if (data == null || !data.containsKey('cycles')) {
        _logger.w('No cycle data found in Firestore for UID: $userId');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No cycle data available')));
        }
        return;
      }

      _logger.i('User data retrieved from Firestore: ${data.keys}');
      _currentCycle = data['currentCycle'] ?? 'Current Cycle';
      _pastCycles = List<String>.from(data['pastCycles'] ?? []);
      await _prefs.setString('currentCycle', _currentCycle);
      await _prefs.setStringList('pastCycles', _pastCycles);
      _logger.i('Updated local state: currentCycle=$_currentCycle, pastCycles=$_pastCycles');

      Map<String, dynamic> cycles = data['cycles'] ?? {};
      for (String cycle in [_currentCycle, ..._pastCycles]) {
        if (cycles.containsKey(cycle)) {
          _logger.i('Loading data for cycle: $cycle');
          Map<String, dynamic> cycleData = cycles[cycle];
          await _prefs.setString('labourActivities_$cycle', jsonEncode(cycleData['labourActivities'] ?? []));
          await _prefs.setString('mechanicalCosts_$cycle', jsonEncode(cycleData['mechanicalCosts'] ?? []));
          await _prefs.setString('inputCosts_$cycle', jsonEncode(cycleData['inputCosts'] ?? []));
          await _prefs.setString('miscellaneousCosts_$cycle', jsonEncode(cycleData['miscellaneousCosts'] ?? []));
          await _prefs.setString('revenues_$cycle', jsonEncode(cycleData['revenues'] ?? []));
          await _prefs.setString('paymentHistory_$cycle', jsonEncode(cycleData['paymentHistory'] ?? []));
          await _prefs.setString('loanData_$cycle', jsonEncode(cycleData['loanData'] ?? {}));
          _logger.i('Cycle data for $cycle saved to SharedPreferences');
        } else {
          _logger.w('No data found for cycle: $cycle in Firestore');
        }
      }

      _loadCycleData(_currentCycle);
      _logger.i('Data loaded from Firestore successfully');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data loaded from Firestore successfully')));
      }
      onDataChanged();
    } catch (e, stackTrace) {
      String errorMessage = e is FirebaseException
          ? 'Firebase Error: ${e.code} - ${e.message}'
          : 'Unexpected error: $e';
      _logger.e('Error loading from Firestore: $errorMessage', error: e, stackTrace: stackTrace);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load data: $errorMessage')));
      }
    }
  }

  String _validateJson(String jsonString) {
    try {
      jsonDecode(jsonString);
      return jsonString;
    } catch (e) {
      _logger.w('Invalid JSON: $jsonString, error: $e');
      return jsonString.contains('[') ? '[]' : '{}';
    }
  }

  Future<void> _saveDataOnChange() async {
    _logger.i('Saving data to SharedPreferences...');
    await _prefs.setString('labourActivities_$_currentCycle', jsonEncode(labourActivities));
    await _prefs.setString('mechanicalCosts_$_currentCycle', jsonEncode(mechanicalCosts));
    await _prefs.setString('inputCosts_$_currentCycle', jsonEncode(inputCosts));
    await _prefs.setString('miscellaneousCosts_$_currentCycle', jsonEncode(miscellaneousCosts));
    await _prefs.setString('revenues_$_currentCycle', jsonEncode(revenues));
    await _prefs.setString('paymentHistory_$_currentCycle', jsonEncode(paymentHistory));
    await _prefs.setStringList('pastCycles', _pastCycles);
    await _prefs.setString('currentCycle', _currentCycle);
    _logger.i('Data saved to SharedPreferences for cycle: $_currentCycle');
    onDataChanged();
  }

  void saveForm() {
    _logger.i('Saving form...');
    if (labourActivities.isEmpty &&
        mechanicalCosts.isEmpty &&
        inputCosts.isEmpty &&
        miscellaneousCosts.isEmpty &&
        revenues.isEmpty &&
        paymentHistory.isEmpty &&
        loanAmountController.text.isEmpty) {
      _logger.w('No data to save');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter some data before saving')));
      }
      return;
    }
    _saveDataOnChange();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data Saved Successfully')));
    }
    _resetForm();
    _logger.i('Form saved successfully');
  }

  void _resetForm() {
    _logger.i('Resetting form...');
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
    _logger.i('Form reset completed');
  }

  Future<void> startNewCycle() async {
    _logger.i('Starting new cycle...');
    String? selectedCycleName;
    String customCycleName = '';
    int? selectedYear;
    if (context.mounted) {
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
                  ...predefinedCycleNames.map((name) => DropdownMenuItem(value: name, child: Text(name)))
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
                  _logger.i('Creating new cycle: $newCycleName');
                  _saveCurrentCycle(newCycleName);
                  Navigator.pop(context);
                } else {
                  _logger.w('Invalid cycle name or year');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a cycle name and year')));
                  }
                }
              },
              child: const Text('Start New'),
            ),
          ],
        ),
      );
    }
  }

  void _saveCurrentCycle(String newCycleName) {
    _logger.i('Saving current cycle and starting new: $newCycleName');
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
    _logger.i('New cycle started: $newCycleName, reset to currentCycle=$_currentCycle');
    onDataChanged();
  }

  Future<void> retrievePastCycle() async {
    _logger.i('Starting retrievePastCycle...');
    String? selectedCycleName;
    int? selectedYear;
    List<String> recentCycles = _pastCycles.take(3).toList();
    TextEditingController searchController = TextEditingController();
    bool useFirebase = false;

    if (context.mounted) {
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
                      items: predefinedCycleNames.map((name) => DropdownMenuItem(value: name, child: Text(name))).toList(),
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
                            _logger.i('Selected recent cycle: $cycle');
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
                          if (closestMatch.isNotEmpty && closestMatch != value && context.mounted) {
                            _logger.i('Found close match for search: $closestMatch');
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
                                        _logger.i('Retrieved cycle via search: $closestMatch');
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
                      _logger.i('Attempting to retrieve cycle: $cycleToRetrieve');
                      Navigator.pop(context);

                      if (_pastCycles.contains(cycleToRetrieve)) {
                        _retrievedCycle = cycleToRetrieve;
                        _loadCycleData(cycleToRetrieve);
                        _logger.i('Retrieved cycle locally: $cycleToRetrieve');
                        onDataChanged();
                      } else if (useFirebase) {
                        String? userId = FirebaseAuth.instance.currentUser?.uid;
                        if (userId == null) {
                          _logger.w('No user logged in for Firebase retrieval');
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('You must be logged in to fetch from Firebase')));
                          }
                          return;
                        }

                        try {
                          DocumentSnapshot doc = await _firestore.collection('farm_data').doc(userId).get();
                          if (!doc.exists) {
                            _logger.w('No data found in Firestore for UID: $userId');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('No data found for this user')));
                            }
                            return;
                          }
                          Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
                          if (data == null || !data.containsKey('cycles')) {
                            _logger.w('No cycle data found in Firestore for UID: $userId');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('No cycle data available')));
                            }
                            return;
                          }
                          Map<String, dynamic> cycles = data['cycles'];
                          if (cycles.containsKey(cycleToRetrieve)) {
                            _retrievedCycle = cycleToRetrieve;
                            labourActivities = List<Map<String, dynamic>>.from(cycles[cycleToRetrieve]['labourActivities'] ?? []);
                            mechanicalCosts = List<Map<String, dynamic>>.from(cycles[cycleToRetrieve]['mechanicalCosts'] ?? []);
                            inputCosts = List<Map<String, dynamic>>.from(cycles[cycleToRetrieve]['inputCosts'] ?? []);
                            miscellaneousCosts = List<Map<String, dynamic>>.from(cycles[cycleToRetrieve]['miscellaneousCosts'] ?? []);
                            revenues = List<Map<String, dynamic>>.from(cycles[cycleToRetrieve]['revenues'] ?? []);
                            paymentHistory = List<Map<String, dynamic>>.from(cycles[cycleToRetrieve]['paymentHistory'] ?? []);
                            await _prefs.setString('labourActivities_$cycleToRetrieve', jsonEncode(cycles[cycleToRetrieve]['labourActivities'] ?? []));
                            await _prefs.setString('mechanicalCosts_$cycleToRetrieve', jsonEncode(cycles[cycleToRetrieve]['mechanicalCosts'] ?? []));
                            await _prefs.setString('inputCosts_$cycleToRetrieve', jsonEncode(cycles[cycleToRetrieve]['inputCosts'] ?? []));
                            await _prefs.setString('miscellaneousCosts_$cycleToRetrieve', jsonEncode(cycles[cycleToRetrieve]['miscellaneousCosts'] ?? []));
                            await _prefs.setString('revenues_$cycleToRetrieve', jsonEncode(cycles[cycleToRetrieve]['revenues'] ?? []));
                            await _prefs.setString('paymentHistory_$cycleToRetrieve', jsonEncode(cycles[cycleToRetrieve]['paymentHistory'] ?? []));
                            await _prefs.setString('loanData_$cycleToRetrieve', jsonEncode(cycles[cycleToRetrieve]['loanData'] ?? {}));
                            _loadLoanData(cycleToRetrieve);
                            calculateTotalProductionCost();
                            _pastCycles.add(cycleToRetrieve);
                            await _prefs.setStringList('pastCycles', _pastCycles);
                            _logger.i('Retrieved cycle from Firestore: $cycleToRetrieve');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Data retrieved from Firebase')));
                            }
                            onDataChanged();
                          } else {
                            _logger.w('Cycle not found in Firestore: $cycleToRetrieve');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Cycle "$cycleToRetrieve" not found')));
                            }
                          }
                        } catch (e, stackTrace) {
                          String errorMessage = e is FirebaseException
                              ? 'Firebase Error: ${e.code} - ${e.message}'
                              : 'Unexpected error: $e';
                          _logger.e('Error fetching from Firestore: $errorMessage', error: e, stackTrace: stackTrace);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error fetching from Firebase: $errorMessage')));
                          }
                        }
                      } else {
                        _logger.w('Cycle not found locally: $cycleToRetrieve');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Cycle not found locally')));
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
  }

  void recordPayment() {
    _logger.i('Recording payment...');
    if (paymentAmountController.text.isNotEmpty) {
      final newPayment = {
        'amount': paymentAmountController.text,
        'date': paymentDate.toIso8601String().substring(0, 10),
        'remainingBalance': (double.tryParse(remainingBalanceController.text) ?? 0).toStringAsFixed(2),
      };
      paymentHistory.insert(0, newPayment);
      _saveDataOnChange();
      paymentAmountController.clear();
      paymentDate = DateTime.now();
      updateLoanCalculations();
      _logger.i('Payment recorded: $newPayment');
      onDataChanged();
    } else {
      _logger.w('Invalid payment amount');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a payment amount')));
      }
    }
  }

  List<String> getEquipmentSuggestions() {
    return mechanicalCosts.map((cost) => cost['equipment'] as String).toSet().toList();
  }

  List<String> getInputSuggestions() {
    return inputCosts.map((cost) => cost['input'] as String).toSet().toList();
  }

  Future<void> editCycleName(VoidCallback onCycleChanged) async {
    _logger.i('Starting editCycleName...');
    String? selectedCycleName;
    String customCycleName = '';
    int? selectedYear;
    if (context.mounted) {
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
                  ...predefinedCycleNames.map((name) => DropdownMenuItem(value: name, child: Text(name)))
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
                  _logger.i('Cycle name updated to: $_currentCycle');
                  _saveDataOnChange();
                  onCycleChanged();
                  Navigator.pop(context);
                } else {
                  _logger.w('Invalid cycle name or year');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a cycle name and year')));
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
    }
  }

  void addLabourCost() {
    _logger.i('Adding labour cost...');
    if (labourActivityController.text.isNotEmpty && labourCostController.text.isNotEmpty) {
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
      _logger.i('Labour cost added: $newActivity');
      onDataChanged();
    } else {
      _logger.w('Invalid labour activity or cost');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please fill in all labour fields')));
      }
    }
  }

  void addMechanicalCost() {
    _logger.i('Adding mechanical cost...');
    if (equipmentUsedController.text.isNotEmpty && equipmentCostController.text.isNotEmpty) {
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
      _logger.i('Mechanical cost added: $newCost');
      onDataChanged();
    } else {
      _logger.w('Invalid equipment or cost');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please fill in all equipment fields')));
      }
    }
  }

  void addInputCost() {
    _logger.i('Adding input cost...');
    if (inputUsedController.text.isNotEmpty && inputCostController.text.isNotEmpty) {
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
      _logger.i('Input cost added: $newCost');
      onDataChanged();
    } else {
      _logger.w('Invalid input or cost');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please fill in all input fields')));
      }
    }
  }

  void addMiscellaneousCost() {
    _logger.i('Adding miscellaneous cost...');
    if (miscellaneousDescController.text.isNotEmpty && miscellaneousCostController.text.isNotEmpty) {
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
      _logger.i('Miscellaneous cost added: $newCost');
      onDataChanged();
    } else {
      _logger.w('Invalid description or cost');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please fill in all miscellaneous fields')));
      }
    }
  }

  void addRevenue() {
    _logger.i('Adding revenue...');
    if (coffeeVarietyController.text.isNotEmpty && revenueController.text.isNotEmpty) {
      final newRevenue = {
        'coffeeVariety': coffeeVarietyController.text,
        'amount': revenueController.text,
        'date': DateTime.now().toIso8601String().substring(0, 10),
      };
      revenues.insert(0, newRevenue);
      _saveDataOnChange();
      coffeeVarietyController.clear();
      yieldController.clear();
      revenueController.clear();
      calculateTotalProductionCost();
      _logger.i('Revenue added: $newRevenue');
      onDataChanged();
    } else {
      _logger.w('Invalid coffee variety or revenue');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please fill in all revenue fields')));
      }
    }
  }

  void deleteActivity(String category, int index) {
    _logger.i('Deleting activity: category=$category, index=$index');
    switch (category) {
      case 'labour':
        if (index >= 0 && index < labourActivities.length) {
          labourActivities.removeAt(index);
        }
        break;
      case 'mechanical':
        if (index >= 0 && index < mechanicalCosts.length) {
          mechanicalCosts.removeAt(index);
        }
        break;
      case 'input':
        if (index >= 0 && index < inputCosts.length) {
          inputCosts.removeAt(index);
        }
        break;
      case 'miscellaneous':
        if (index >= 0 && index < miscellaneousCosts.length) {
          miscellaneousCosts.removeAt(index);
        }
        break;
      case 'revenue':
        if (index >= 0 && index < revenues.length) {
          revenues.removeAt(index);
        }
        break;
      case 'payment':
        if (index >= 0 && index < paymentHistory.length) {
          paymentHistory.removeAt(index);
        }
        break;
    }
    _saveDataOnChange();
    calculateTotalProductionCost();
    _logger.i('Activity deleted from $category at index $index');
    onDataChanged();
  }
}