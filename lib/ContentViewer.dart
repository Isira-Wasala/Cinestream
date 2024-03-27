import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ContentViewer extends StatefulWidget {
  final String title;

  const ContentViewer({Key? key, required this.title}) : super(key: key);

  @override
  ContentViewerState createState() => ContentViewerState();
}

class ContentViewerState extends State<ContentViewer> {
  TextEditingController _feedbackController = TextEditingController();
  VideoPlayerController? _controller;
  bool _liked = false;
  bool _disliked = false;
  int _likes = 0;
  int _dislikes = 0;
  List<dynamic> _feedbackList = [];

  @override
  void initState() {
    super.initState();
    _getVideoUrl(widget.title);
    _fetchLikesAndDislikes(widget.title); // Fetch likes and dislikes
    _fetchFeedback(widget.title); // Fetch previous feedback
  }

  // Method to fetch likes and dislikes count
  Future<void> _fetchLikesAndDislikes(String title) async {
    // Fetch likes count
    await FirebaseFirestore.instance
        .collection('content')
        .doc(title)
        .collection('likes')
        .get()
        .then((QuerySnapshot querySnapshot) {
      setState(() {
        _likes = querySnapshot.docs.length;
      });
    });

    // Fetch dislikes count
    await FirebaseFirestore.instance
        .collection('content')
        .doc(title)
        .collection('dislikes')
        .get()
        .then((QuerySnapshot querySnapshot) {
      setState(() {
        _dislikes = querySnapshot.docs.length;
      });
    });
  }

  // Method to fetch previous feedback
  Future<void> _fetchFeedback(String title) async {
    await FirebaseFirestore.instance
        .collection('content')
        .doc(title)
        .collection('feedback')
        .orderBy('timestamp', descending: true)
        .get()
        .then((QuerySnapshot querySnapshot) {
      setState(() {
        _feedbackList = querySnapshot.docs.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          var feedback = data['feedback'] ??
              ''; // Use null-aware access and provide a default value
          var timestamp = data['timestamp'] == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(
                      (data['timestamp'] as Timestamp).millisecondsSinceEpoch)
                  .toString()
                  .substring(0, 10); // Format timestamp as dd/mm/yy
          return {'feedback': feedback, 'timestamp': timestamp, 'id': doc.id};
        }).toList();
      });
    });
  }

  // Method to handle like action
  void _likeVideo() {
    if (!_liked) {
      // get user email
      String? userEmail = FirebaseAuth.instance.currentUser?.email;
      if (userEmail == null) {
        print("User not logged in.");
        return;
      }
      // Store like in Firestore
      FirebaseFirestore.instance
          .collection('content')
          .doc(widget.title)
          .collection('likes')
          .doc(userEmail) // Use user's email as the document ID
          .set({'like': true});
      setState(() {
        _liked = true;
        _likes++;
        if (_disliked) {
          _disliked = false;
          _dislikes--;
          // remove dislike from Firestore
          FirebaseFirestore.instance
              .collection('content')
              .doc(widget.title)
              .collection('dislikes')
              .doc(userEmail)
              .delete();
        }
      });
    }
  }

