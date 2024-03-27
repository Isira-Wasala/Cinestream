import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatbotScreen> {
  final TextEditingController _textController = TextEditingController();
  late String _userName = ''; // Initialize _userName
  bool _sendButtonVisible = true;
  int _countdownSeconds = 20;

  @override
  void initState() {
    super.initState();
    _retrieveUserName();
  }

  Future<void> _retrieveUserName() async {
    String? userEmail = FirebaseAuth.instance.currentUser?.email;

    if (userEmail != null) {
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .where('email', isEqualTo: userEmail)
          .get();

      if (userSnapshot.docs.isEmpty) {
        userSnapshot = await FirebaseFirestore.instance
            .collection('Creator')
            .where('email', isEqualTo: userEmail)
            .get();
      }

      if (userSnapshot.docs.isEmpty) {
        userSnapshot = await FirebaseFirestore.instance
            .collection('Sponsor')
            .where('email', isEqualTo: userEmail)
            .get();
      }

      if (userSnapshot.docs.isNotEmpty) {
        _userName = userSnapshot.docs.first['name'];
      } else {
        _userName = userEmail;
      }

      setState(() {});
    }
  }

  void _sendMessage() async {
    if (_textController.text.isNotEmpty && _sendButtonVisible) {
      String message = _textController.text;

      if (_userName.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('chatbot_messages')
            .doc(_userName)
            .collection('messages')
            .add({
          'text': message,
          'timestamp': FieldValue.serverTimestamp(),
        });

        if (_isGreeting(message)) {
          _handleGreeting(message);
        } else if (_isContentQuery(message)) {
          _handleContentQuery(message);
        } else if (_isLiveQuery(message)) {
          _handleLiveQuery(message);
        } else {
          _handleDefaultResponse();
        }

        print('Message sent: $message');
        _textController.clear();

        setState(() {
          _sendButtonVisible = false;
        });

        _startCountdown();
      } else {
        print('User name not available.');
      }
    }
  }

  bool _isGreeting(String message) {
    final greetings = ['hi', 'hey', 'hello', 'yoh', 'hey there'];
    return greetings.contains(message.toLowerCase());
  }

  bool _isContentQuery(String message) {
    final contentQueries = [
      'what materials are accessible?',
      'what resources are on offer?',
      'what content is available for use?',
      'what options do we have in terms of content?',
      'what materials are at our disposal?',
      'what content can we access?',
      'what is included in the available content?',
      'what resources are currently accessible?',
      'what content is at our fingertips?',
      'what materials are on hand for use?',
      'contents'
    ];

    return contentQueries.contains(message.toLowerCase());
  }

  bool _isLiveQuery(String message) {
    final liveEventQueries = [
      "what live events or programs are currently scheduled?",
      "are there any upcoming live performances or shows?",
      "what live entertainment options do you have available?",
      "could you provide information on any live events happening soon?",
      "i'm interested in attending a live program, do you have any recommendations?",
      "what are the options for live activities or events this week?",
      "are there any live shows or events happening in the near future?",
      "where can i find information about live programs or performances?",
      "are there any live experiences or events happening locally?",
      "what live events or programs do you have on offer?",
    ];

    return liveEventQueries.contains(message.toLowerCase());
  }

  void _handleGreeting(String greeting) {
    String response;
    switch (greeting.toLowerCase()) {
      case 'hi':
      case 'hey':
      case 'yoh':
      case 'hey there':
        response = "Hey, how can I assist you today?";
        break;
      case 'hello':
        response = "Hello, how can I help you?";
        break;
      default:
        response = "Hello! How can I assist you today?";
    }

    FirebaseFirestore.instance
        .collection('chatbot_messages')
        .doc(_userName)
        .collection('messages')
        .add({
      'text': response,
      'timestamp': FieldValue.serverTimestamp(),
      'sender': 'Chatbot'
    });
  }

  void _handleContentQuery(String query) async {
    final QuerySnapshot collectionSnapshot =
        await FirebaseFirestore.instance.collection('content').get();

    if (collectionSnapshot.docs.isNotEmpty) {
      String response = 'Here are the available collections:\n';
      for (final doc in collectionSnapshot.docs) {
        final String collectionName = doc.id;
        response += '- $collectionName\n';
      }

      FirebaseFirestore.instance
          .collection('chatbot_messages')
          .doc(_userName)
          .collection('messages')
          .add({
        'text': response,
        'timestamp': FieldValue.serverTimestamp(),
        'sender': 'Chatbot'
      });
    } else {
      String response =
          'Sorry, no content collections are available at the moment.';
      FirebaseFirestore.instance
          .collection('chatbot_messages')
          .doc(_userName)
          .collection('messages')
          .add({
        'text': response,
        'timestamp': FieldValue.serverTimestamp(),
        'sender': 'Chatbot'
      });
    }
  }

  void _handleLiveQuery(String query) async {
    final QuerySnapshot liveEventsSnapshot =
        await FirebaseFirestore.instance.collection('live_events').get();

    if (liveEventsSnapshot.docs.isNotEmpty) {
      List<String> eventTitles = [];
      liveEventsSnapshot.docs.forEach((doc) {
        final String eventTitle = doc['title'];
        eventTitles.add(eventTitle);
      });

      String response = 'Here are the upcoming live events:\n';
      eventTitles.forEach((title) {
        response += '- $title\n';
      });

      FirebaseFirestore.instance
          .collection('chatbot_messages')
          .doc(_userName)
          .collection('messages')
          .add({
        'text': response,
        'timestamp': FieldValue.serverTimestamp(),
        'sender': 'Chatbot'
      });
    } else {
      String response = 'Sorry, no live events are scheduled at the moment.';
      FirebaseFirestore.instance
          .collection('chatbot_messages')
          .doc(_userName)
          .collection('messages')
          .add({
        'text': response,
        'timestamp': FieldValue.serverTimestamp(),
        'sender': 'Chatbot'
      });
    }
  }

  void _handleDefaultResponse() {
    String response =
        "As a newly developed AI model, I'm still in a learning progress. "
        "At the moment, I can only tell you about available contents and live events. "
        "If you need to know about contents, please type 'Contents'. "
        "If you need to know about live events, please type 'Live Events'.";

    FirebaseFirestore.instance
        .collection('chatbot_messages')
        .doc(_userName)
        .collection('messages')
        .add({
      'text': response,
      'timestamp': FieldValue.serverTimestamp(),
      'sender': 'Chatbot'
    });
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 20), () {
      setState(() {
        _sendButtonVisible = true;
        _countdownSeconds = 20;
      });
    });

    const oneSecond = Duration(seconds: 1);
    Timer.periodic(oneSecond, (Timer timer) {
      setState(() {
        if (_countdownSeconds < 1) {
          timer.cancel();
        } else {
          _countdownSeconds -= 1;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chatbot'),
      ),
      body: Column(
        children: <Widget>[
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('chatbot_messages')
                    .doc(_userName) // Navigate to the user's folder
                    .collection('messages')
                    .orderBy('timestamp')
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  final messages = snapshot.data?.docs;
                  print(
                      'Number of messages: ${messages?.length}'); // Added for debugging
                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: messages?.length,
                    itemBuilder: (context, index) {
                      final message = messages?[index].data();
                      final timestamp = (message
                          as Map<String, dynamic>)['timestamp'] as Timestamp?;
                      final formattedTime = timestamp != null
                          ? _formatTimestamp(timestamp.toDate())
                          : '';

                      final isUserMessage = (message['sender'] ?? '') ==
                          _userName; // Check if message is sent by the current user

                      return Padding(
                        padding: EdgeInsets.symmetric(
                            vertical: 4.0, horizontal: 8.0),
                        child: Align(
                          alignment: isUserMessage
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isUserMessage
                                  ? Colors.blue[200]
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.only(
                                topLeft:
                                    Radius.circular(isUserMessage ? 12.0 : 0),
                                topRight:
                                    Radius.circular(isUserMessage ? 0 : 12.0),
                                bottomLeft: Radius.circular(12.0),
                                bottomRight: Radius.circular(12.0),
                              ),
                            ),
                            padding: EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message['text'] ?? '',
                                  style: TextStyle(
                                      fontSize: 16.0,
                                      color: isUserMessage
                                          ? Colors.black
                                          : Colors.black87),
                                ),
                                SizedBox(height: 4.0),
                                Text(
                                  formattedTime,
                                  style: TextStyle(
                                      fontSize: 12.0, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          const Divider(height: 1.0),
          Container(
            decoration: BoxDecoration(color: Theme.of(context).cardColor),
            child: _buildTextComposer(),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    String formattedDate = "${timestamp.day}/${timestamp.month}";
    String formattedTime = "${timestamp.hour}:${timestamp.minute}";
    return "$formattedDate - $formattedTime";
  }

  Widget _buildTextComposer() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: IconTheme(
        data: IconThemeData(color: Theme.of(context).canvasColor),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: <Widget>[
              Flexible(
                child: TextField(
                  controller: _textController,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: const InputDecoration.collapsed(
                      hintText: 'Send a message'),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.send,
                  color: Colors.blue,
                ),
                onPressed: _sendButtonVisible ? _sendMessage : null,
              ),
              if (!_sendButtonVisible)
                Text(
                  '$_countdownSeconds',
                  style: TextStyle(fontSize: 18),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
