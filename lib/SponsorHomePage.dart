import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:main/SponsorAdsPage.dart';
import 'CommunityWidget.dart';
import 'SponsorSearchWidget.dart';
import 'SponsorSettingWidget.dart';
import 'chatbotscreen.dart'; // Import the chatbot screen

class SponsorHomePage extends StatefulWidget {
  const SponsorHomePage({Key? key});

  @override
  _SponsorHomePageState createState() => _SponsorHomePageState();
}

class _SponsorHomePageState extends State<SponsorHomePage> {
  int _selectedIndex = 0;

  final List<Widget> _widgetOptions = <Widget>[
    const HomeWidget(),
    const SponsorSearchWidget(),
    CommunityWidget(),
    SponsorAdsPage(),
    const SponsorSettingWidget(),
  ];

  void _onItemTapped(int index) {
    if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SponsorSettingWidget()),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _showNotificationPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Notifications"),
          content: const Text("You have new notifications!"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 0
          ? AppBar(
              automaticallyImplyLeading: false, // Remove the back button
              title: const Text(
                'Cinestream',
                style: TextStyle(fontSize: 35.0),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: _showNotificationPopup,
                ),
              ],
            )
          : null,
      body: Stack(
        children: [
          _widgetOptions.elementAt(_selectedIndex),
          if (_selectedIndex == 0)
            Positioned(
              bottom: kBottomNavigationBarHeight - 30,
              right: 16,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ChatbotScreen()),
                  );
                },
                child: Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                    color: Colors.yellow,
                  ),
                  child: const Icon(
                    Icons.rocket,
                    size: 35,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Community',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'ADS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.black,
        unselectedLabelStyle: const TextStyle(color: Colors.black),
        onTap: _onItemTapped,
      ),
    );
  }
}

// class HomeWidget extends StatelessWidget {
//   const HomeWidget({Key? key});

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       child: Column(
//         children: [
//           SizedBox(
//             height: 180,
//             width: double.infinity,
//             child: SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               child: Row(
//                 children: [
//                   Padding(
//                     padding: const EdgeInsets.only(right: 10.0),
//                     child: _buildSquare(Colors.red),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.only(right: 10.0),
//                     child: _buildSquare(Colors.blue),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.only(right: 10.0),
//                     child: _buildSquare(Colors.green),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.only(right: 10.0),
//                     child: _buildSquare(Colors.orange),
//                   ),
//                   _buildSquare(Colors.purple),
//                 ],
//               ),
//             ),
//           ),
//           const SizedBox(height: 20), // Add some space between sections
//           const Padding(
//             padding: EdgeInsets.fromLTRB(10.0, 10.0, 0.0, 8.0),
//             child: Align(
//               alignment: Alignment.centerLeft,
//               child: Text(
//                 'Short Movies',
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ),
//           SizedBox(
//             height: 180,
//             width: double.infinity,
//             child: SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               child: Row(
//                 children: [
//                   Padding(
//                     padding: const EdgeInsets.only(right: 10.0),
//                     child: _buildMovieSquare(Colors.yellow),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.only(right: 10.0),
//                     child: _buildMovieSquare(Colors.teal),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.only(right: 10.0),
//                     child: _buildMovieSquare(Colors.pink),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.only(right: 10.0),
//                     child: _buildMovieSquare(Colors.indigo),
//                   ),
//                   _buildMovieSquare(Colors.amber),
//                 ],
//               ),
//             ),
//           ),
//           const SizedBox(height: 20), // Add some space between sections
//           const Padding(
//             padding: EdgeInsets.fromLTRB(10.0, 10.0, 0.0, 8.0),
//             child: Align(
//               alignment: Alignment.centerLeft,
//               child: Text(
//                 'Standup Comedy',
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ),
//           SizedBox(
//             height: 180,
//             width: double.infinity,
//             child: SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               child: Row(
//                 children: [
//                   Padding(
//                     padding: const EdgeInsets.only(right: 10.0),
//                     child: _buildComedySquare(Colors.yellow),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.only(right: 10.0),
//                     child: _buildComedySquare(Colors.teal),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.only(right: 10.0),
//                     child: _buildComedySquare(Colors.pink),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.only(right: 10.0),
//                     child: _buildComedySquare(Colors.indigo),
//                   ),
//                   _buildComedySquare(Colors.amber),
//                 ],
//               ),
//             ),
//           ),
//           const SizedBox(height: 20), // Add some space between sections
//           const Padding(
//             padding: EdgeInsets.fromLTRB(10.0, 10.0, 0.0, 8.0),
//             child: Align(
//               alignment: Alignment.centerLeft,
//               child: Text(
//                 'Stage Plays',
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ),
//           SizedBox(
//             height: 180,
//             width: double.infinity,
//             child: SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               child: Row(
//                 children: [
//                   Padding(
//                     padding: const EdgeInsets.only(right: 10.0),
//                     child: _buildStagePlaySquare(Colors.yellow),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.only(right: 10.0),
//                     child: _buildStagePlaySquare(Colors.teal),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.only(right: 10.0),
//                     child: _buildStagePlaySquare(Colors.pink),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.only(right: 10.0),
//                     child: _buildStagePlaySquare(Colors.indigo),
//                   ),
//                   _buildStagePlaySquare(Colors.amber),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSquare(Color color) {
//     return SizedBox(
//       height: 180,
//       width: 375,
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(15),
//         child: Container(
//           color: color,
//         ),
//       ),
//     );
//   }

//   Widget _buildMovieSquare(Color color) {
//     return SizedBox(
//       height: 180,
//       width: 120,
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(15),
//         child: Container(
//           color: color,
//         ),
//       ),
//     );
//   }

//   Widget _buildComedySquare(Color color) {
//     return SizedBox(
//       height: 180,
//       width: 120,
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(15),
//         child: Container(
//           color: color,
//         ),
//       ),
//     );
//   }

//   Widget _buildStagePlaySquare(Color color) {
//     return SizedBox(
//       height: 180,
//       width: 120,
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(15),
//         child: Container(
//           color: color,
//         ),
//       ),
//     );
//   }
// }

class HomeWidget extends StatefulWidget {
  const HomeWidget({Key? key});

  @override
  _HomeWidgetState createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  List<String> imageUrls = [];

  @override
  void initState() {
    super.initState();
    fetchImageUrls();
  }

  Future<void> fetchImageUrls() async {
    final List<String> urls = [];

    for (int i = 1; i <= 7; i++) {
      final String imagePath = 'Flyers/$i.png';
      final String imageUrl = await getImageUrl(imagePath);
      urls.add(imageUrl);
    }

    setState(() {
      imageUrls = urls;
    });
  }

  Future<String> getImageUrl(String imagePath) async {
    try {
      final Reference ref = FirebaseStorage.instance.ref().child(imagePath);
      final pngUrl = await ref.getDownloadURL();
      return pngUrl;
    } catch (e) {
      try {
        final jpgPath = imagePath.replaceAll('.png', '.jpg');
        final Reference ref = FirebaseStorage.instance.ref().child(jpgPath);
        final jpgUrl = await ref.getDownloadURL();
        return jpgUrl;
      } catch (e) {
        // Both png and jpg fetching failed
        print('Error fetching image: $e');
        return '';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Latest Events',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: imageUrls.map((imageUrl) {
                return GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => Dialog(
                        child: InteractiveViewer(
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 2.0,
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.grey.shade200,
                          Colors.white,
                        ],
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        imageUrl,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class FullScreenImage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
