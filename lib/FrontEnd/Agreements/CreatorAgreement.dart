import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:main/CreatorLoginPage.dart';

// The CreatorAgreementPage widget, which displays an agreement text for creators.
class CreatorAgreementPage extends StatefulWidget {
  final ValueChanged<bool> onModeChange;
  const CreatorAgreementPage({super.key, required this.onModeChange});

  @override
  CreatorAgreementPageState createState() => CreatorAgreementPageState();
}

class CreatorAgreementPageState extends State<CreatorAgreementPage> {
  bool _agreementAccepted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Creator Agreement'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('CreatorAgreement')
            .doc('agreement')
            .get(),
        builder:
            (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.hasError) {
            return const Text("Something went wrong");
          }

          if (snapshot.hasData && !snapshot.data!.exists) {
            return const Text("Document does not exist");
          }

          if (snapshot.connectionState == ConnectionState.done) {
            Map<String, dynamic> data =
                snapshot.data!.data() as Map<String, dynamic>;
            return Column(
              children: [
                Text("Creator agreement:\n${data['agreement']}"),
                CheckboxListTile(
                  title: const Text("I Accept"),
                  value: _agreementAccepted,
                  onChanged: (newValue) {
                    setState(() {
                      _agreementAccepted = newValue!;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _agreementAccepted
                          ? () {
                              widget.onModeChange(true);
                              // Navigator.pushReplacement(
                              //   context,
                              //   MaterialPageRoute(
                              //       builder: (context) =>
                              //           const CreatorLoginPage()),
                              // );
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const CreatorLoginPage()),
                                (route) => false,
                              );
                            }
                          : null,
                      child: const Text('OK'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        widget.onModeChange(false);
                        Navigator.pop(context);
                      },
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ],
            );
          }
          return const Text("Loading");
        },
      ),
    );
  }
}
