// ignore_for_file: prefer_const_literals_to_create_immutables, avoid_print, unnecessary_string_interpolations, prefer_const_constructors, library_private_types_in_public_api, file_names, use_build_context_synchronously
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class CreatorCommunityPage extends StatefulWidget {
  const CreatorCommunityPage({super.key});

  @override
  _CreatorCommunityPageState createState() => _CreatorCommunityPageState();
}

class _CreatorCommunityPageState extends State<CreatorCommunityPage> {
  final TextEditingController channelNameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  late Stream<QuerySnapshot> _channelsStream;
  File? attachedFile; // Define attachedFile variable

  @override
  void initState() {
    super.initState();
    _channelsStream = FirebaseFirestore.instance
        .collection('channels')
        .where('creatorEmail',
            isEqualTo: FirebaseAuth.instance.currentUser?.email)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // This line hides the back button
        title: Text('Creator Community'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.white],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _channelsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  } else {
                    final channels = snapshot.data!.docs;
                    return ListView.builder(
                      itemCount: channels.length,
                      itemBuilder: (context, index) {
                        final channel = channels[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChannelDetailPage(
                                  channelId: channel.id,
                                  channelName: channel['channelName'],
                                  channelProfilePic:
                                      channel['channelProfilePic'],
                                ),
                              ),
                            );
                          },
                          child: ChannelCard(
                            channelName: channel['channelName'],
                            profilePicUrl: channel['channelProfilePic'],
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: FloatingActionButton(
            backgroundColor: const Color.fromARGB(255, 82, 204, 71),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Create Channel'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: channelNameController,
                        decoration: InputDecoration(labelText: 'Channel Name'),
                      ),
                      TextField(
                        controller: descriptionController,
                        decoration: InputDecoration(labelText: 'Description'),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        createChannel(context);
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 82, 204, 71), // Background color
                        primary: Colors.white, // Text color
                      ),
                      child: Text('Create'),
                    ),
                  ],
                ),
              );
            },
            child: Icon(Icons.add),
          ),
        ),
      ),
    );
  }

  void createChannel(BuildContext context) async {
    if (channelNameController.text.isNotEmpty &&
        descriptionController.text.isNotEmpty) {
      final currentUser = FirebaseAuth.instance.currentUser;
      final channelName = channelNameController.text;
      final channelRef =
          await FirebaseFirestore.instance.collection('channels').add({
        'channelProfilePic': "",
        'channelName': channelName, // Added channel name here
        'creatorEmail': currentUser!.email,
        'channelDetails':
            descriptionController.text, // Added channel details here
      });

      // Send initial welcome message
      final welcomeMessage = {
        'text': 'Welcome to $channelName!',
        'senderEmail': 'Admin',
        'timestamp': Timestamp.now(),
      };

      // Save the welcome message in the "messages" collection under the channel document
      await channelRef.collection('messages').add(welcomeMessage);

      // Reload the stream to reflect the newly created community
      setState(() {
        _channelsStream = FirebaseFirestore.instance
            .collection('channels')
            .where('creatorEmail', isEqualTo: currentUser.email)
            .snapshots();
      });

      Navigator.pop(context);
      channelNameController.clear();
      descriptionController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields')),
      );
    }
  }
}

class ChannelCard extends StatelessWidget {
  final String channelName;
  final String? profilePicUrl;

