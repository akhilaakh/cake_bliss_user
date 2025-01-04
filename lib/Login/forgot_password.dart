import 'package:cake_bliss/services/auth_service.dart';
import 'package:cake_bliss/Login/loginpage.dart';
import 'package:flutter/material.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final _auth = AuthService();
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    // Dispose controllers to avoid memory leaks
    _emailController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(),
        body: Center(
            child: SingleChildScrollView(
                // Prevent overflow on smaller screens
                child: Column(children: [
          Image.asset(
            'asset/image.png',
            height: 200,
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginPage(),
                  ));
            },
            child: const Text(
              'Forgot Password',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
          const Text(
            'Please sign in to your existing account',
            style: TextStyle(fontWeight: FontWeight.w200),
          ),
          const SizedBox(
            height: 20,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                  borderSide: BorderSide(
                      color: Colors.transparent), // Optional: No visible border
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                  borderSide: BorderSide(
                    color: Color(0xFF6F2E00),
                  ), // Border color when focused
                ),
                labelText: 'Email',
                fillColor: Color.fromARGB(
                    255, 245, 219, 199), // Adding the background color
                filled: true,
              ),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          ElevatedButton(
            onPressed: () async {
              await _auth.sendPassWordResetLink(_emailController.text);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text(
                      "an email for password  reset has been sent to your email")));
              Navigator.pop(context);

              // Logic for normal login
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: const Color(0xFF6F2E00),
              padding:
                  const EdgeInsets.symmetric(vertical: 15, horizontal: 140),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 5,
              shadowColor: Colors.black.withOpacity(0.5),
            ),
            child: const Text(
              'SEND CODE',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ]))));
  }
}
