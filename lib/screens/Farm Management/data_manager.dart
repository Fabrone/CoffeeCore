import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

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

  // Helper function to safely parse numeric values
  double _parseNumber(dynamic value, {double defaultValue = 0.0}) {
    if (value == null) return defaultValue;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  // Initialize default cycle data
  void _initializeDefaultCycle() {
    _logger.i('Initializing default cycle: Current Cycle');
    _currentCycle = 'Current Cycle';
    _pastCycles = [];
    labourActivities = [];
    mechanicalCosts = [];
    inputCosts = [];
    miscellaneousCosts = [];
    revenues = [];
    paymentHistory = [];
    loanAmountController.text = '0';
    interestRateController.text = '0';
    loanInterestController.text = '0.00';
    totalRepaymentController.text = '0.00';
    remainingBalanceController.text = '0.00';
    loanSourceController.text = '';
    totalProductionCostController.text = '0.00';
    profitLossController.text = '0.00';
    _resetForm();
  }

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

    // Check if Firestore has data; if not, initialize default cycle
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      QuerySnapshot cyclesSnapshot = await _firestore
          .collection('FarmData')
          .doc(userId)
          .collection('Cycles')
          .get();
      if (cyclesSnapshot.docs.isEmpty) {
        _logger.i('No cycles found in Firestore, initializing default cycle');
        _initializeDefaultCycle();
        await _prefs.setString('currentCycle', _currentCycle);
        await _prefs.setStringList('pastCycles', _pastCycles);
        await _prefs.setBool('isFirstLaunch', true);
        await syncToFirestore();
      }
    }

    _logger.i('Loaded from SharedPreferences: currentCycle=$_currentCycle, pastCycles=$_pastCycles, isFirstLaunch=$isFirstLaunch');
    await loadCycleData(_currentCycle);
    callback(isFirstLaunch, _currentCycle);
  }

  Future<void> loadCycleData(String cycle) async {
    _logger.i('Loading cycle data for: $cycle');
    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        // Try to load from Firestore first
        DocumentSnapshot cycleDoc = await _firestore
            .collection('FarmData')
            .doc(userId)
            .collection('Cycles')
            .doc(cycle)
            .get();
        if (cycleDoc.exists) {
          Map<String, dynamic> data = cycleDoc.data() as Map<String, dynamic>;
          labourActivities = List<Map<String, dynamic>>.from(data['labourActivities'] ?? []);
          mechanicalCosts = List<Map<String, dynamic>>.from(data['mechanicalCosts'] ?? []);
          inputCosts = List<Map<String, dynamic>>.from(data['inputCosts'] ?? []);
          miscellaneousCosts = List<Map<String, dynamic>>.from(data['miscellaneousCosts'] ?? []);
          revenues = List<Map<String, dynamic>>.from(data['revenues'] ?? []);
          paymentHistory = List<Map<String, dynamic>>.from(data['paymentHistory'] ?? []);
          Map<String, dynamic> loanData = Map<String, dynamic>.from(data['loanData'] ?? {});

          // Safely parse numeric fields
          loanAmountController.text = _parseNumber(loanData['loanAmount']).toString();
          interestRateController.text = _parseNumber(loanData['interestRate']).toString();
          loanInterestController.text = _parseNumber(loanData['interest']).toStringAsFixed(2);
          totalRepaymentController.text = _parseNumber(loanData['totalRepayment']).toStringAsFixed(2);
          remainingBalanceController.text = _parseNumber(loanData['remainingBalance']).toStringAsFixed(2);
          loanSourceController.text = loanData['loanSource']?.toString() ?? '';
          totalProductionCostController.text = _parseNumber(data['totalProductionCost']).toStringAsFixed(2);
          profitLossController.text = _parseNumber(data['profitLoss']).toStringAsFixed(2);

          // Save to SharedPreferences for offline access
          await _prefs.setString('labourActivities_$cycle', jsonEncode(labourActivities));
          await _prefs.setString('mechanicalCosts_$cycle', jsonEncode(mechanicalCosts));
          await _prefs.setString('inputCosts_$cycle', jsonEncode(inputCosts));
          await _prefs.setString('miscellaneousCosts_$cycle', jsonEncode(miscellaneousCosts));
          await _prefs.setString('revenues_$cycle', jsonEncode(revenues));
          await _prefs.setString('paymentHistory_$cycle', jsonEncode(paymentHistory));
          await _prefs.setString('loanData_$cycle', jsonEncode(loanData));
          _logger.i('Loaded cycle data from Firestore for $cycle');
        } else {
          // Fallback to SharedPreferences or initialize default cycle
          if (_prefs.getString('labourActivities_$cycle') != null) {
            labourActivities = validateJsonList(_prefs.getString('labourActivities_$cycle') ?? '[]');
            mechanicalCosts = validateJsonList(_prefs.getString('mechanicalCosts_$cycle') ?? '[]');
            inputCosts = validateJsonList(_prefs.getString('inputCosts_$cycle') ?? '[]');
            miscellaneousCosts = validateJsonList(_prefs.getString('miscellaneousCosts_$cycle') ?? '[]');
            revenues = validateJsonList(_prefs.getString('revenues_$cycle') ?? '[]');
            paymentHistory = validateJsonList(_prefs.getString('paymentHistory_$cycle') ?? '[]');
            _loadLoanData(cycle);
            _logger.i('Loaded cycle data from SharedPreferences for $cycle');
          } else {
            _logger.i('No data in SharedPreferences for $cycle, initializing default cycle');
            _initializeDefaultCycle();
            await _prefs.setString('currentCycle', _currentCycle);
            await syncToFirestore();
          }
        }
      } else {
        // Load from SharedPreferences if no user is logged in
        if (_prefs.getString('labourActivities_$cycle') != null) {
          labourActivities = validateJsonList(_prefs.getString('labourActivities_$cycle') ?? '[]');
          mechanicalCosts = validateJsonList(_prefs.getString('mechanicalCosts_$cycle') ?? '[]');
          inputCosts = validateJsonList(_prefs.getString('inputCosts_$cycle') ?? '[]');
          miscellaneousCosts = validateJsonList(_prefs.getString('miscellaneousCosts_$cycle') ?? '[]');
          revenues = validateJsonList(_prefs.getString('revenues_$cycle') ?? '[]');
          paymentHistory = validateJsonList(_prefs.getString('paymentHistory_$cycle') ?? '[]');
          _loadLoanData(cycle);
          _logger.i('Loaded cycle data from SharedPreferences for $cycle (no user logged in)');
        } else {
          _logger.i('No data in SharedPreferences for $cycle, initializing default cycle');
          _initializeDefaultCycle();
          await _prefs.setString('currentCycle', _currentCycle);
        }
      }
      _currentCycle = cycle;
      await _prefs.setString('currentCycle', _currentCycle);
      // Ensure pastCycles includes currentCycle if it's not already there
      if (!_pastCycles.contains(cycle) && cycle != 'Current Cycle') {
        _pastCycles.add(cycle);
        await _prefs.setStringList('pastCycles', _pastCycles);
      }
      calculateTotalProductionCost();
      _logger.d('Cycle data loaded successfully for cycle: $cycle');
      onDataChanged();
    } catch (e, stackTrace) {
      _logger.e('Error loading cycle data for $cycle: $e', error: e, stackTrace: stackTrace);
      _initializeDefaultCycle();
      await _prefs.setString('currentCycle', _currentCycle);
      await _prefs.setStringList('pastCycles', _pastCycles);
      calculateTotalProductionCost();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load cycle data: $e')));
      }
    }
  }

  void calculateTotalProductionCost() {
    _logger.i('Calculating total production cost...');
    double totalCost = labourActivities.fold<double>(
        0.0, (total, item) => total + (double.tryParse(item['cost'].toString()) ?? 0));
    totalCost += mechanicalCosts.fold<double>(
        0.0, (total, item) => total + (double.tryParse(item['cost'].toString()) ?? 0));
    totalCost += inputCosts.fold<double>(
        0.0, (total, item) => total + (double.tryParse(item['cost'].toString()) ?? 0));
    totalCost += miscellaneousCosts.fold<double>(
        0.0, (total, item) => total + (double.tryParse(item['cost'].toString()) ?? 0));
    totalProductionCostController.text = totalCost.toStringAsFixed(2);
    _logger.i('Total production cost: $totalCost');
    _calculateProfitLoss();
  }

  void _calculateProfitLoss() {
    _logger.i('Calculating profit/loss...');
    double totalCost = double.tryParse(totalProductionCostController.text) ?? 0;
    double totalRevenue = revenues.fold<double>(
        0.0, (total, item) => total + (double.tryParse(item['amount'].toString()) ?? 0));
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

    double paymentsMade = paymentHistory.fold<double>(
        0.0, (total, payment) => total + (double.tryParse(payment['amount'].toString()) ?? 0));
    double remainingBalance = totalRepayment - paymentsMade;

    loanInterestController.text = interest.toStringAsFixed(2);
    totalRepaymentController.text = totalRepayment.toStringAsFixed(2);
    remainingBalanceController.text = remainingBalance.toStringAsFixed(2);

    _saveLoanData(_currentCycle, loanAmount, interestRate, interest, totalRepayment, remainingBalance);
    _logger.i('Loan calculations updated: loanAmount=$loanAmount, interest=$interest, totalRepayment=$totalRepayment, remainingBalance=$remainingBalance');
  }

  void _saveLoanData(String cycle, double loanAmount, double interestRate, double interest, double totalRepayment, double remainingBalance) {
    _logger.i('Saving loan data for cycle: $cycle');
    try {
      final loanData = {
        'loanAmount': loanAmount,
        'interestRate': interestRate,
        'interest': interest,
        'totalRepayment': totalRepayment,
        'remainingBalance': remainingBalance,
        'loanSource': loanSourceController.text,
      };
      _prefs.setString('loanData_$cycle', jsonEncode(loanData));
      _saveDataOnChange();
      _logger.i('Loan data saved: $loanData');
    } catch (e, stackTrace) {
      _logger.e('Error saving loan data for $cycle: $e', error: e, stackTrace: stackTrace);
    }
  }

  void _loadLoanData(String cycle) {
    _logger.i('Loading loan data for cycle: $cycle');
    String? savedLoanData = _prefs.getString('loanData_$cycle');
    if (savedLoanData != null && savedLoanData.isNotEmpty) {
      try {
        dynamic decodedData = jsonDecode(savedLoanData);
        Map<String, dynamic> loanData;
        if (decodedData is String) {
          loanData = jsonDecode(decodedData) as Map<String, dynamic>;
        } else if (decodedData is Map) {
          loanData = Map<String, dynamic>.from(decodedData);
        } else {
          throw FormatException('Invalid loan data format: $decodedData');
        }

        loanAmountController.text = _parseNumber(loanData['loanAmount']).toString();
        interestRateController.text = _parseNumber(loanData['interestRate']).toString();
        loanInterestController.text = _parseNumber(loanData['interest']).toStringAsFixed(2);
        totalRepaymentController.text = _parseNumber(loanData['totalRepayment']).toStringAsFixed(2);
        remainingBalanceController.text = _parseNumber(loanData['remainingBalance']).toStringAsFixed(2);
        loanSourceController.text = loanData['loanSource']?.toString() ?? '';
        _logger.i('Loan data loaded: $loanData');
      } catch (e, stackTrace) {
        _logger.e('Error decoding loan data for $cycle: $e', error: e, stackTrace: stackTrace);
        loanAmountController.clear();
        interestRateController.clear();
        loanInterestController.clear();
        totalRepaymentController.text = '0.00';
        remainingBalanceController.text = '0.00';
        loanSourceController.clear();
      }
    } else {
      loanAmountController.clear();
      interestRateController.clear();
      loanInterestController.clear();
      totalRepaymentController.text = '0.00';
      remainingBalanceController.text = '0.00';
      loanSourceController.clear();
      _logger.i('No loan data found for cycle: $cycle');
    }
  }

  Future<Map<String, dynamic>?> loadFromFirestore() async {
    _logger.i('Starting loadFromFirestore...');
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      _logger.w('No user logged in. Cannot load from Firestore.');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in to load data')));
      }
      return null;
    }

    _logger.i('User logged in with UID: $userId');
    try {
      DocumentSnapshot userDoc = await _firestore.collection('FarmData').doc(userId).get();
      Map<String, dynamic> data = {};
      if (userDoc.exists) {
        data = userDoc.data() as Map<String, dynamic>? ?? {};
        _currentCycle = data['currentCycle'] ?? 'Current Cycle';
        _pastCycles = List<String>.from(data['pastCycles'] ?? []);
        await _prefs.setString('currentCycle', _currentCycle);
        await _prefs.setStringList('pastCycles', _pastCycles);
        _logger.i('Updated local state: currentCycle=$_currentCycle, pastCycles=$_pastCycles');
      }

      QuerySnapshot cyclesSnapshot = await _firestore
          .collection('FarmData')
          .doc(userId)
          .collection('Cycles')
          .get();
      Map<String, dynamic> cycles = {};
      for (var doc in cyclesSnapshot.docs) {
        String cycleName = doc.id;
        cycles[cycleName] = doc.data() as Map<String, dynamic>;
        await _prefs.setString('labourActivities_$cycleName', jsonEncode(cycles[cycleName]['labourActivities'] ?? []));
        await _prefs.setString('mechanicalCosts_$cycleName', jsonEncode(cycles[cycleName]['mechanicalCosts'] ?? []));
        await _prefs.setString('inputCosts_$cycleName', jsonEncode(cycles[cycleName]['inputCosts'] ?? []));
        await _prefs.setString('miscellaneousCosts_$cycleName', jsonEncode(cycles[cycleName]['miscellaneousCosts'] ?? []));
        await _prefs.setString('revenues_$cycleName', jsonEncode(cycles[cycleName]['revenues'] ?? []));
        await _prefs.setString('paymentHistory_$cycleName', jsonEncode(cycles[cycleName]['paymentHistory'] ?? []));
        await _prefs.setString('loanData_$cycleName', jsonEncode(cycles[cycleName]['loanData'] ?? {}));
        _logger.i('Cycle data for $cycleName saved to SharedPreferences');
      }

      _pastCycles = cycles.keys.where((cycle) => cycle != _currentCycle).toList();
      await _prefs.setStringList('pastCycles', _pastCycles);

      // If no cycles exist, initialize default cycle
      if (cycles.isEmpty) {
        _initializeDefaultCycle();
        await _prefs.setString('currentCycle', _currentCycle);
        await _prefs.setStringList('pastCycles', _pastCycles);
        await syncToFirestore();
      }

      await loadCycleData(_currentCycle);
      _logger.i('Data loaded from Firestore successfully');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data loaded from Firestore successfully')));
      }
      onDataChanged();
      return {'cycles': cycles};
    } catch (e, stackTrace) {
      _logger.e('Error loading from Firestore: $e', error: e, stackTrace: stackTrace);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load data: $e')));
      }
      return null;
    }
  }

  Future<void> syncToFirestore() async {
    _logger.i('Starting syncToFirestore...');
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      _logger.w('No user logged in. Cannot sync to Firestore.');
      return;
    }

    _logger.i('User logged in with UID: $userId');
    try {
      WriteBatch batch = _firestore.batch();
      DocumentReference userDocRef = _firestore.collection('FarmData').doc(userId);

      batch.set(
          userDocRef,
          {
            'currentCycle': _currentCycle,
            'pastCycles': _pastCycles,
            'timestamp': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true));
      _logger.i('User-level data prepared for batch write');

      Map<String, dynamic> cycleDataToSave = {
        'name': _currentCycle,
        'year': _currentCycle.split(' ').last,
        'labourActivities': labourActivities,
        'mechanicalCosts': mechanicalCosts,
        'inputCosts': inputCosts,
        'miscellaneousCosts': miscellaneousCosts,
        'revenues': revenues,
        'paymentHistory': paymentHistory,
        'loanData': {
          'loanAmount': double.tryParse(loanAmountController.text) ?? 0,
          'interestRate': double.tryParse(interestRateController.text) ?? 0,
          'interest': double.tryParse(loanInterestController.text) ?? 0,
          'totalRepayment': double.tryParse(totalRepaymentController.text) ?? 0,
          'remainingBalance': double.tryParse(remainingBalanceController.text) ?? 0,
          'loanSource': loanSourceController.text,
        },
        'totalProductionCost': double.tryParse(totalProductionCostController.text) ?? 0,
        'profitLoss': double.tryParse(profitLossController.text) ?? 0,
        'timestamp': FieldValue.serverTimestamp(),
      };
      DocumentReference cycleDocRef = userDocRef.collection('Cycles').doc(_currentCycle);
      batch.set(cycleDocRef, cycleDataToSave);
      _logger.i('Cycle data for $_currentCycle added to batch');

      await batch.commit();
      _logger.i('Batch write to Firestore completed successfully');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data synced to Firestore successfully')));
      }
    } catch (e, stackTrace) {
      _logger.e('Error syncing to Firestore: $e', error: e, stackTrace: stackTrace);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to sync data: $e')));
      }
    }
  }

  List<Map<String, dynamic>> validateJsonList(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString);
      return decoded is List
          ? List<Map<String, dynamic>>.from(
              decoded.map((item) => Map<String, dynamic>.from(item)))
          : [];
    } catch (e) {
      _logger.w('Invalid JSON list: $jsonString, error: $e');
      return [];
    }
  }

  Map<String, dynamic> validateJsonMap(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : {};
    } catch (e) {
      _logger.w('Invalid JSON map: $jsonString, error: $e');
      return {};
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
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Cycle Name',
                  hintText: 'e.g., Coffee Harvest',
                ),
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
              onPressed: () async {
                if (customCycleName.isNotEmpty && selectedYear != null) {
                  String newCycleName = '$customCycleName $selectedYear';
                  _logger.i('Creating new cycle: $newCycleName');
                  await _saveCurrentCycle(newCycleName);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
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

  Future<void> _saveCurrentCycle(String newCycleName) async {
    _logger.i('Saving current cycle and starting new: $newCycleName');
    // Save current cycle data before switching
    await _saveDataOnChange();
    if (_currentCycle != 'Current Cycle') {
      _pastCycles.add(_currentCycle);
    }
    await _prefs.setStringList('pastCycles', _pastCycles);

    // Initialize new cycle
    _currentCycle = newCycleName;
    await _prefs.setString('currentCycle', _currentCycle);
    labourActivities = [];
    mechanicalCosts = [];
    inputCosts = [];
    miscellaneousCosts = [];
    revenues = [];
    paymentHistory = [];
    loanAmountController.text = '0';
    interestRateController.text = '0';
    loanInterestController.text = '0.00';
    totalRepaymentController.text = '0.00';
    remainingBalanceController.text = '0.00';
    loanSourceController.text = '';
    totalProductionCostController.text = '0.00';
    profitLossController.text = '0.00';

    // Save initialized data to SharedPreferences
    await _prefs.setString('labourActivities_$_currentCycle', jsonEncode(labourActivities));
    await _prefs.setString('mechanicalCosts_$_currentCycle', jsonEncode(mechanicalCosts));
    await _prefs.setString('inputCosts_$_currentCycle', jsonEncode(inputCosts));
    await _prefs.setString('miscellaneousCosts_$_currentCycle', jsonEncode(miscellaneousCosts));
    await _prefs.setString('revenues_$_currentCycle', jsonEncode(revenues));
    await _prefs.setString('paymentHistory_$_currentCycle', jsonEncode(paymentHistory));
    await _prefs.setString('loanData_$_currentCycle', jsonEncode({
      'loanAmount': 0,
      'interestRate': 0,
      'interest': 0,
      'totalRepayment': 0,
      'remainingBalance': 0,
      'loanSource': '',
    }));
    await _prefs.setBool('isFirstLaunch', true);

    _resetForm();
    calculateTotalProductionCost();
    await syncToFirestore();
    _logger.i('New cycle started: $newCycleName');
    onDataChanged();
  }

  Future<void> retrievePastCycle() async {
    _logger.i('Starting retrievePastCycle...');
    String searchQuery = '';
    TextEditingController searchController = TextEditingController();
    List<String> cycleNames = [];

    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      try {
        QuerySnapshot cyclesSnapshot = await _firestore
            .collection('FarmData')
            .doc(userId)
            .collection('Cycles')
            .get();
        cycleNames = cyclesSnapshot.docs.map((doc) => doc.id).toList();
        _pastCycles = cycleNames.where((cycle) => cycle != _currentCycle).toList();
        await _prefs.setStringList('pastCycles', _pastCycles);
      } catch (e) {
        _logger.e('Error fetching cycles from Firestore: $e');
      }
    }

    if (context.mounted) {
      await showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (BuildContext context, StateSetter dialogSetState) {
            return AlertDialog(
              title: const Text('Retrieve Past Cycle'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search Cycle Name',
                      hintText: 'e.g., Coffee Harvest 2025',
                    ),
                    onChanged: (value) {
                      searchQuery = value;
                      dialogSetState(() {});
                    },
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      itemCount: cycleNames
                          .where((cycle) => cycle.toLowerCase().contains(searchQuery.toLowerCase()))
                          .length,
                      itemBuilder: (context, index) {
                        String cycle = cycleNames
                            .where((cycle) => cycle.toLowerCase().contains(searchQuery.toLowerCase()))
                            .elementAt(index);
                        return ListTile(
                          title: Text(cycle),
                          onTap: () async {
                            _logger.i('Selected cycle: $cycle');
                            Navigator.pop(context);
                            await loadCycleData(cycle);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        ),
      );
    }
    if (searchQuery.isNotEmpty && !_pastCycles.any((cycle) => cycle.toLowerCase().contains(searchQuery.toLowerCase())) && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No cycle found matching "$searchQuery"')));
    }
  }

  Future<void> editCycleName(VoidCallback onCycleChanged) async {
    _logger.i('Starting editCycleName...');
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
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Cycle Name',
                  hintText: 'e.g., Coffee Harvest',
                ),
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
              onPressed: () async {
                if (customCycleName.isNotEmpty && selectedYear != null) {
                  String newCycleName = '$customCycleName $selectedYear';
                  _logger.i('Updating cycle name to: $newCycleName');
                  await _saveDataOnChange();
                  await _prefs.setString('labourActivities_$newCycleName', jsonEncode(labourActivities));
                  await _prefs.setString('mechanicalCosts_$newCycleName', jsonEncode(mechanicalCosts));
                  await _prefs.setString('inputCosts_$newCycleName', jsonEncode(inputCosts));
                  await _prefs.setString('miscellaneousCosts_$newCycleName', jsonEncode(miscellaneousCosts));
                  await _prefs.setString('revenues_$newCycleName', jsonEncode(revenues));
                  await _prefs.setString('paymentHistory_$newCycleName', jsonEncode(paymentHistory));
                  await _prefs.setString('loanData_$newCycleName', _prefs.getString('loanData_$_currentCycle') ?? '{}');
                  await _prefs.remove('labourActivities_$_currentCycle');
                  await _prefs.remove('mechanicalCosts_$_currentCycle');
                  await _prefs.remove('inputCosts_$_currentCycle');
                  await _prefs.remove('miscellaneousCosts_$_currentCycle');
                  await _prefs.remove('revenues_$_currentCycle');
                  await _prefs.remove('paymentHistory_$_currentCycle');
                  await _prefs.remove('loanData_$_currentCycle');
                  _pastCycles.remove(_currentCycle);
                  _pastCycles.add(newCycleName);
                  await _prefs.setStringList('pastCycles', _pastCycles);
                  _currentCycle = newCycleName;
                  await _prefs.setString('currentCycle', _currentCycle);
                  await _prefs.setBool('isFirstLaunch', false);
                  await _saveDataOnChange();
                  await syncToFirestore();
                  _logger.i('Cycle name updated to: $_currentCycle');
                  onCycleChanged();
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
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
        'yield': yieldController.text.isNotEmpty ? yieldController.text : null,
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

  Future<void> editActivity(String category, int index, Map<String, dynamic> updatedData) async {
    _logger.i('Editing activity: category=$category, index=$index');
    try {
      switch (category) {
        case 'labour':
          if (index >= 0 && index < labourActivities.length) {
            labourActivities[index] = {
              'activity': updatedData['activity'] ?? labourActivities[index]['activity'],
              'cost': updatedData['cost'] ?? labourActivities[index]['cost'],
              'date': updatedData['date'] ?? labourActivities[index]['date'],
            };
          }
          break;
        case 'mechanical':
          if (index >= 0 && index < mechanicalCosts.length) {
            mechanicalCosts[index] = {
              'equipment': updatedData['equipment'] ?? mechanicalCosts[index]['equipment'],
              'cost': updatedData['cost'] ?? mechanicalCosts[index]['cost'],
              'date': updatedData['date'] ?? mechanicalCosts[index]['date'],
            };
          }
          break;
        case 'input':
          if (index >= 0 && index < inputCosts.length) {
            inputCosts[index] = {
              'input': updatedData['input'] ?? inputCosts[index]['input'],
              'cost': updatedData['cost'] ?? inputCosts[index]['cost'],
              'date': updatedData['date'] ?? inputCosts[index]['date'],
            };
          }
          break;
        case 'miscellaneous':
          if (index >= 0 && index < miscellaneousCosts.length) {
            miscellaneousCosts[index] = {
              'description': updatedData['description'] ?? miscellaneousCosts[index]['description'],
              'cost': updatedData['cost'] ?? miscellaneousCosts[index]['cost'],
              'date': updatedData['date'] ?? miscellaneousCosts[index]['date'],
            };
          }
          break;
        case 'revenue':
          if (index >= 0 && index < revenues.length) {
            revenues[index] = {
              'coffeeVariety': updatedData['coffeeVariety'] ?? revenues[index]['coffeeVariety'],
              'amount': updatedData['amount'] ?? revenues[index]['amount'],
              'yield': updatedData['yield'] ?? revenues[index]['yield'],
              'date': updatedData['date'] ?? revenues[index]['date'],
            };
          }
          break;
        case 'payment':
          if (index >= 0 && index < paymentHistory.length) {
            paymentHistory[index] = {
              'amount': updatedData['amount'] ?? paymentHistory[index]['amount'],
              'date': updatedData['date'] ?? paymentHistory[index]['date'],
              'remainingBalance': updatedData['remainingBalance'] ?? paymentHistory[index]['remainingBalance'],
            };
          }
          break;
      }
      await _saveDataOnChange();
      calculateTotalProductionCost();
      _logger.i('Activity edited: $category at index $index');
      onDataChanged();
    } catch (e) {
      _logger.e('Error editing activity: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to edit activity: $e')));
      }
    }
  }
}