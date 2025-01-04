import 'dart:developer';

import 'package:cake_bliss/model/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final _fire = FirebaseFirestore.instance;

  create(UserModel user) {
    try {
      _fire.collection("users").add({
        "name": user.name,
        "address": user.address,
        "email": user.email,
        "password": user.id,
        "phone": user.phone,
        "image": user.imageUrl
      });
    } catch (e) {
      log(e.toString());
    }
  }

  Future<UserModel?> readUserProfile(String email) async {
    try {
      final querySnapshot = await _fire
          .collection("users")
          .where("email", isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs.first.data();
        return UserModel(
          id: userData['password'] ??
              '', // Using password field as ID based on your create method
          name: userData['name'] ?? '',
          email: userData['email'] ?? '',
          phone: userData['phone'] ?? '',
          address: userData['address'] ?? '',
          imageUrl: userData['image'],
        );
      }
      return null;
    } catch (e) {
      log("Error reading user profile: ${e.toString()}");
      return null;
    }
  }
}
