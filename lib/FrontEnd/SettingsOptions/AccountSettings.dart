import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// firebase imports
import 'package:flutter/material.dart';

import '../DialogViews/DeleteDialog.dart';
import '../../WelcomePage.dart';

class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Settings'),
      ),
      body: ListView(
        children: ListTile.divideTiles(
          context: context,
          tiles: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profiles'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilesPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Password and Security'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PasswordSecurityPage()),
                );
              },
            ),
          ],
        ).toList(),
      ),
    );
  }
}

class ProfilesPage extends StatefulWidget {
  const ProfilesPage({super.key});

  @override
  ProfilesPageState createState() => ProfilesPageState();
}

class ProfilesPageState extends State<ProfilesPage> {
  String currentProfile = 'Current Profile';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(currentProfile),
      ),
      body: ListView(
        children: ListTile.divideTiles(
          context: context,
          tiles: [
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(currentProfile),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileDetailPage(
                      profileName: currentProfile,
                      onProfileUpdate: (newName) {
                        setState(() {
                          currentProfile = newName;
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ).toList(),
      ),
    );
  }
}

/////////////////////////////////////////--------------------------------------------------------------wont work-----------------------

class ProfileDetailPage extends StatefulWidget {
  final String profileName;
  final Function(String) onProfileUpdate;

  const ProfileDetailPage(
      {super.key, required this.profileName, required this.onProfileUpdate});

  @override
  ProfileDetailPageState createState() => ProfileDetailPageState();
}

class ProfileDetailPageState extends State<ProfileDetailPage> {
  TextEditingController nameController = TextEditingController();
  String profilePicture =
      'https://th.bing.com/th/id/R.1793bfb2e99bafe0dacdd0c4c142a1b6?rik=YweeylHdlmYULQ&pid=ImgRaw&r=0';
  String name = '';
  String age = '';
  String country = '';
  String userType = '';

  @override
  void initState() {
    super.initState();
    nameController.text = widget.profileName;
    fetchProfileDetails();
  }

  fetchProfileDetails() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final email = user.email;

      try {
        final creatorQuery = await FirebaseFirestore.instance
            .collection('Creator')
            .where('email', isEqualTo: email)
            .get();

        if (creatorQuery.docs.isNotEmpty) {
          final profileDoc = creatorQuery.docs.first;
          setState(() {
            name = profileDoc['name'] ?? 'not specified';
            age = profileDoc['age'] ?? 'not specified';
            country = profileDoc['country'] ?? 'not specified';
            profilePicture = profileDoc['profilePicture'] ??
                'https://th.bing.com/th/id/R.1793bfb2e99bafe0dacdd0c4c142a1b6?rik=YweeylHdlmYULQ&pid=ImgRaw&r=0'; // default profile picture URL
          });
          return;
        }
        // User is a regular user
        final userQuery = await FirebaseFirestore.instance
            .collection('Users')
            .where('email', isEqualTo: email)
            .get();

        if (userQuery.docs.isNotEmpty) {
          final profileDoc = userQuery.docs.first;
          setState(() {
            name = profileDoc['name'] ?? 'not specified';
            age = profileDoc['age'] ?? 'not specified';
            country = profileDoc['country'] ?? 'not specified';
            profilePicture = profileDoc['profilePicture'] ??
                'https://th.bing.com/th/id/R.1793bfb2e99bafe0dacdd0c4c142a1b6?rik=YweeylHdlmYULQ&pid=ImgRaw&r=0'; // default profile picture URL
          });
          return;
        }
        // User is an admin
        final adminQuery = await FirebaseFirestore.instance
            .collection('Sponsor')
            .where('email', isEqualTo: email)
            .get();
        if (adminQuery.docs.isNotEmpty) {
          final profileDoc = adminQuery.docs.first;
          setState(() {
            name = profileDoc['name'] ?? 'not specified';
            age = profileDoc['age'] ?? 'not specified';
            country = profileDoc['country'] ?? 'not specified';
            profilePicture = profileDoc['profilePicture'] ??
                'https://th.bing.com/th/id/R.1793bfb2e99bafe0dacdd0c4c142a1b6?rik=YweeylHdlmYULQ&pid=ImgRaw&r=0'; // default profile picture URL
          });
          return;
        }
        setState(() {
          userType = 'Creator profile not found';
        });
      } catch (e) {
        print('Error fetching profile details: $e');
        setState(() {
          userType = 'Error fetching profile';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Details'),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            title: const Text('Profile Picture'),
            subtitle: Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(profilePicture),
              ),
            ),
          ),
          ListTile(
            title: const Text('Name'),
            subtitle: Text(name),
            onTap: () async {
              final result = await showDialog(
                context: context,
                builder: (context) => EditFieldDialog(
                  initialValue: name,
                  fieldName: 'Name',
                  userId: FirebaseAuth.instance.currentUser?.uid ?? '',
                ),
              );

              if (result != null && result.isNotEmpty) {
                // Save the updated name to Firebase or perform other actions
                setState(() {
                  name = result;
                });
              }
            },
          ),
          ListTile(
            title: const Text('Age'),
            subtitle: Text(age),
            onTap: () async {
              final result = await showDialog(
                context: context,
                builder: (context) => EditFieldDialog(
                  initialValue: age,
                  fieldName: 'Age',
                  userId: FirebaseAuth.instance.currentUser?.uid ?? '',
                ),
              );
              if (result != null && result.isNotEmpty) {
                // Save the updated name to Firebase or perform other actions
                setState(() {
                  age = result;
                });
              }
            },
          ),
          ListTile(
            title: const Text('Country'),
            subtitle: Text(country),
            onTap: () async {
              final result = await showDialog(
                context: context,
                builder: (context) => EditFieldDialog(
                  initialValue: country,
                  fieldName: 'Country',
                  userId: FirebaseAuth.instance.currentUser?.uid ?? '',
                ),
              );
              if (result != null && result.isNotEmpty) {
                // Save the updated name to Firebase or perform other actions
                setState(() {
                  country = result;
                });
              }
            },
          ),
        ],
      ),
    );
  }
}

