import 'package:flutter/material.dart';
import 'package:main/CreatorLoginPage.dart';
import 'package:main/SponsorLoginPage.dart';
import 'package:main/UserLoginPage.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({Key? key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      //appBar: AppBar(
      //elevation: 0, // Remove appbar shadow
      // backgroundColor:
      // Color.fromARGB(255, 255, 255, 255), // Make appbar transparent
      // title: const Text(
      // '/CineStream', // Add title "CineStream"
      // style: TextStyle(
      //  color: Color.fromARGB(255, 10, 2, 2), // Text color black
      //  fontSize: 24, // Font size
      //   fontWeight: FontWeight.bold, // Bold font weight
      //  ),
      //  ),
      //   centerTitle: true,
      // ),
      backgroundColor:
          Colors.transparent, // Set Scaffold background to transparent
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
                "images/background_image.jpg"), // Replace with your image path
            fit: BoxFit.cover, // Cover the whole area with the image
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 2), // Add padding to top
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Select Your Account Type',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.black, // Change text color to black
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto', // Use a professional font
                  ),
                ),
                const SizedBox(
                    height: 0), // Add space between title and buttons
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const UserLoginPage()),
                    );
                  },
                  style: ButtonStyle(
                    padding: MaterialStateProperty.all<EdgeInsets>(
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 32),


                    ),
                    textStyle: MaterialStateProperty.all<TextStyle>(
                      const TextStyle(
                          fontSize: 18,
                          color: Colors.black), // Change text color to black
                    ),
                    side: MaterialStateProperty.all<BorderSide>(
                      const BorderSide(
                          color: Colors.black), // Change border color to black
                    ),
                    shape: MaterialStateProperty.all<OutlinedBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32.0),
                      ),
                    ),
                    foregroundColor: MaterialStateProperty.all<Color>(
                        Colors.black), // Change text color to black
                  ),

                  child: const Text('User'),
                ),
                const SizedBox(height: 25), // Add space between buttons
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const CreatorLoginPage()),
                    );
                  },
                  style: ButtonStyle(
                    padding: MaterialStateProperty.all<EdgeInsets>(
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                    ),
                    textStyle: MaterialStateProperty.all<TextStyle>(
                      const TextStyle(
                          fontSize: 18,
                          color: Colors.black), // Change text color to black
                    ),
                    side: MaterialStateProperty.all<BorderSide>(
                      const BorderSide(
                          color: Colors.black), // Change border color to black


                    ),
                    shape: MaterialStateProperty.all<OutlinedBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32.0),
                      ),
                    ),
                    foregroundColor: MaterialStateProperty.all<Color>(
                        Colors.black), // Change text color to black
                  ),

                  child: const Text('Creator'),
                ),
                const SizedBox(height: 20), // Add space between buttons
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SponsorLoginPage()),
                    );
                  },
                  style: ButtonStyle(
                    padding: MaterialStateProperty.all<EdgeInsets>(
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                    ),
                    textStyle: MaterialStateProperty.all<TextStyle>(
                      const TextStyle(
                          fontSize: 18,
                          color: Colors.black), // Change text color to black
                    ),
                    side: MaterialStateProperty.all<BorderSide>(
                      const BorderSide(
                          color: Colors.black), // Change border color to black
                    ),
                    shape: MaterialStateProperty.all<OutlinedBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32.0),
                      ),

                 

                    ),
                    foregroundColor: MaterialStateProperty.all<Color>(
                        Colors.black), // Change text color to black
                  ),

                  child: const Text('Sponsor'),

                 
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
