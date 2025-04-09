import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:coffeecore/authentication/splashscreen.dart';
import 'package:coffeecore/authentication/login.dart';
import 'package:coffeecore/authentication/registration.dart';
import 'package:coffeecore/home.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CoffeeCore', // Updated app name
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.brown, // Coffee-inspired color
          primary: Colors.brown[700], // Darker coffee shade
          secondary: Colors.green[800], // Hint of coffee plant green
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegistrationScreen(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}