// password security page
class PasswordSecurityPage extends StatefulWidget {
  const PasswordSecurityPage({super.key});

  @override
  PasswordSecurityPageState createState() => PasswordSecurityPageState();
}

class PasswordSecurityPageState extends State<PasswordSecurityPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Password and Security'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          ListTile(
            title: const Text('Change Password'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PasswordForm()),
              );
            },
          ),
          ListTile(
            title: const Text('Email Verification'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              if (FirebaseAuth.instance.currentUser?.emailVerified == false) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const EmailVerificationPage()),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text(
                        'Your email is already verified. No action required.')));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.mail),
            title: const Text('Recovery Email'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const RecoveryEmailPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.red),
            title: const Text('Delete Account',
                style: TextStyle(color: Colors.red)),
            onTap: () async {
              final shouldDelete = await deleteDialog(context);
              if (shouldDelete) {
                await FirebaseAuth.instance.currentUser!.delete();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          const WelcomePage()), // need named route async function
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

// password form
class PasswordForm extends StatefulWidget {
  const PasswordForm({super.key});

  @override
  _PasswordFormState createState() => _PasswordFormState();
}

class _PasswordFormState extends State<PasswordForm> {
  final _formKey = GlobalKey<FormState>();
  String currentPassword = '';
  String newPassword = '';
  String confirmNewPassword = '';
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmNewPassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: <Widget>[
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Current Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureCurrentPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureCurrentPassword = !_obscureCurrentPassword;
                    });
                  },
                ),
              ),
              obscureText: _obscureCurrentPassword,
              onChanged: (value) {
                currentPassword = value;
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your current password';
                }
                return null;
              },
            ),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'New Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNewPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureNewPassword = !_obscureNewPassword;
                    });
                  },
                ),
              ),
              obscureText: _obscureNewPassword,
              onChanged: (value) {
                newPassword = value;
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your new password';
                }
                return null;
              },
            ),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmNewPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmNewPassword = !_obscureConfirmNewPassword;
                    });
                  },
                ),
              ),
              obscureText: _obscureConfirmNewPassword,
              onChanged: (value) {
                confirmNewPassword = value;
              },
              validator: (value) {
                if (value != newPassword) {
                  return 'New password and confirm password do not match';
                }
                return null;
              },
            ),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    child: const Text('Update'),
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        try {
                          // Get the current user
                          User? user = FirebaseAuth.instance.currentUser;
                          // Re-authenticate the user
                          AuthCredential credential =
                              EmailAuthProvider.credential(
                                  email: user!.email!,
                                  password: currentPassword);
                          await user.reauthenticateWithCredential(credential);
                          // Update the password
                          await user.updatePassword(newPassword);
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Password updated successfully')));
                          Navigator.pop(context);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Failed to update password: $e')));
                        }
                      }
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    child: const Text('Cancel'),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// email verification
class EmailVerificationPage extends StatelessWidget {
  const EmailVerificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    // check if current user is logged in and email is verified
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Verification'),
      ),
      body: Center(
        child: user != null && user.emailVerified
            ? const Text('Email is verified')
            : ElevatedButton(
                onPressed: () {
                  user?.sendEmailVerification();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text(
                          'Verification email sent to your email address')));
                },
                child: const Text('Send Verification Email'),
              ),
      ),
    );
  }
}

