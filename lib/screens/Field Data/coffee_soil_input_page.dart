import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'coffee_soil_form.dart';
import 'coffee_soil_summary_page.dart';

class CoffeeSoilInputPage extends StatefulWidget {
  final String structureType;

  const CoffeeSoilInputPage({required this.structureType, super.key});

  @override
  State<CoffeeSoilInputPage> createState() => _CoffeeSoilInputPageState();
}

class _CoffeeSoilInputPageState extends State<CoffeeSoilInputPage>
    with SingleTickerProviderStateMixin {
  late String _farmingScenario;
  late List<String> _plotIds;
  late TabController _tabController;
  late FlutterLocalNotificationsPlugin _notificationsPlugin;
  final Map<String, bool> _plotHasData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    _initializeNotifications();
    _farmingScenario = widget.structureType;
    _plotIds = _farmingScenario == 'multiple' ? ['Plot 1'] : ['SingleCrop'];
    _tabController = TabController(length: _plotIds.length, vsync: this);
    _checkPlotDataStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    _notificationsPlugin = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(initSettings);
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
  }

  Future<void> _checkPlotDataStatus() async {
    setState(() => _isLoading = true);
    final userId = FirebaseAuth.instance.currentUser!.uid;
    for (var plotId in _plotIds) {
      final snapshot = await FirebaseFirestore.instance
          .collection('SoilData')
          .where('userId', isEqualTo: userId)
          .where('plotId', isEqualTo: plotId)
          .where('isDeleted', isEqualTo: false)
          .get();
      if (mounted) {
        setState(() => _plotHasData[plotId] = snapshot.docs.isNotEmpty);
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _showOnboardingDialog() async {
    int? plotCount;
    String? plotLabelPrefix;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: const Text('Redefine Farming Structure',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A2C2A))),
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_farmingScenario == 'multiple') ...[
                  TextFormField(
                    decoration: const InputDecoration(
                        labelText: 'Number of Plots',
                        border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => plotCount = int.tryParse(value),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                        labelText: 'Plot Label Prefix',
                        border: OutlineInputBorder()),
                    onChanged: (value) =>
                        plotLabelPrefix = value.isNotEmpty ? value : 'Plot',
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (_farmingScenario != 'multiple' ||
                  (plotCount != null && plotCount! > 0)) {
                if (mounted) {
                  setState(() {
                    if (_farmingScenario == 'multiple') {
                      _plotIds = List.generate(plotCount!,
                          (i) => '${plotLabelPrefix ?? 'Plot'} ${i + 1}');
                      _tabController.dispose();
                      _tabController =
                          TabController(length: _plotIds.length, vsync: this);
                    }
                  });
                  Navigator.pop(dialogContext, true);
                  _checkPlotDataStatus();
                }
              }
            },
            child: const Text('OK', style: TextStyle(color: Color(0xFF4A2C2A))),
          ),
        ],
      ),
    );

    if (result != true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Structure not changed')));
    }
  }

  void _showFieldHistory() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                CoffeeSoilSummaryPage(userId: FirebaseAuth.instance.currentUser!.uid)));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _plotIds.length,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF3C2F2F),
          leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context)),
          title: const Text('Enhanced Soil Analysis',
              style: TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4.0),
            child: Container(
              color: const Color(0xFF3A5F0B),
              height: 4.0,
            ),
          ),
        ),
        backgroundColor: const Color(0xFFF5E8C7),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if (_plotIds.isNotEmpty)
                    Container(
                      color: const Color(0xFFF0E4D7),
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        labelColor: const Color(0xFF4A2C2A),
                        unselectedLabelColor: Colors.black54,
                        indicatorColor: const Color(0xFF3A5F0B),
                        tabs: _plotIds.map((plotId) => Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(plotId),
                              if (_plotHasData[plotId] == true) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.check_circle, size: 16, color: Colors.green),
                              ],
                            ],
                          ),
                        )).toList(),
                      ),
                    ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: _plotIds.map((plotId) => CoffeeSoilForm(
                            userId: FirebaseAuth.instance.currentUser!.uid,
                            plotId: plotId,
                            structureType: _farmingScenario,
                            notificationsPlugin: _notificationsPlugin,
                            onSave: _checkPlotDataStatus,
                          )).toList(),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF0E4D7),
                      border: Border(top: BorderSide(color: Color(0xFF3A5F0B), width: 2)),
                    ),
                    child: Row(
                      children: [
                        if (_farmingScenario == 'multiple')
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _showOnboardingDialog,
                              icon: const Icon(Icons.settings),
                              label: const Text('Redefine Structure'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4A2C2A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        if (_farmingScenario == 'multiple') const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _showFieldHistory,
                            icon: const Icon(Icons.history),
                            label: const Text('Soil History'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3A5F0B),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}