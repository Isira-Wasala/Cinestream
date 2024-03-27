import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:main/LivePage.dart';
import 'package:main/go_live.dart';
import 'package:video_player/video_player.dart';
import 'ContentFormPage.dart';
import 'package:intl/intl.dart';

class CreatorPostingPage extends StatefulWidget {
  const CreatorPostingPage({super.key});

  @override
  _CreatorPostingPageState createState() => _CreatorPostingPageState();
}

class _CreatorPostingPageState extends State<CreatorPostingPage> {
  int _selectedIndex = 0;
  final double _fontSize = 16.0;
  late Future<List<Map<String, String>>> futureVideosWithPreviews;
  late Future<List<Map<String, dynamic>>> futureLiveDetails;

  @override
  void initState() {
    super.initState();
    futureVideosWithPreviews = getUploadedVideosWithPreviews();
    futureLiveDetails = getLiveDetails();
  }

  Future<List<Map<String, String>>> getUploadedVideosWithPreviews() async {
    try {
      String? email = FirebaseAuth.instance.currentUser?.email;
      if (email == null) {
        print("User not logged in.");
        return [];
      }

      String? creatorName = await getCreatorNameFromFirestore(email);

      if (creatorName == null) {
        print("Failed to retrieve creator's name.");
        return [];
      }

      List<Map<String, String>> videosWithPreviews = [];

      // Iterate through each video folder (Video 1, Video 2, etc.)
      for (int videoNumber = 1;; videoNumber++) {
        String path =
            "videos/$creatorName Contents/Video $videoNumber"; // Path to each video folder

        // List the items in the specified path in Firebase Storage
        firebase_storage.ListResult listResult =
            await firebase_storage.FirebaseStorage.instance.ref(path).list();

        String? jpgPreview;
        String? mp4File;

        // Extract the video file name from each folder
        for (var item in listResult.items) {
          // Check if the item is a file with .mp4 extension
          if (item.name.toLowerCase().endsWith('.mp4')) {
            mp4File = item.name;
          }
          // Check if the item is a file with .jpg extension
          else if (item.name.toLowerCase().endsWith('.jpg')) {
            jpgPreview = "$path/${item.name}";
          }
        }

        // If both MP4 and JPG files are found, add them to the list
        if (mp4File != null && jpgPreview != null) {
          videosWithPreviews.add({
            'mp4': mp4File,
            'jpg': jpgPreview,
          });
        }

        // Break the loop if no more videos are found in the current folder
        if (listResult.items.isEmpty) {
          break;
        }
      }

      return videosWithPreviews;
    } catch (error) {
      print("Error fetching uploaded videos: $error");
      return [];
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Manager'),
        automaticallyImplyLeading: false, // This line hides the back button
      ),
      body: Column(
        children: [
          _buildCombinedTabButton('Uploaded', 'Live'),
          Expanded(
            child: _selectedIndex == 0
                ? FutureBuilder<List<Map<String, String>>>(
                    future: futureVideosWithPreviews,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else {
                        return _buildVideoList(snapshot.data!);
                      }
                    },
                  )
                : FutureBuilder<List<Map<String, dynamic>>>(
                    future: futureLiveDetails, // Method to fetch live details
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else {
                        return _buildLiveDetailsList(snapshot.data!);
                      }
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showOptionsDialog(context);
        },
        backgroundColor: const Color.fromARGB(255, 82, 204, 71),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildVideoList(List<Map<String, String>> videos) {
    return ListView.builder(
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final Map<String, String> videoInfo = videos[index];
        final String videoName = videoInfo['mp4']!;
        final String jpgPreview = videoInfo['jpg']!;

        return ListTile(
          title: Row(
            children: [
              // Show JPG preview alongside MP4 file
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(),
                ),
                child: FutureBuilder<String>(
                  future: getImageUrl(jpgPreview),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return const Icon(Icons.error);
                    } else {
                      return Image.network(
                        snapshot.data!,
                        fit: BoxFit.cover,
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Text(videoName.split('/').last.replaceAll('.mp4', '')),
            ],
          ),
          onTap: () {
            _showVideoPlayerDialog(videoName);
          },
        );
      },
    );
  }

  Widget _buildLiveDetailsList(List<Map<String, dynamic>> liveDetails) {
    return ListView.builder(
      itemCount: liveDetails.length,
      itemBuilder: (context, index) {
        final Map<String, dynamic> detail = liveDetails[index];
        return GestureDetector(
          child: Card(
            child: ListTile(
              title: Text(detail['title'] ?? ''),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (detail['scheduled_time'] is Timestamp)
                    Text(
                      'Scheduled Time: ${DateFormat('yyyy-MM-dd HH:mm').format(detail['scheduled_time'].toDate())}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  if (detail['scheduled_time'] is String)
                    Text(
                      'Scheduled Time: ${detail['scheduled_time']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  const SizedBox(height: 4),
                  Text('Description: ${detail['description'] ?? ''}'),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      _deleteLiveEvent((detail['scheduled_time'] ?? ''),
                          (detail['title'] ?? ''));
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.timer),
                    onPressed: () {
                      _postponeLiveEvent((detail['scheduled_time'] ?? ''),
                          (detail['title'] ?? ''));
                    },
                  ),
                  IconButton(
                      icon: const Icon(Icons.tv),
                      onPressed: () {
                        String title = detail['title'] ?? '';
                        String creatorEmail =
                            FirebaseAuth.instance.currentUser?.email ?? '';
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    GoLivePage(creatorEmail, title)));
                      }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _deleteLiveEvent(dynamic scheduledTime, dynamic title) async {
    try {
      DateTime? scheduledDateTime;
      if (scheduledTime is Timestamp) {
        scheduledDateTime = scheduledTime.toDate();
        print(scheduledDateTime.toString() + "timestamp");
      } else if (scheduledTime is DateTime) {
        scheduledDateTime = scheduledTime;
        print(scheduledDateTime.toString() + "date time");
      } else {
        print("Invalid scheduled time format.");
        return;
      }

      String? email = FirebaseAuth.instance.currentUser?.email;

      if (email == null) {
        print("User not logged in.");
        return;
      }

      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance
              .collection('live_events')
              .where('creator_email', isEqualTo: email)
              .where('title', isEqualTo: title)
              .get();

      if (querySnapshot.docs.isEmpty) {
        print("Live event not found.");
        return;
      }

      String liveEventId = querySnapshot.docs.first.id;
      await FirebaseFirestore.instance
          .collection('live_events')
          .doc(liveEventId)
          .delete();

      print("Live event deleted successfully.");
    } catch (error) {
      print("Error deleting live event: $error");
    }
  }

  void _postponeLiveEvent(dynamic scheduledTime, dynamic title) async {
    try {
      DateTime? scheduledDateTime;
      if (scheduledTime is Timestamp) {
        scheduledDateTime = scheduledTime.toDate();
        print(scheduledDateTime.toString());
      } else if (scheduledTime is DateTime) {
        scheduledDateTime = scheduledTime;
        print(scheduledDateTime.toString());
      } else {
        print("Invalid scheduled time format." + scheduledDateTime.toString());
        return;
      }

      DateTime? newScheduledTime = await _showDateTimePicker(scheduledDateTime);
      if (newScheduledTime == null) {
        print("No new schedule selected.");
        return;
      }

      String? email = FirebaseAuth.instance.currentUser?.email;
      if (email == null) {
        print("User not logged in.");
        return;
      }

      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance
              .collection('live_events')
              .where('creator_email', isEqualTo: email)
              .where('title', isEqualTo: title)
              .get();

      if (querySnapshot.docs.isEmpty) {
        print("Live event not found.");
        return;
      }

      String liveEventId = querySnapshot.docs.first.id;

      // Format the new scheduled time as 'yyyy-MM-dd HH:mm'
      String formattedNewScheduledTime =
          DateFormat('yyyy-MM-dd HH:mm').format(newScheduledTime);

      await FirebaseFirestore.instance
          .collection('live_events')
          .doc(liveEventId)
          .update({'scheduled_time': formattedNewScheduledTime});

      print("Live event rescheduled successfully.");
    } catch (error) {
      print("Error rescheduling live event: $error");
    }
  }

  Future<DateTime?> _showDateTimePicker(DateTime scheduledTime) async {
    try {
      DateTime? initialDate = scheduledTime.isAfter(DateTime.now())
          ? scheduledTime
          : DateTime.now();
      return await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: DateTime.now(),
        lastDate: DateTime(2100),
      ).then((selectedDate) async {
        if (selectedDate != null) {
          return await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(scheduledTime),
          ).then((selectedTime) {
            if (selectedTime != null) {
              return DateTime(
                selectedDate.year,
                selectedDate.month,
                selectedDate.day,
                selectedTime.hour,
                selectedTime.minute,
              );
            } else {
              return null;
            }
          });
        } else {
          return null;
        }
      });
    } catch (error) {
      print("Error showing date time picker: $error");
      return null;
    }
  }

  Future<String> getImageUrl(String imagePath) async {
    try {
      final Reference imageRef =
          firebase_storage.FirebaseStorage.instance.ref(imagePath);
      final imageUrl = await imageRef.getDownloadURL();
      return imageUrl;
    } catch (error) {
      print("Error fetching image URL: $error");
      rethrow;
    }
  }

  Widget _buildCombinedTabButton(String title1, String title2) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () {
            setState(() {
              _selectedIndex = 0;
            });
          },
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.black,
            backgroundColor: _selectedIndex == 0
                ? const Color.fromARGB(255, 82, 204, 71)
                : Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
            ),
          ),
          child: Text(
            title1,
            style: TextStyle(fontSize: _fontSize),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _selectedIndex = 1;
            });
          },
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.black,
            backgroundColor: _selectedIndex == 1
                ? const Color.fromARGB(255, 82, 204, 71)
                : Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
          ),
          child: Text(
            title2,
            style: TextStyle(fontSize: _fontSize),
          ),
        ),
      ],
    );
  }

  void _showOptionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  "Select to proceed",
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20.0),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _navigateToContentForm(context);
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color.fromARGB(255, 82, 204, 71),
                    padding: const EdgeInsets.all(16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: const Text(
                    'Upload Content',
                    style: TextStyle(fontSize: 16.0),
                  ),
                ),
                const SizedBox(height: 10.0),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _navigateToLivePage(context); // Navigate to LivePage
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color.fromARGB(255, 82, 204, 71),
                    padding: const EdgeInsets.all(16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: const Text(
                    'Go Live',
                    style: TextStyle(fontSize: 16.0),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToContentForm(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ContentFormPage()),
    );
  }

  Future<void> _navigateToLivePage(BuildContext context) async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GLivePage()),
    );
  }

  Future<void> _showVideoPlayerDialog(String videoName) async {
    try {
      String? email = FirebaseAuth.instance.currentUser?.email;
      if (email == null) {
        print("User not logged in.");
        return;
      }
      // Get the creator's name using the email
      String? creatorName = await getCreatorNameFromFirestore(email);

      // Iterate through each video number
      for (int videoNumber = 1;; videoNumber++) {
        // Construct the path to the video
        String path =
            "videos/$creatorName Contents/Video $videoNumber/$videoName";
        // Try to get the download URL for the video
        print("Video path: $path");
        try {
          String videoUrl = await firebase_storage.FirebaseStorage.instance
              .ref(path)
              .getDownloadURL();
          // Show the video player dialog
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 300, // Adjust the height as needed
                  child: Chewie(
                    controller: ChewieController(
                      videoPlayerController: VideoPlayerController.network(
                        // Pass the video URL directly
                        videoUrl,
                      ),
                      aspectRatio: 16 / 9, // Adjust the aspect ratio as needed
                      autoInitialize: true,
                      looping: false,
                      errorBuilder: (context, errorMessage) {
                        return Center(
                          child: Text(errorMessage),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          );
          break;
        } catch (error) {
          print("Error fetching download URL for video $videoNumber: $error");

          if (error.toString().contains("object-not-found")) {
            continue;
          }
        }
      }
    } catch (error) {
      print("Error showing video player dialog: $error");
    }
  }

  Future<List<Map<String, dynamic>>> getLiveDetails() async {
    try {
      // Fetch live details from Firestore or any other database
      String? email = FirebaseAuth.instance.currentUser?.email;
      if (email == null) {
        print("User not logged in.");
        return [];
      }
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance
              .collection('live_events')
              .where('creator_email', isEqualTo: email)
              .get();

      List<Map<String, dynamic>> liveDetailsList = [];

      // Iterate through the documents to extract live details
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> liveDetails = {
          'title': doc['title'],
          'description': doc['description'],
          'scheduled_time': doc['scheduled_time'],
          'price': doc['price'],
        };
        liveDetailsList.add(liveDetails);
      }

      return liveDetailsList;
    } catch (error) {
      print("Error fetching live details: $error");
      return [];
    }
  }
}
