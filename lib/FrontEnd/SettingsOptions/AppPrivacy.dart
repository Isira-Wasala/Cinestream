import 'package:flutter/material.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: <Widget>[
            RichText(
              text: const TextSpan(
                children: <TextSpan>[
                  TextSpan(
                      text: 'User Privacy:\n\n',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                          color: Colors.black)),
                  TextSpan(
                      text:
                          "At Cinestream , we prioritize and value your privacy above all else. We are committed to ensuring that your personal information remains secure and confidential. Our stringent privacy measures access controls, continuous monitoring to safeguard your data against unauthorized access or misuse. We adhere strictly to global privacy standards and regulations, such as GDPR and CCPA, to guarantee transparency, accountability, and user control over their data. Rest assured that your trust in us is paramount, and we remain dedicated to upholding the highest standards of privacy protection throughout your experience with Cinestream . Your privacy is not just a feature; it's our promise.\n\n",
                      style: TextStyle(fontSize: 14.0, color: Colors.grey)),
                  TextSpan(
                      text: 'Account Privacy:\n\n',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                          color: Colors.black)),
                  TextSpan(
                      text:
                          'We understand the significance of safeguarding your personal information and ensuring its confidentiality. your data remains securely stored and inaccessible to unauthorized parties. We adhere to industry-leading standards to fortify your account against any potential breaches, offering you peace of mind as you engage with our application. Your trust is our top priority, and we are committed to upholding the highest standards of account privacy to maintain the integrity of your information.\n\n',
                      style: TextStyle(fontSize: 14.0, color: Colors.grey)),
                  TextSpan(
                      text: 'Community Standards:\n\n',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                          color: Colors.black)),
                  TextSpan(
                      text:
                          'We strive to maintain a respectful, engaging, and inclusive community. We expect every member to adhere to these standards, which prohibit any form of harassment, hate speech, bullying, or other harmful behavior. Violation of these standards may result in penalties ranging from temporary suspension to permanent removal from the platform, depending on the severity and frequency of the offense.\n\n',
                      style: TextStyle(fontSize: 14.0, color: Colors.grey)),
                  TextSpan(
                      text: 'Terms of Service:\n\n',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                          color: Colors.black)),
                  TextSpan(
                      text:
                          'Our Terms of Service outline the agreement between users and our application. By using our services, you agree to abide by these terms. You must be of legal age to use the application. Users are responsible for their actions and content shared through the platform. Any misuse or violation of these terms may result in the termination of your account. We reserve the right to modify or terminate our services at any time. Your privacy is important to us, and we are committed to protecting your data in accordance with our Privacy Policy. By using our application, you consent to the collection and use of your information as outlined in the Privacy Policy.\n\n',
                      style: TextStyle(fontSize: 14.0, color: Colors.grey)),
                  TextSpan(
                      text: 'Contact Us:\n\n',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                          color: Colors.black)),
                  TextSpan(
                      text:
                          'If you have any questions about our privacy policy, please contact us at:\n\nisirawasala01@gmail.com\nsahan@gmail.com\njwkj1212@gmail.com\nmalikkumara123@gmail.com',
                      style: TextStyle(fontSize: 14.0, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
