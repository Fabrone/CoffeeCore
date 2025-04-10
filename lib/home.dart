import 'package:coffeecore/screens/Farm%20Management/coffee_management_screen.dart';
import 'package:coffeecore/screens/Field%20Data/coffee_soil_home_page.dart';
import 'package:coffeecore/screens/admin/admin_management_screen.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:coffeecore/models/user_model.dart';
import 'package:coffeecore/screens/learn_coffee_farming.dart';
import 'package:coffeecore/screens/manuals_screen.dart';
import 'package:coffeecore/screens/pests_diseases_home.dart';
import 'package:coffeecore/screens/user_profile.dart';
import 'package:coffeecore/screens/weather_screen.dart';
import 'package:coffeecore/screens/market_prices.dart';
import 'package:coffeecore/screens/market_officer_screen.dart';
import 'package:coffeecore/authentication/login.dart';
import 'package:coffeecore/settings/notifications_settings_screen.dart';
import 'package:coffeecore/settings/settings_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'dart:convert';
import 'dart:typed_data';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _userData;
  Uint8List? _profileImageBytes;
  bool _isMainAdmin = false;
  bool _isMarketOfficer = false;
  final logger = Logger(printer: PrettyPrinter());
  String? _userId;

  final List<String> _carouselImages = [
    'assets/coffee_weather.jpg',
    'assets/coffee_field_data.jpg',
    'assets/coffee_pestdisease_management.jpg',
    'assets/coffee_funds_management.jpg',
    'assets/coffee_manuals.jpg',
    'assets/coffee_farming_tips.jpg',
    'assets/coffee_soil.jpg',
  ];

  @override
  void initState() {
    super.initState();
    logger.i('HomePage initState called');
    _initializeUserData();
    _listenToAuthState();
  }

  Future<void> _initializeUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userId = user.uid;
      await _fetchUserData();
      _listenToUserAndRoleStatus();
    } else {
      _redirectToLogin('No user logged in');
    }
  }

  Future<void> _fetchUserData() async {
    if (_userId == null) return;

    try {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(_userId)
          .get();

      if (!userSnapshot.exists) {
        logger.w('User document not found in Users collection for UID: $_userId');
        _redirectToLogin('User account not found. Please log in again.');
        return;
      }

      AppUser appUser = AppUser.fromFirestore(userSnapshot as DocumentSnapshot<Map<String, dynamic>>, null);

      DocumentSnapshot adminSnapshot = await FirebaseFirestore.instance
          .collection('Admins')
          .doc(_userId)
          .get();
      bool isAdmin = adminSnapshot.exists;

      DocumentSnapshot marketOfficerSnapshot = await FirebaseFirestore.instance
          .collection('MarketOfficers')
          .doc(_userId)
          .get();
      bool isMarketOfficer = marketOfficerSnapshot.exists;

      String? profileImageBase64 = appUser.profileImage;
      Uint8List? decodedImage;

      try {
        if (profileImageBase64 != null && profileImageBase64.isNotEmpty) {
          decodedImage = base64Decode(profileImageBase64);
        }
      } catch (e) {
        logger.e('Error decoding profile image: $e');
        decodedImage = null; // Ensure decodedImage is null if decoding fails
      }

      if (mounted) {
        setState(() {
          _userData = appUser.toMap();
          _profileImageBytes = decodedImage;
          _isMainAdmin = isAdmin;
          _isMarketOfficer = isMarketOfficer;
          logger.i('Fetched data - UserId: $_userId, UserData: $_userData, IsAdmin: $_isMainAdmin, IsMarketOfficer: $_isMarketOfficer');
        });
      }
    } catch (e) {
      logger.e('Error fetching user data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching user data: $e')),
        );
      }
      // Do not redirect to login here; let the listener handle it
    }
  }

  void _listenToAuthState() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        logger.i('Auth state changed - User logged in: ${user.uid}');
        if (mounted) {
          setState(() {
            _userId = user.uid;
          });
          _fetchUserData();
          _listenToUserAndRoleStatus();
        }
      } else {
        logger.w('Auth state changed - No user logged in');
        _redirectToLogin('User logged out. Please log in again.');
      }
    });
  }

  void _listenToUserAndRoleStatus() {
    if (_userId == null) return;

    FirebaseFirestore.instance
        .collection('Users')
        .doc(_userId)
        .snapshots()
        .listen((userSnapshot) {
      if (!userSnapshot.exists) {
        logger.w('User document deleted from Users collection for UID: $_userId');
        _redirectToLogin('Your account has been removed. Please log in again.');
      } else if (mounted) {
        AppUser appUser = AppUser.fromFirestore(userSnapshot, null);
        String? profileImageBase64 = appUser.profileImage;
        Uint8List? decodedImage;
        try {
          if (profileImageBase64 != null && profileImageBase64.isNotEmpty) {
            decodedImage = base64Decode(profileImageBase64);
          }
        } catch (e) {
          logger.e('Error decoding profile image in listener: $e');
          decodedImage = null;
        }
        setState(() {
          _userData = appUser.toMap();
          _profileImageBytes = decodedImage;
          logger.i('User data updated: $_userData');
        });
      }
    }, onError: (e) {
      logger.e('Error listening to Users: $e');
      _redirectToLogin('Error syncing user data. Please log in again.');
    });

    FirebaseFirestore.instance
        .collection('Admins')
        .doc(_userId)
        .snapshots()
        .listen((adminSnapshot) {
      if (mounted) {
        bool newAdminStatus = adminSnapshot.exists;
        if (newAdminStatus != _isMainAdmin) {
          setState(() {
            _isMainAdmin = newAdminStatus;
            logger.i('Admin status updated: $_isMainAdmin');
          });
        }
      }
    }, onError: (e) {
      logger.e('Error listening to Admins: $e');
      if (mounted) {
        setState(() {
          _isMainAdmin = false;
        });
      }
    });

    FirebaseFirestore.instance
        .collection('MarketOfficers')
        .doc(_userId)
        .snapshots()
        .listen((marketOfficerSnapshot) {
      if (mounted) {
        bool newMarketOfficerStatus = marketOfficerSnapshot.exists;
        if (newMarketOfficerStatus != _isMarketOfficer) {
          setState(() {
            _isMarketOfficer = newMarketOfficerStatus;
            logger.i('Market Officer status updated: $_isMarketOfficer');
          });
        }
      }
    }, onError: (e) {
      logger.e('Error listening to MarketOfficers: $e');
      if (mounted) {
        setState(() {
          _isMarketOfficer = false;
        });
      }
    });
  }

  void _redirectToLogin(String message) {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _handleLogout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pop(context);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(MediaQuery.of(context).size.height * 0.08),
        child: AppBar(
          title: const Text(
            'CoffeeCore',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.brown[700],
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white, size: 40),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications, color: Colors.white, size: 40),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationsSettingsScreen()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white, size: 40),
              onPressed: () {},
            ),
          ],
        ),
      ),
      drawer: _buildDrawer(),
      body: Container(
        color: Colors.grey[200],
        child: Column(
          children: [
            _buildCarousel(),
            _buildClickableSections(),
            _buildRoleBasedButtons(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildRoleBasedButtons() {
    if (_isMainAdmin) {
      return _buildAdminButton();
    } else if (_isMarketOfficer) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Builder(
            builder: (context) => _buildMenuButton(context),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: _buildMarketOfficerButton(),
          ),
        ],
      );
    } else {
      return Builder(
        builder: (context) => _buildMenuButton(context),
      );
    }
  }

  Widget _buildAdminButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AdminManagementScreen()),
          );
        },
        icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
        label: const Text('Admin Management', style: TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          backgroundColor: Colors.brown[700],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext scaffoldContext) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton.icon(
        onPressed: () {
          Scaffold.of(scaffoldContext).openDrawer();
        },
        icon: const Icon(Icons.menu, color: Colors.white),
        label: const Text('MENU', style: TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          backgroundColor: Colors.brown[700],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildMarketOfficerButton() {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MarketOfficerScreen()),
        );
      },
      icon: const Icon(Icons.price_change, color: Colors.white),
      label: const Text('Set Prices', style: TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        backgroundColor: Colors.brown[700],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildCarousel() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.4,
      child: CarouselSlider(
        options: CarouselOptions(
          height: MediaQuery.of(context).size.height * 0.4,
          autoPlay: true,
          enlargeCenterPage: true,
          aspectRatio: 16 / 9,
          autoPlayCurve: Curves.fastOutSlowIn,
          enableInfiniteScroll: true,
          autoPlayAnimationDuration: const Duration(milliseconds: 800),
          viewportFraction: 0.8,
        ),
        items: _carouselImages.map((image) {
          int index = _carouselImages.indexOf(image);
          List<String> labels = [
            'Get Weather Forecasts',
            'Record Coffee Field Data',
            'Manage Pests & Diseases',
            'Manage Coffee Farming',
            'Coffee Farming Manuals',
            'Get Coffee Farming Tips',
            'Explore Coffee Soil Insights',
          ];
          return Stack(
            children: [
              Container(
                margin: const EdgeInsets.all(5.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  image: DecorationImage(image: AssetImage(image), fit: BoxFit.cover),
                ),
              ),
              Positioned(
                bottom: 10,
                left: 10,
                child: Container(
                  color: Colors.black54,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Text(labels[index], style: const TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildClickableSections() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildClickableCard('Coffee Farming Tips', Icons.lightbulb, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => LearnCoffeeFarming()));
          }),
          _buildClickableCard('Coffee Market Prices', Icons.shopping_cart, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => MarketPricesWidget()));
          }),
        ],
      ),
    );
  }

  Widget _buildClickableCard(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.brown[50],
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade500.withAlpha(128),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.brown[700]),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Manuals'),
        BottomNavigationBarItem(icon: Icon(Icons.coffee), label: 'Coffee'),
        BottomNavigationBarItem(icon: Icon(Icons.article), label: 'Tips'),
      ],
      currentIndex: _selectedIndex,
      selectedItemColor: Colors.brown[700],
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CoffeeManagementScreen()),
            );
          }
        });
      },
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const UserProfileScreen()));
            },
            child: UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Colors.brown[700]),
              accountName: Text(
                _userData?['fullName'] ?? 'Loading...',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: _profileImageBytes != null
                    ? ClipOval(
                        child: Image.memory(
                          _profileImageBytes!,
                          fit: BoxFit.cover,
                          width: 60,
                          height: 60,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(Icons.person, size: 40, color: Colors.brown[700]),
                        ),
                      )
                    : Icon(Icons.person, size: 40, color: Colors.brown[700]),
              ),
              accountEmail: null,
            ),
          ),
          _buildDrawerItem(Icons.home, 'Home', () {
            Navigator.pop(context);
            setState(() {});
          }),
          _buildDrawerItem(Icons.cloud, 'Weather', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const WeatherScreen()));
          }),
          _buildDrawerItem(Icons.input, 'Field Data (Soil)', () {
            logger.i('Navigating to CoffeeSoilHomePage, userId: $_userId');
            if (_userId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CoffeeSoilHomePage()),
              );
            } else {
              logger.w('User ID is null, attempting refresh');
              _fetchUserData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User ID not available. Retrying...')),
              );
            }
          }),
          _buildDrawerItem(Icons.pest_control, 'Pests & Diseases', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const PestDiseaseHomePage()));
          }),
          _buildDrawerItem(Icons.supervisor_account, 'Farm Management', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const CoffeeManagementScreen()));
          }),
          _buildDrawerItem(Icons.book, 'Coffee Manuals', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ManualsScreen()));
          }),
          _buildDrawerItem(Icons.settings, 'Settings', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen()));
          }),
          _buildDrawerItem(Icons.logout, 'Logout', _handleLogout),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }
}