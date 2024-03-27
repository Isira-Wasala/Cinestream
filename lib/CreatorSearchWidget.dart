// ignore_for_file: prefer_const_literals_to_create_immutables, avoid_print,, unused_field, dead_code, unnecessary_const 
//unnecessary_string_interpolations, prefer_const_constructors, library_private_types_in_public_api, 
//file_names, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:main/ContentViewer.dart';
import 'package:main/MyHomePage.dart';

class SearchWidget extends StatefulWidget {
  const SearchWidget({super.key});

  @override
  State<SearchWidget> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchWidget> {
  String _contentType = 'All'; // Default content type.
  final TextEditingController _startPriceController = TextEditingController();
  final TextEditingController _endPriceController = TextEditingController();
  TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<String> searchResults = [];
  List<String> searchHistory = [];

  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> searchFiles(String searchTerm) async {
    setState(() {
      searchResults.clear();
    });

    try {
      // Access 'videos' directory
      Reference videosRef = _storage.ref().child('videos');

      // List all items under 'videos' directory
      ListResult result = await videosRef.listAll();

      // Iterate through items and check for folders ending with 'Contents'
      for (var item in result.prefixes) {
        if (item.name.endsWith('Contents')) {
          await searchInContents(item, searchTerm);
        }
      }
    } catch (e) {
      print('Error searching files: $e');
    }
  }

  Future<void> searchInContents(
      Reference contentsRef, String searchTerm) async {
    try {
      // List items under the folder ending with 'Contents'
      ListResult contentResult = await contentsRef.list();

      // Iterate through items and check for folders named 'video 1', 'video 2', etc.
      for (var videoFolder in contentResult.prefixes) {
        await searchInVideoFolder(videoFolder, searchTerm);
      }
    } catch (e) {
      print('Error searching in contents: $e');
    }
  }

  Future<void> searchInVideoFolder(
      Reference videoFolderRef, String searchTerm) async {
    try {
      ListResult videoResult = await videoFolderRef.list();

      for (var videoItem in videoResult.items) {
        if (videoItem.name.endsWith('.jpg') &&
            videoItem.name.contains(searchTerm) &&
            !searchResults.contains(videoItem.fullPath)) {
          setState(() {
            searchResults.add(videoItem.fullPath);
            print('Firebase Storage Path: ${videoItem.fullPath}');
          });
        }
      }
    } catch (e) {
      print('Error searching in video folder: $e');
    }
  }

  Future<String> getImageDownloadUrl(String imagePath) async {
    try {
      Reference imageRef = _storage.ref().child(imagePath);
      String downloadUrl = await imageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error getting download URL: $e');
      return ''; // Return empty string if an error occurs
    }
  }

  void updateList(String value) {
    setState(() {
      _isSearching = value.isNotEmpty;
      if (_isSearching) {
        searchFiles(value);
      } else {
        searchResults.clear();
      }
    });
  }

  void clearSearch() {
    setState(() {
      _searchController.clear();
      _isSearching = false;
      _startPriceController.clear();
      _endPriceController.clear();
      searchResults.clear();
    });
  }

  void addToSearchHistory(String term) {
    setState(() {
      searchHistory.add(term);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        automaticallyImplyLeading: false, // This line hides the back button
      ),
      backgroundColor: Colors.white,
      body: WillPopScope(
        onWillPop: () async {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MyHomePage()),
          );
          return false;
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Search for keywords",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 22.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 20.0,
                ),
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      updateList(value);
                      if (_isSearching) {
                        searchHistory.clear();
                      }
                    });
                  },
                  onSubmitted: (value) {
                    updateList(value);
                    addToSearchHistory(value);
                  },
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color.fromARGB(255, 189, 185, 185),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide.none,
                    ),
                    hintText: "Ex: Short Movies",
                    prefixIcon: const Icon(Icons.search),
                    prefixIconColor: Colors.purple.shade900,
                    suffixIcon: _isSearching
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: clearSearch,
                          )
                        : null,
                  ),
                ),
                const SizedBox(
                  height: 20.0,
                ),
                if (searchResults.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Search Results:',
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 20.0, // Add space here
                      ),
                      SizedBox(
                        height: 400.0, // Adjust height according to your UI
                        child: ListView.builder(
                          itemCount: searchResults.length,
                          itemBuilder: (context, index) {
                            String imagePath = searchResults[index];
                            return FutureBuilder(
                              future: getImageDownloadUrl(imagePath),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const CircularProgressIndicator(); // Show loading indicator while fetching URL
                                } else if (snapshot.hasError) {
                                  return Text('Error: ${snapshot.error}');
                                } else {
                                  String imageUrl = snapshot.data.toString();
                                  if (kIsWeb) {
                                    // Display web specific widget
                                    return WebImageDisplay(
                                        imageUrl: imageUrl,
                                        imagePath: imagePath);
                                  } else {
                                    // Display non-web specific widget
                                    return MobileImageDisplay(
                                        imageUrl: imageUrl,
                                        imagePath: imagePath);
                                  }
                                }
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(
                        height: 20.0, // Add space here
                      ),
                    ],
                  ),
                if (searchResults.isEmpty && _isSearching)
                  const Text(
                    'Oops, there is no any contents like that',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (searchHistory.isNotEmpty &&
                    !_isSearching) // Only show when not searching
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Search History:',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(
                          height: 70.0,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: searchHistory.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ElevatedButton(
                                  onPressed: () {
                                    _searchController.text =
                                        searchHistory[index];
                                    updateList(searchHistory[index]);
                                  },
                                  child: Text(searchHistory[index]),
                                ),
                              );
                            },
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            print('Clearing all search histories');
                            setState(() {
                              searchHistory.clear();
                            });
                          },
                          child: const Text('Clear All'),
                        ),
                      ],
                    ),
                  ),
                if (searchResults.isEmpty && !_isSearching)
                  const SizedBox(height: 20.0), // Space instead of the message
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MobileImageDisplay extends StatefulWidget {
  final String imageUrl;
  final String imagePath;

  const MobileImageDisplay({
    super.key,
    required this.imageUrl,
    required this.imagePath,
  });

  @override
  _MobileImageDisplayState createState() => _MobileImageDisplayState();
}

