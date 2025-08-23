import 'dart:convert';
import 'dart:developer' as developer;
import 'package:coffeecore/screens/Field%20Data/coffee_soil_form.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:uuid/uuid.dart';

class CoffeeSoilInputPage extends StatefulWidget {
  const CoffeeSoilInputPage({super.key});

  @override
  State<CoffeeSoilInputPage> createState() => _CoffeeSoilInputPageState();
}

class _CoffeeSoilInputPageState extends State<CoffeeSoilInputPage> {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  List<String> _plotIds = [];
  String _userId = '';
  String? _selectedPlotId;
  bool _isLoading = true;
  bool _hasNotificationPermission = false;
  final Map<String, String> _tempPlotIds = {}; // Map form index to temp plot ID

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    _initializeUser();
    _initializeNotifications();
    _loadPlots();
  }

  Future<void> _initializeUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          _userId = user.uid;
        });
        developer.log('User initialized: $_userId', name: 'CoffeeSoilInputPage');
      } else {
        developer.log('No user logged in', name: 'CoffeeSoilInputPage');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please log in to continue.'),
              backgroundColor: Color(0xFF4A2C2A),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      developer.log('Error initializing user: $e',
          name: 'CoffeeSoilInputPage', error: e, stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to load user data. Please try again.'),
            backgroundColor: Color(0xFF4A2C2A),
          ),
        );
      }
    }
  }

  Future<void> _initializeNotifications() async {
    try {
      const androidInitSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initializationSettings = InitializationSettings(android: androidInitSettings);
      await _notificationsPlugin.initialize(initializationSettings);

      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      bool? granted = await androidPlugin?.requestNotificationsPermission();
      final prefs = await SharedPreferences.getInstance();
      bool hasPrompted = prefs.getBool('has_prompted_notifications') ?? false;

      setState(() {
        _hasNotificationPermission = granted ?? false;
      });

      developer.log('Notification initialization: permission = $_hasNotificationPermission',
          name: 'CoffeeSoilInputPage');

      if (!_hasNotificationPermission && !hasPrompted) {
        await _promptNotificationPermission();
        await prefs.setBool('has_prompted_notifications', true);
      } else if (_hasNotificationPermission) {
        await _retryPendingNotifications();
      }
    } catch (e, stackTrace) {
      developer.log('Error initializing notifications: $e',
          name: 'CoffeeSoilInputPage', error: e, stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to set up notifications. Please try again.'),
            backgroundColor: Color(0xFF4A2C2A),
          ),
        );
      }
    }
  }

  Future<void> _promptNotificationPermission() async {
    try {
      final currentContext = context; // Capture context
      final result = await showDialog<bool>(
        context: currentContext,
        builder: (context) => AlertDialog(
          title: const Text('Enable Notifications', style: TextStyle(color: Color(0xFF4A2C2A))),
          content: const Text(
            'Notifications are required for soil follow-up reminders. Would you like to enable them now?',
            style: TextStyle(color: Color(0xFF3A5F0B)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Skip', style: TextStyle(color: Color(0xFF4A2C2A))),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Enable', style: TextStyle(color: Color(0xFF4A2C2A))),
            ),
          ],
        ),
      );

      if (result == true) {
        final androidPlugin = _notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        bool? granted = await androidPlugin?.requestNotificationsPermission();
        setState(() {
          _hasNotificationPermission = granted ?? false;
        });
        if (_hasNotificationPermission) {
          await _retryPendingNotifications();
        }
        developer.log('Notification permission prompt result: $_hasNotificationPermission',
            name: 'CoffeeSoilInputPage');
      } else {
        developer.log('User skipped notification permission prompt', name: 'CoffeeSoilInputPage');
      }
    } catch (e, stackTrace) {
      developer.log('Error prompting notification permission: $e',
          name: 'CoffeeSoilInputPage', error: e, stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to request notification permissions. Please enable them in settings.'),
            backgroundColor: Color(0xFF4A2C2A),
          ),
        );
      }
    }
  }

  Future<void> _retryPendingNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingNotifications = prefs.getStringList('pending_notifications') ?? [];
      developer.log('Found ${pendingNotifications.length} pending notifications',
          name: 'CoffeeSoilInputPage');

      if (pendingNotifications.isEmpty) return;

      for (final notification in pendingNotifications) {
        final decoded = jsonDecode(notification) as Map<String, dynamic>;
        final date = DateTime.parse(decoded['date'] as String);
        final message = decoded['message'] as String;
        final plotId = decoded['plotId'] as String;

        if (date.isAfter(DateTime.now())) {
          await _scheduleReminder(date, message, plotId);
          developer.log('Retried notification for plot: $plotId at $date', name: 'CoffeeSoilInputPage');
        }
      }

      await prefs.setStringList('pending_notifications', []);
      developer.log('Cleared pending notifications after retry', name: 'CoffeeSoilInputPage');
    } catch (e, stackTrace) {
      developer.log('Error retrying pending notifications: $e',
          name: 'CoffeeSoilInputPage', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> _scheduleReminder(DateTime date, String message, String plotId) async {
    try {
      if (!_hasNotificationPermission) {
        final prefs = await SharedPreferences.getInstance();
        final pendingNotifications = prefs.getStringList('pending_notifications') ?? [];
        pendingNotifications.add(jsonEncode({
          'date': date.toIso8601String(),
          'message': message,
          'plotId': plotId,
        }));
        await prefs.setStringList('pending_notifications', pendingNotifications);
        developer.log('Stored notification offline for plot: $plotId at $date',
            name: 'CoffeeSoilInputPage');
        return;
      }

      const androidDetails = AndroidNotificationDetails(
        'soil_reminder',
        'Soil Reminders',
        channelDescription: 'Reminders for soil follow-ups',
        importance: Importance.max,
        priority: Priority.high,
      );
      const notificationDetails = NotificationDetails(android: androidDetails);
      await _notificationsPlugin.zonedSchedule(
        (_userId + plotId + date.toString()).hashCode,
        'Soil Follow-Up for $plotId',
        message,
        tz.TZDateTime.from(date, tz.local),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      final querySnapshot = await FirebaseFirestore.instance
          .collection('SoilData')
          .where('userId', isEqualTo: _userId)
          .where('plotId', isEqualTo: plotId)
          .where('interventionFollowUpDate', isEqualTo: Timestamp.fromDate(date))
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.update({'notificationTriggered': true});
        developer.log('Updated notificationTriggered for doc: ${doc.id}', name: 'CoffeeSoilInputPage');
      }

      developer.log('Scheduled reminder for plot: $plotId at $date', name: 'CoffeeSoilInputPage');
    } catch (e, stackTrace) {
      developer.log('Error scheduling reminder: $e',
          name: 'CoffeeSoilInputPage', error: e, stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to schedule reminder. Please try again.'),
            backgroundColor: Color(0xFF4A2C2A),
          ),
        );
      }
    }
  }

  Future<void> _loadPlots() async {
    try {
      setState(() => _isLoading = true);
      final isOnline = await _isConnected();
      final prefs = await SharedPreferences.getInstance();

      if (isOnline && _userId.isNotEmpty) {
        developer.log('Loading plots online for user: $_userId', name: 'CoffeeSoilInputPage');
        final userDoc = await FirebaseFirestore.instance.collection('Users').doc(_userId).get();

        final plotData = userDoc.data()?['plots'] as Map<String, dynamic>?;
        final cachedPlots = prefs.getString('cached_plots_$_userId');

        if (plotData != null) {
          setState(() {
            _plotIds = List<String>.from(plotData['plotIds'] ?? []);
            _selectedPlotId = _plotIds.isNotEmpty ? _plotIds[0] : null;
            if (_plotIds.isEmpty) {
              _plotIds.add('temp_0');
              _selectedPlotId = 'temp_0';
              _tempPlotIds['0'] = 'temp_0';
            }
          });

          await prefs.setString('cached_plots_$_userId',
              jsonEncode({'plotIds': _plotIds}));
          developer.log('Loaded plots from Firestore: $_plotIds',
              name: 'CoffeeSoilInputPage');
        } else if (cachedPlots != null) {
          final decoded = jsonDecode(cachedPlots) as Map<String, dynamic>;
          setState(() {
            _plotIds = List<String>.from(decoded['plotIds'] ?? []);
            _selectedPlotId = _plotIds.isNotEmpty ? _plotIds[0] : null;
            if (_plotIds.isEmpty) {
              _plotIds.add('temp_0');
              _selectedPlotId = 'temp_0';
              _tempPlotIds['0'] = 'temp_0';
            }
          });
          developer.log('Loaded plots from cache: $_plotIds',
              name: 'CoffeeSoilInputPage');
        } else {
          setState(() {
            _plotIds = ['temp_0'];
            _selectedPlotId = 'temp_0';
            _tempPlotIds['0'] = 'temp_0';
          });
          developer.log('Initialized default state: no plots',
              name: 'CoffeeSoilInputPage');
        }
      } else {
        final cachedPlots = prefs.getString('cached_plots_$_userId');
        if (cachedPlots != null) {
          final decoded = jsonDecode(cachedPlots) as Map<String, dynamic>;
          setState(() {
            _plotIds = List<String>.from(decoded['plotIds'] ?? []);
            _selectedPlotId = _plotIds.isNotEmpty ? _plotIds[0] : null;
            if (_plotIds.isEmpty) {
              _plotIds.add('temp_0');
              _selectedPlotId = 'temp_0';
              _tempPlotIds['0'] = 'temp_0';
            }
          });
          developer.log('Loaded plots from cache (offline): $_plotIds',
              name: 'CoffeeSoilInputPage');
        } else {
          setState(() {
            _plotIds = ['temp_0'];
            _selectedPlotId = 'temp_0';
            _tempPlotIds['0'] = 'temp_0';
          });
          developer.log('Initialized default state (offline): no plots',
              name: 'CoffeeSoilInputPage');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Device offline. Using cached data.'),
                backgroundColor: Color(0xFF4A2C2A),
              ),
            );
          }
        }
      }

      setState(() => _isLoading = false);
      developer.log('Plots loaded: $_plotIds, selected: $_selectedPlotId',
          name: 'CoffeeSoilInputPage');
    } catch (e, stackTrace) {
      developer.log('Error loading plots: $e',
          name: 'CoffeeSoilInputPage', error: e, stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to load plot data. Please try again.'),
            backgroundColor: Color(0xFF4A2C2A),
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _syncPlots() async {
    try {
      final isOnline = await _isConnected();
      if (!isOnline || _userId.isEmpty) {
        developer.log('Skipping plot sync: offline=${!isOnline}, userId=$_userId',
            name: 'CoffeeSoilInputPage');
        if (!isOnline && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Device offline. Plot changes will sync when online.'),
              backgroundColor: Color(0xFF4A2C2A),
            ),
          );
        }
        return;
      }

      developer.log('Syncing plots for user: $_userId, plots: $_plotIds', name: 'CoffeeSoilInputPage');
      await FirebaseFirestore.instance.collection('Users').doc(_userId).set({
        'plots': {
          'plotIds': _plotIds.where((id) => !id.startsWith('temp_')).toList(),
        },
      }, SetOptions(merge: true));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_plots_$_userId',
          jsonEncode({'plotIds': _plotIds}));
      developer.log('Successfully synced plots: $_plotIds', name: 'CoffeeSoilInputPage');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plot data synced successfully'),
            backgroundColor: Color(0xFF4A2C2A),
          ),
        );
      }
    } catch (e, stackTrace) {
      developer.log('Error syncing plots: $e',
          name: 'CoffeeSoilInputPage', error: e, stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to sync plot data. Please try again.'),
            backgroundColor: Color(0xFF4A2C2A),
          ),
        );
      }
    }
  }

  Future<void> _addNewPlot() async {
    try {
// Capture context
      String newPlotId = 'temp_${Uuid().v4()}';
      setState(() {
        _plotIds.add(newPlotId);
        _selectedPlotId = newPlotId;
        _tempPlotIds[_plotIds.length.toString()] = newPlotId;
      });
      developer.log('Added new temporary plot: $newPlotId', name: 'CoffeeSoilInputPage');
    } catch (e, stackTrace) {
      developer.log('Error adding new plot: $e',
          name: 'CoffeeSoilInputPage', error: e, stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to add new plot. Please try again.'),
            backgroundColor: Color(0xFF4A2C2A),
          ),
        );
      }
    }
  }

  void _onInputInteraction() {
    developer.log('Input interaction detected', name: 'CoffeeSoilInputPage');
  }

  void _onSave(String tempPlotId, String newPlotId) {
    setState(() {
      final index = _plotIds.indexOf(tempPlotId);
      if (index != -1) {
        _plotIds[index] = newPlotId;
        _selectedPlotId = newPlotId;
        _tempPlotIds[index.toString()] = newPlotId;
      }
    });
    _syncPlots();
    developer.log('Updated plot ID from $tempPlotId to $newPlotId', name: 'CoffeeSoilInputPage');
  }

  Future<bool> _isConnected() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final isOnline = connectivityResult.contains(ConnectivityResult.mobile) ||
          connectivityResult.contains(ConnectivityResult.wifi);
      developer.log('Connectivity check: isOnline=$isOnline, result=$connectivityResult',
          name: 'CoffeeSoilInputPage');
      return isOnline;
    } catch (e, stackTrace) {
      developer.log('Error checking connectivity: $e',
          name: 'CoffeeSoilInputPage', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3C2F2F),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            developer.log('Navigating back from CoffeeSoilInputPage', name: 'CoffeeSoilInputPage');
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Enhanced Soil Analysis',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
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
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF4A2C2A)),
                  SizedBox(height: 16),
                  Text('Loading...', style: TextStyle(color: Color(0xFF4A2C2A))),
                ],
              ),
            )
          : Column(
              children: [
                // Plot Selection
                Container(
                  color: const Color(0xFFF0E4D7),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: DropdownButton<String>(
                    value: _selectedPlotId,
                    isExpanded: true,
                    hint: const Text('Select a Plot', style: TextStyle(color: Color(0xFF4A2C2A))),
                    items: _plotIds
                        .map((plotId) => DropdownMenuItem(
                              value: plotId,
                              child: Text(
                                plotId.startsWith('temp_') ? 'New Plot' : plotId,
                                style: const TextStyle(color: Color(0xFF4A2C2A)),
                              ),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPlotId = value;
                      });
                      developer.log('Selected plot: $value', name: 'CoffeeSoilInputPage');
                    },
                    style: const TextStyle(color: Color(0xFF4A2C2A)),
                    dropdownColor: const Color(0xFFF0E4D7),
                    underline: Container(
                      height: 2,
                      color: const Color(0xFF3A5F0B),
                    ),
                  ),
                ),
                // Form
                Expanded(
                  child: CoffeeSoilForm(
                    key: ValueKey(_selectedPlotId),
                    userId: _userId,
                    plotId: _selectedPlotId ?? 'temp_0',
                    notificationsPlugin: _notificationsPlugin,
                    onSave: _onSave,
                    onInputInteraction: _onInputInteraction,
                  ),
                ),
                // Add New Plot button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0E4D7),
                    border: Border(top: BorderSide(color: Color(0xFF3A5F0B), width: 2)),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _addNewPlot,
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text('Add New Plot', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A2C2A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}