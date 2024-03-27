import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:file_picker/file_picker.dart';

class ContentFormPage extends StatefulWidget {
  const ContentFormPage({Key? key});

  @override
  _ContentFormPageState createState() => _ContentFormPageState();
}

class _ContentFormPageState extends State<ContentFormPage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedCategory;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  bool _isUploading = false;
  PlatformFile? pickedFile;
  PlatformFile? thumbnailFile;
  UploadTask? uploadTask;
  VideoPlayerController? _videoPlayerController;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  Future selectFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.media,
    );
    if (result == null) return;
    setState(() {
      pickedFile = result.files.first;
    });

    if (pickedFile!.extension == 'mp4') {
      if (kIsWeb) {
        final path = "videos/${pickedFile!.name}";
        final ref = firebase_storage.FirebaseStorage.instance.ref().child(path);
        uploadTask = ref.putData(pickedFile!.bytes!);
        final snapshot = await uploadTask!.whenComplete(() {});
        final urlDownload = await snapshot.ref.getDownloadURL();

        _videoPlayerController = VideoPlayerController.network(urlDownload);
      } else {
        _videoPlayerController =
            VideoPlayerController.file(File(pickedFile!.path!));
      }
      await _videoPlayerController!.initialize();
      setState(() {});
    }
  }

  Future selectThumbnail() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result == null) return;
    setState(() {
      thumbnailFile = result.files.first;
    });
  }

  Future uploadFile() async {
    if (pickedFile == null ||
        _titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _selectedCategory == null ||
        _priceController.text.isEmpty ||
        thumbnailFile == null) {
      return;
    }

    // Set _isUploading to true to show the progress bar
    setState(() {
      _isUploading = true;
    });

    // Get the name of the creator (you may adjust this logic as needed)
    String? email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) {
      print("User not logged in.");
      return;
    }

    String? creatorName = await getCreatorNameFromFirestore(email);

    if (creatorName == null) {
      print("Failed to retrieve creator's name.");
      return;
    }

    // Create the folder path with the creator's name followed by "Contents"
    final folderPath = "videos/$creatorName Contents";

    // Fetch the number of videos already uploaded by the creator to determine the next video number
    int nextVideoNumber = await getNextVideoNumber(folderPath);

    // Create the subfolder for the current video
    final videoFolderPath = "$folderPath/Video $nextVideoNumber";
    final fileName =
        "${_titleController.text}.${pickedFile!.extension}"; // Keep the original file name
    final path = "$videoFolderPath/$fileName";
    final ref = firebase_storage.FirebaseStorage.instance.ref().child(path);

    if (kIsWeb) {
      uploadTask = ref.putData(pickedFile!.bytes!);
    } else {
      final file = File(pickedFile!.path!);
      final data = await file.readAsBytes();
      uploadTask = ref.putData(data);
    }

    // Listen to the task changes to get the progress
    uploadTask!.snapshotEvents.listen((event) {
      double percentage = (event.bytesTransferred / event.totalBytes) * 100;
      print('Upload progress: $percentage%');
    });

    final snapshot = await uploadTask!.whenComplete(() {});
    final urlDownload = await snapshot.ref.getDownloadURL();
    print('Download link: $urlDownload');

    // Upload thumbnail
    final thumbnailPath =
        "$videoFolderPath/${_titleController.text}.${thumbnailFile!.extension}";
    final thumbnailRef =
        firebase_storage.FirebaseStorage.instance.ref().child(thumbnailPath);
    if (kIsWeb) {
      uploadTask = thumbnailRef.putData(thumbnailFile!.bytes!);
    } else {
      final thumbnailData = await thumbnailFile!.bytes;
      uploadTask = thumbnailRef.putData(thumbnailData!);
    }

    final snapshotI = await uploadTask!.whenComplete(() {
      print("Thumbnail uploaded.");
    });
    final urlDownload1 = await snapshotI.ref.getDownloadURL();

    // Save field details as a text file
    final fieldDetailsPath = "$videoFolderPath/${_titleController.text}.txt";
    final fieldDetailsRef =
        firebase_storage.FirebaseStorage.instance.ref().child(fieldDetailsPath);
    final fieldDetailsContent = "Title: ${_titleController.text}\n"
        "Description: ${_descriptionController.text}\n"
        "Category: $_selectedCategory\n"
        "Price: ${_priceController.text}";
    final fieldDetailsUploadTask =
        fieldDetailsRef.putString(fieldDetailsContent);
    await fieldDetailsUploadTask.whenComplete(() {
      print("Field details saved.");
    });

    // Add content details to Firestore
    try {
      await FirebaseFirestore.instance
          .collection('content')
          .doc(_titleController.text)
          .set({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'price': _priceController.text,
        'videourl': urlDownload, // URL of the video
        'imageurl': urlDownload1, // Path to the thumbnail image
        'category': _selectedCategory,
        'creatorEmail': email, // Creator's email
      });

      print("Content details added to Firestore.");
    } catch (error) {
      print("Error adding content details to Firestore: $error");
    }

    // Set _isUploading to false to hide the progress bar
    setState(() {
      _isUploading = false;
    });

    // Clear the selected file previews and form fields
    setState(() {
      pickedFile = null;
      thumbnailFile = null;
      _titleController.clear();
      _descriptionController.clear();
      _priceController.clear();
      _selectedCategory = null;
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return UploadCompleteDialog(parentContext: context);
      },
    );
  }

  Widget buildFilePreview() {
    if (pickedFile == null) {
      return Container();
    }

    Widget filePreview;

    if (pickedFile!.extension == 'jpg' || pickedFile!.extension == 'png') {
      filePreview = Image.memory(
        pickedFile!.bytes!,
        fit: BoxFit.cover,
      );
    } else if (pickedFile!.extension == 'mp4') {
      filePreview = _videoPlayerController!.value.isInitialized
          ? AspectRatio(
              aspectRatio: _videoPlayerController!.value.aspectRatio,
              child: VideoPlayer(_videoPlayerController!),
            )
          : Container();
    } else {
      filePreview = Container();
    }

    return Flexible(
      child: Container(
        color: Colors.grey[200],
        child: filePreview,
      ),
    );
  }

  Widget buildThumbnailPreview() {
    if (thumbnailFile == null) {
      return Container();
    }

    Widget thumbnailPreview;

    if (thumbnailFile!.extension == 'jpg' ||
        thumbnailFile!.extension == 'png') {
      thumbnailPreview = Image.memory(
        thumbnailFile!.bytes!,
        fit: BoxFit.cover,
      );
    } else {
      thumbnailPreview =
          Container(); // Handle other types of thumbnails if needed
    }

    return Flexible(
      child: Container(
        color: Colors.grey[200],
        child: thumbnailPreview,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Content'),
      ),
      body: _isUploading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text('Uploading...'),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: selectFile,
                            style: ElevatedButton.styleFrom(
                              primary: Color.fromARGB(255, 82, 204, 71), // Background color
                              onPrimary: Colors.white, // Text color
                            ),
                            child: const Text('Select Video'),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: selectThumbnail,
                            style: ElevatedButton.styleFrom(
                              primary: Color.fromARGB(255, 82, 204, 71), // Background color
                              onPrimary: Colors.white, // Text color
                            ),
                            child: const Text('Select Thumbnail'),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: buildFilePreview(),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: buildThumbnailPreview(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(labelText: 'Title'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _descriptionController,
                        decoration:
                            const InputDecoration(labelText: 'Description'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                      ),
                      DropdownButtonFormField<String>(
                        decoration:
                            const InputDecoration(labelText: 'Category'),
                        value: _selectedCategory,
                        items: [
                          'entertainment',
                          'music',
                          'Comedy',
                          'religious',
                          'charity',
                          'stage plays',
                          'short films',
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a category';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(labelText: 'Price'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a price';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20.0),
                      ElevatedButton(
                        onPressed: uploadFile,
                        style: ElevatedButton.styleFrom(
                          primary: Color.fromARGB(255, 82, 204, 71), // Background color
                          onPrimary: Colors.white, // Text color
                        ),
                        child: const Text('Submit'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Future<String?> getCreatorNameFromFirestore(String email) async {
    try {
      // Query Firestore to find the matching document where email equals to the logged email
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

class UploadCompleteDialog extends StatelessWidget {
  final BuildContext parentContext;

  const UploadCompleteDialog({super.key, required this.parentContext});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Upload Complete'),
      content: const Text('Content successfully uploaded'),
      actions: [
        TextButton(
          child: const Text('OK'),
          onPressed: () {
            Navigator.of(context).pop();
            // Redirect to the main page
          },
        ),
      ],
    );
  }
}
