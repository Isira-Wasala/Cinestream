import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:main/MyHomePage.dart';

// CommunityWidget Class
class CommunityWidget extends StatefulWidget {
  const CommunityWidget({super.key});

  @override
  _CommunityWidgetState createState() => _CommunityWidgetState();
}

class _CommunityWidgetState extends State<CommunityWidget> {
  // Properties
  late TextEditingController _searchController;
  late List<String> _channelNames;
  late List<bool> _isFollowing;
  late List<String> _filteredChannelNames;
  late List<String> _filteredChannelIds;

  // Initialization
  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _channelNames = [];
    _isFollowing = [];
    _filteredChannelNames = [];
    _filteredChannelIds = [];
    _fetchChannelNames();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Fetch Channel Names
  Future<void> _fetchChannelNames() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('channels').get();
      setState(() {
        _channelNames = querySnapshot.docs
            .map((doc) => doc['channelName'].toString())
            .toList();
        _isFollowing = List.generate(_channelNames.length, (index) => false);
        _filteredChannelNames = _channelNames;
        _filteredChannelIds = querySnapshot.docs.map((doc) => doc.id).toList();
      });
      // Load user's following status
      _loadFollowingStatus();
    } catch (e) {
      print('Error fetching channel names: $e');
      // Implement error handling, show a snackbar or dialog with a user-friendly message
    }
  }

  // Load Following Status
  void _loadFollowingStatus() async {
    try {
      final currentUserEmail = _currentUserEmail();
      for (int i = 0; i < _filteredChannelIds.length; i++) {
        final channelRef = FirebaseFirestore.instance
            .collection('channels')
            .doc(_filteredChannelIds[i]);
        final docSnapshot =
            await channelRef.collection('members').doc(currentUserEmail).get();
        if (docSnapshot.exists) {
          setState(() {
            _isFollowing[i] = true;
          });
        }
      }
    } catch (e) {
      print('Error loading following status: $e');
    }
  }

  // Get Current User Email
  String _currentUserEmail() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      return currentUser.email ?? '';
    } else {
      return '';
    }
  }

  // Filter Channel Names
  void _filterChannelNames(String query) {
    setState(() {
      if (query.isNotEmpty) {
        _filteredChannelNames = _channelNames.where((channel) {
          final channelLower = channel.toLowerCase();
          final queryLower = query.toLowerCase();
          return channelLower.contains(queryLower);
        }).toList();
      } else {
        _filteredChannelNames = _channelNames;
      }
    });
  }

  // Toggle Follow
  void _toggleFollow(int channelIndex) async {
    if (_isFollowing[channelIndex]) {
      _unfollowChannel(channelIndex);
    } else {
      _followChannel(channelIndex);
    }
  }

  // Follow Channel
  void _followChannel(int channelIndex) async {
    try {
      final currentUserEmail = _currentUserEmail();
      final channelId = _filteredChannelIds[channelIndex];
      final channelRef =
          FirebaseFirestore.instance.collection('channels').doc(channelId);

      // Save user info inside the channel collection
      await channelRef.collection('members').doc(currentUserEmail).set({
        'email': currentUserEmail,
        // You can add more user information if needed
      });

      setState(() {
        _isFollowing[channelIndex] = true;
      });

      // Navigate to the chat screen after following the channel
      _navigateToChat(_filteredChannelNames[channelIndex]);
    } catch (e) {
      print('Error following channel: $e');
      // Implement error handling
    }
  }

  // Unfollow Channel
  void _unfollowChannel(int channelIndex) async {
    try {
      final currentUserEmail = _currentUserEmail();
      final channelId = _filteredChannelIds[channelIndex];
      final channelRef =
          FirebaseFirestore.instance.collection('channels').doc(channelId);

      // Remove user from channel members
      await channelRef.collection('members').doc(currentUserEmail).delete();

      setState(() {
        _isFollowing[channelIndex] = false;
      });
    } catch (e) {
      print('Error unfollowing channel: $e');
      // Implement error handling
    }
  }

  // Build Method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        automaticallyImplyLeading: false, // This line hides the back button
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: ChannelSearchDelegate(
                  _channelNames,
                  _filterChannelNames,
                  _toggleFollow,
                  _navigateToChat,
                  _isFollowing,
                  _filteredChannelIds,
                ),
              );
            },
          ),
        ],
      ),
      backgroundColor: Colors.white, // Set background color to yellow
      body: Column(
        children: [
          Expanded(
            child: _filteredChannelNames.isEmpty
                ? const Center(
                    child: Text('No result'),
                  )
                : ListView.builder(
                    itemCount: _filteredChannelNames.length,
                    itemBuilder: (context, index) {
                      final channelName = _filteredChannelNames[index];
                      final isFollowing = _isFollowing[
                          index]; // Check if user is following the channel
                      if (!isFollowing) {
                        return const SizedBox
                            .shrink(); // If user is not following, hide the channel
                      }
                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: ListTile(
                          title: Text(
                            channelName,
                            style: TextStyle(
                              fontSize: _calculateFontSize(index),
                            ),
                          ),
                          tileColor: isFollowing
                              ? const Color.fromARGB(255, 82, 204, 71)
                              : Colors.white,
                          trailing: ElevatedButton(
                            child: isFollowing
                                ? const Text('Following')
                                : const Text('Follow'),
                            onPressed: () {
                              _toggleFollow(index);
                            },
                          ),
                          onTap: () {
                            if (isFollowing) {
                              _navigateToChat(channelName);
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Calculate Font Size
  double _calculateFontSize(int index) {
    // You can define your own logic to calculate font size based on index
    // For example, you can increase font size if index is odd, decrease if even
    return 16.0;
  }

  // Navigate to Chat
  void _navigateToChat(String channelName) {
    final channelId =
        _filteredChannelIds[_filteredChannelNames.indexOf(channelName)];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          channelId: channelId,
          channelName: channelName,
        ),
      ),
    );
  }
}

// ChatScreen Class
class ChatScreen extends StatelessWidget {
  final String channelId;
  final String channelName;

  const ChatScreen(
      {super.key, required this.channelId, required this.channelName});

  // Format Time
  String _formatTime(DateTime time) {
    return DateFormat('MMMM dd, yyyy - hh:mm a').format(time);
  }

  // Build Method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // Display profile picture here
            InkWell(
              onTap: () {
                _showProfileDialog(context, channelName,
                    channelId); // Function to show profile dialog
              },
              child: const CircleAvatar(
                // You can replace 'default_profile_picture_url' with the actual profile picture URL from Firestore
                backgroundImage: NetworkImage('default_profile_picture_url'),
              ),
            ),
            const SizedBox(
                width:
                    8), // Add spacing between profile picture and channel name
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  channelName,
                  style: const TextStyle(
                    fontSize: 20.0,
                  ),
                ),
                const SizedBox(height: 4),
                FutureBuilder<int>(
                  future: _fetchSubscriberCount(channelId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(); // Return an empty widget while waiting for the subscriber count
                    }
                    final subscriberCount = snapshot.data ?? 0;
                    return Text(
                      '$subscriberCount subscribers',
                      style: const TextStyle(
                        fontSize: 12.0,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('channels')
                  .doc(channelId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                final messages = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final senderEmail = message['senderEmail'];
                    final text = message['text'];
                    final timestamp = message['timestamp'] as Timestamp;
                    final time = timestamp.toDate();
                    final currentUser = FirebaseAuth.instance.currentUser;
                    final isCurrentUser = senderEmail == currentUser?.email;
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: isCurrentUser
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isCurrentUser
                                  ? Colors.black
                                  : Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              text,
                              style: TextStyle(
                                fontSize: 16,
                                color:
                                    isCurrentUser ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Center(
                            child: Text(
                              '${_formatTime(time)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Fetch Subscriber Count
  Future<int> _fetchSubscriberCount(String channelId) async {
    try {
      final subscriberSnapshot = await FirebaseFirestore.instance
          .collection('channels')
          .doc(channelId)
          .collection('members')
          .get();
      return subscriberSnapshot.docs.length;
    } catch (e) {
      print('Error fetching subscriber count: $e');
      return 0; // Return 0 in case of error
    }
  }

  // Show Profile Dialog
  void _showProfileDialog(
      BuildContext context, String channelName, String channelId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Channel Info",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Row(
                    mainAxisAlignment:
                        MainAxisAlignment.start, // Align avatar to left corner
                    children: [
                      CircleAvatar(
                        // Replace with actual profile picture URL
                        backgroundImage:
                            NetworkImage('default_profile_picture_url'),
                        radius: 30,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Channel: $channelName", // Replace with actual channel name
                    style: const TextStyle(
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('channels')
                        .doc(channelId)
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(); // Return an empty widget while waiting for the document snapshot
                      }
                      final channelData = snapshot.data;
                      final channelDetails =
                          channelData?['channelDetails'] ?? '';
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          Text(
                            "Details: $channelDetails", // Display channel details
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 10),
                          FutureBuilder<int>(
                            future: _fetchSubscriberCount(channelId),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const SizedBox(); // Return an empty widget while waiting for the subscriber count
                              }
                              final subscriberCount = snapshot.data ?? 0;
                              return Text(
                                'Subscribers: $subscriberCount',
                                style: const TextStyle(
                                  fontSize: 16,
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          "Close",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ChannelSearchDelegate Class
class ChannelSearchDelegate extends SearchDelegate<String> {
  // Properties
  final List<String> channelNames;
  final Function(String) filterFunction;
  final Function(int) toggleFollowFunction;
  final Function(String) navigateToChatFunction;
  final List<bool> isFollowing;
  final List<String> filteredChannelIds;

  // Constructor
  ChannelSearchDelegate(
      this.channelNames,
      this.filterFunction,
      this.toggleFollowFunction,
      this.navigateToChatFunction,
      this.isFollowing,
      this.filteredChannelIds);

  // Build Actions
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          filterFunction('');
        },
      ),
    ];
  }

  // Build Results
  @override
  Widget buildResults(BuildContext context) {
    filterFunction(query);
    return Container();
  }

  // Build Suggestions
  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestionList = query.isEmpty
        ? []
        : channelNames.where((channel) {
            final channelLower = channel.toLowerCase();
            final queryLower = query.toLowerCase();
            return channelLower.contains(queryLower);
          }).toList();

    return ListView.builder(
      itemCount: suggestionList.length,
      itemBuilder: (context, index) {
        final channelName = suggestionList[index];
        final isFollowingIndex = channelNames.indexOf(channelName);
        final isFollowingChannel =
            isFollowingIndex != -1 && isFollowingIndex < isFollowing.length
                ? isFollowing[isFollowingIndex]
                : false;

        return ListTile(
          title: Text(channelName),
          trailing: ElevatedButton(
            child: isFollowingChannel
                ? const Text('Following')
                : const Text('Follow'),
            onPressed: () {
              toggleFollowFunction(isFollowingIndex);
            },
          ),
          onTap: () {
            navigateToChatFunction(channelName);
          },
        );
      },
    );
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }
}
