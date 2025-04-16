import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:coffeecore/authentication/registration.dart';
import 'package:coffeecore/home.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fillAnimation; // For coffee "filling" effect
  late Animation<double> _textFadeAnimation; // For text fade-in/out

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4), 
      vsync: this,
    );

    // Animation for coffee filling the cup (0 to 1)
    _fillAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut), // Fill happens in first 60%
      ),
    );

    // Animation for text fade-in and fade-out
    _textFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.easeInOut), // Text fades in and out between 20%-80%
      ),
    );

    _controller.forward(); // Start the animation

    // Navigate after the animation completes
    SchedulerBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          _navigateBasedOnAuthState();
        }
      });
    });
  }

  Future<void> _navigateBasedOnAuthState() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // User is logged in, go to HomePage
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else {
      // User is not logged in, go to RegistrationScreen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const RegistrationScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.brown[100], 
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Coffee Cup Animation
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Coffee "liquid" filling effect
                        Positioned(
                          bottom: 0,
                          child: Container(
                            width: 100,
                            height: 100 * _fillAnimation.value, 
                            decoration: BoxDecoration(
                              color: Colors.brown[800], 
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(50),
                                bottomRight: Radius.circular(50),
                              ),
                            ),
                          ),
                        ),
                        // Coffee cup outline (static)
                        const Icon(
                          Icons.local_cafe, 
                          size: 120,
                          color: Colors.brown,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Fading Text
                  Opacity(
                    opacity: _textFadeAnimation.value,
                    child: const Text(
                      'Sow, Safeguard, Soar',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}