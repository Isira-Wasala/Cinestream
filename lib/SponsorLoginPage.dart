// ignore_for_file: prefer_const_literals_to_create_immutables,
//avoid_print, unnecessary_string_interpolations, prefer_const_constructors,
//library_private_types_in_public_api, file_names, use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:main/SponsorHomePage.dart';
import 'package:main/WelcomePage.dart';

import 'FrontEnd/DialogViews/ShowErrorDialog.dart';

class MyNavigatorObserver extends NavigatorObserver {
  @override
  void didPop(Route route, Route? previousRoute) {
    if (previousRoute == null) {
      // The user is going back to a previous route which does not exist
      // This means the back button was pressed on the initial route
      // Redirect to MyHomePage
      navigator?.pushReplacement(
        MaterialPageRoute(builder: (context) => const WelcomePage()),
      );
    }
  }
}

class SponsorLoginPage extends StatefulWidget {
  const SponsorLoginPage({super.key});

  @override
  _SponsorLoginPageState createState() => _SponsorLoginPageState();
}

class _SponsorLoginPageState extends State<SponsorLoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _ageController = TextEditingController();
  TextEditingController _countryController = TextEditingController();

  bool _isForgotPassword = false;
  bool _isCreatingAccount = false;

  String _errorMessage = '';

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sponsor Login',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _isForgotPassword
                      ? _buildForgotPasswordWidgets()
                      : _isCreatingAccount
                          ? _buildCreateAccountWidgets()
                          : _buildLoginWidgets(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildLoginWidgets() {
    return [
      const Text(
        'Welcome Back!',
        style: TextStyle(
          fontSize: 24.0,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      const SizedBox(height: 20.0),
      TextFormField(
        controller: _emailController,
        decoration: const InputDecoration(
          hintText: 'Email',
          border: OutlineInputBorder(),
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          prefixIcon: Icon(Icons.email, color: Colors.black),
          hintStyle: TextStyle(color: Colors.black),
        ),
        keyboardType: TextInputType.emailAddress,
        style: const TextStyle(color: Colors.black),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your email';
          }
          return null;
        },
      ),
      const SizedBox(height: 20.0),
      TextFormField(
        controller: _passwordController,
        obscureText: true,
        decoration: const InputDecoration(
          hintText: 'Password',
          border: OutlineInputBorder(),
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          prefixIcon: Icon(Icons.lock, color: Colors.black),
          hintStyle: TextStyle(color: Colors.black),
        ),
        style: const TextStyle(color: Colors.black),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your password';
          }
          return null;
        },
      ),
      const SizedBox(height: 20.0),
      ElevatedButton(
        onPressed: () {
          if (_formKey.currentState?.validate() ?? false) {
            _signInWithEmailAndPassword();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 82, 204, 71),
          textStyle: const TextStyle(fontSize: 20.0, color: Colors.black54),
          padding: const EdgeInsets.symmetric(horizontal: 60.0, vertical: 14.0),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
        ),
        child: const Text(
          'Login',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      const SizedBox(height: 10.0),
      TextButton(
        onPressed: () {
          setState(() {
            _isCreatingAccount = true;
          });
        },
        child: const Text(
          'Create New Account',
          style: TextStyle(color: Colors.black),
        ),
      ),
      const SizedBox(height: 10.0),
      TextButton(
        onPressed: () {
          setState(() {
            _isForgotPassword = true;
          });
        },
        child: const Text(
          'Forgot Password?',
          style: TextStyle(color: Colors.black),
        ),
      ),
    ];
  }

  List<Widget> _buildCreateAccountWidgets() {
    return [
      const Text(
        'Create New Account',
        style: TextStyle(
          fontSize: 24.0,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      const SizedBox(height: 20.0),
      TextFormField(
        controller: _nameController,
        decoration: const InputDecoration(
          hintText: 'Your name',
          border: OutlineInputBorder(),
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          prefixIcon: Icon(Icons.person, color: Colors.black),
          hintStyle: TextStyle(color: Colors.black),
        ),
        style: const TextStyle(color: Colors.black),
      ),
      const SizedBox(height: 20.0),
      TextFormField(
        controller: _ageController,
        decoration: const InputDecoration(
          hintText: 'Age',
          border: OutlineInputBorder(),
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          prefixIcon: Icon(Icons.calendar_today, color: Colors.black),
          hintStyle: TextStyle(color: Colors.black),
        ),
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.black),
      ),
      const SizedBox(height: 20.0),
      TextFormField(
        controller: _countryController,
        decoration: const InputDecoration(
          hintText: 'Country',
          border: OutlineInputBorder(),
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          prefixIcon: Icon(Icons.flag, color: Colors.black),
          hintStyle: TextStyle(color: Colors.black),
        ),
        style: const TextStyle(color: Colors.black),
      ),
      const SizedBox(height: 20.0),
      TextFormField(
        controller: _emailController,
        decoration: const InputDecoration(
          hintText: 'Email',
          border: OutlineInputBorder(),
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          prefixIcon: Icon(Icons.email, color: Colors.black),
          hintStyle: TextStyle(color: Colors.black),
        ),
        keyboardType: TextInputType.emailAddress,
        style: const TextStyle(color: Colors.black),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your email';
          }
          return null;
        },
      ),
      const SizedBox(height: 20.0),
      TextFormField(
        controller: _passwordController,
        obscureText: true,
        decoration: const InputDecoration(
          hintText: 'Password',
          border: OutlineInputBorder(),
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          prefixIcon: Icon(Icons.lock, color: Colors.black),
          hintStyle: TextStyle(color: Colors.black),
        ),
        style: const TextStyle(color: Colors.black),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your password';
          }
          return null;
        },
      ),
      const SizedBox(height: 20.0),
      TextFormField(
        obscureText: true,
        decoration: const InputDecoration(
          hintText: 'Confirm Password',
          border: OutlineInputBorder(),
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          prefixIcon: Icon(Icons.lock, color: Colors.black),
          hintStyle: TextStyle(color: Colors.black),
        ),
        style: const TextStyle(color: Colors.black),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please confirm your password';
          } else if (value != _passwordController.text) {
            return 'Passwords do not match';
          }
          return null;
        },
      ),
      const SizedBox(height: 20.0),
      ElevatedButton(
        onPressed: () {
          if (_formKey.currentState?.validate() ?? false) {
            _createAccount();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 82, 204, 71),
          textStyle: const TextStyle(fontSize: 20.0, color: Colors.black54),
          padding: const EdgeInsets.symmetric(horizontal: 60.0, vertical: 14.0),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
        ),
        child: const Text(
          'Create Account',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      const SizedBox(height: 10.0),
      TextButton(
        onPressed: () {
          setState(() {
            _isCreatingAccount = false;
          });
        },
        child: const Text(
          'Back to Login',
          style: TextStyle(color: Colors.black),
        ),
      ),
    ];
  }

  List<Widget> _buildForgotPasswordWidgets() {
    return [
      const Text(
        'Forgot Password?',
        style: TextStyle(
          fontSize: 24.0,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      const SizedBox(height: 20.0),
      TextFormField(
        controller: _emailController,
        decoration: const InputDecoration(
          hintText: 'Email',
          border: OutlineInputBorder(),
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          prefixIcon: Icon(Icons.email, color: Colors.black),
          hintStyle: TextStyle(color: Colors.black),
        ),
        keyboardType: TextInputType.emailAddress,
        style: const TextStyle(color: Colors.black),
      ),
      const SizedBox(height: 20.0),
      ElevatedButton(
        onPressed: () {
          _verifyEmail();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 82, 204, 71),
          textStyle: const TextStyle(fontSize: 20.0, color: Colors.black54),
          padding: const EdgeInsets.symmetric(horizontal: 60.0, vertical: 14.0),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
        ),
        child: const Text(
          'Verify',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      const SizedBox(height: 10.0),
      TextButton(
        onPressed: () {
          setState(() {
            _isForgotPassword = false;
          });
        },
        child: const Text(
          'Back to Login',
          style: TextStyle(color: Colors.black),
        ),
      ),
    ];
  }

  void _signInWithEmailAndPassword() async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (userCredential.user != null) {
        // Login successful, navigate to home page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SponsorHomePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'An error occurred';
      });
      if (e.code == "user-not-found") {
        await showErrorDialog(context, 'User not found');
      } else if (e.code == "wrong-password") {
        await showErrorDialog(context, 'Wrong password');
      } else if (e.code == "invalid-credential") {
        await showErrorDialog(context, 'Invalid email or password');
      } else if (e.code == "too-many-requests") {
        await showErrorDialog(context, 'Too many requests');
      } else {
        await showErrorDialog(context, e.message.toString());
      }
    }
  }

  void _createAccount() async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (userCredential.user != null) {
        // Save additional user details to Firestore
        await _firestore
            .collection('Sponsor')
            .doc(userCredential.user!.uid)
            .set({
          'name': _nameController.text,
          'age': _ageController.text,
          'country': _countryController.text,
          'email': _emailController.text,
        });

        // Account creation successful, navigate to home page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SponsorHomePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'An error occurred';
      });
      if (e.code == "email-already-in-use") {
        await showErrorDialog(context, 'Email already in use');
      } else if (e.code == "weak-password") {
        await showErrorDialog(context, 'Weak password');
      } else {
        await showErrorDialog(context, e.message.toString());
      }
    }
  }

  void _verifyEmail() async {
    try {
      await _auth.sendPasswordResetEmail(email: _emailController.text);

      // Open the link for email verification
      // You can open the link in a webview or use a package like url_launcher
      // Here's an example of using url_launcher:
      // await launch('https://cinestream-firebase-d1d2e.firebaseapp.com//auth/action');

      // For demonstration, you can print the link
      print('https://cinestream-firebase-d1d2e.firebaseapp.com//auth/action');

      // Notify user that email has been sent
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent. Please check your email.'),
        ),
      );
    } catch (e) {
      // Handle errors here
      print(e.toString());
      if (e == "user-not-found") {
        await showErrorDialog(context, 'User not found');
      } else if (e == "invalid-email") {
        await showErrorDialog(context, 'Invalid email');
      } else {
        await showErrorDialog(context, e.toString());
      }
    }
  }
}
