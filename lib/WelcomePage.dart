import 'dart:async';
import 'package:flutter/material.dart';
import 'package:main/LoginPage.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({Key? key});

  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
    Timer(const Duration(seconds: 3), () {
      // Navigate to MyHomePage after 1.5 seconds
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set background color to white
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Welcome ',
                  style: TextStyle(
                    color: Colors.black, // Set color of "Welcome" to black
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: 'to ',
                  style: TextStyle(
                    color: Colors.black, // Set color of "to" to black
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: 'Cinestream',
                  style: TextStyle(
                    color: Colors.black, // Set color of "Cinestream" to black
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
