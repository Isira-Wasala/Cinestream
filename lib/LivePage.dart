import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:main/go_live.dart';

class GLivePage extends StatefulWidget {
  const GLivePage({super.key});

  @override
  _LivePageState createState() => _LivePageState();
}

class _LivePageState extends State<GLivePage> {
  DateTime? scheduledLive;
  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  bool detailsVisible = false;
  bool eventAdded = false;
  final database = FirebaseFirestore.instance;

  // get the email of the user
  String? creatorMail = FirebaseAuth.instance.currentUser?.email;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Page'),
        actions: [
          IconButton(
            onPressed: () => _selectScheduledLive(context),
            icon: const Icon(Icons.schedule),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (scheduledLive == null)
                // Opening display message
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  child: const SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Icon(Icons.info),
                        SizedBox(width: 10),
                        Text(
                          'You can add an event by clicking the \n schedule icon in the top bar.',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              if (scheduledLive != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Scheduled Live Event:',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Scheduled Time: ${DateFormat('yyyy-MM-dd HH:mm').format(scheduledLive!)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    if (titleController.text.isNotEmpty &&
                        descriptionController.text.isNotEmpty &&
                        priceController.text.isNotEmpty)
                      TextButton(
                        onPressed: () => _showEventDetails(context),
                        child: const Text('Details'),
                      ),
                    const Divider(),
                  ],
                ),
              if (!detailsVisible && scheduledLive != null && !eventAdded)
                ElevatedButton(
                  onPressed: _addDetailsForm,
                  child: const Text('Add Live Event Details'),
                ),
              if (detailsVisible &&
                  titleController.text.isEmpty &&
                  descriptionController.text.isEmpty &&
                  priceController.text.isEmpty)
                Column(
                  children: [
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    TextFormField(
                      controller: descriptionController,
                      decoration:
                          const InputDecoration(labelText: 'Description'),
                    ),
                    TextFormField(
                      controller: priceController,
                      decoration: const InputDecoration(labelText: 'Price'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _scheduleLiveEvent,
                      child: const Text('Schedule Live Event'),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              if (titleController.text.isNotEmpty &&
                  descriptionController.text.isNotEmpty &&
                  priceController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: ElevatedButton(
                            onPressed: _resheduleLiveEvent,
                            child: const Text('Postpone The Event'),
                          ),
                        ),
                      ),
                      const SizedBox(
                          width: 8.0), // Add padding between the buttons
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: ElevatedButton(
                            onPressed: _gotoLiveEvent,
                            child: const Text('Go To The Event'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectScheduledLive(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setState(() {
          scheduledLive = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _scheduleLiveEvent() {
    if (titleController.text.isNotEmpty &&
        descriptionController.text.isNotEmpty &&
        priceController.text.isNotEmpty) {
      // Create a map containing the live event details
      final Map<String, dynamic> liveEvent = {
        'title': titleController.text,
        'description': descriptionController.text,
        'price': priceController.text,
        'scheduled_time': scheduledLive,
        'creator_email': creatorMail,
      };

      // Store live event details in Firebase database
      database.collection('live_events').add(liveEvent);
      setState(() {
        detailsVisible = false;
        eventAdded = true;
      });
      // Show success message
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Success'),
          content: const Text('Live event scheduled successfully.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Missing Details'),
          content: const Text('Please fill in all details.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _showEventDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scheduled Live Event Details'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'Scheduled Time: ${DateFormat('yyyy-MM-dd HH:mm').format(scheduledLive!)}'),
            Text('Title: ${titleController.text}'),
            Text('Description: ${descriptionController.text}'),
            Text('Price: ${priceController.text}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          IconButton(
            onPressed: () => _deleteEvent(scheduledLive),
            icon: const Icon(Icons.delete),
          ),
        ],
      ),
    );
  }

  void _addDetailsForm() {
    setState(() {
      if (titleController.text.isEmpty &&
          descriptionController.text.isEmpty &&
          priceController.text.isEmpty) {
        detailsVisible = true;
      }
    });
  }

  void _resheduleLiveEvent() async {
    // Open date and time picker to select a new scheduled time
    final DateTime? newScheduledTime = await _selectScheduledTime();

    if (newScheduledTime != null) {
      setState(() {
        scheduledLive = newScheduledTime;
      });

      if (scheduledLive != null) {
        // Get the document ID of the live event to be rescheduled
        final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('live_events')
            .where('title', isEqualTo: titleController.text.toString())
            .get();

        if (querySnapshot.docs.isEmpty) {
          print("Live event not found.");
          return;
        }

        String liveEventId = querySnapshot.docs.first.id;

        // Update the scheduled time in the database
        await FirebaseFirestore.instance
            .collection('live_events')
            .doc(liveEventId)
            .update({'scheduled_time': scheduledLive});

        // Show success message to the user
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success'),
            content: const Text('Live event rescheduled successfully.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } else {
      print("User canceled the operation.");
    }
  }

  Future<DateTime?> _selectScheduledTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        return DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      }
    }

    return null; // Return null if the user cancels the operation
  }

  void _gotoLiveEvent() {
    String creatorMail = FirebaseAuth.instance.currentUser?.email ?? '';

    // Direct to live event page
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              GoLivePage(creatorMail, titleController.text.toString())),
    );
  }

  void _deleteEvent(DateTime? scheduledTime) async {
    // Query Firestore collection to find the document with the specified scheduled time
    final QuerySnapshot querySnapshot = await database
        .collection('live_events')
        .where('scheduled_time', isEqualTo: scheduledTime)
        .get();

    // Check if any documents are found
    if (querySnapshot.docs.isNotEmpty) {
      // Delete the first document found (assuming scheduled time is unique)
      final DocumentSnapshot document = querySnapshot.docs.first;
      await database.collection('live_events').doc(document.id).delete();

      // Close the dialog
      Navigator.pop(context);
      // show success message
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Success'),
          content: const Text('Live event deleted successfully.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      // Show error message if no matching document is found
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content:
              const Text('No event found with the specified scheduled time.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}
