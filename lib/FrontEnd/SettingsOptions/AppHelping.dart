import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({super.key});

  @override
  HelpCenterPageStage createState() => HelpCenterPageStage();
}

class HelpCenterPageStage extends State<HelpCenterPage> {
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final String currentUserEmail = FirebaseAuth.instance.currentUser!.email!;

  Future<void> _sendEmail() async {
    final Uri params = Uri(
      scheme: 'mailto',
      path: 'isirawasala01@gmail.com',
      query:
          'subject=${_subjectController.text}&body=${_bodyController.text}&cc=$currentUserEmail',
    );

    var url = params.toString();
    if (await canLaunch(url)) {
      await launch(url);
      _subjectController.clear();
      _bodyController.clear();
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            const Text(
              'If you found a content/activity that violates community standards, or you need help from an agent for application errors, please submit an email.',
              style: TextStyle(fontSize: 16),
            ),
            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(labelText: 'Subject'),
            ),
            TextField(
              controller: _bodyController,
              decoration: const InputDecoration(labelText: 'Body'),
            ),
            ElevatedButton(
              onPressed: _sendEmail,
              style: ElevatedButton.styleFrom(
                primary: Color.fromARGB(255, 82, 204, 71), // Background color
                onPrimary: Colors.white, // Text color
              ),
              child: const Text('Send Email'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }
}
