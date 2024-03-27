import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class NewPage extends StatefulWidget {
  const NewPage({super.key});

  @override
  _NewPageState createState() => _NewPageState();
}

class _NewPageState extends State<NewPage> {
  final List<String> categories = [
    'All',
    'Short Movies',
    'Standup Comedy',
    'Stage Plays'
  ];
  String selectedCategory = 'All';
  TextEditingController priceController = TextEditingController();
  TextEditingController adTitleController =
      TextEditingController(); // New text controller for ad title
  TextEditingController adDescriptionController =
      TextEditingController(); // New text controller for ad description
  bool agreedToTerms = false;
  PlatformFile? uploadedFile;

  Future<void> uploadFileToFirebaseStorage(PlatformFile file) async {
    try {
      FirebaseStorage storage = FirebaseStorage.instance;
      String? email = FirebaseAuth.instance.currentUser?.email;
      if (email == null) {
        print("User not logged in.");
        return;
      }
      String? sponsorname = await getSponsorNameFromFirestore(email);

      if (sponsorname == null) {
        print("Failed to retrieve creator's name.");
        return;
      }
      final folderPath = "ads/$sponsorname Contents";
      int nextVideoNumber = await getNextVideoNumber(folderPath);
      final fileName =
          "${adTitleController.text}.${file.extension}"; // Keep the original file name
      final path = "$folderPath/ad $nextVideoNumber/$fileName";
      firebase_storage.Reference adsRef =
          storage.ref().child(path); // Specify the path

      // Upload the file to Firebase Storage
      if (kIsWeb) {
        // Read the file as bytes and upload to Firebase Storage
        UploadTask task = adsRef.putData(file.bytes!);
        await task;
      } else {
        // For mobile platforms, upload the file directly
        UploadTask task = adsRef.putFile(
          File(file.path!),
        );
        await task;
      }

      // Get the URL of the uploaded file
      String fileUrl = await adsRef.getDownloadURL();

      // Store ad details in Firestore
      await FirebaseFirestore.instance.collection('ads').add({
        'title': adTitleController.text,
        'description': adDescriptionController.text,
        'category': selectedCategory,
        'price': priceController.text,
        'sponsor email': email,
        'fileUrl': fileUrl,
      });
      setState(() {
        uploadedFile = file;
      });
      print('File uploaded successfully.');
    } catch (error) {
      print('Error uploading file: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ad Posting Page'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Upload Image or Video',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: uploadedFile != null
                    ? Image.memory(uploadedFile!.bytes!, fit: BoxFit.cover)
                    : Center(
                        child: IconButton(
                          icon: const Icon(Icons.file_upload),
                          onPressed: () async {
                            FilePickerResult? result =
                                await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: [
                                'jpg',
                                'jpeg',
                                'png',
                                'mp4',
                                'mov'
                              ],
                            );

                            if (result != null) {
                              PlatformFile? file = result.files.first;
                              setState(() {
                                uploadedFile = file;
                              });
                            } else {
                              // User canceled the file picking
                            }
                          },
                        ),
                      ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ad Title',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: adTitleController, // Bind ad title controller
                decoration: const InputDecoration(
                  hintText: "What's Your Ad About?",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ad Description',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller:
                    adDescriptionController, // Bind ad description controller
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Enter ad details...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select Category',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: selectedCategory,
                items: categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      selectedCategory = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Price (Rs.)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Enter the price of the Ad',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: agreedToTerms,
                    onChanged: (value) {
                      setState(() {
                        agreedToTerms = value ?? false;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  const Text('Agree to the Terms and Conditions'),
                ],
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.bottomRight,
                child: ElevatedButton(
                  onPressed: agreedToTerms
                      ? () async {
                          if (adTitleController.text.isNotEmpty &&
                              adDescriptionController.text.isNotEmpty &&
                              priceController.text.isNotEmpty &&
                              uploadedFile != null) {
                            // Upload the file to Firebase Storage and store ad details in Firestore
                            await uploadFileToFirebaseStorage(uploadedFile!);

                            // Clear text controllers
                            adTitleController.clear();
                            adDescriptionController.clear();
                            priceController.clear();
                            // Reset selected category and terms agreement
                            setState(() {
                              selectedCategory = 'All';
                              agreedToTerms = false;
                              uploadedFile =
                                  null; // Reset uploaded file after successful upload
                            });
                            // Show success message or navigate to a different page
                          } else {
                            print(
                                "Please fill all the details and upload a file.");
                          }
                        }
                      : null,
                  child: const Text('Submit Ad'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> getSponsorNameFromFirestore(String email) async {
    try {
      // Query Firestore to find the matching document where email equals to the logged email
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance
              .collection('Sponsor')
              .where('email', isEqualTo: email)
              .get();

      // If there is no matching document, return null
      if (querySnapshot.docs.isEmpty) {
        print("No document found for the provided email.");
        return null;
      }

      // Retrieve the 'name' field from the first document (assuming email is unique)
      String sponsorName = querySnapshot.docs.first.get('name');

      return sponsorName;
    } catch (error) {
      print("Error fetching creator's name from Firestore: $error");
      return null;
    }
  }

  Future<int> getNextVideoNumber(String folderPath) async {
    try {
      // Query Firestore to count the number of subfolders (videos) already present
      final ListResult listResult = await firebase_storage
          .FirebaseStorage.instance
          .ref(folderPath)
          .list();
      int videoCount = listResult.prefixes.length;
      return videoCount + 1; // Increment the count to get the next video number
    } catch (error) {
      print("Error counting videos: $error");
      return 1; // If an error occurs, assume it's the first video
    }
  }
}

// SponsorAdsPage Widget
class SponsorAdsPage extends StatefulWidget {
  const SponsorAdsPage({super.key});

  @override
  _SponsorAdsPageState createState() => _SponsorAdsPageState();
}

class _SponsorAdsPageState extends State<SponsorAdsPage> {
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
              title: const Text('Sponsor ADS'),
              automaticallyImplyLeading:
                  false, // This line hides the back button
              // automaticallyImplyLeading: false, // This line hides the back button
              // leading: IconButton(
              //   icon: const Icon(Icons.arrow_back),
              //   onPressed: () {
              //     Navigator.pop(context);
              //   },
              // ),
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
                final adEmail = adData['sponsor email'] as String?;
                final isCurrentUserAd = currentUserEmail == adEmail;

                return AdTile(
                  adTitle: adData['title'],
                  adPrice: double.parse(adData['price'].toString()),
                  adDescription: adData['description'],
                  imageUrl: adData['fileUrl'],
                  adCategory: adData['category'],
                  isCurrentUserAd: isCurrentUserAd,
                );
              },
            );
          }
          return const SizedBox();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NewPage()),
          );
        },
        backgroundColor: const Color.fromARGB(255, 82, 204, 71),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class AdTile extends StatelessWidget {
  final String adTitle;
  final double adPrice;
  final String adDescription;
  final String adCategory;
  final String imageUrl;
  final bool isCurrentUserAd;

  const AdTile({
    super.key,
    required this.adTitle,
    required this.adPrice,
    required this.adDescription,
    required this.adCategory,
    required this.imageUrl,
    required this.isCurrentUserAd,
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
              child: isCurrentUserAd
                  ? Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        padding: const EdgeInsets.all(4.0),
                        color: Color.fromARGB(255, 82, 204, 71),
                        child: const Text(
                          'Your Ad',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                  : null,
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

  const AdDetailsPopup({
    super.key,
    required this.adTitle,
    required this.adPrice,
    required this.adDescription,
    required this.adCategory,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ad Details'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Title: ', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(adTitle),
          const SizedBox(height: 8.0),
          const Text('Category: ',
              style: TextStyle(fontWeight: FontWeight.bold)),
          Text(adCategory),
          const SizedBox(height: 8.0),
          const Text('Price: ', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('Rs. $adPrice'),
          const SizedBox(height: 8.0),
          const Text('Description: ',
              style: TextStyle(fontWeight: FontWeight.bold)),
          Text(adDescription),
        ],
      ),
      actions: [
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 82, 204, 71), // Background color
                borderRadius: BorderRadius.circular(
                    8), // Optional: Add border radius for rounded corners
              ),
              child: ElevatedButton(
                onPressed: () async {
                  final currentUserEmail =
                      FirebaseAuth.instance.currentUser?.email;
                  if (currentUserEmail != null) {
                    try {
                      final adQuery = await FirebaseFirestore.instance
                          .collection('ads')
                          .where('title', isEqualTo: adTitle)
                          .get();

                      if (adQuery.docs.isNotEmpty) {
                        final adDocId = adQuery.docs.first.id;

                        final interestedCreatorsQuery = await FirebaseFirestore
                            .instance
                            .collection('ads')
                            .doc(adDocId)
                            .collection('interestedCreators')
                            .get();

                        if (interestedCreatorsQuery.docs.isNotEmpty) {
                          String creatorsInfo = '';
                          for (final doc in interestedCreatorsQuery.docs) {
                            final email = doc['email'];
                            final timestamp = doc['timestamp'];
                            final formattedTimestamp = timestamp != null
                                ? _formatTimestamp(timestamp)
                                : '';
                            creatorsInfo += '$email\n$formattedTimestamp\n\n';
                          }
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('Interested Creators'),
                                content: Container(
                                  width: double.maxFinite,
                                  child: SingleChildScrollView(
                                    child: Text(
                                      creatorsInfo,
                                      textAlign: TextAlign.left,
                                      style: const TextStyle(
                                        fontSize: 16.0,
                                      ),
                                    ),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    style: TextButton.styleFrom(
                                      backgroundColor: Color.fromARGB(
                                          255, 82, 204, 71), // Background color
                                      primary: Colors.white, // Text color
                                    ),
                                    child: const Text('Close'),
                                  ),
                                ],
                              );
                            },
                          );
                        } else {
                          print('No interested creators found.');
                        }
                      } else {
                        print('No ad found with title: $adTitle');
                      }
                    } catch (error) {
                      print('Error: $error');
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  primary: const Color.fromARGB(
                      255, 82, 204, 71), // Background color
                  onPrimary: Colors.white, // Text color
                ),
                child: const Text('Interested Creators'),
              ),
            ),
            const Spacer(),
            Container(
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 82, 204, 71), // Background color
                borderRadius: BorderRadius.circular(
                    8), // Optional: Add border radius for rounded corners
              ),
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  primary: Colors.white, // Text color
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    final formattedDate =
        '${dateTime.year}-${_twoDigits(dateTime.month)}-${_twoDigits(dateTime.day)}';
    final formattedTime =
        '${_twoDigits(dateTime.hour)}:${_twoDigits(dateTime.minute)}';
    return '$formattedDate ($formattedTime)';
  }

  String _twoDigits(int n) {
    if (n >= 10) return '$n';
    return '0$n';
  }
}
