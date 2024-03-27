import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:main/FrontEnd/SettingsOptions/AppHelping.dart';
import 'package:main/FrontEnd/SettingsOptions/AppPrivacy.dart';
import 'package:main/SponsorHomePage.dart';
import 'package:main/Wallet.dart';

import 'FrontEnd/Agreements/SponsorAgreement.dart';
import 'FrontEnd/DialogViews/SignOutDialog.dart';
import 'FrontEnd/SettingsOptions/AccountSettings.dart';
import 'WelcomePage.dart';

class MyNavigatorObserver extends NavigatorObserver {
  @override
  void didPop(Route route, Route? previousRoute) {
    if (previousRoute == null) {
      // The user is going back to a previous route which does not exist
      // This means the back button was pressed on the initial route
      // Redirect to SponsorHomePage
      navigator?.pushReplacement(
        MaterialPageRoute(builder: (context) => const SponsorHomePage()),
      );
    }
  }
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

class SponsorSettingsPage extends StatefulWidget {
  final bool isSponsorMode;
  const SponsorSettingsPage({super.key, this.isSponsorMode = false});

  @override
  SponsorSettingsPageState createState() => SponsorSettingsPageState();
}

class SponsorSettingsPageState extends State<SponsorSettingsPage> {
  late bool isSponsorMode;

  @override
  void initState() {
    super.initState();
    isSponsorMode = widget.isSponsorMode;
  }

  void handleModeChange(String mode, bool value) {
    setState(() {
      if (mode == 'sponsor') {
        isSponsorMode = value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
        ),
        body: WillPopScope(
          onWillPop: () async {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const SponsorHomePage()),
            );
            return false;
          },
          child: ListView(
            children: ListTile.divideTiles(
              context: context,
              tiles: [
                SwitchListTile(
                  title: const Text('Sponsor Mode'),
                  value: isSponsorMode,
                  onChanged: (bool value) {
                    if (value) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SponsorAgreementPage(
                            onModeChange: (value) => handleModeChange(
                                'sponsor', value), // Corrected line
                          ),
                        ),
                      );
                    } /* else {
                      handleModeChange('sponsor', false);
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
                          builder: (context) => const PrivacyPage()),
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
                // Additional tiles for Sponsor Mode
                if (isSponsorMode)
                  ListTile(
                    leading: const Icon(Icons.ad_units),
                    title: const Text('Advert Tools'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const DetailPage(title: 'Advert Tools')),
                      );
                    },
                  ),
                if (isSponsorMode)
                  ListTile(
                    leading: const Icon(Icons.account_balance_wallet),
                    title: const Text('Wallet'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const Wallet(type: "sponsor")),
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
