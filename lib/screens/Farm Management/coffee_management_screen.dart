import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';
import 'activities_screen.dart';
import 'data_manager.dart';
import 'constants.dart';
import 'package:coffeecore/home.dart';
import 'history_screen.dart';

class CoffeeManagementScreen extends StatefulWidget {
  const CoffeeManagementScreen({super.key});

  @override
  State<CoffeeManagementScreen> createState() => _CoffeeManagementScreenState();
}

class _CoffeeManagementScreenState extends State<CoffeeManagementScreen>
    with SingleTickerProviderStateMixin {
  final Logger _logger = Logger();
  late TabController _tabController;
  late DataManager _dataManager;
  bool _isLoading = true;
  bool _isFirstLaunch = true;
  String? _selectedCycle;

  // Form controllers
  final _labourActivityController = TextEditingController();
  final _labourCostController = TextEditingController();
  final _equipmentUsedController = TextEditingController();
  final _equipmentCostController = TextEditingController();
  final _inputUsedController = TextEditingController();
  final _inputCostController = TextEditingController();
  final _miscellaneousDescController = TextEditingController();
  final _miscellaneousCostController = TextEditingController();
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

  @override
  void initState() {
    super.initState();
    _logger.i('Initializing CoffeeManagementScreen...');
    _tabController = TabController(length: 5, vsync: this);
    _dataManager = DataManager(
      context: context,
      labourActivityController: _labourActivityController,
      labourCostController: _labourCostController,
      equipmentUsedController: _equipmentUsedController,
      equipmentCostController: _equipmentCostController,
      inputUsedController: _inputUsedController,
      inputCostController: _inputCostController,
      miscellaneousDescController: _miscellaneousDescController,
      miscellaneousCostController: _miscellaneousCostController,
      coffeeVarietyController: _cropGrownController,
      yieldController: TextEditingController(),
      revenueController: _revenueController,
      totalProductionCostController: _totalProductionCostController,
      profitLossController: _profitLossController,
      loanSourceController: TextEditingController(),
      loanAmountController: _loanAmountController,
      interestRateController: _interestRateController,
      loanInterestController: _loanInterestController,
      totalRepaymentController: _totalRepaymentController,
      remainingBalanceController: _remainingBalanceController,
      paymentAmountController: _paymentAmountController,
      onDataChanged: () {
        if (mounted) {
          setState(() {
            _logger.i('Data changed, updating UI...');
            _dataManager.calculateTotalProductionCost();
            _selectedCycle = _dataManager.currentCycle;
          });
        }
      },
    );
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowStoragePopup();
    });
  }

  Future<void> _loadData() async {
    _logger.i('Loading initial data...');
    if (mounted) {
      setState(() => _isLoading = true);
    }
    await _dataManager.loadData((isFirstLaunch, retrievedCycle) {
      if (mounted) {
        setState(() {
          _isFirstLaunch = isFirstLaunch;
          _selectedCycle = retrievedCycle ?? _dataManager.currentCycle;
          _isLoading = false;
        });
      }
    });
    _logger.i('Initial data loaded: isFirstLaunch=$_isFirstLaunch, selectedCycle=$_selectedCycle');
  }

  Future<void> _switchCycle(String? newCycle) async {
    if (newCycle == null || newCycle == _selectedCycle) return;
    _logger.i('Switching to cycle: $newCycle');
    setState(() => _isLoading = true);
    try {
      if (await _checkConnectivity()) {
        await _dataManager.loadCycleData(newCycle);
        if (mounted) {
          setState(() {
            _selectedCycle = newCycle;
            _isFirstLaunch = false;
            _updateFormControllers();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Switched to cycle: $newCycle')),
          );
        }
      } else {
        _logger.w('No internet connection, cannot switch cycle');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No internet connection to switch cycle')),
          );
        }
      }
    } catch (e) {
      _logger.e('Error switching cycle: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error switching cycle: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _updateFormControllers() {
    // Clear and update controllers with selected cycle's data
    _labourActivityController.clear();
    _labourCostController.clear();
    _equipmentUsedController.clear();
    _equipmentCostController.clear();
    _inputUsedController.clear();
    _inputCostController.clear();
    _miscellaneousDescController.clear();
    _miscellaneousCostController.clear();
    _cropGrownController.clear();
    _revenueController.clear();
    _totalProductionCostController.text = _dataManager.totalProductionCostController.text;
    _profitLossController.text = _dataManager.profitLossController.text;
    _loanAmountController.text = _dataManager.loanAmountController.text;
    _interestRateController.text = _dataManager.interestRateController.text;
    _loanInterestController.text = _dataManager.loanInterestController.text;
    _totalRepaymentController.text = _dataManager.totalRepaymentController.text;
    _remainingBalanceController.text = _dataManager.remainingBalanceController.text;
    _paymentAmountController.clear();
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

  Future<void> _checkAndShowStoragePopup() async {
    bool hasShownPopup = await _dataManager.hasShownStoragePopup();
    if (!hasShownPopup && mounted) {
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
                  'Good news! Your financial info is stored securely.',
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
                  _dataManager.setStoragePopupShown();
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
                        'Your coffee farm data is stored locally on this device. '
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

  Future<void> _saveData() async {
    _logger.i('Saving data for cycle: $_selectedCycle');
    _dataManager.saveForm();
    if (await _checkConnectivity()) {
      await _dataManager.syncToFirestore();
      if (mounted) {
        setState(() {
          _dataManager.calculateTotalProductionCost();
          _updateFormControllers();
        });
      }
    } else {
      _logger.i('No internet, data saved locally only');
    }
  }

  Future<void> _showHistorySection() async {
    _logger.i('Showing history section...');
    if (!await _checkConnectivity()) {
      return;
    }
    if (mounted) {
      setState(() => _isLoading = true);
    }
    try {
      Map<String, dynamic>? data = await _dataManager.loadFromFirestore();
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

      Map<String, dynamic> cycles = data['cycles'] ?? {};
      cycles.keys.toList();
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HistoryScreen(
              cycleName: _selectedCycle ?? _dataManager.currentCycle,
              pastCycles: _dataManager.pastCycles,
              dataManager: _dataManager,
            ),
          ),
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _logger.e('Error loading history: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading history: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  void _showActivitiesScreen() {
    _logger.i('View All Activities button pressed');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivitiesScreen(
          labourActivities: _dataManager.labourActivities,
          mechanicalCosts: _dataManager.mechanicalCosts,
          inputCosts: _dataManager.inputCosts,
          miscellaneousCosts: _dataManager.miscellaneousCosts,
          revenues: _dataManager.revenues,
          paymentHistory: _dataManager.paymentHistory,
          totalCosts: _totalProductionCostController.text,
          profitLoss: _profitLossController.text,
          onDelete: (category, index) {
            _logger.i('Delete activity: category=$category, index=$index');
            if (mounted) {
              setState(() {
                _dataManager.deleteActivity(category, index);
                _dataManager.calculateTotalProductionCost();
                Navigator.pop(context);
              });
            }
          },
        ),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Combine currentCycle and pastCycles, ensuring uniqueness
    final cycles = {_dataManager.currentCycle, ..._dataManager.pastCycles}.toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          tooltip: 'Back to Home',
          onPressed: () {
            _logger.i('Back button pressed');
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
            icon: const Icon(Icons.task_alt, color: Colors.white),
            tooltip: 'View Farm Activities',
            onPressed: _showActivitiesScreen,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            tooltip: 'Start New Cycle',
            onPressed: () async {
              _logger.i('Start New Cycle button pressed');
              await _dataManager.startNewCycle();
              if (mounted) {
                setState(() {
                  _selectedCycle = _dataManager.currentCycle;
                  _isFirstLaunch = true;
                  _updateFormControllers();
                });
              }
            },
          ),
          DropdownButton<String>(
            value: _selectedCycle != null && cycles.contains(_selectedCycle)
                ? _selectedCycle
                : cycles.isNotEmpty
                    ? cycles.first
                    : null,
            hint: const Text('Select Cycle', style: TextStyle(color: Colors.white)),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
            dropdownColor: customBrown,
            style: const TextStyle(color: Colors.white),
            items: cycles.isNotEmpty
                ? cycles.map((String cycle) {
                    return DropdownMenuItem<String>(
                      value: cycle,
                      child: Text(cycle),
                    );
                  }).toList()
                : [
                    const DropdownMenuItem<String>(
                      value: 'Current Cycle',
                      child: Text('Current Cycle'),
                    ),
                  ],
            onChanged: _switchCycle,
          ),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            tooltip: 'View History',
            onPressed: _showHistorySection,
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
                _buildDashboard(),
                _buildCostsTab(),
                _buildRevenueTab(),
                _buildProfitLossTab(),
                _buildLoansTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveData,
        backgroundColor: customBrown,
        tooltip: 'Save Data',
        child: const Icon(Icons.save, color: Colors.white),
      ),
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Dashboard - ${_selectedCycle ?? _dataManager.currentCycle}',
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, color: customBrown),
              ),
              if (_isFirstLaunch)
                IconButton(
                  icon: const Icon(Icons.edit, color: customBrown),
                  tooltip: 'Edit Cycle Name',
                  onPressed: () {
                    _logger.i('Edit Cycle Name button pressed');
                    _dataManager.editCycleName(() {
                      if (mounted) {
                        setState(() {
                          _isFirstLaunch = false;
                          _selectedCycle = _dataManager.currentCycle;
                        });
                      }
                    });
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
                    value: _dataManager.labourActivities.fold<double>(
                        0.0,
                        (sum, item) =>
                            sum + (double.tryParse(item['cost'] ?? '0') ?? 0)),
                    color: Colors.red,
                    title: 'Labour',
                  ),
                  PieChartSectionData(
                    value: _dataManager.mechanicalCosts.fold<double>(
                        0.0,
                        (sum, item) =>
                            sum + (double.tryParse(item['cost'] ?? '0') ?? 0)),
                    color: Colors.blue,
                    title: 'Equipment',
                  ),
                  PieChartSectionData(
                    value: _dataManager.inputCosts.fold<double>(
                        0.0,
                        (sum, item) =>
                            sum + (double.tryParse(item['cost'] ?? '0') ?? 0)),
                    color: Colors.orange,
                    title: 'Inputs',
                  ),
                  PieChartSectionData(
                    value: _dataManager.miscellaneousCosts.fold<double>(
                        0.0,
                        (sum, item) =>
                            sum + (double.tryParse(item['cost'] ?? '0') ?? 0)),
                    color: Colors.grey,
                    title: 'Misc',
                  ),
                  PieChartSectionData(
                    value: _dataManager.revenues.fold<double>(
                        0.0,
                        (sum, item) =>
                            sum + (double.tryParse(item['amount'] ?? '0') ?? 0)),
                    color: Colors.green,
                    title: 'Revenue',
                  ),
                  PieChartSectionData(
                    value:
                        (double.tryParse(_profitLossController.text) ?? 0).abs(),
                    color: (double.tryParse(_profitLossController.text) ?? 0) >= 0
                        ? Colors.purple
                        : Colors.grey,
                    title: (double.tryParse(_profitLossController.text) ?? 0) >= 0
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
              subtitle: Text('KSH ${_totalProductionCostController.text}'),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Total Revenue'),
              subtitle: Text(
                  'KSH ${_dataManager.revenues.fold<double>(0.0, (double sum, item) => sum + (double.tryParse(item['amount'] ?? '0') ?? 0)).toStringAsFixed(2)}'),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Profit/Loss'),
              subtitle: Text('KSH ${_profitLossController.text}'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostsTab() {
    return SingleChildScrollView(
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
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                        'Date: ${_dataManager.labourActivityDate.toString().substring(0, 10)}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      _logger.i('Selecting labour activity date...');
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _dataManager.labourActivityDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null && mounted) {
                        setState(() {
                          _dataManager.labourActivityDate = picked;
                          _logger.i('Labour activity date set to: $picked');
                        });
                      }
                    },
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: customBrown, foregroundColor: Colors.white),
                    onPressed: () {
                      _logger.i('Add Activity Cost button pressed');
                      _dataManager.addLabourCost();
                      if (mounted) {
                        setState(() {});
                      }
                    },
                    child: const Text('Add Activity Cost'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_dataManager.labourActivities.isNotEmpty)
            ListTile(
              title: Text(
                  'Latest Activity: ${_dataManager.labourActivities.first['activity']} - KSH ${_dataManager.labourActivities.first['cost']}'),
              subtitle: Text('Date: ${_dataManager.labourActivities.first['date']}'),
              trailing: IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                tooltip: 'Cancel Latest Activity',
                onPressed: () {
                  _logger.i('Cancel Latest Activity button pressed');
                  if (mounted) {
                    setState(() {
                      _dataManager.deleteActivity('labour', 0);
                      _dataManager.calculateTotalProductionCost();
                    });
                  }
                },
              ),
            ),
          Card(
            color: Colors.blue[100],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text('Coffee Farm Equipment Costs',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return _dataManager.getEquipmentSuggestions();
                      }
                      return _dataManager.getEquipmentSuggestions().where((option) =>
                          option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                    },
                    onSelected: (String selection) {
                      _logger.i('Selected equipment: $selection');
                      _equipmentUsedController.text = selection;
                    },
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
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
                        'Date: ${_dataManager.equipmentUsedDate.toString().substring(0, 10)}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      _logger.i('Selecting equipment used date...');
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _dataManager.equipmentUsedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null && mounted) {
                        setState(() {
                          _dataManager.equipmentUsedDate = picked;
                          _logger.i('Equipment used date set to: $picked');
                        });
                      }
                    },
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: customBrown, foregroundColor: Colors.white),
                    onPressed: () {
                      _logger.i('Add Equipment Cost button pressed');
                      _dataManager.addMechanicalCost();
                      if (mounted) {
                        setState(() {});
                      }
                    },
                    child: const Text('Add Equipment Cost'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_dataManager.mechanicalCosts.isNotEmpty)
            ListTile(
              title: Text(
                  'Latest Equipment: ${_dataManager.mechanicalCosts.first['equipment']} - KSH ${_dataManager.mechanicalCosts.first['cost']}'),
              subtitle: Text('Date: ${_dataManager.mechanicalCosts.first['date']}'),
              trailing: IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                tooltip: 'Cancel Latest Equipment',
                onPressed: () {
                  _logger.i('Cancel Latest Equipment button pressed');
                  if (mounted) {
                    setState(() {
                      _dataManager.deleteActivity('equipment', 0);
                      _dataManager.calculateTotalProductionCost();
                    });
                  }
                },
              ),
            ),
          Card(
            color: Colors.orange[100],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text('Coffee Farm Input Costs',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return _dataManager.getInputSuggestions();
                      }
                      return _dataManager.getInputSuggestions().where((option) =>
                          option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                    },
                    onSelected: (String selection) {
                      _logger.i('Selected input: $selection');
                      _inputUsedController.text = selection;
                    },
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
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
                        'Date: ${_dataManager.inputUsedDate.toString().substring(0, 10)}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      _logger.i('Selecting input used date...');
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _dataManager.inputUsedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null && mounted) {
                        setState(() {
                          _dataManager.inputUsedDate = picked;
                          _logger.i('Input used date set to: $picked');
                        });
                      }
                    },
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: customBrown, foregroundColor: Colors.white),
                    onPressed: () {
                      _logger.i('Add Input Cost button pressed');
                      _dataManager.addInputCost();
                      if (mounted) {
                        setState(() {});
                      }
                    },
                    child: const Text('Add Input Cost'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_dataManager.inputCosts.isNotEmpty)
            ListTile(
              title: Text(
                  'Latest Input: ${_dataManager.inputCosts.first['input']} - KSH ${_dataManager.inputCosts.first['cost']}'),
              subtitle: Text('Date: ${_dataManager.inputCosts.first['date']}'),
              trailing: IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                tooltip: 'Cancel Latest Input',
                onPressed: () {
                  _logger.i('Cancel Latest Input button pressed');
                  if (mounted) {
                    setState(() {
                      _dataManager.deleteActivity('input', 0);
                      _dataManager.calculateTotalProductionCost();
                    });
                  }
                },
              ),
            ),
          Card(
            color: Colors.grey[200],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text('Miscellaneous Costs',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                        'Date: ${_dataManager.miscellaneousDate.toString().substring(0, 10)}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      _logger.i('Selecting miscellaneous date...');
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _dataManager.miscellaneousDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null && mounted) {
                        setState(() {
                          _dataManager.miscellaneousDate = picked;
                          _logger.i('Miscellaneous date set to: $picked');
                        });
                      } else if (mounted) {
                        setState(() {
                          _dataManager.miscellaneousDate = DateTime.now();
                          _logger.i('Miscellaneous date set to now due to null picked date');
                        });
                      }
                    },
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: customBrown, foregroundColor: Colors.white),
                    onPressed: () {
                      _logger.i('Add Miscellaneous Cost button pressed');
                      _dataManager.addMiscellaneousCost();
                      if (mounted) {
                        setState(() {});
                      }
                    },
                    child: const Text('Add Miscellaneous Cost'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_dataManager.miscellaneousCosts.isNotEmpty)
            ListTile(
              title: Text(
                  'Latest Misc: ${_dataManager.miscellaneousCosts.first['description']} - KSH ${_dataManager.miscellaneousCosts.first['cost']}'),
              subtitle: Text('Date: ${_dataManager.miscellaneousCosts.first['date']}'),
              trailing: IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                tooltip: 'Cancel Latest Miscellaneous',
                onPressed: () {
                  _logger.i('Cancel Latest Miscellaneous button pressed');
                  if (mounted) {
                    setState(() {
                      _dataManager.deleteActivity('miscellaneous', 0);
                      _dataManager.calculateTotalProductionCost();
                    });
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRevenueTab() {
    return SingleChildScrollView(
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
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  TextFormField(
                    controller: _cropGrownController,
                    decoration: const InputDecoration(
                        labelText: 'Coffee Variety',
                        prefixIcon: Icon(Icons.coffee),
                        hintText: 'e.g., Arabica, Robusta'),
                    maxLength: 30,
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
                        backgroundColor: customBrown, foregroundColor: Colors.white),
                    onPressed: () {
                      _logger.i('Add Revenue button pressed');
                      _dataManager.addRevenue();
                      if (mounted) {
                        setState(() {});
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
              itemCount: _dataManager.revenues.length,
              itemBuilder: (context, index) {
                _logger.d('Rendering revenue item: index=$index');
                return ListTile(
                  title: Text(
                      '${_dataManager.revenues[index]['coffeeVariety']} - KSH ${_dataManager.revenues[index]['amount']}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitLossTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text('Profit/Loss',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  TextFormField(
                    controller: _totalProductionCostController,
                    decoration: const InputDecoration(labelText: 'Total Cost (KSH)'),
                    readOnly: true,
                  ),
                  TextFormField(
                    controller: _profitLossController,
                    decoration: const InputDecoration(labelText: 'Profit/Loss (KSH)'),
                    readOnly: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoansTab() {
    return SingleChildScrollView(
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
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  TextFormField(
                    controller: _loanAmountController,
                    decoration: const InputDecoration(
                        labelText: 'Loan Amount (KSH)',
                        prefixIcon: Icon(Icons.account_balance_wallet)),
                    keyboardType: TextInputType.number,
                    onChanged: (_) {
                      _logger.i('Loan amount changed, updating calculations');
                      _dataManager.updateLoanCalculations();
                    },
                  ),
                  TextFormField(
                    controller: _interestRateController,
                    decoration: const InputDecoration(
                        labelText: 'Interest Rate (%)',
                        prefixIcon: Icon(Icons.percent)),
                    keyboardType: TextInputType.number,
                    onChanged: (_) {
                      _logger.i('Interest rate changed, updating calculations');
                      _dataManager.updateLoanCalculations();
                    },
                  ),
                  TextFormField(
                    controller: _loanInterestController,
                    decoration: const InputDecoration(labelText: 'Interest (KSH)'),
                    readOnly: true,
                  ),
                  TextFormField(
                    controller: _totalRepaymentController,
                    decoration: const InputDecoration(labelText: 'Total Repayment (KSH)'),
                    readOnly: true,
                  ),
                  TextFormField(
                    controller: _remainingBalanceController,
                    decoration: const InputDecoration(labelText: 'Remaining Balance (KSH)'),
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
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  TextFormField(
                    controller: _paymentAmountController,
                    decoration: const InputDecoration(
                        labelText: 'Payment Amount (KSH)',
                        prefixIcon: Icon(Icons.payment)),
                    keyboardType: TextInputType.number,
                  ),
                  ListTile(
                    title: Text(
                        'Payment Date: ${_dataManager.paymentDate.toString().substring(0, 10)}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      _logger.i('Selecting payment date...');
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _dataManager.paymentDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null && mounted) {
                        setState(() {
                          _dataManager.paymentDate = picked;
                          _logger.i('Payment date set to: $picked');
                        });
                      }
                    },
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: customBrown, foregroundColor: Colors.white),
                    onPressed: () {
                      _logger.i('Record Payment button pressed');
                      _dataManager.recordPayment();
                      if (mounted) {
                        setState(() {});
                      }
                    },
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
              itemCount: _dataManager.paymentHistory.length,
              itemBuilder: (context, index) {
                _logger.d('Rendering payment history item: index=$index');
                return ListTile(
                  title: Text(
                      '${_dataManager.paymentHistory[index]['date']} - KSH ${_dataManager.paymentHistory[index]['amount']}'),
                  subtitle: Text(
                      'Remaining: KSH ${_dataManager.paymentHistory[index]['remainingBalance']}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _logger.i('Disposing CoffeeManagementScreen...');
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