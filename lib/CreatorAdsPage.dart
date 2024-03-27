// ignore_for_file: file_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// CreatorAdsPage Widget
class CreatorAdsPage extends StatefulWidget {
  const CreatorAdsPage({super.key});

  @override
  CreatorAdsPageState createState() => CreatorAdsPageState();
}

class CreatorAdsPageState extends State<CreatorAdsPage> {
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserEmail = FirebaseAuth.instance.currentUser?.email;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 56),
        child: Column(
          children: [
            AppBar(
              title: const Text('Creator ADS'),
              automaticallyImplyLeading:
                  false, // This line hides the back button
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(20.0),
              child: Container(
                color: Colors.grey[200],
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                width: MediaQuery.of(context).size.width * 0.9,
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50.0,
                        child: TextField(
                          controller: searchController,
                          decoration: const InputDecoration(
                            hintText: 'Search...',
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.search, color: Colors.grey),
                          ),
                          onChanged: (value) {
                            setState(() {
                              searchQuery = value;
                            });
                          },
                          onSubmitted: (value) {
                            setState(() {
                              searchQuery = value;
                            });
                          },
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        setState(() {
                          searchController.clear();
                          searchQuery = '';
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance.collection('ads').get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.hasData) {
            final ads = snapshot.data!.docs;

            final filteredAds = ads.where((ad) {
              final adData = ad.data() as Map<String, dynamic>;
              final adTitle = adData['title'] as String;
              return adTitle.toLowerCase().contains(searchQuery.toLowerCase());
            }).toList();

            if (filteredAds.isEmpty) {
              return const Center(child: Text('No ads found.'));
            }

            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
              ),
              itemCount: filteredAds.length,
              padding: const EdgeInsets.all(8.0),
              itemBuilder: (context, index) {
                final adData =
                    filteredAds[index].data() as Map<String, dynamic>;

                return AdTile(
                  adTitle: adData['title'],
                  adPrice: double.parse(adData['price'].toString()),
                  adDescription: adData['description'],
                  imageUrl: adData['fileUrl'],
                  adCategory: adData['category'],
                  sponsorEmail: adData['sponsor email'],
                );
              },
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}

class AdTile extends StatelessWidget {
  final String adTitle;
  final double adPrice;
  final String adDescription;
  final String adCategory;
  final String imageUrl;
  final String sponsorEmail;

  const AdTile({
    super.key,
    required this.adTitle,
    required this.adPrice,
    required this.adDescription,
    required this.adCategory,
    required this.imageUrl,
    required this.sponsorEmail,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AdDetailsPopup(
              adTitle: adTitle,
              adPrice: adPrice,
              adDescription: adDescription,
              adCategory: adCategory,
              sponsorEmail: sponsorEmail,
            );
          },
        );
      },
      child: Card(
        elevation: 2.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 150, // Adjust the height as needed
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                image: imageUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdDetailsPopup extends StatelessWidget {
  final String adTitle;
  final double adPrice;
  final String adDescription;
  final String adCategory;
  final String sponsorEmail;

  const AdDetailsPopup({
    super.key,
    required this.adTitle,
    required this.adPrice,
    required this.adDescription,
    required this.adCategory,
    required this.sponsorEmail,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ad Details'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Title: $adTitle'),
          const SizedBox(height: 8.0),
          Text('Category: $adCategory'),
          const SizedBox(height: 8.0),
          Text('Price: Rs. $adPrice'),
          const SizedBox(height: 8.0),
          Text('Description: $adDescription'),
        ],
      ),
      actions: [
        Row(
          children: [
            ElevatedButton(
              onPressed: () async {
                final currentUserEmail =
                    FirebaseAuth.instance.currentUser?.email;
                if (currentUserEmail != null) {
                  try {
                    _sendEmail(
                      adTitle,
                      adPrice,
                      adDescription,
                      adCategory,
                      sponsorEmail,
                    );
                    final adQuery = await FirebaseFirestore.instance
                        .collection('ads')
                        .where('title', isEqualTo: adTitle)
                        .get();

                    if (adQuery.docs.isNotEmpty) {
                      final adDocId = adQuery.docs.first.id;

                      await FirebaseFirestore.instance
                          .collection('ads')
                          .doc(adDocId)
                          .collection('interestedCreators')
                          .doc(currentUserEmail)
                          .set({
                        'email': currentUserEmail,
                        'timestamp': Timestamp.now(),
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Added to Interested!'),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ad not found!'),
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to add to Interested!'),
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('User not logged in!'),
                    ),
                  );
                }
              },
              child: const Text('Interested'),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _sendEmail(
    String adTitle,
    double adPrice,
    String adDescription,
    String adCategory,
    String sponsorEmail,
  ) async {
    final currentUserEmail = FirebaseAuth.instance.currentUser?.email ?? '';
    final subject = 'Interested in Ad: $adTitle';
    final body = '''

Ad Title: $adTitle
Category: $adCategory
Price: Rs. $adPrice
Description: $adDescription
sponsorEmail: $sponsorEmail
Interested Creator: $currentUserEmail
''';

    final Uri params = Uri(
      scheme: 'mailto',
      path: sponsorEmail, // Replace with the recipient's email address
      query: 'subject=${Uri.encodeFull(subject)}&body=${Uri.encodeFull(body)}',
    );

    final url = params.toString();
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
