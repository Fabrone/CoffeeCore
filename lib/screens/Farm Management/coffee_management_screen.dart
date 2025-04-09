import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'activities_screen.dart';
import 'history_screen.dart';
import 'package:coffeecore/home.dart'; 

class CoffeeManagementScreen extends StatefulWidget {
  const CoffeeManagementScreen({super.key});

  @override
  State<CoffeeManagementScreen> createState() => _CoffeeManagementScreenState();
}

class _CoffeeManagementScreenState extends State<CoffeeManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late SharedPreferences _prefs;
  bool _isLoading = true;
  bool _isFirstLaunch = true;
  String? _retrievedCycle;

  final _labourActivityController = TextEditingController();
  final _labourCostController = TextEditingController();
  DateTime _labourActivityDate = DateTime.now();
  final _equipmentUsedController = TextEditingController();
  final _equipmentCostController = TextEditingController();
  DateTime _equipmentUsedDate = DateTime.now();
  final _inputUsedController = TextEditingController();
  final _inputCostController = TextEditingController();
  DateTime _inputUsedDate = DateTime.now();
  final _miscellaneousDescController = TextEditingController();
  final _miscellaneousCostController = TextEditingController();
  DateTime _miscellaneousDate = DateTime.now();
  final _cropGrownController = TextEditingController();
  final _revenueController = TextEditingController();
  final _totalProductionCostController = TextEditingController();
  final _profitLossController = TextEditingController();
  final _loanAmountController = TextEditingController();
  final _interestRateController = TextEditingController();
  final _loanInterestController = TextEditingController();
  final _totalRepaymentController = TextEditingController();
  final _remainingBalanceController = TextEditingController();
  final _paymentAmountController = TextEditingController();
  DateTime _paymentDate = DateTime.now();

  List<Map<String, dynamic>> _labourActivities = [];
  List<Map<String, dynamic>> _mechanicalCosts = [];
  List<Map<String, dynamic>> _inputCosts = [];
  List<Map<String, dynamic>> _miscellaneousCosts = [];
  List<Map<String, dynamic>> _revenues = [];
  List<Map<String, dynamic>> _paymentHistory = [];

  String _currentCycle = 'Current Cycle';
  List<String> _pastCycles = [];
  static const List<String> _predefinedCycleNames = ['Coffee Season'];

  static const Color customBrown = Color(0xFF4E2D00);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowStoragePopup();
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _isFirstLaunch = _prefs.getBool('isFirstLaunch') ?? true;
      _currentCycle = _prefs.getString('currentCycle') ?? 'Current Cycle';
      _pastCycles = _prefs.getStringList('pastCycles') ?? [];
      _loadCycleData(_currentCycle);
      _isLoading = false;
    });
  }

  void _loadCycleData(String cycle) {
    setState(() {
      _labourActivities = (_prefs.getString('labourActivities_$cycle') != null)
          ? List<Map<String, dynamic>>.from(
              jsonDecode(_prefs.getString('labourActivities_$cycle')!))
          : [];
      _mechanicalCosts = (_prefs.getString('mechanicalCosts_$cycle') != null)
          ? List<Map<String, dynamic>>.from(
              jsonDecode(_prefs.getString('mechanicalCosts_$cycle')!))
          : [];
      _inputCosts = (_prefs.getString('inputCosts_$cycle') != null)
          ? List<Map<String, dynamic>>.from(
              jsonDecode(_prefs.getString('inputCosts_$cycle')!))
          : [];
      _miscellaneousCosts =
          (_prefs.getString('miscellaneousCosts_$cycle') != null)
              ? List<Map<String, dynamic>>.from(
                  jsonDecode(_prefs.getString('miscellaneousCosts_$cycle')!))
              : [];
      _revenues = (_prefs.getString('revenues_$cycle') != null)
          ? List<Map<String, dynamic>>.from(
              jsonDecode(_prefs.getString('revenues_$cycle')!))
          : [];
      _paymentHistory = (_prefs.getString('paymentHistory_$cycle') != null)
          ? List<Map<String, dynamic>>.from(
              jsonDecode(_prefs.getString('paymentHistory_$cycle')!))
          : [];
      _loadLoanData(cycle);
      _calculateTotalProductionCost();
      _calculateProfitLoss();
    });
  }

  void _calculateTotalProductionCost() {
    double totalCost = 0;
    for (var item in _labourActivities) {
      totalCost += double.tryParse(item['cost'] ?? '0') ?? 0;
    }
    for (var item in _mechanicalCosts) {
      totalCost += double.tryParse(item['cost'] ?? '0') ?? 0;
    }
    for (var item in _inputCosts) {
      totalCost += double.tryParse(item['cost'] ?? '0') ?? 0;
    }
    for (var item in _miscellaneousCosts) {
      totalCost += double.tryParse(item['cost'] ?? '0') ?? 0;
    }
    _totalProductionCostController.text = totalCost.toStringAsFixed(2);
    _calculateProfitLoss();
  }

  void _calculateProfitLoss() {
    double totalCost = double.tryParse(_totalProductionCostController.text) ?? 0;
    double totalRevenue = _revenues.fold(
        0, (acc, rev) => acc + (double.tryParse(rev['amount'] ?? '0') ?? 0));
    double profitLoss = totalRevenue - totalCost;
    _profitLossController.text = profitLoss.toStringAsFixed(2);
  }

  void _updateLoanCalculations() {
    double loanAmount = double.tryParse(_loanAmountController.text) ?? 0;
    double interestRate = double.tryParse(_interestRateController.text) ?? 0;
    double interest = (loanAmount * interestRate) / 100;
    double totalRepayment = loanAmount + interest;

    double paymentsMade = _paymentHistory.fold(
        0.0,
        (acc, payment) =>
            acc + (double.tryParse(payment['amount'] ?? '0') ?? 0));
    double remainingBalance = totalRepayment - paymentsMade;

    _loanInterestController.text = interest.toStringAsFixed(2);
    _totalRepaymentController.text = totalRepayment.toStringAsFixed(2);
    _remainingBalanceController.text = remainingBalance.toStringAsFixed(2);

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
        }));
  }

  void _loadLoanData(String cycle) {
    String? savedLoanData = _prefs.getString('loanData_$cycle');
    if (savedLoanData != null) {
      Map<String, dynamic> loanData = jsonDecode(savedLoanData);
      _loanAmountController.text = (loanData['loanAmount'] ?? 0).toString();
      _interestRateController.text = (loanData['interestRate'] ?? 0).toString();
      _loanInterestController.text =
          (loanData['interest'] ?? 0).toStringAsFixed(2);
      _totalRepaymentController.text =
          (loanData['totalRepayment'] ?? 0).toStringAsFixed(2);
      _remainingBalanceController.text =
          (loanData['remainingBalance'] ?? (loanData['totalRepayment'] ?? 0))
              .toStringAsFixed(2);
    }
  }

  void _recordPayment() {
    double paymentAmount = double.tryParse(_paymentAmountController.text) ?? 0;
    double remainingBalance =
        double.tryParse(_remainingBalanceController.text) ?? 0;

    if (paymentAmount > 0 && paymentAmount <= remainingBalance) {
      remainingBalance -= paymentAmount;
      _remainingBalanceController.text = remainingBalance.toStringAsFixed(2);

      final newPayment = {
        'date': _paymentDate.toIso8601String().substring(0, 10),
        'amount': paymentAmount.toString(),
        'remainingBalance': remainingBalance.toString(),
      };
      setState(() {
        _paymentHistory.insert(0, newPayment);
        _saveDataOnChange();
        _paymentAmountController.clear();
        _paymentDate = DateTime.now();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid payment amount')));
    }
  }

  void _saveDataOnChange() {
    _prefs.setString(
        'labourActivities_$_currentCycle', jsonEncode(_labourActivities));
    _prefs.setString(
        'mechanicalCosts_$_currentCycle', jsonEncode(_mechanicalCosts));
    _prefs.setString('inputCosts_$_currentCycle', jsonEncode(_inputCosts));
    _prefs.setString(
        'miscellaneousCosts_$_currentCycle', jsonEncode(_miscellaneousCosts));
    _prefs.setString('revenues_$_currentCycle', jsonEncode(_revenues));
    _prefs.setString(
        'paymentHistory_$_currentCycle', jsonEncode(_paymentHistory));
    _saveLoanData(
        _currentCycle,
        double.tryParse(_loanAmountController.text) ?? 0,
        double.tryParse(_interestRateController.text) ?? 0,
        double.tryParse(_loanInterestController.text) ?? 0,
        double.tryParse(_totalRepaymentController.text) ?? 0,
        double.tryParse(_remainingBalanceController.text) ?? 0);
  }

  void _saveForm() {
    if (_labourActivities.isEmpty &&
        _mechanicalCosts.isEmpty &&
        _inputCosts.isEmpty &&
        _miscellaneousCosts.isEmpty &&
        _revenues.isEmpty &&
        _paymentHistory.isEmpty &&
        _loanAmountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter some data before saving')));
    } else {
      _saveDataOnChange();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data Saved Successfully')));
      _resetForm();
    }
  }

  void _resetForm() {
    setState(() {
      _labourActivityController.clear();
      _labourCostController.clear();
      _labourActivityDate = DateTime.now();
      _equipmentUsedController.clear();
      _equipmentCostController.clear();
      _equipmentUsedDate = DateTime.now();
      _inputUsedController.clear();
      _inputCostController.clear();
      _inputUsedDate = DateTime.now();
      _miscellaneousDescController.clear();
      _miscellaneousCostController.clear();
      _miscellaneousDate = DateTime.now();
      _cropGrownController.clear();
      _revenueController.clear();
      _paymentAmountController.clear();
      _paymentDate = DateTime.now();
    });
  }

  Future<void> _startNewCycle() async {
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
                ..._predefinedCycleNames
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
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Please enter a cycle name and year')));
              }
            },
            child: const Text('Start New'),
          ),
        ],
      ),
    );
  }

  void _saveCurrentCycle(String newCycleName) {
    setState(() {
      _saveDataOnChange();
      _pastCycles.add(newCycleName);
      _prefs.setStringList('pastCycles', _pastCycles);

      _currentCycle = 'Current Cycle';
      _prefs.setString('currentCycle', _currentCycle);
      _labourActivities.clear();
      _mechanicalCosts.clear();
      _inputCosts.clear();
      _miscellaneousCosts.clear();
      _revenues.clear();
      _paymentHistory.clear();
      _prefs.remove('labourActivities_$_currentCycle');
      _prefs.remove('mechanicalCosts_$_currentCycle');
      _prefs.remove('inputCosts_$_currentCycle');
      _prefs.remove('miscellaneousCosts_$_currentCycle');
      _prefs.remove('revenues_$_currentCycle');
      _prefs.remove('paymentHistory_$_currentCycle');
      _prefs.remove('loanData_$_currentCycle');

      _resetForm();
      _calculateTotalProductionCost();
      _retrievedCycle = null;
    });
  }

  Future<void> _retrievePastCycle() async {
    String? selectedCycleName;
    int? selectedYear;
    List<String> recentCycles = _pastCycles.take(3).toList();
    TextEditingController searchController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retrieve Past Cycle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration:
                    const InputDecoration(labelText: 'Cycle Name', hintText: 'Select Cycle'),
                items: _predefinedCycleNames
                    .map((name) => DropdownMenuItem(value: name, child: Text(name)))
                    .toList(),
                onChanged: (value) => selectedCycleName = value,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Year'),
                keyboardType: TextInputType.number,
                onChanged: (value) => selectedYear = int.tryParse(value),
              ),
              const SizedBox(height: 10),
              const Text('Recent Cycles:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...recentCycles.map((cycle) => ListTile(
                    title: Text(cycle),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _retrievedCycle = cycle;
                        _loadCycleData(cycle);
                      });
                    },
                  )),
              const SizedBox(height: 10),
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Text('Did you mean '),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                  setState(() {
                                    _retrievedCycle = closestMatch;
                                    _loadCycleData(closestMatch);
                                  });
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
            onPressed: () {
              if (selectedCycleName != null && selectedYear != null) {
                String cycleToRetrieve = '$selectedCycleName $selectedYear';
                if (_pastCycles.contains(cycleToRetrieve)) {
                  Navigator.pop(context);
                  setState(() {
                    _retrievedCycle = cycleToRetrieve;
                    _loadCycleData(cycleToRetrieve);
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No such data found')));
                }
              }
            },
            child: const Text('Retrieve'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkAndShowStoragePopup() async {
    bool hasShownPopup = _prefs.getBool('hasShownPopup') ?? false;
    if (!hasShownPopup) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: Row(
              children: [
                Icon(Icons.lock, color: customBrown, size: 24),
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
                  'Good news! Your financial info is stored only on this device.',
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
                  _prefs.setBool('hasShownPopup', true);
                },
                child: Text('Got It',
                    style: TextStyle(color: customBrown, fontWeight: FontWeight.bold)),
              ),
              TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('More Info'),
                      content: const Text(
                        'Your costs, revenues, and loans are saved locally using SharedPreferences. '
                        'You can also sync to Firestore for backup. '
                        'For security, avoid lending your device or use a passcode.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK', style: TextStyle(color: customBrown)),
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
  }

  List<String> _getEquipmentSuggestions() {
    return _mechanicalCosts
        .map((cost) => cost['equipment'] as String)
        .toSet()
        .toList();
  }

  List<String> _getInputSuggestions() {
    return _inputCosts.map((cost) => cost['input'] as String).toSet().toList();
  }

  Future<void> _editCycleName() async {
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
                ..._predefinedCycleNames
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
            onPressed: () {
              if ((selectedCycleName != null && selectedYear != null) &&
                  (selectedCycleName!.isNotEmpty || customCycleName.isNotEmpty)) {
                setState(() {
                  _currentCycle = selectedCycleName!.isEmpty
                      ? '$customCycleName $selectedYear'
                      : '$selectedCycleName $selectedYear';
                  _prefs.setString('currentCycle', _currentCycle);
                  _prefs.setBool('isFirstLaunch', false);
                  _isFirstLaunch = false;
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> syncToFirestore() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to sync data')));
      return;
    }

    String uid = user.uid;
    CollectionReference cycles =
        FirebaseFirestore.instance.collection('Users/$uid/Farm Cycles');

    await FirebaseFirestore.instance.collection('Users').doc(uid).set({
      'currentCycle': _currentCycle,
      'pastCycles': _pastCycles,
    });

    List<String> allCycles = [_currentCycle, ..._pastCycles];
    for (String cycle in allCycles) {
      Map<String, dynamic> cycleData = {
        'labourActivities': _prefs.getString('labourActivities_$cycle') ?? '[]',
        'mechanicalCosts': _prefs.getString('mechanicalCosts_$cycle') ?? '[]',
        'inputCosts': _prefs.getString('inputCosts_$cycle') ?? '[]',
        'miscellaneousCosts':
            _prefs.getString('miscellaneousCosts_$cycle') ?? '[]',
        'revenues': _prefs.getString('revenues_$cycle') ?? '[]',
        'paymentHistory': _prefs.getString('paymentHistory_$cycle') ?? '[]',
        'loanData': _prefs.getString('loanData_$cycle') ?? '{}',
      };
      await cycles.doc(cycle).set(cycleData);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data synced to Firestore successfully')));
    }
  }

  Future<void> loadFromFirestore() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to load data')));
      return;
    }

    String uid = user.uid;
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('Users').doc(uid).get();
    if (!userDoc.exists) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No data found in Firestore')));
      }
      return;
    }

    setState(() {
      _currentCycle = userDoc['currentCycle'];
      _pastCycles = List<String>.from(userDoc['pastCycles']);
      _prefs.setString('currentCycle', _currentCycle);
      _prefs.setStringList('pastCycles', _pastCycles);
    });

    CollectionReference cycles =
        FirebaseFirestore.instance.collection('Users/$uid/Farm Cycles');
    for (String cycle in [_currentCycle, ..._pastCycles]) {
      DocumentSnapshot cycleDoc = await cycles.doc(cycle).get();
      if (cycleDoc.exists) {
        Map<String, dynamic> data = cycleDoc.data() as Map<String, dynamic>;
        _prefs.setString('labourActivities_$cycle', data['labourActivities']);
        _prefs.setString('mechanicalCosts_$cycle', data['mechanicalCosts']);
        _prefs.setString('inputCosts_$cycle', data['inputCosts']);
        _prefs.setString('miscellaneousCosts_$cycle', data['miscellaneousCosts']);
        _prefs.setString('revenues_$cycle', data['revenues']);
        _prefs.setString('paymentHistory_$cycle', data['paymentHistory']);
        _prefs.setString('loanData_$cycle', data['loanData']);
      }
    }

    _loadCycleData(_currentCycle);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data loaded from Firestore successfully')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          },
        ),
        title: const Text(
          'Coffee Farm Management',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: customBrown,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_edu, color: Colors.white),
            tooltip: 'View History',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HistoryScreen(
                  labourActivities: _labourActivities,
                  mechanicalCosts: _mechanicalCosts,
                  inputCosts: _inputCosts,
                  miscellaneousCosts: _miscellaneousCosts,
                  revenues: _revenues,
                  paymentHistory: _paymentHistory,
                  cycleName: _currentCycle,
                  pastCycles: _pastCycles,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            tooltip: 'Save Current Cycle',
            onPressed: _saveForm,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            tooltip: 'Start New Cycle',
            onPressed: _startNewCycle,
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            tooltip: 'Retrieve Past Cycle',
            onPressed: _retrievePastCycle,
          ),
          IconButton(
            icon: const Icon(Icons.cloud_upload, color: Colors.white),
            tooltip: 'Sync to Cloud',
            onPressed: syncToFirestore,
          ),
          IconButton(
            icon: const Icon(Icons.cloud_download, color: Colors.white),
            tooltip: 'Load from Cloud',
            onPressed: loadFromFirestore,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Dashboard', icon: Icon(Icons.dashboard)),
            Tab(text: 'Costs', icon: Icon(Icons.money_off)),
            Tab(text: 'Revenue', icon: Icon(Icons.attach_money)),
            Tab(text: 'Profit/Loss', icon: Icon(Icons.account_balance)),
            Tab(text: 'Loans', icon: Icon(Icons.account_balance_wallet)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Dashboard - ${_retrievedCycle ?? _currentCycle}',
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: customBrown),
                          ),
                          if (_isFirstLaunch)
                            IconButton(
                              icon: const Icon(Icons.edit, color: customBrown),
                              onPressed: () {
                                _editCycleName();
                              },
                            ),
                        ],
                      ),
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sections: [
                              PieChartSectionData(
                                value: _labourActivities.fold(
                                    0.0,
                                    (acc, item) =>
                                        acc! +
                                        (double.tryParse(item['cost'] ?? '0') ?? 0)),
                                color: Colors.red,
                                title: 'Labour',
                              ),
                              PieChartSectionData(
                                value: _mechanicalCosts.fold(
                                    0.0,
                                    (acc, item) =>
                                        acc! +
                                        (double.tryParse(item['cost'] ?? '0') ?? 0)),
                                color: Colors.blue,
                                title: 'Equipment',
                              ),
                              PieChartSectionData(
                                value: _inputCosts.fold(
                                    0.0,
                                    (acc, item) =>
                                        acc! +
                                        (double.tryParse(item['cost'] ?? '0') ?? 0)),
                                color: Colors.orange,
                                title: 'Inputs',
                              ),
                              PieChartSectionData(
                                value: _miscellaneousCosts.fold(
                                    0.0,
                                    (acc, item) =>
                                        acc! +
                                        (double.tryParse(item['cost'] ?? '0') ?? 0)),
                                color: Colors.grey,
                                title: 'Misc',
                              ),
                              PieChartSectionData(
                                value: _revenues.fold(
                                    0.0,
                                    (acc, item) =>
                                        acc! +
                                        (double.tryParse(item['amount'] ?? '0') ?? 0)),
                                color: Colors.green,
                                title: 'Revenue',
                              ),
                              PieChartSectionData(
                                value:
                                    (double.tryParse(_profitLossController.text) ?? 0)
                                        .abs(),
                                color: (double.tryParse(_profitLossController.text) ??
                                            0) >=
                                        0
                                    ? Colors.purple
                                    : Colors.grey,
                                title:
                                    (double.tryParse(_profitLossController.text) ?? 0) >=
                                            0
                                        ? 'Profit'
                                        : 'Loss',
                              ),
                            ],
                          ),
                        ),
                      ),
                      Card(
                          child: ListTile(
                              title: const Text('Total Costs'),
                              subtitle:
                                  Text('KSH ${_totalProductionCostController.text}'))),
                      Card(
                          child: ListTile(
                              title: const Text('Total Revenue'),
                              subtitle: Text(
                                  'KSH ${_revenues.fold(0.0, (acc, item) => acc + (double.tryParse(item['amount'] ?? '0') ?? 0)).toStringAsFixed(2)}'))),
                      Card(
                          child: ListTile(
                              title: const Text('Profit/Loss'),
                              subtitle: Text('KSH ${_profitLossController.text}'))),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Card(
                        color: Colors.red[100],
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Text('Coffee Farm Activity Costs',
                                  style:
                                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              TextFormField(
                                controller: _labourActivityController,
                                decoration: const InputDecoration(
                                  labelText: 'Coffee Farm Activity',
                                  prefixIcon: Icon(Icons.work),
                                  hintText: 'e.g., Pruning coffee trees, Harvesting coffee cherries',
                                ),
                                maxLength: 30,
                              ),
                              TextFormField(
                                controller: _labourCostController,
                                decoration: const InputDecoration(
                                    labelText: 'Cost (KSH)',
                                    prefixIcon: Icon(Icons.currency_exchange)),
                                keyboardType: TextInputType.number,
                              ),
                              ListTile(
                                title: Text(
                                    'Date: ${_labourActivityDate.toString().substring(0, 10)}'),
                                trailing: const Icon(Icons.calendar_today),
                                onTap: () async {
                                  DateTime? picked = await showDatePicker(
                                    context: context,
                                    initialDate: _labourActivityDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2030),
                                  );
                                  if (picked != null) {
                                    setState(() => _labourActivityDate = picked);
                                  }
                                },
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: customBrown,
                                    foregroundColor: Colors.white),
                                onPressed: () {
                                  if (_labourActivityController.text.isNotEmpty &&
                                      _labourCostController.text.isNotEmpty) {
                                    final newActivity = {
                                      'activity': _labourActivityController.text.trim(),
                                      'cost': _labourCostController.text,
                                      'date': _labourActivityDate
                                          .toIso8601String()
                                          .substring(0, 10),
                                    };
                                    setState(() {
                                      _labourActivities.insert(0, newActivity);
                                      _saveDataOnChange();
                                      _calculateTotalProductionCost();
                                      _labourActivityController.clear();
                                      _labourCostController.clear();
                                      _labourActivityDate = DateTime.now();
                                    });
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Please enter both activity and cost')));
                                  }
                                },
                                child: const Text('Add Activity Cost'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_labourActivities.isNotEmpty)
                        ListTile(
                          title: Text(
                              'Latest Activity: ${_labourActivities.first['activity']} - KSH ${_labourActivities.first['cost']}'),
                          subtitle: Text('Date: ${_labourActivities.first['date']}'),
                        ),
                      Card(
                        color: Colors.blue[100],
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Text('Coffee Farm Equipment Costs',
                                  style:
                                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              Autocomplete<String>(
                                optionsBuilder: (TextEditingValue textEditingValue) {
                                  if (textEditingValue.text.isEmpty) {
                                    return _getEquipmentSuggestions();
                                  }
                                  return _getEquipmentSuggestions().where((option) =>
                                      option
                                          .toLowerCase()
                                          .contains(textEditingValue.text.toLowerCase()));
                                },
                                onSelected: (String selection) {
                                  _equipmentUsedController.text = selection;
                                },
                                fieldViewBuilder:
                                    (context, controller, focusNode, onFieldSubmitted) {
                                  _equipmentUsedController.text = controller.text;
                                  return TextFormField(
                                    controller: controller,
                                    focusNode: focusNode,
                                    decoration: const InputDecoration(
                                      labelText: 'Coffee Farm Equipment',
                                      prefixIcon: Icon(Icons.agriculture),
                                      hintText: 'e.g., Coffee harvester, Coffee roaster',
                                    ),
                                    maxLength: 30,
                                    onFieldSubmitted: (_) => onFieldSubmitted(),
                                  );
                                },
                              ),
                              TextFormField(
                                controller: _equipmentCostController,
                                decoration: const InputDecoration(
                                    labelText: 'Cost (KSH)',
                                    prefixIcon: Icon(Icons.currency_exchange)),
                                keyboardType: TextInputType.number,
                              ),
                              ListTile(
                                title: Text(
                                    'Date: ${_equipmentUsedDate.toString().substring(0, 10)}'),
                                trailing: const Icon(Icons.calendar_today),
                                onTap: () async {
                                  DateTime? picked = await showDatePicker(
                                    context: context,
                                    initialDate: _equipmentUsedDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2030),
                                  );
                                  if (picked != null) {
                                    setState(() => _equipmentUsedDate = picked);
                                  }
                                },
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: customBrown,
                                    foregroundColor: Colors.white),
                                onPressed: () {
                                  if (_equipmentUsedController.text.isNotEmpty &&
                                      _equipmentCostController.text.isNotEmpty) {
                                    final newCost = {
                                      'equipment': _equipmentUsedController.text.trim(),
                                      'cost': _equipmentCostController.text,
                                      'date': _equipmentUsedDate
                                          .toIso8601String()
                                          .substring(0, 10),
                                    };
                                    setState(() {
                                      _mechanicalCosts.insert(0, newCost);
                                      _saveDataOnChange();
                                      _calculateTotalProductionCost();
                                      _equipmentUsedController.clear();
                                      _equipmentCostController.clear();
                                      _equipmentUsedDate = DateTime.now();
                                    });
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Please enter both equipment and cost')));
                                  }
                                },
                                child: const Text('Add Equipment Cost'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_mechanicalCosts.isNotEmpty)
                        ListTile(
                          title: Text(
                              'Latest Equipment: ${_mechanicalCosts.first['equipment']} - KSH ${_mechanicalCosts.first['cost']}'),
                          subtitle: Text('Date: ${_mechanicalCosts.first['date']}'),
                        ),
                      Card(
                        color: Colors.orange[100],
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Text('Coffee Farm Input Costs',
                                  style:
                                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              Autocomplete<String>(
                                optionsBuilder: (TextEditingValue textEditingValue) {
                                  if (textEditingValue.text.isEmpty) {
                                    return _getInputSuggestions();
                                  }
                                  return _getInputSuggestions().where((option) =>
                                      option
                                          .toLowerCase()
                                          .contains(textEditingValue.text.toLowerCase()));
                                },
                                onSelected: (String selection) {
                                  _inputUsedController.text = selection;
                                },
                                fieldViewBuilder:
                                    (context, controller, focusNode, onFieldSubmitted) {
                                  _inputUsedController.text = controller.text;
                                  return TextFormField(
                                    controller: controller,
                                    focusNode: focusNode,
                                    decoration: const InputDecoration(
                                      labelText: 'Coffee Farm Input',
                                      prefixIcon: Icon(Icons.local_florist),
                                      hintText: 'e.g., Coffee fertilizers, Coffee seeds',
                                    ),
                                    maxLength: 30,
                                    onFieldSubmitted: (_) => onFieldSubmitted(),
                                  );
                                },
                              ),
                              TextFormField(
                                controller: _inputCostController,
                                decoration: const InputDecoration(
                                    labelText: 'Cost (KSH)',
                                    prefixIcon: Icon(Icons.currency_exchange)),
                                keyboardType: TextInputType.number,
                              ),
                              ListTile(
                                title: Text(
                                    'Date: ${_inputUsedDate.toString().substring(0, 10)}'),
                                trailing: const Icon(Icons.calendar_today),
                                onTap: () async {
                                  DateTime? picked = await showDatePicker(
                                    context: context,
                                    initialDate: _inputUsedDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2030),
                                  );
                                  if (picked != null) {
                                    setState(() => _inputUsedDate = picked);
                                  }
                                },
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: customBrown,
                                    foregroundColor: Colors.white),
                                onPressed: () {
                                  if (_inputUsedController.text.isNotEmpty &&
                                      _inputCostController.text.isNotEmpty) {
                                    final newCost = {
                                      'input': _inputUsedController.text.trim(),
                                      'cost': _inputCostController.text,
                                      'date':
                                          _inputUsedDate.toIso8601String().substring(0, 10),
                                    };
                                    setState(() {
                                      _inputCosts.insert(0, newCost);
                                      _saveDataOnChange();
                                      _calculateTotalProductionCost();
                                      _inputUsedController.clear();
                                      _inputCostController.clear();
                                      _inputUsedDate = DateTime.now();
                                    });
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content:
                                                Text('Please enter both input and cost')));
                                  }
                                },
                                child: const Text('Add Input Cost'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_inputCosts.isNotEmpty)
                        ListTile(
                          title: Text(
                              'Latest Input: ${_inputCosts.first['input']} - KSH ${_inputCosts.first['cost']}'),
                          subtitle: Text('Date: ${_inputCosts.first['date']}'),
                        ),
                      Card(
                        color: Colors.grey[200],
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Text('Miscellaneous Costs',
                                  style:
                                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              TextFormField(
                                controller: _miscellaneousDescController,
                                decoration: const InputDecoration(
                                  labelText: 'Description',
                                  prefixIcon: Icon(Icons.miscellaneous_services),
                                  hintText: 'e.g., Repairs, Transport',
                                ),
                                maxLength: 30,
                              ),
                              TextFormField(
                                controller: _miscellaneousCostController,
                                decoration: const InputDecoration(
                                    labelText: 'Cost (KSH)',
                                    prefixIcon: Icon(Icons.currency_exchange)),
                                keyboardType: TextInputType.number,
                              ),
                              ListTile(
                                title: Text(
                                    'Date: ${_miscellaneousDate.toString().substring(0, 10)}'),
                                trailing: const Icon(Icons.calendar_today),
                                onTap: () async {
                                  DateTime? picked = await showDatePicker(
                                    context: context,
                                    initialDate: _miscellaneousDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2030),
                                  );
                                  if (picked != null) {
                                    setState(() => _miscellaneousDate = picked);
                                  }
                                },
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: customBrown,
                                    foregroundColor: Colors.white),
                                onPressed: () {
                                  if (_miscellaneousDescController.text.isNotEmpty &&
                                      _miscellaneousCostController.text.isNotEmpty) {
                                    final newCost = {
                                      'description':
                                          _miscellaneousDescController.text.trim(),
                                      'cost': _miscellaneousCostController.text,
                                      'date': _miscellaneousDate
                                          .toIso8601String()
                                          .substring(0, 10),
                                    };
                                    setState(() {
                                      _miscellaneousCosts.insert(0, newCost);
                                      _saveDataOnChange();
                                      _calculateTotalProductionCost();
                                      _miscellaneousDescController.clear();
                                      _miscellaneousCostController.clear();
                                      _miscellaneousDate = DateTime.now();
                                    });
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Please enter both description and cost')));
                                  }
                                },
                                child: const Text('Add Miscellaneous Cost'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_miscellaneousCosts.isNotEmpty)
                        ListTile(
                          title: Text(
                              'Latest Misc: ${_miscellaneousCosts.first['description']} - KSH ${_miscellaneousCosts.first['cost']}'),
                          subtitle: Text('Date: ${_miscellaneousCosts.first['date']}'),
                        ),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Card(
                        color: Colors.green[100],
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Text('Revenue',
                                  style:
                                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              TextFormField(
                                controller: _cropGrownController,
                                decoration: const InputDecoration(
                                    labelText: 'Coffee Variety',
                                    prefixIcon: Icon(Icons.coffee),
                                    hintText: 'e.g., Arabica, Robusta'),
                              ),
                              TextFormField(
                                controller: _revenueController,
                                decoration: const InputDecoration(
                                    labelText: 'Revenue (KSH)',
                                    prefixIcon: Icon(Icons.attach_money)),
                                keyboardType: TextInputType.number,
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: customBrown,
                                    foregroundColor: Colors.white),
                                onPressed: () {
                                  if (_cropGrownController.text.isNotEmpty &&
                                      _revenueController.text.isNotEmpty) {
                                    final newRevenue = {
                                      'crop': _cropGrownController.text,
                                      'amount': _revenueController.text,
                                    };
                                    setState(() {
                                      _revenues.insert(0, newRevenue);
                                      _saveDataOnChange();
                                      _calculateTotalProductionCost();
                                      _cropGrownController.clear();
                                      _revenueController.clear();
                                    });
                                  }
                                },
                                child: const Text('Add Revenue'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          itemCount: _revenues.length,
                          itemBuilder: (context, index) => ListTile(
                            title: Text(
                                '${_revenues[index]['crop']} - KSH ${_revenues[index]['amount']}'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Text('Profit/Loss',
                                  style:
                                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              TextFormField(
                                controller: _totalProductionCostController,
                                decoration: const InputDecoration(labelText: 'Total Cost (KSH)'),
                                readOnly: true,
                              ),
                              TextFormField(
                                controller: _profitLossController,
                                decoration:
                                    const InputDecoration(labelText: 'Profit/Loss (KSH)'),
                                readOnly: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Card(
                        color: Colors.purple[100],
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Text('Loan Details',
                                  style:
                                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              TextFormField(
                                controller: _loanAmountController,
                                decoration: const InputDecoration(
                                    labelText: 'Loan Amount (KSH)',
                                    prefixIcon: Icon(Icons.account_balance_wallet)),
                                keyboardType: TextInputType.number,
                                onChanged: (_) => _updateLoanCalculations(),
                              ),
                              TextFormField(
                                controller: _interestRateController,
                                decoration: const InputDecoration(
                                    labelText: 'Interest Rate (%)',
                                    prefixIcon: Icon(Icons.percent)),
                                keyboardType: TextInputType.number,
                                onChanged: (_) => _updateLoanCalculations(),
                              ),
                              TextFormField(
                                controller: _loanInterestController,
                                decoration: const InputDecoration(labelText: 'Interest (KSH)'),
                                readOnly: true,
                              ),
                              TextFormField(
                                controller: _totalRepaymentController,
                                decoration:
                                    const InputDecoration(labelText: 'Total Repayment (KSH)'),
                                readOnly: true,
                              ),
                              TextFormField(
                                controller: _remainingBalanceController,
                                decoration:
                                    const InputDecoration(labelText: 'Remaining Balance (KSH)'),
                                readOnly: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        color: Colors.purple[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Text('Loan Payments',
                                  style:
                                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              TextFormField(
                                controller: _paymentAmountController,
                                decoration: const InputDecoration(
                                    labelText: 'Payment Amount (KSH)',
                                    prefixIcon: Icon(Icons.payment)),
                                keyboardType: TextInputType.number,
                              ),
                              ListTile(
                                title: Text(
                                    'Payment Date: ${_paymentDate.toString().substring(0, 10)}'),
                                trailing: const Icon(Icons.calendar_today),
                                onTap: () async {
                                  DateTime? picked = await showDatePicker(
                                    context: context,
                                    initialDate: _paymentDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2030),
                                  );
                                  if (picked != null) {
                                    setState(() => _paymentDate = picked);
                                  }
                                },
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: customBrown,
                                    foregroundColor: Colors.white),
                                onPressed: _recordPayment,
                                child: const Text('Record Payment'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          itemCount: _paymentHistory.length,
                          itemBuilder: (context, index) => ListTile(
                            title: Text(
                                '${_paymentHistory[index]['date']} - KSH ${_paymentHistory[index]['amount']}'),
                            subtitle: Text(
                                'Remaining: KSH ${_paymentHistory[index]['remainingBalance']}'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ActivitiesScreen(
              labourActivities: _labourActivities,
              mechanicalCosts: _mechanicalCosts,
              inputCosts: _inputCosts,
              miscellaneousCosts: _miscellaneousCosts,
              revenues: _revenues,
              paymentHistory: _paymentHistory,
              totalCosts: _totalProductionCostController.text,
              profitLoss: _profitLossController.text,
              onDelete: (category, index) {
                setState(() {
                  switch (category) {
                    case 'labour':
                      _labourActivities.removeAt(index);
                      _saveDataOnChange();
                      break;
                    case 'mechanical':
                      _mechanicalCosts.removeAt(index);
                      _saveDataOnChange();
                      break;
                    case 'input':
                      _inputCosts.removeAt(index);
                      _saveDataOnChange();
                      break;
                    case 'miscellaneous':
                      _miscellaneousCosts.removeAt(index);
                      _saveDataOnChange();
                      break;
                    case 'revenue':
                      _revenues.removeAt(index);
                      _saveDataOnChange();
                      break;
                    case 'payment':
                      _paymentHistory.removeAt(index);
                      _saveDataOnChange();
                      _updateLoanCalculations();
                      break;
                  }
                  _calculateTotalProductionCost();
                  Navigator.pop(context);
                });
              },
            ),
          ),
        ).then((_) => setState(() {})),
        backgroundColor: customBrown,
        tooltip: 'View All Activities',
        child: const Icon(Icons.list, color: Colors.white),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _labourActivityController.dispose();
    _labourCostController.dispose();
    _equipmentUsedController.dispose();
    _equipmentCostController.dispose();
    _inputUsedController.dispose();
    _inputCostController.dispose();
    _miscellaneousDescController.dispose();
    _miscellaneousCostController.dispose();
    _cropGrownController.dispose();
    _revenueController.dispose();
    _totalProductionCostController.dispose();
    _profitLossController.dispose();
    _loanAmountController.dispose();
    _interestRateController.dispose();
    _loanInterestController.dispose();
    _totalRepaymentController.dispose();
    _remainingBalanceController.dispose();
    _paymentAmountController.dispose();
    super.dispose();
  }
}