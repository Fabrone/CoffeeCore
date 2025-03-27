import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
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

  // Form controllers
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

  // Lists to store current cycle data
  List<Map<String, dynamic>> _labourActivities = [];
  List<Map<String, dynamic>> _mechanicalCosts = [];
  List<Map<String, dynamic>> _inputCosts = [];
  List<Map<String, dynamic>> _miscellaneousCosts = [];
  List<Map<String, dynamic>> _revenues = [];
  List<Map<String, dynamic>> _paymentHistory = [];

  // Current farming cycle
  String _currentCycle = 'Current Cycle';
  List<String> _pastCycles = [];
  static const List<String> _predefinedCycleNames = [
    'Maize Season',
    'Wheat Season',
    'Bean Season',
    'Tea Season',
    'Coffee Season',
  ];

  static const Color customGreen = Color(0xFF003900);
  bool _hasShownPopup = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasShownPopup) {
        _showStoragePopup();
      }
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
        0, (sum, rev) => sum + (double.tryParse(rev['amount'] ?? '0') ?? 0));
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
        (sum, payment) =>
            sum + (double.tryParse(payment['amount'] ?? '0') ?? 0));
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
    Map<String, dynamic> loanData = jsonDecode(savedLoanData!);
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
        _saveDataOnChange(); // Auto-save on payment
        _paymentAmountController.clear();
        _paymentDate = DateTime.now();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid payment amount')));
    }
  }

  void _saveDataOnChange() {
    _prefs.setString('labourActivities_$_currentCycle', jsonEncode(_labourActivities));
    _prefs.setString('mechanicalCosts_$_currentCycle', jsonEncode(_mechanicalCosts));
    _prefs.setString('inputCosts_$_currentCycle', jsonEncode(_inputCosts));
    _prefs.setString('miscellaneousCosts_$_currentCycle', jsonEncode(_miscellaneousCosts));
    _prefs.setString('revenues_$_currentCycle', jsonEncode(_revenues));
    _prefs.setString('paymentHistory_$_currentCycle', jsonEncode(_paymentHistory));
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
      _saveDataOnChange(); // Save current cycle data before switching
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
      _retrievedCycle = null; // Reset retrieved cycle
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

  Future<void> _showStoragePopup() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              Icon(Icons.lock, color: customGreen, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Your Data Stays Safe',
                style: TextStyle(color: customGreen, fontWeight: FontWeight.bold, fontSize: 18),
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
                setState(() => _hasShownPopup = true);
              },
              child: const Text('Got It',
                  style: TextStyle(color: customGreen, fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('More Info'),
                    content: const Text(
                      'Your costs, revenues, and loans are saved locally using SharedPreferences. '
                      'No data is sent to servers unless you choose to share it. '
                      'For security, avoid lending your device or use a passcode.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK', style: TextStyle(color: customGreen)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
          },
        ),
        title: const Text(
          'Farm Management',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: customGreen,
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
                                color: customGreen),
                          ),
                          if (_isFirstLaunch)
                            IconButton(
                              icon: const Icon(Icons.edit, color: customGreen),
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
                                    (sum, item) =>
                                        sum! +
                                        (double.tryParse(item['cost'] ?? '0') ?? 0)),
                                color: Colors.red,
                                title: 'Labour',
                              ),
                              PieChartSectionData(
                                value: _mechanicalCosts.fold(
                                    0.0,
                                    (sum, item) =>
                                        sum! +
                                        (double.tryParse(item['cost'] ?? '0') ?? 0)),
                                color: Colors.blue,
                                title: 'Equipment',
                              ),
                              PieChartSectionData(
                                value: _inputCosts.fold(
                                    0.0,
                                    (sum, item) =>
                                        sum! +
                                        (double.tryParse(item['cost'] ?? '0') ?? 0)),
                                color: Colors.orange,
                                title: 'Inputs',
                              ),
                              PieChartSectionData(
                                value: _miscellaneousCosts.fold(
                                    0.0,
                                    (sum, item) =>
                                        sum! +
                                        (double.tryParse(item['cost'] ?? '0') ?? 0)),
                                color: Colors.grey,
                                title: 'Misc',
                              ),
                              PieChartSectionData(
                                value: _revenues.fold(
                                    0.0,
                                    (sum, item) =>
                                        sum! +
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
                                  'KSH ${_revenues.fold(0.0, (sum, item) => sum + (double.tryParse(item['amount'] ?? '0') ?? 0)).toStringAsFixed(2)}'))),
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
                              const Text('Labour Costs',
                                  style:
                                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              TextFormField(
                                controller: _labourActivityController,
                                decoration: const InputDecoration(
                                  labelText: 'Labour Activity',
                                  prefixIcon: Icon(Icons.work),
                                  hintText: 'e.g., Planting, Pruning',
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
                                    backgroundColor: customGreen,
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
                                      _saveDataOnChange(); // Auto-save
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
                                child: const Text('Add Labour Cost'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_labourActivities.isNotEmpty)
                        ListTile(
                          title: Text(
                              'Latest Labour: ${_labourActivities.first['activity']} - KSH ${_labourActivities.first['cost']}'),
                          subtitle: Text('Date: ${_labourActivities.first['date']}'),
                        ),
                      Card(
                        color: Colors.blue[100],
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Text('Mechanical Costs',
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
                                      labelText: 'Equipment Used',
                                      prefixIcon: Icon(Icons.agriculture),
                                      hintText: 'e.g., Tractor, Harvester',
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
                                    backgroundColor: customGreen,
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
                                      _saveDataOnChange(); // Auto-save
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
                              const Text('Input Costs',
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
                                      labelText: 'Input Used',
                                      prefixIcon: Icon(Icons.local_florist),
                                      hintText: 'e.g., Fertilizer, Seeds',
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
                                    backgroundColor: customGreen,
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
                                      _saveDataOnChange(); // Auto-save
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
                                    backgroundColor: customGreen,
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
                                      _saveDataOnChange(); // Auto-save
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
                                    labelText: 'Crop Grown', prefixIcon: Icon(Icons.grass)),
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
                                    backgroundColor: customGreen,
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
                                      _saveDataOnChange(); // Auto-save
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
                                    backgroundColor: customGreen,
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
        backgroundColor: customGreen,
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

// --- ActivitiesScreen ---
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
      appBar: AppBar(title: const Text('All Farm Activities')),
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
            const Text('Labour Activities',
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
            const Text('Mechanical Costs',
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
            const Text('Input Costs',
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

// --- HistoryScreen ---
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
      if (!item.containsKey('date')) return true; // For revenues without date
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
              const Text('Labour Activities',
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
              const Text('Mechanical Costs',
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
              const Text('Input Costs',
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