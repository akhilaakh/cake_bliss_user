// import 'package:cake_bliss/Bloc/profile%20edit/event.dart';
// import 'package:cake_bliss/Bloc/profile%20edit/state.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:cake_bliss/Bloc/profile/bloc.dart';
// import 'package:cake_bliss/Bloc/profile/event.dart';
// import 'package:cake_bliss/Bloc/profile/state.dart';
// import 'package:cake_bliss/model/user_model.dart';

// class ProfileEditPage extends StatefulWidget {
//   const ProfileEditPage({super.key});

//   @override
//   State<ProfileEditPage> createState() => _ProfileEditPageState();
// }

// class _ProfileEditPageState extends State<ProfileEditPage> {
//   final TextEditingController _nameController = TextEditingController();
//   final TextEditingController _addressController = TextEditingController();
//   final TextEditingController _phoneController = TextEditingController();

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _addressController.dispose();
//     _phoneController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF6F2E00),
//         title: const Text(
//           'Edit Profile',
//           style: TextStyle(color: Colors.white),
//         ),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: BlocConsumer<ProfileBloc, ProfileState>(
//         listener: (context, state) {
//           if (state is ProfileLoaded) {
//             _nameController.text = state.user.name;
//             _addressController.text = state.user.address;
//             _phoneController.text = state.user.phone;
//           }
//           if (state is ProfileUpdateSuccess) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(content: Text('Profile updated successfully!')),
//             );
//             Navigator.pop(context);
//           }
//           if (state is ProfileError) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(content: Text(state.message)),
//             );
//           }
//         },
//         builder: (context, state) {
//           if (state is ProfileLoading) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           return Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: SingleChildScrollView(
//               child: Column(
//                 children: [
//                   TextField(
//                     controller: _nameController,
//                     decoration: InputDecoration(
//                       labelText: 'Name',
//                       filled: true,
//                       fillColor: const Color.fromARGB(255, 245, 219, 199),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   TextField(
//                     controller: _addressController,
//                     decoration: InputDecoration(
//                       labelText: 'Address',
//                       filled: true,
//                       fillColor: const Color.fromARGB(255, 245, 219, 199),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   TextField(
//                     controller: _phoneController,
//                     decoration: InputDecoration(
//                       labelText: 'Phone',
//                       filled: true,
//                       fillColor: const Color.fromARGB(255, 245, 219, 199),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 30),
//                   ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFF6F2E00),
//                       foregroundColor: Colors.white,
//                       minimumSize: const Size(double.infinity, 50),
//                     ),
//                     onPressed: () {
//                       if (state is ProfileLoaded) {
//                         final updatedUser = UserModel(
//                           id: state.user.id,
//                           name: _nameController.text,
//                           email: state.user.email,
//                           phone: _phoneController.text,
//                           address: _addressController.text,
//                           imageUrl: state.user.imageUrl,
//                         );
//                         context.read<ProfileBloc>().add(
//                               UpdateProfileEvent(updatedUser),
//                             );
//                       }
//                     },
//                     child: const Text('Save Changes'),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// lib/screen/profile_edit.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cake_bliss/Bloc/profile/bloc.dart';
import 'package:cake_bliss/Bloc/profile/event.dart';
import 'package:cake_bliss/Bloc/profile/state.dart';
import 'package:cake_bliss/model/user_model.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(const FetchProfileEvent());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6F2E00),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileLoaded) {
            _nameController.text = state.user.name;
            _addressController.text = state.user.address;
            _phoneController.text = state.user.phone;
          }
          if (state is ProfileUpdateSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated successfully!')),
            );
            Navigator.pop(context);
          }
          if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      filled: true,
                      fillColor: const Color.fromARGB(255, 245, 219, 199),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: 'Address',
                      filled: true,
                      fillColor: const Color.fromARGB(255, 245, 219, 199),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone',
                      filled: true,
                      fillColor: const Color.fromARGB(255, 245, 219, 199),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6F2E00),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: () {
                      if (state is ProfileLoaded) {
                        final updatedUser = UserModel(
                          id: state.user.id,
                          name: _nameController.text,
                          email: state.user.email,
                          phone: _phoneController.text,
                          address: _addressController.text,
                          imageUrl: state.user.imageUrl,
                        );
                        context.read<ProfileBloc>().add(
                              UpdateProfileEvent(updatedUser),
                            );
                      }
                    },
                    child: const Text('Save Changes'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
