import 'dart:math';
import 'package:flutter/material.dart';
import 'package:main/FrontEnd/config/keys.dart';
import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GoLivePage extends StatefulWidget {
  final String creatorMail;
  final String title;
  const GoLivePage(this.creatorMail, this.title, {super.key, required});
  @override
  State<StatefulWidget> createState() => GoLivePageState();
}

class GoLivePageState extends State<GoLivePage> {
  final _formKey = GlobalKey<FormState>();
  final idController = TextEditingController();
  bool isHostButton = false;
  String? creatorName;
  @override
  void initState() {
    super.initState();
    fetchCreatorName();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Live"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: idController,
                decoration: const InputDecoration(labelText: "Live ID"),
              ),
              Row(
                children: [
                  const Text("Host Button : "),
                  Switch(
                      value: isHostButton,
                      onChanged: (value) {
                        setState(() {
                          isHostButton = !isHostButton;
                        });
                      })
                ],
              )
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.blue,
          onPressed: () async {
            if (creatorName != null) {
              // Only navigate if the creator's name is fetched successfully
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => LivePage(
                  liveID: idController.text.toString(),
                  isHost: isHostButton,
                  title: widget.title,
                  creatorMail: widget.creatorMail,
                  updateFirebase: updateFirebase,
                  name: creatorName!, // Pass the creator's name to LivePage
                ),
              ));
            } else {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => LivePage(
                        liveID: idController.text.toString(),
                        isHost: isHostButton,
                        title: widget.title,
                        creatorMail: widget.creatorMail,
                        updateFirebase: updateFirebase,
                        name: widget.creatorMail.split('@').first,
                      )));
            }
          },
          child: const Text("Go Live")),
    );
  }

  Future<void> fetchCreatorName() async {
    String? name = await getCreatorNameFromFirestore(widget.creatorMail);
    setState(() {
      creatorName = name;
    });
  }

  Future<String?> getCreatorNameFromFirestore(String email) async {
    try {
      // Query Firestore to find the matching document where email equals the logged email
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance
              .collection('Creator')
              .where('email', isEqualTo: email)
              .get();

      // If there is no matching document, return null
      if (querySnapshot.docs.isEmpty) {
        print("No document found for the provided email.");
        return null;
      }

      // Retrieve the 'name' field from the first document (assuming email is unique)
      String creatorName = querySnapshot.docs.first.get('name');

      return creatorName;
    } catch (error) {
      print("Error fetching creator's name from Firestore: $error");
      return null;
    }
  }

  // update firebase by adding liveID to event collection
  Future<void> updateFirebase(String title, String creatorMail) async {
    final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('live_events')
        .where('creator_email', isEqualTo: creatorMail)
        .where('title', isEqualTo: title)
        .get();

    if (querySnapshot.docs.isEmpty) {
      print("Live event not found.");
      return;
    }

    String liveEventId = querySnapshot.docs.first.id;

    // Update the liveID in the database
    await FirebaseFirestore.instance
        .collection('live_events')
        .doc(liveEventId)
        .update({'liveID': idController.text.toString()});
  }
}

class LivePage extends StatelessWidget {
  final String liveID;
  final bool isHost;
  final String title;
  final String creatorMail;
  final Function(String, String) updateFirebase;
  final String name;

  const LivePage({
    super.key,
    required this.liveID,
    this.isHost = false,
    required this.title,
    required this.creatorMail,
    required this.updateFirebase,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    updateFirebase(title, creatorMail);
    return SafeArea(
      child: ZegoUIKitPrebuiltLiveStreaming(
        appID: appID,
        appSign: appSign,
        userID: 'user_id${Random().nextInt(100)}',
        userName: 'Host : $name',
        // userName: 'user_name${Random().nextInt(100)}',
        liveID: liveID,
        config: isHost
            ? ZegoUIKitPrebuiltLiveStreamingConfig.host()
            : ZegoUIKitPrebuiltLiveStreamingConfig.audience(),
      ),
    );
  }
}

class JoinLivePage extends StatelessWidget {
  final String liveID;
  final String title;

  const JoinLivePage({
    super.key,
    required this.liveID,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ZegoUIKitPrebuiltLiveStreaming(
        appID: appID,
        appSign: appSign,
        userID: 'user_id${Random().nextInt(100)}',
        userName: 'user_name${Random().nextInt(100)}',
        liveID: liveID,
        config: ZegoUIKitPrebuiltLiveStreamingConfig.audience(),
      ),
    );
  }
}
