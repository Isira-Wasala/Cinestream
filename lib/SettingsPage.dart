import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:main/MyHomePage.dart';
import 'package:main/FrontEnd/SettingsOptions/AccountSettings.dart';
import 'package:main/FrontEnd/Agreements/CreatorAgreement.dart';
import 'package:main/FrontEnd/Agreements/SponsorAgreement.dart';
import 'package:main/FrontEnd/DialogViews/SignOutDialog.dart';
import 'package:main/FrontEnd/SettingsOptions/AppHelping.dart';
import 'package:main/FrontEnd/SettingsOptions/AppPrivacy.dart';
import 'package:main/Wallet.dart';
import 'package:main/WelcomePage.dart';

class MyNavigatorObserver extends NavigatorObserver {
  @override
  void didPop(Route route, Route? previousRoute) {
    if (previousRoute == null) {
      // The user is going back to a previous route which does not exist
      // This means the back button was pressed on the initial route
      // Redirect to MyHomePage
      navigator?.pushReplacement(
        MaterialPageRoute(builder: (context) => const MyHomePage()),
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

class SettingsPage extends StatefulWidget {
  final bool isCreatorMode;
  final bool isSponsorMode;
  const SettingsPage(
      {super.key, this.isCreatorMode = false, this.isSponsorMode = false});
  @override
  SettingsPageState createState() => SettingsPageState();
}

// the state for the SettingsPage widget, including the state variables for creator mode and sponsor mode.
class SettingsPageState extends State<SettingsPage> {
  late bool isCreatorMode;
  late bool isSponsorMode;

  @override
  void initState() {
    super.initState();
    isCreatorMode = widget.isCreatorMode;
    isSponsorMode = widget.isSponsorMode;
  }

  void handleModeChange(String mode, bool value) {
    setState(() {
      if (mode == 'creator') {
        isCreatorMode = value;
      } else if (mode == 'sponsor') {
        isSponsorMode = value;
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
              MaterialPageRoute(builder: (context) => const MyHomePage()),
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
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet),
                  title: const Text('Wallet'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const Wallet(type: "user")),
                    );
                  },
                ),
                // A list tile for the logout option.
                ListTile(
                  leading: const Icon(Icons.exit_to_app, color: Colors.red),
                  title:
                      const Text('Logout', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    final shouldSignout = await showSignOutDialog(context);
                    if (shouldSignout) {
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
