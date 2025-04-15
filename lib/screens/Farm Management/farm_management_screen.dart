import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'activities_screen.dart';
import 'history_screen.dart';
import 'data_manager.dart';
import 'constants.dart';

class FarmManagementScreen extends StatefulWidget {
  const FarmManagementScreen({super.key});

  @override
  State<FarmManagementScreen> createState() => _FarmManagementScreenState();
}

class _FarmManagementScreenState extends State<FarmManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DataManager _dataManager;
  bool _isLoading = true;
  bool _isFirstLaunch = true;
  String? _retrievedCycle;

  // Form controllers
  final _labourActivityController = TextEditingController();
  final _labourCostController = TextEditingController();
  final _equipmentUsedController = TextEditingController();
  final _equipmentCostController = TextEditingController();
  final _inputUsedController = TextEditingController();
  final _inputCostController = TextEditingController();
  final _miscellaneousDescController = TextEditingController();
  final _miscellaneousCostController = TextEditingController();
  final _coffeeVarietyController = TextEditingController();
  final _yieldController = TextEditingController();
  final _revenueController = TextEditingController();
  final _totalProductionCostController = TextEditingController();
  final _profitLossController = TextEditingController();
  final _loanSourceController = TextEditingController();
  final _loanAmountController = TextEditingController();
  final _interestRateController = TextEditingController();
  final _loanInterestController = TextEditingController();
  final _totalRepaymentController = TextEditingController();
  final _remainingBalanceController = TextEditingController();
  final _paymentAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
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
      coffeeVarietyController: _coffeeVarietyController,
      yieldController: _yieldController,
      revenueController: _revenueController,
      totalProductionCostController: _totalProductionCostController,
      profitLossController: _profitLossController,
      loanSourceController: _loanSourceController,
      loanAmountController: _loanAmountController,
      interestRateController: _interestRateController,
      loanInterestController: _loanInterestController,
      totalRepaymentController: _totalRepaymentController,
      remainingBalanceController: _remainingBalanceController,
      paymentAmountController: _paymentAmountController,
      onDataChanged: () {
        setState(() {
          _calculateTotalProductionCost();
        });
      },
    );
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await _dataManager.loadData((isFirstLaunch, retrievedCycle) {
      setState(() {
        _isFirstLaunch = isFirstLaunch;
        _retrievedCycle = retrievedCycle;
        _isLoading = false;
      });
    });
  }

  void _calculateTotalProductionCost() {
    _dataManager.calculateTotalProductionCost();
  }

  Future<void> _editCycleName() async {
    await _dataManager.editCycleName(() {
      setState(() {
        _isFirstLaunch = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Farm Management',
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
                  labourActivities: _dataManager.labourActivities,
                  mechanicalCosts: _dataManager.mechanicalCosts,
                  inputCosts: _dataManager.inputCosts,
                  miscellaneousCosts: _dataManager.miscellaneousCosts,
                  revenues: _dataManager.revenues,
                  paymentHistory: _dataManager.paymentHistory,
                  cycleName: _dataManager.currentCycle,
                  pastCycles: _dataManager.pastCycles,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            tooltip: 'Save Current Cycle',
            onPressed: _dataManager.saveForm,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            tooltip: 'Start New Cycle',
            onPressed: _dataManager.startNewCycle,
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            tooltip: 'Retrieve Past Cycle',
            onPressed: () async {
              await _dataManager.retrievePastCycle();
              setState(() {
                _retrievedCycle = _dataManager.retrievedCycle;
                _calculateTotalProductionCost();
              });
            },
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
        onPressed: () => Navigator.push(
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
                setState(() {
                  _dataManager.deleteActivity(category, index);
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

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Dashboard - ${_retrievedCycle ?? _dataManager.currentCycle}',
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, color: customBrown),
              ),
              if (_isFirstLaunch)
                IconButton(
                  icon: Icon(Icons.edit, color: customBrown),
                  onPressed: _editCycleName,
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
          _buildLabourCostCard(),
          const SizedBox(height: 16),
          if (_dataManager.labourActivities.isNotEmpty)
            ListTile(
              title: Text(
                  'Latest Labour: ${_dataManager.labourActivities.first['activity']} - KSH ${_dataManager.labourActivities.first['cost']}'),
              subtitle: Text('Date: ${_dataManager.labourActivities.first['date']}'),
            ),
          _buildMechanicalCostCard(),
          const SizedBox(height: 16),
          if (_dataManager.mechanicalCosts.isNotEmpty)
            ListTile(
              title: Text(
                  'Latest Equipment: ${_dataManager.mechanicalCosts.first['equipment']} - KSH ${_dataManager.mechanicalCosts.first['cost']}'),
              subtitle: Text('Date: ${_dataManager.mechanicalCosts.first['date']}'),
            ),
          _buildInputCostCard(),
          const SizedBox(height: 16),
          if (_dataManager.inputCosts.isNotEmpty)
            ListTile(
              title: Text(
                  'Latest Input: ${_dataManager.inputCosts.first['input']} - KSH ${_dataManager.inputCosts.first['cost']}'),
              subtitle: Text('Date: ${_dataManager.inputCosts.first['date']}'),
            ),
          _buildMiscellaneousCostCard(),
          const SizedBox(height: 16),
          if (_dataManager.miscellaneousCosts.isNotEmpty)
            ListTile(
              title: Text(
                  'Latest Misc: ${_dataManager.miscellaneousCosts.first['description']} - KSH ${_dataManager.miscellaneousCosts.first['cost']}'),
              subtitle:
                  Text('Date: ${_dataManager.miscellaneousCosts.first['date']}'),
            ),
        ],
      ),
    );
  }

  Widget _buildLabourCostCard() {
    return Card(
      color: Colors.red[100],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Labour Costs',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            TextFormField(
              controller: _labourActivityController,
              decoration: const InputDecoration(
                  labelText: 'Labour Activity',
                  prefixIcon: Icon(Icons.work),
                  hintText: 'e.g., Planting, Pruning'),
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
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _dataManager.labourActivityDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  setState(() => _dataManager.labourActivityDate = picked);
                }
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: customBrown, foregroundColor: Colors.white),
              onPressed: () {
                _dataManager.addLabourCost();
                setState(() {});
              },
              child: const Text('Add Labour Cost'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMechanicalCostCard() {
    return Card(
      color: Colors.blue[100],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Mechanical Costs',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return _dataManager.getEquipmentSuggestions();
                }
                return _dataManager.getEquipmentSuggestions().where((option) =>
                    option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
              },
              onSelected: (String selection) =>
                  _equipmentUsedController.text = selection,
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                _equipmentUsedController.text = controller.text;
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                      labelText: 'Equipment Used',
                      prefixIcon: Icon(Icons.agriculture),
                      hintText: 'e.g., Tractor, Harvester'),
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
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _dataManager.equipmentUsedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  setState(() => _dataManager.equipmentUsedDate = picked);
                }
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: customBrown, foregroundColor: Colors.white),
              onPressed: () {
                _dataManager.addMechanicalCost();
                setState(() {});
              },
              child: const Text('Add Equipment Cost'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCostCard() {
    return Card(
      color: Colors.orange[100],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Input Costs',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return _dataManager.getInputSuggestions();
                }
                return _dataManager.getInputSuggestions().where((option) =>
                    option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
              },
              onSelected: (String selection) => _inputUsedController.text = selection,
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                _inputUsedController.text = controller.text;
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                      labelText: 'Input Used',
                      prefixIcon: Icon(Icons.local_florist),
                      hintText: 'e.g., Fertilizer, Seeds'),
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
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _dataManager.inputUsedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  setState(() => _dataManager.inputUsedDate = picked);
                }
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: customBrown, foregroundColor: Colors.white),
              onPressed: () {
                _dataManager.addInputCost();
                setState(() {});
              },
              child: const Text('Add Input Cost'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiscellaneousCostCard() {
    return Card(
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
                  hintText: 'e.g., Repairs, Transport'),
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
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _dataManager.miscellaneousDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  setState(() => _dataManager.miscellaneousDate = picked);
                }
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: customBrown, foregroundColor: Colors.white),
              onPressed: () {
                _dataManager.addMiscellaneousCost();
                setState(() {});
              },
              child: const Text('Add Miscellaneous Cost'),
            ),
          ],
        ),
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
                    controller: _coffeeVarietyController,
                    decoration: const InputDecoration(
                        labelText: 'Coffee Variety',
                        prefixIcon: Icon(Icons.local_florist),
                        hintText: 'e.g., Arabica, Robusta'),
                    maxLength: 30,
                  ),
                  TextFormField(
                    controller: _yieldController,
                    decoration: const InputDecoration(
                        labelText: 'Yield (kg)',
                        prefixIcon: Icon(Icons.scale),
                        hintText: 'Enter yield in kilograms'),
                    keyboardType: TextInputType.number,
                  ),
                  TextFormField(
                    controller: _revenueController,
                    decoration: const InputDecoration(
                        labelText: 'Revenue (KSH)',
                        prefixIcon: Icon(Icons.attach_money),
                        hintText: 'Enter revenue in KSH'),
                    keyboardType: TextInputType.number,
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: customBrown, foregroundColor: Colors.white),
                    onPressed: () {
                      _dataManager.addRevenue();
                      setState(() {});
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
              itemBuilder: (context, index) => ListTile(
                title: Text(
                    '${_dataManager.revenues[index]['coffeeVariety']} - KSH ${_dataManager.revenues[index]['amount']}'),
                subtitle: Text(
                    'Yield: ${_dataManager.revenues[index]['yield']} kg - Date: ${_dataManager.revenues[index]['date']}'),
              ),
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
                    controller: _loanSourceController,
                    decoration: const InputDecoration(
                        labelText: 'Loan Source',
                        prefixIcon: Icon(Icons.business),
                        hintText: 'e.g., Cooperative, Bank, Microfinance'),
                    maxLength: 50,
                  ),
                  TextFormField(
                    controller: _loanAmountController,
                    decoration: const InputDecoration(
                        labelText: 'Loan Amount (KSH)',
                        prefixIcon: Icon(Icons.account_balance_wallet)),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _dataManager.updateLoanCalculations(),
                  ),
                  TextFormField(
                    controller: _interestRateController,
                    decoration: const InputDecoration(
                        labelText: 'Interest Rate (%)',
                        prefixIcon: Icon(Icons.percent)),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _dataManager.updateLoanCalculations(),
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
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _dataManager.paymentDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() => _dataManager.paymentDate = picked);
                      }
                    },
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: customBrown, foregroundColor: Colors.white),
                    onPressed: () {
                      _dataManager.recordPayment();
                      setState(() {});
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
              itemBuilder: (context, index) => ListTile(
                title: Text(
                    '${_dataManager.paymentHistory[index]['date']} - KSH ${_dataManager.paymentHistory[index]['amount']}'),
                subtitle: Text(
                    'Remaining: KSH ${_dataManager.paymentHistory[index]['remainingBalance']}'),
              ),
            ),
          ),
        ],
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
    _coffeeVarietyController.dispose();
    _yieldController.dispose();
    _revenueController.dispose();
    _totalProductionCostController.dispose();
    _profitLossController.dispose();
    _loanSourceController.dispose();
    _loanAmountController.dispose();
    _interestRateController.dispose();
    _loanInterestController.dispose();
    _totalRepaymentController.dispose();
    _remainingBalanceController.dispose();
    _paymentAmountController.dispose();
    super.dispose();
  }
}