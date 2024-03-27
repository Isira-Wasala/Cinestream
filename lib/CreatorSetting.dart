import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:main/CreatorHomePage.dart';
import 'package:main/FrontEnd/SettingsOptions/AppHelping.dart';
import 'package:main/FrontEnd/SettingsOptions/AppPrivacy.dart';
import 'package:main/Wallet.dart';

import 'FrontEnd/SettingsOptions/AccountSettings.dart';
import 'FrontEnd/Agreements/CreatorAgreement.dart';
import 'FrontEnd/DialogViews/SignOutDialog.dart';
import 'WelcomePage.dart';
import 'package:flutter_paypal_checkout/flutter_paypal_checkout.dart';

class MyNavigatorObserver extends NavigatorObserver {
  @override
  void didPop(Route route, Route? previousRoute) {
    if (previousRoute == null) {
      // The user is going back to a previous route which does not exist
      // This means the back button was pressed on the initial route
      // Redirect to MyHomePage
      navigator?.pushReplacement(
        MaterialPageRoute(
            builder: (context) => const CreatorHomePage(
                  creatorId: '',
                )),
      );
    }
  }
}

class CreatorSettingsPage extends StatefulWidget {
  final bool isCreatorMode;
  const CreatorSettingsPage({Key? key, this.isCreatorMode = false})
      : super(key: key);

  @override
  CreatorSettingsPageState createState() => CreatorSettingsPageState();
}

class DetailPage extends StatelessWidget {
  final String title;

  const DetailPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Text('Welcome to the $title'),
      ),
    );
  }
}

class CreatorSettingsPageState extends State<CreatorSettingsPage> {
  late bool isCreatorMode;

  @override
  void initState() {
    super.initState();
    isCreatorMode = widget.isCreatorMode;
  }

  void handleModeChange(String mode, bool value) {
    setState(() {
      if (mode == 'creator') {
        isCreatorMode = value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          automaticallyImplyLeading: false, // This line hides the back button
        ),
        body: WillPopScope(
          onWillPop: () async {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => const CreatorHomePage(
                        creatorId: '',
                      )),
            );
            return false;
          },
          child: ListView(
            children: ListTile.divideTiles(
              context: context,
              tiles: [
                SwitchListTile(
                  title: const Text('Creator Mode'),
                  value: isCreatorMode,
                  onChanged: (bool value) {
                    if (value) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreatorAgreementPage(
                            onModeChange: (value) => handleModeChange(
                                'creator', value), // Corrected line
                          ),
                        ),
                      );
                    } /* else {
                      handleModeChange('creator', false);
                    }*/
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Account Settings'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AccountSettingsPage()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.privacy_tip),
                  title: const Text('Privacy'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const PrivacyPage()), // need named route beacause of async function
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.help),
                  title: const Text('Help & Support'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const HelpCenterPage()),
                    );
                  },
                ),
                if (isCreatorMode)
                  ListTile(
                    leading: const Icon(Icons.videocam),
                    title: const Text('Streaming Tools'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const DetailPage(title: 'Streaming Tools')),
                      );
                    },
                  ),
                // additonal tiles for creator mode
                if (isCreatorMode)
                  ListTile(
                    leading: const Icon(Icons.account_balance_wallet),
                    title: const Text('Wallet'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const Wallet(type: "creator")),
                      );
                    },
                  ),
                // A list tile for the logout option.
                ListTile(
                  leading: const Icon(Icons.exit_to_app, color: Colors.red),
                  title:
                      const Text('Logout', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    final should_signOut = await showSignOutDialog(context);
                    if (should_signOut) {
                      await FirebaseAuth.instance.signOut();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const WelcomePage()), // need named route beacause of async function
                      );
                    }
                  },
                ),
              ],
            ).toList(),
          ),
        ));
  }
}
