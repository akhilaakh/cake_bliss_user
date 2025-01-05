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
    const HomePage(),
    const FavouritePage(),
    const Cart(),
    const Chat(),
    const Profile(),
  ];

  // Method to show bottom sheet
  void _showBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 200,
          color: Colors.white,
          child: const Center(
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
          Icon(
            Icons.home,
            size: 30,
            color: Colors.white,
          ),
          Icon(
            Icons.favorite_border_outlined,
            size: 30,
            color: Colors.white,
          ),
          Icon(
            Icons.shopping_cart,
            color: Colors.white,
          ),
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 28,
            color: Colors.white,
          ),
          Icon(
            Icons.person,
            color: Colors.white,
          ),
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