  ChannelCard({
    required this.channelName,
    this.profilePicUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      color: Colors.green, // Set the background color to green
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Row(
          children: [
            if (profilePicUrl != null)
              CircleAvatar(
                backgroundImage: NetworkImage(profilePicUrl!),
                radius: 20,
              ),
            SizedBox(width: 8.0),
            Text(
              channelName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white, // Set text color to white
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChannelDetailPage extends StatefulWidget {
  final String channelId;
  final String? channelName;
  final String? channelProfilePic;

  ChannelDetailPage({
    required this.channelId,
    this.channelName,
    this.channelProfilePic,
  });

  @override
  _ChannelDetailPageState createState() => _ChannelDetailPageState();
}

class _ChannelDetailPageState extends State<ChannelDetailPage> {
  final TextEditingController messageController = TextEditingController();
  bool isEditing = false;
  late String editingMessageId;
  bool isSending = false;

  @override
  void initState() {
    super.initState();
    messageController.addListener(() {
      setState(() {
        // Check if the message box is not empty to enable sending
        isSending = messageController.text.trim().isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    // Dispose of the controller to avoid memory leaks
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            GestureDetector(
              onTap: () {
                _showOptionsDialog(); // Show the options dialog on tap
              },
              child: CircleAvatar(
                backgroundImage: NetworkImage(widget.channelProfilePic!),
                radius: 20,
              ),
            ),
            SizedBox(width: 8.0),
            Text(widget.channelName ?? 'Channel Detail'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('channels')
                  .doc(widget.channelId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
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
                    return GestureDetector(
                      onLongPress: () {
                        if (isCurrentUser) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Edit or Delete Message'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      // Edit message
                                      setState(() {
                                        isEditing = true;
                                        editingMessageId = message.id;
                                        messageController.text = text;
                                      });
                                      Navigator.pop(
                                          context); // Close the dialog
                                    },
                                    child: Text('Edit'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      // Delete message
                                      deleteMessage(message.id);
                                      Navigator.pop(
                                          context); // Close the dialog
                                    },
                                    child: Text('Delete'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: isCurrentUser
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isCurrentUser
                                    ? Colors.green
                                    : Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                text,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isCurrentUser
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            ),
                            SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${time.month}/${time.day}/${time.year}',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '${_formatTime(time)}',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            color: Colors.grey[200],
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    onChanged: (value) {
                      setState(() {
                        // Show send button only if the message box is not empty
                        isSending = value.trim().isNotEmpty;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    isEditing
                        ? editMessage(editingMessageId, messageController.text)
                        : sendMessage();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour % 12}:${time.minute.toString().padLeft(2, '0')} ${time.hour < 12 ? 'AM' : 'PM'}';
  }

  void sendMessage() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final channelRef =
        FirebaseFirestore.instance.collection('channels').doc(widget.channelId);

    final messageText =
        messageController.text.trim(); // Trim leading and trailing whitespace

    if (messageText.isNotEmpty) {
      try {
        setState(() {
          isSending = false;
        });

        final messageId =
            FirebaseFirestore.instance.collection('channels').doc().id;

        final messageData = {
          'text': messageText,
          'senderEmail': currentUser!.email,
          'timestamp': Timestamp.now(),
        };

        await channelRef.collection('messages').doc(messageId).set(messageData);

        messageController.clear();
      } catch (e) {
        print('Error sending message: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message. Please try again later.'),
          ),
        );
      } finally {
        setState(() {
          isSending = true;
        });
      }
    } else {
      // Display an error message if the message is empty
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot send empty message.'),
        ),
      );
    }
  }

  void editMessage(String messageId, String newText) {
    final channelRef =
        FirebaseFirestore.instance.collection('channels').doc(widget.channelId);

    channelRef.collection('messages').doc(messageId).update({
      'text': newText,
      'timestamp': Timestamp.now(),
    }).then((_) {
      setState(() {
        isEditing = false;
        editingMessageId = '';
        messageController.clear();
      });
    }).catchError((error) {
      print('Error updating message: $error');
      // Handle error here, e.g., show a snackbar to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update message. Please try again later.'),
        ),
      );
    });
  }

  void deleteMessage(String messageId) {
    final channelRef =
        FirebaseFirestore.instance.collection('channels').doc(widget.channelId);

    channelRef.collection('messages').doc(messageId).delete().then((_) {
      // Handle success, if needed
    }).catchError((error) {
      print('Error deleting message: $error');
      // Handle error here, e.g., show a snackbar to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete message. Please try again later.'),
        ),
      );
    });
  }

  Widget _buildCircleAvatar() {
    return GestureDetector(
      onTap: () {
        _showOptionsDialog(); // Show the options dialog on tap
      },
      child: CircleAvatar(
        backgroundImage: NetworkImage(widget.channelProfilePic!),
        radius: 30,
      ),
    );
  }

  void _showOptionsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('channels')
              .doc(widget.channelId)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
            if (snapshot.hasError) {
              return AlertDialog(
                title: Text('Error'),
                content: Text('Failed to load channel details.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('OK'),
                  ),
                ],
              );
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return AlertDialog(
                title: Text('Error'),
                content: Text('Channel details not found.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('OK'),
                  ),
                ],
              );
            }
            final channelData = snapshot.data!.data() as Map<String, dynamic>;
            final channelName = channelData['channelName'] ?? '';
            final channelDetails = channelData['channelDetails'] ?? '';

            // Retrieve members collection and count documents
            return FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('channels')
                  .doc(widget.channelId)
                  .collection('members')
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }
                if (snapshot.hasError) {
                  return AlertDialog(
                    title: Text('Error'),
                    content: Text('Failed to load subscriber count.'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text('OK'),
                      ),
                    ],
                  );
                }
                final subscriberCount = snapshot.data!.docs.length;
                return AlertDialog(
                  title: Text('Channel Info'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4.0),
                      _buildCircleAvatar(), // Profile circle
                      SizedBox(height: 4.0),
                      Text(
                        'Channel: $channelName',
                        style: TextStyle(
                          fontSize: 18.0,
                        ),
                      ),
                      Text(
                        'Details: $channelDetails',
                        style: TextStyle(fontSize: 16.0),
                      ),
                      SizedBox(height: 4.0),
                      Text(
                        'Subscribers: $subscriberCount',
                        style: TextStyle(fontSize: 16.0),
                      ),
                      SizedBox(height: 16.0),
                      Container(
                        decoration: BoxDecoration(
                          color: Color.fromARGB(255, 82, 204, 71), // Background color
                          borderRadius: BorderRadius.circular(8), // Optional: Add border radius for rounded corners
                        ),
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.white), // Icon color
                          title: Text(
                            'Delete Channel',
                            style: TextStyle(color: Colors.white), // Text color
                          ),
                          onTap: () {
                            // Implement delete channel functionality
                            Navigator.pop(context); // Close the dialog
                            _deleteChannel();
                          },
                        ),
                      )
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _deleteChannel() {
    // Show a confirmation dialog to confirm channel deletion
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this channel?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Cancel the deletion
              },
              child: Text('No'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(true); // Confirm the deletion
                await _performChannelDeletion(); // Perform channel deletion
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performChannelDeletion() async {
    try {
      final channelRef = FirebaseFirestore.instance
          .collection('channels')
          .doc(widget.channelId);

      // Delete messages associated with the channel
      await channelRef.collection('messages').get().then((snapshot) {
        for (DocumentSnapshot ds in snapshot.docs) {
          ds.reference.delete();
        }
      });

      // Delete members associated with the channel
      await channelRef.collection('members').get().then((snapshot) {
        for (DocumentSnapshot ds in snapshot.docs) {
          ds.reference.delete();
        }
      });

      // Delete the channel document itself
      await channelRef.delete();

      // Close the channel detail page after successful deletion
      Navigator.pop(context);

      // Show a confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Channel and associated data deleted successfully.'),
        ),
      );
    } catch (e) {
      print('Error deleting channel: $e');
      // Show an error message if deletion fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete channel. Please try again later.'),
        ),
      );
    }
  }
}
