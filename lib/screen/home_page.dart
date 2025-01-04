import 'package:cake_bliss/services/auth_service.dart';
import 'package:cake_bliss/Login/loginpage.dart';
import 'package:cake_bliss/screen/cart.dart';
import 'package:cake_bliss/screen/chat.dart';
import 'package:cake_bliss/screen/favorite.dart';
import 'package:cake_bliss/screen/profile.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _auth = AuthService();

  void _handleMenuItemClick(String value) async {
    switch (value) {
      case 'Home':
        // Add navigation logic for Home if needed
        break;
      case 'Profile':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Profile()),
        );
        break;
      case 'Favorites':
        // Add navigation logic for Favorites
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FavouritePage()),
        );
        break;
      case 'Cart':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Cart()),
        );
        // Add navigation logic for Cart
        break;
      case 'Chat':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Chat()),
        );
        // Add navigation logic for Chat
        break;
      case 'Orders':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Chat()),
        );
        // Add navigation logic for Orders
        break;
      case 'Privacy Policy':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Cart()),
        );
        // Add navigation logic for Privacy Policy
        break;
      case 'App Info':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Cart()),
        );
        // Add navigation logic for App Info
        break;
      case 'Sign Out':
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Logout Confirmation"),
              content: const Text("Are you sure you want to logout?"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop(); // Close the dialog
                    await _auth.signout(); // Sign out the user
                    // ignore: use_build_context_synchronously
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginPage()),
                    );
                  },
                  child: const Text("Logout"),
                ),
              ],
            );
          },
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF6F2E00),
        toolbarHeight: 150,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Cake Bliss',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onSelected: _handleMenuItemClick,
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem(
                      value: 'Home',
                      child: Row(
                        children: [
                          Icon(Icons.home, color: Colors.black),
                          SizedBox(width: 8),
                          Text('Home'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'Profile',
                      child: Row(
                        children: [
                          Icon(Icons.person, color: Colors.black),
                          SizedBox(width: 8),
                          Text('Profile'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'Favorites',
                      child: Row(
                        children: [
                          Icon(Icons.favorite, color: Colors.black),
                          SizedBox(width: 8),
                          Text('Favorites'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'Cart',
                      child: Row(
                        children: [
                          Icon(Icons.shopping_cart, color: Colors.black),
                          SizedBox(width: 8),
                          Text('Cart'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'Chat',
                      child: Row(
                        children: [
                          Icon(Icons.chat, color: Colors.black),
                          SizedBox(width: 8),
                          Text('Chat'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'Orders',
                      child: Row(
                        children: [
                          Icon(Icons.list_alt, color: Colors.black),
                          SizedBox(width: 8),
                          Text('Orders'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'Privacy Policy',
                      child: Row(
                        children: [
                          Icon(Icons.privacy_tip, color: Colors.black),
                          SizedBox(width: 8),
                          Text('Privacy Policy'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'App Info',
                      child: Row(
                        children: [
                          Icon(Icons.info, color: Colors.black),
                          SizedBox(width: 8),
                          Text('App Info'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'Sign Out',
                      child: Row(
                        children: [
                          Icon(Icons.exit_to_app, color: Colors.black),
                          SizedBox(width: 8),
                          Text('Sign Out'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(
              height: 50,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: const TextStyle(color: Color(0xFF6F2E00)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF6F2E00),
                  ),
                ),
                style: const TextStyle(color: Color(0xFF6F2E00)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
