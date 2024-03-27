import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:main/ContentViewer.dart';
import 'package:main/FrontEnd/DialogViews/ShowErrorDialog.dart';
import 'package:main/PaymentFunction.dart';
import 'package:main/go_live.dart';

class ProfilePage extends StatefulWidget {
  final String creatorName;

  const ProfilePage({super.key, required this.creatorName});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String profilePicture =
      'https://th.bing.com/th/id/R.1793bfb2e99bafe0dacdd0c4c142a1b6?rik=YweeylHdlmYULQ&pid=ImgRaw&r=0';
  String name = '';
  String age = '';
  String country = '';

  @override
  void initState() {
    super.initState();
    fetchProfileDetails();
  }

  Future<void> fetchProfileDetails() async {
    try {
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Creator')
          .where('name', isEqualTo: widget.creatorName)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final profileDoc =
            querySnapshot.docs.first.data() as Map<String, dynamic>;
        setState(() {
          this.name = profileDoc['name'] ?? 'not specified';
          this.age = profileDoc['age']?.toString() ??
              'not specified'; // Ensure age is fetched as string
          this.country = profileDoc['country'] ?? 'not specified';
          this.profilePicture = profileDoc['profilePicture'] ?? profilePicture;
        });
      }
    } catch (e) {
      print('Error fetching profile details: $e');
      // Handle error
    }
  }

  Future<String> getCreatorEmail(String creatorName) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Creator')
          .where('name', isEqualTo: creatorName)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first['email'];
      } else {
        return ''; // Return an empty string if no matching document found
      }
    } catch (e) {
      print('Error fetching creator email: $e');
      return ''; // Return an empty string in case of error
    }
  }

  Widget _buildVideosTab() {
    return FutureBuilder<String>(
      future: getCreatorEmail(widget.creatorName),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        if (snapshot.hasData) {
          String creatorEmail = snapshot.data!;
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('content')
                .where('creatorEmail', isEqualTo: creatorEmail)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }
              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot content = snapshot.data!.docs[index];
                    return GestureDetector(
                      onTap: () {
                        _handleVideoTap(content);
                        // display the price and the descrption of the video. meka price as button and add // await processPayment();
                        // Navigate to content viewer() page if payment is successful
                      },
                      child: Container(
                        color: Colors.grey[300],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Image.network(
                              content['imageurl'],
                              width: 100,
                              height: 100,
                            ),
                            Text(content['title']),
                            Text(
                              'Video ${index + 1}',
                              style: const TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }
              return const Text('No videos available');
            },
          );
        } else {
          return const Text('No creator email available');
        }
      },
    );
  }

  Widget _buildLiveEventsTab() {
    return FutureBuilder<String>(
      future: getCreatorEmail(widget.creatorName),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        if (snapshot.hasData) {
          String creatorEmail = snapshot.data!;
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('live_events')
                .where('creator_email', isEqualTo: creatorEmail)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }
              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot content = snapshot.data!.docs[index];
                    return ListTile(
                      title: Text(content['title']),
                      subtitle: Text('Live Event ${index + 1}'),
                      onTap: () {
                        _handleLiveEventTap(content);
                        // display the price and the descrption of the live content. meka price as button and add // await processPayment();
                        // Navigate to JoinLivePage() page if payment is successful
                      },
                    );
                  },
                );
              }
              return const Text('No live events available');
            },
          );
        } else {
          return const Text('No creator email available');
        }
      },
    );
  }

  void _handleVideoTap(DocumentSnapshot content) async {
    // Extract video details
    String videoTitle = content['title'];
    String videoDescription = content['description'];
    double videoPrice = content['price'];

    // Display price and description
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(videoTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Description: $videoDescription',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Price: \$${videoPrice.toStringAsFixed(2)}'),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                // Call the processPayment function
                bool paymentSuccessful =
                    await processPayment(videoPrice as String);
                if (paymentSuccessful) {
                  // Navigate to content viewer page if payment is successful
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ContentViewer(
                          title: videoTitle,
                        ),
                      ));
                } else {
                  // Show payment failure dialog
                  showErrorDialog(
                    context,
                    'Insufficient coins',
                  );
                }
              },
              child: const Text('Buy'),
            ),
          ],
        );
      },
    );
  }

  void _handleLiveEventTap(DocumentSnapshot content) async {
    // Extract live event details
    String liveEventTitle = content['title'];
    String liveEventDescription = content['description'];
    String liveEventPrice =
        content['price']; // Retrieving the price of the live event
    String liveEventId = content['liveID'];

    // Display price and description
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(liveEventTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Description: $liveEventDescription',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Price: Rs.$liveEventPrice'),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                // Call the processPayment function

                bool paymentSuccessful = await processPayment(liveEventPrice);

                if (paymentSuccessful) {
                  // Navigate to JoinLivePage if payment is successful
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => JoinLivePage(
                              liveID: liveEventId,
                              title: liveEventTitle,
                            )),
                  );
                } else {
                  // Show payment failure dialog
                  showErrorDialog(
                    context,
                    'Insufficient coins',
                  );
                }
              },
              // Modified button label to include the price
              child: Text('Buy for Rs.$liveEventPrice'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 20),
            Center(
              child: CircleAvatar(
                radius: 80,
                backgroundImage: NetworkImage(profilePicture),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Name: $name',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                'Age: $age',
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                'Country: $country',
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Contents:',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'Videos'),
                      Tab(text: 'Live Events'),
                    ],
                  ),
                  Container(
                    height: MediaQuery.of(context).size.height -
                        300, // Adjust height as needed
                    child: TabBarView(
                      children: [
                        _buildVideosTab(),
                        _buildLiveEventsTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Handle Video button press
                  },
                  child: const Text('Video'),
                ),
                const VerticalDivider(
                    width: 20, color: Colors.black), // Vertical line separator
                ElevatedButton(
                  onPressed: () {
                    // Handle Live button press
                  },
                  child: const Text('Live'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