// recovery email class
class RecoveryEmailPage extends StatefulWidget {
  const RecoveryEmailPage({super.key});

  @override
  _RecoveryEmailPageState createState() => _RecoveryEmailPageState();
}

class _RecoveryEmailPageState extends State<RecoveryEmailPage> {
  final _formKey = GlobalKey<FormState>();
  String recoveryEmail = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recovery Email'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: <Widget>[
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Recovery Email',
              ),
              onChanged: (value) {
                recoveryEmail = value;
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your recovery email';
                }
                return null;
              },
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                child: const Text('Update'),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    // Here you can handle the recovery email update
                    // For example, you can save it to Firestore
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      await FirebaseFirestore.instance
                          .collection('Users')
                          .doc(user.uid)
                          .update({'recoveryEmail': recoveryEmail});
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content:
                              Text('Recovery email updated successfully')));
                      Navigator.pop(context);
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Editing fields for the profile
class EditFieldDialog extends StatefulWidget {
  final String initialValue;
  final String fieldName;
  final String userId;

  const EditFieldDialog({
    super.key,
    required this.initialValue,
    required this.fieldName,
    required this.userId,
  });

  @override
  _EditFieldDialogState createState() => _EditFieldDialogState();
}

class _EditFieldDialogState extends State<EditFieldDialog> {
  late TextEditingController _textEditingController;

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController(text: widget.initialValue);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit ${widget.fieldName}'),
      content: TextField(
        controller: _textEditingController,
        decoration: InputDecoration(labelText: widget.fieldName),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            // Update the corresponding field in Firestore
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              // check if the collection is 'Creator' or 'User'
              final creatorQuery = await FirebaseFirestore.instance
                  .collection('Creator')
                  .where('email', isEqualTo: user.email)
                  .get();
              if (creatorQuery.docs.isNotEmpty) {
                // update the field in Firestore
                await FirebaseFirestore.instance
                    .collection('Creator')
                    .doc(widget.userId)
                    .update({
                  _getFieldName(widget.fieldName): _textEditingController.text
                });
              } else {
                final userQuery = await FirebaseFirestore.instance
                    .collection('User')
                    .where('email', isEqualTo: user.email)
                    .get();
                if (userQuery.docs.isNotEmpty) {
                  // update the field in Firestore
                  await FirebaseFirestore.instance
                      .collection('User')
                      .doc(widget.userId)
                      .update({
                    _getFieldName(widget.fieldName): _textEditingController.text
                  });
                }
              }
              final adminQuery = await FirebaseFirestore.instance
                  .collection('Sponsor')
                  .where('email', isEqualTo: user.email)
                  .get();
              if (adminQuery.docs.isNotEmpty) {
                // update the field in Firestore
                await FirebaseFirestore.instance
                    .collection('Sponsor')
                    .doc(widget.userId)
                    .update({
                  _getFieldName(widget.fieldName): _textEditingController.text
                });
              }
            }
            Navigator.of(context).pop(_textEditingController.text);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  // Helper function to get the Firestore field name based on the UI field name
  String _getFieldName(String uiFieldName) {
    switch (uiFieldName) {
      case 'Name':
        return 'name';
      case 'Age':
        return 'age';
      case 'Country':
        return 'country';
      default:
        throw ArgumentError('Invalid field name: $uiFieldName');
    }
  }
}
