import 'dart:developer';

import 'package:cake_bliss/Bloc/profile/event.dart';
import 'package:cake_bliss/databaseServices/database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final DatabaseService _dbService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ProfileBloc() : super(const ProfileInitial()) {
    on<FetchProfileEvent>(_fetchProfile);
  }

  Future<void> _fetchProfile(
      FetchProfileEvent event, Emitter<ProfileState> emit) async {
    emit(const ProfileLoading());

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        emit(const ProfileError("No user logged in"));
        return;
      }

      final userModel = await _dbService.readUserProfile(currentUser.email!);
      if (userModel != null) {
        emit(ProfileLoaded(userModel));
      } else {
        emit(const ProfileError("User profile not found"));
      }
    } catch (e) {
      log("Error fetching profile: ${e.toString()}");
      emit(ProfileError("Failed to load profile: ${e.toString()}"));
    }
  }
}