// Method to handle dislike action
  void _dislikeVideo() {
    if (!_disliked) {
      // get user email
      String? userEmail = FirebaseAuth.instance.currentUser?.email;
      if (userEmail == null) {
        print("User not logged in.");
        return;
      }
      // Store dislike in Firestore
      FirebaseFirestore.instance
          .collection('content')
          .doc(widget.title)
          .collection('dislikes')
          .doc(userEmail) // Use user's email as the document ID
          .set({'dislike': true});
      setState(() {
        _disliked = true;
        _dislikes++;
        if (_liked) {
          _liked = false;
          _likes--;
          // remove like from Firestore
          FirebaseFirestore.instance
              .collection('content')
              .doc(widget.title)
              .collection('likes')
              .doc(userEmail)
              .delete();
        }
      });
    }
  }

  Future<void> _getVideoUrl(String name) async {
    try {
      String videoUrl = await getVideoUrl(name);

      if (videoUrl.isNotEmpty) {
        print(videoUrl);
        await _initializeVideoPlayer(videoUrl);
      } else {
        // Document does not exist or videoUrl is null
        print('Document does not exist or videoUrl is null');
      }
    } catch (error) {
      // Error occurred while fetching document
      print('Error fetching document: $error');
    }
  }

  Future<String> getVideoUrl(String name) async {
    try {
      // Get a reference to the Firestore document
      DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
          .instance
          .collection('content')
          .doc(name)
          .get();

      // Check if the document exists
      if (snapshot.exists) {
        // Extract data from the document
        Map<String, dynamic>? data = snapshot.data();

        // Extract videoUrl from the data map
        String videoUrl = data?['videourl'] ?? '';

        // Return the videoUrl
        return videoUrl;
      } else {
        // Document does not exist
        print('Document does not exist: $name');
      }
    } catch (e) {
      // Handle any errors that occur during the process
      print('Error getting video URL: $e');
    }

    // Return an empty string if an error occurs or no data is received
    return "";
  }

  Future<void> _initializeVideoPlayer(String videoUrl) async {
    // Initialize video controller with the retrieved video URL
    _controller = VideoPlayerController.network(
      videoUrl,
    );

    // Listen for when the initialization is complete
    await _controller!.initialize();

    // Rebuild the widget tree with the new controller
    setState(() {});

    // Listen for video player errors
    _controller?.addListener(() {
      if (_controller!.value.hasError) {
        print('Video player error: ${_controller?.value.errorDescription}');
      }
    });
  }

  @override
  void dispose() {
    // Dispose of the video controller when the widget is removed from the tree
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Viewer'),
      ),
      body: Column(
        children: [
          if (_controller != null && _controller!.value.isInitialized)
            AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  VideoPlayer(_controller!),
                  _ControlsOverlay(controller: _controller!),
                ],
              ),
            )
          else
            const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.thumb_up),
                color: _liked ? Colors.blue : null,
                onPressed: _likeVideo,
              ),
              Text('$_likes'),
              IconButton(
                icon: const Icon(Icons.thumb_down),
                color: _disliked ? Colors.blue : null,
                onPressed: _dislikeVideo,
              ),
              Text('$_dislikes'),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 100, // Set the height of the SizedBox
            child: ListView.builder(
              itemCount: _feedbackList.length,
              itemBuilder: (context, index) {
                var feedback = _feedbackList[index];
                var timestamp = feedback['timestamp'];
                return ListTile(
                  leading: const Icon(Icons.message), // Icon for feedback
                  title: Text(feedback['feedback']),
                  subtitle: Text(timestamp),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteFeedback(index),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _feedbackController,
              decoration: InputDecoration(
                hintText: 'Enter your feedback',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    _submitFeedback(_feedbackController.text, widget.title);
                    _feedbackController.clear();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submitFeedback(String feedback, String title) {
    // Get current user's email
    String? userEmail = FirebaseAuth.instance.currentUser?.email;
    if (userEmail == null) {
      print("User not logged in.");
      return;
    }

    // Submit feedback to Firestore with sender email and timestamp
    FirebaseFirestore.instance
        .collection('content')
        .doc(title)
        .collection('feedback')
        .add({
      'feedback': feedback,
      'sender': userEmail, // Add sender email
      'timestamp': DateTime.now(),
    }).then((_) {
      // Feedback submitted successfully
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Feedback submitted successfully!'),
        ),
      );
      // Fetch updated feedback after submitting
      _fetchFeedback(title);
    }).catchError((error) {
      // Error occurred while submitting feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit feedback: $error'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  void _deleteFeedback(int index) {
    // Get the document ID of the feedback to delete
    String feedbackId = _feedbackList[index]['id'];

    // Delete the feedback from Firestore
    FirebaseFirestore.instance
        .collection('content')
        .doc(widget.title)
        .collection('feedback')
        .doc(feedbackId)
        .delete()
        .then((_) {
      // Feedback deleted successfully
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Feedback deleted successfully!'),
        ),
      );
      // Remove the deleted feedback from the local list
      setState(() {
        _feedbackList.removeAt(index);
      });
    }).catchError((error) {
      // Error occurred while deleting feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete feedback: $error'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }
}

class _ControlsOverlay extends StatelessWidget {
  const _ControlsOverlay({Key? key, required this.controller})
      : super(key: key);

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            onPressed: () {
              controller.seekTo(const Duration(seconds: 0));
            },
            icon: const Tooltip(
              message: 'Restart',
              child: Icon(
                Icons.replay,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              controller.value.isPlaying
                  ? controller.pause()
                  : controller.play();
              // controller is not playing restart the video
              if (!controller.value.isPlaying) {
                controller.seekTo(const Duration(seconds: 0));
              }
            },
            icon: Tooltip(
              message: controller.value.isPlaying ? 'Pause' : 'Play',
              child: Icon(
                controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              if (controller.value.position - const Duration(seconds: 5) >
                  Duration.zero) {
                controller.seekTo(
                    controller.value.position + const Duration(seconds: 5));
              }
            },
            icon: const Tooltip(
              message: 'move 5 seconds',
              child: Icon(
                Icons.replay_10,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              if (controller.value.volume == 0) {
                controller.setVolume(1);
              } else {
                controller.setVolume(0);
              }
            },
            icon: Tooltip(
              message: controller.value.volume == 0 ? 'Unmute' : 'Mute',
              child: Icon(
                controller.value.volume == 0
                    ? Icons.volume_off
                    : Icons.volume_up,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
