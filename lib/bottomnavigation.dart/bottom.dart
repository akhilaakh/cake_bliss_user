import 'package:cake_bliss/screen/home_page.dart';
import 'package:cake_bliss/screen/cart.dart';
import 'package:cake_bliss/screen/chat.dart';
import 'package:cake_bliss/screen/favorite.dart';

import 'package:cake_bliss/screen/profile.dart';
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

class BottomNavigationScreen extends StatefulWidget {
  const BottomNavigationScreen({Key? key}) : super(key: key);

  @override
  State<BottomNavigationScreen> createState() => _BottomNavigationScreenState();
}

class _BottomNavigationScreenState extends State<BottomNavigationScreen> {
  int currentIndex = 0;

  final List<Widget> _screens = [
    HomePage(),
    FavouritePage(),
    Cart(),
    Chat(),
    Profile(),
  ];

  // Method to show bottom sheet
  void _showBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 200,
          color: Colors.white,
          child: Center(
            child: Text(
              'This is the bottom sheet!',
              style: TextStyle(fontSize: 24),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: CurvedNavigationBar(
        index: currentIndex,
        height: 60.0,
        items: const <Widget>[
          Icon(Icons.home, size: 30),
          Icon(Icons.favorite, size: 30),
          Icon(Icons.shopping_cart),
          Icon(Icons.chat, size: 30),
          Icon(Icons.person),
        ],
        color: const Color(0xFF6F2E00),
        buttonBackgroundColor: const Color(0xFF6F2E00),
        backgroundColor: Colors.white,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
        onTap: (index) {
          setState(() {
            currentIndex = index;
            // Show bottom sheet when 'Add' icon (index 2) is tapped
            currentIndex = index;
            // if (index == 0) {
            //   // Navigate to Home Screen
            //   Navigator.pushReplacement(
            //     context,
            //     MaterialPageRoute(
            //       builder: (context) => const HomePage(),
            //     ),
            //   );
            // }
          });
        },
      ),
      body: _screens[currentIndex], // Display the selected screen
    );
  }
}
