import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:main/UserLoginPage.dart'; // Adjust import path as per your project structure
import 'package:mockito/mockito.dart'; // Import your MyHomePage widget

class MockNavigatorObserver extends Mock implements NavigatorObserver {
  // Mock implementation
}

void main() {
  testWidgets('UserLoginPage UI Test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaterialApp(home: UserLoginPage()));

    // Verify that the login page contains necessary widgets
    expect(find.text('User Login'), findsOneWidget); // App bar title
    expect(find.byType(TextFormField),
        findsNWidgets(2)); // Email and password fields
    expect(find.text('Login'), findsOneWidget); // Login button
    expect(find.text('Create New Account'),
        findsOneWidget); // Create account button
    expect(find.text('Forgot Password?'),
        findsOneWidget); // Forgot password button
  });

  testWidgets('UserLoginPage Create Account Test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaterialApp(home: UserLoginPage()));

    // Tap on 'Create New Account' button
    await tester.tap(find.text('Create New Account'));
    await tester.pump();

    // Verify that create account widgets are displayed
    expect(find.text('Create New Account'), findsOneWidget);
    expect(find.text('Back to Login'), findsOneWidget);
    expect(find.text('Your name'), findsOneWidget);
    expect(find.text('Age'), findsOneWidget);
    expect(find.text('Country'), findsOneWidget);
    expect(find.text('Confirm Password'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
  });

  testWidgets('UserLoginPage Forgot Password Test',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaterialApp(home: UserLoginPage()));

    // Tap on 'Forgot Password?' button
    await tester.tap(find.text('Forgot Password?'));
    await tester.pump();

    // Verify that forgot password widgets are displayed
    expect(find.text('Forgot Password?'), findsOneWidget);
    expect(find.text('Back to Login'), findsOneWidget);
    expect(find.text('Verify'), findsOneWidget);
  });
  testWidgets('UserLoginPage Create Account Test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: UserLoginPage(),
      ),
    );
    // Tap on 'Create New Account' button
    await tester.tap(find.text('Create New Account'));
    await tester.pump();

    // Verify that create account widgets are displayed
    expect(find.text('Create New Account'), findsOneWidget);
    expect(find.text('Back to Login'), findsOneWidget);
    expect(find.text('Your name'), findsOneWidget);
    expect(find.text('Age'), findsOneWidget);
    expect(find.text('Country'), findsOneWidget);
    expect(find.text('Confirm Password'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);

    // Simulate entering text into text fields
    await tester.enterText(find.byType(TextFormField).at(0), 'Test User');
    await tester.enterText(find.byType(TextFormField).at(1), '25');
    await tester.enterText(find.byType(TextFormField).at(2), 'USA');
    await tester.enterText(find.byType(TextFormField).at(3), 'password');

    // Tap on 'Create Account' button
    await tester.tap(find.text('Create Account'));
    await tester.pump();
  });
}
