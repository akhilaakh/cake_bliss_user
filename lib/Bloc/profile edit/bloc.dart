import 'package:cake_bliss/model/user_model.dart';
import 'package:equatable/equatable.dart';

abstract class ProfileEditState extends Equatable {
  const ProfileEditState();

  @override
  List<Object?> get props => [];
}

class ProfileEditInitial extends ProfileEditState {
  const ProfileEditInitial();
}

class ProfileEditLoading extends ProfileEditState {
  const ProfileEditLoading();
}

class ProfileEditLoaded extends ProfileEditState {
  final UserModel user;

  const ProfileEditLoaded(this.user);

  @override
  List<Object> get props => [user];
}

class ProfileEditSuccess extends ProfileEditState {
  const ProfileEditSuccess();
}

class ProfileEditError extends ProfileEditState {
  final String message;

  const ProfileEditError(this.message);

  @override
  List<Object> get props => [message];
}