class _MobileImageDisplayState extends State<MobileImageDisplay> {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Color _boxColor = Colors.blue;

  Future<Map<String, String>> getFileDetails(String name) async {
    try {
      // Construct the path to the details document in Firestore
      String detailsDocumentPath = name;

      // Get a reference to the Firestore document
      DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
          .instance
          .collection('content')
          .doc(detailsDocumentPath)
          .get();
      // Check if the document exists
      if (snapshot.exists) {
        // Extract data from the document
        Map<String, dynamic> data = snapshot.data()!;

        // Extract details from the data map
        String title = data['title'] ?? '';
        String description = data['description'] ?? '';
        String category = data['category'] ?? '';
        String price = data['price'] ?? '';

        // Return the details as a Map
        return {
          'title': title,
          'description': description,
          'category': category,
          'price': price,
        };
      } else {
        // Document does not exist
        print('Document does not exist: $detailsDocumentPath');
      }
    } catch (e) {
      // Handle any errors that occur during the process
      print('Error getting file details: $e');
    }

    // Return an empty map if an error occurs or no data is received
    return {};
  }

  @override
  Widget build(BuildContext context) {
    // Extracting file name without extension
    String fileName = widget.imagePath.split('/').last.split('.').first;

    return GestureDetector(
      onTap: () {
        // Show popup window
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('File Details'),
              content: FutureBuilder(
                future: getFileDetails(
                  fileName,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    // Display fetched details
                    Map<String, String>? fileDetails = snapshot.data;

                    // Check if fileDetails is null, if yes, assign an empty map
                    fileDetails ??= {};

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Title: ${fileDetails['title'] ?? ''}'),
                        Text(
                            'Description: ${fileDetails['description'] ?? ''}'),
                        Text('Category: ${fileDetails['category'] ?? ''}'),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('Close'),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                // add payment gateway logic here
                                bool paymentSuccess =
                                    true; // await processPayment(); // Example function for processing payment

                                if (paymentSuccess) {
                                  // Navigate to content viewer if payment is successful
                                  Navigator.of(context)
                                      .pop(); // Close the dialog
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ContentViewer(
                                        title: fileDetails?['title'] ?? '',
                                      ),
                                    ),
                                  );
                                } else {
                                  // Show payment failure dialog
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Row(
                                          children: [
                                            Icon(
                                              Icons.error,
                                              color: Colors.red,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Payment Failed',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.red,
                                              ),
                                            ),
                                          ],
                                        ),
                                        content: const Text(
                                          'Unfortunately, the payment has failed. Please try again later.',
                                        ),
                                        actions: <Widget>[
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.of(context)
                                                  .pop(); // Close the dialog
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      const SearchWidget(),
                                                ),
                                              );
                                            },
                                            child: const Text('Close'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                }
                              },
                              child: Text(
                                  'Buy - Price: ${fileDetails['price'] ?? ''}'),
                            ),
                          ],
                        ),
                      ],
                    );
                  }
                },
              ),
            );
          },
        );
      },
      child: Container(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _boxColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 200, // Make the width same as height for square image
              child: Column(
                children: [
                  Container(
                    height: 200, // Set height to maintain aspect ratio
                    width: 200, // Set width to maintain aspect ratio
                    color: Colors.red,
                    child: Image.network(
                      widget.imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (BuildContext context, Widget child,
                          ImageChunkEvent? loadingProgress) {
                        if (loadingProgress == null) {
                          return child;
                        } else {
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      (loadingProgress.expectedTotalBytes ?? 1)
                                  : null,
                            ),
                          );
                        }
                      },
                      errorBuilder: (
                        BuildContext context,
                        Object error,
                        StackTrace? stackTrace,
                      ) {
                        // Handle error
                        print('Error loading image: $error');
                        return const Center(
                          child: Icon(
                            Icons.error,
                            color: Colors.red,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              width: 20,
            ), // Add spacing between image and text
            Expanded(
              child: Text(
                fileName, // Displaying only the file name without extension
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WebImageDisplay extends StatefulWidget {
  final String imageUrl;
  final String imagePath;

  const WebImageDisplay({
    super.key,
    required this.imageUrl,
    required this.imagePath,
  });

  @override
  _WebImageDisplayState createState() => _WebImageDisplayState();
}

class _WebImageDisplayState extends State<WebImageDisplay> {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  Color _boxColor = Colors.blue;

  Future<Map<String, String>> getFileDetails(String name) async {
    try {
      // Construct the path to the details document in Firestore
      String detailsDocumentPath = name;

      // Get a reference to the Firestore document
      DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
          .instance
          .collection('content')
          .doc(detailsDocumentPath)
          .get();

      // Check if the document exists
      if (snapshot.exists) {
        // Extract data from the document
        Map<String, dynamic> data = snapshot.data()!;

        // Extract details from the data map
        String title = data['title'] ?? '';
        String description = data['description'] ?? '';
        String category = data['category'] ?? '';
        String price = data['price'] ?? '';

        // Return the details as a Map
        return {
          'title': title,
          'description': description,
          'category': category,
          'price': price,
        };
      } else {
        // Document does not exist
        print('Document does not exist: $detailsDocumentPath');
      }
    } catch (e) {
      // Handle any errors that occur during the process
      print('Error getting file details: $e');
    }

    // Return an empty map if an error occurs or no data is received
    return {};
  }

  @override
  Widget build(BuildContext context) {
    // Extracting file name without extension
    String fileName = widget.imagePath.split('/').last.split('.').first;

    return GestureDetector(
      onTap: () {
        // Show popup window
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('File Details'),
              content: FutureBuilder(
                future: getFileDetails(
                  fileName,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    // Display fetched details
                    Map<String, String>? fileDetails = snapshot.data;

                    // Check if fileDetails is null, if yes, assign an empty map
                    fileDetails ??= {};

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Title: ${fileDetails['title'] ?? ''}'),
                        Text(
                            'Description: ${fileDetails['description'] ?? ''}'),
                        Text('Category: ${fileDetails['category'] ?? ''}'),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('Close'),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                // add payment gateway logic here
                                bool paymentSuccess =
                                    true; // await processPayment(); // function for processing payment

                                if (paymentSuccess) {
                                  // Navigate to content viewer if payment is successful
                                  Navigator.of(context)
                                      .pop(); // Close the dialog
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ContentViewer(
                                        title: fileDetails?['title'] ?? '',
                                      ),
                                    ),
                                  );
                                } else {
                                  // Show payment failure dialog
                                }
                              },
                              child: Text(
                                  'Buy - Price: ${fileDetails['price'] ?? ''}'),
                            ),
                          ],
                        ),
                      ],
                    );
                  }
                },
              ),
            );
          },
        );
      },
      child: Container(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _boxColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 200, // Make the width same as height for square image
              child: Column(
                children: [
                  Container(
                    height: 200, // Set height to maintain aspect ratio
                    width: 200, // Set width to maintain aspect ratio
                    color: Colors.red,
                    child: Image.network(
                      widget.imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (BuildContext context, Widget child,
                          ImageChunkEvent? loadingProgress) {
                        if (loadingProgress == null) {
                          return child;
                        } else {
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      (loadingProgress.expectedTotalBytes ?? 1)
                                  : null,
                            ),
                          );
                        }
                      },
                      errorBuilder: (
                        BuildContext context,
                        Object error,
                        StackTrace? stackTrace,
                      ) {
                        // Handle error
                        print('Error loading image: $error');
                        return const Center(
                          child: Icon(
                            Icons.error,
                            color: Colors.red,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              width: 20,
            ), // Add spacing between image and text
            Expanded(
              child: Text(
                fileName, // Displaying only the file name without extension
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
