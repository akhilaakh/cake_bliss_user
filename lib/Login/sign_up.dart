import 'dart:io';

import 'package:cake_bliss/Bloc/signup/bloc.dart';
import 'package:cake_bliss/Bloc/signup/event.dart';
import 'package:cake_bliss/Bloc/signup/state.dart';
import 'package:cake_bliss/databaseServices/database_service.dart';
import 'package:cake_bliss/services/auth_service.dart';
import 'package:cake_bliss/bottomnavigation.dart/bottom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart'; // Import the image_picker package

final _auth = AuthService();

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final _dbService = DatabaseService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // Regular expression for validating name
  final RegExp nameRegExp = RegExp(r'^[a-zA-Z]+$'); // Only alphabets allowed

  // Variable to store selected image
  XFile? _selectedImage;

  // Function to pick an image from the gallery
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color.fromARGB(255, 15, 6, 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Image Picker Section
              GestureDetector(
                onTap: _pickImage, // Open the gallery when tapped
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _selectedImage != null
                      ? FileImage(File(_selectedImage!.path))
                      : null,
                  child: _selectedImage == null
                      ? Icon(Icons.camera_alt, size: 40, color: Colors.grey)
                      : null,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Sign Up',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 7),
              const Text('Please sign up to get started'),
              const SizedBox(height: 20),

              // Name TextField
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                      borderSide: BorderSide(
                        color: Colors.transparent,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                      borderSide: BorderSide(
                        color: Color(0xFF6F2E00),
                      ),
                    ),
                    labelText: 'Name',
                    fillColor: Color.fromARGB(255, 245, 219, 199),
                    filled: true,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                      borderSide: BorderSide(
                        color: Colors.transparent,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                      borderSide: BorderSide(
                        color: Color(0xFF6F2E00),
                      ),
                    ),
                    labelText: 'Address',
                    fillColor: Color.fromARGB(255, 245, 219, 199),
                    filled: true,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Email TextField
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                      borderSide: BorderSide(
                        color: Colors.transparent,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                      borderSide: BorderSide(
                        color: Color(0xFF6F2E00),
                      ),
                    ),
                    labelText: 'Email',
                    fillColor: Color.fromARGB(255, 245, 219, 199),
                    filled: true,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Password TextField
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                      borderSide: BorderSide(
                        color: Colors.transparent,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                      borderSide: BorderSide(
                        color: Color(0xFF6F2E00),
                      ),
                    ),
                    labelText: 'Password',
                    fillColor: Color.fromARGB(255, 245, 219, 199),
                    filled: true,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Phone TextField
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                      borderSide: BorderSide(
                        color: Colors.transparent,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                      borderSide: BorderSide(
                        color: Color(0xFF6F2E00),
                      ),
                    ),
                    labelText: 'Phone',
                    fillColor: Color.fromARGB(255, 245, 219, 199),
                    filled: true,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Sign Up Button
              BlocConsumer<Signinbloc, SigninState>(
                listener: (context, state) {
                  if (state is SigninSuccess) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const BottomNavigationScreen()),
                    );
                  } else if (state is SigninFailure) {
                    _showSnackBar(state.errormessage);
                  }
                },
                builder: (context, state) {
                  return ElevatedButton(
                    onPressed: () {
                      final name = _nameController.text.trim();
                      final email = _emailController.text.trim();
                      final password = _passwordController.text;
                      final phone = _phoneController.text.trim();
                      final address = _addressController.text.trim();

                      // Validations
                      if (name.isEmpty || !nameRegExp.hasMatch(name)) {
                        _showSnackBar('Name can only contain alphabets!');
                        return;
                      }
                      if (password.length < 8) {
                        _showSnackBar(
                            'Password must be at least 8 characters!');
                        return;
                      }
                      if (phone.isEmpty || phone.length != 10) {
                        _showSnackBar('Phone number must be 10 digits!');
                        return;
                      }

                      // Trigger Bloc event
                      context.read<Signinbloc>().add(
                            SignButtonClick(
                              name: name,
                              email: email,
                              password: password,
                              phone: phone,
                              address: address,
                              context: context,
                            ),
                          );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 150),
                      primary: Color(0xFF6F2E00),
                    ),
                    child: BlocBuilder<Signinbloc, SigninState>(
                        builder: (context, state) {
                      if (state is SigninLoading) {
                        return const CircularProgressIndicator(
                            color: Colors.white);
                      }
                      return const Text('SIGN UP',
                          style: TextStyle(color: Colors.white));
                    }),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
