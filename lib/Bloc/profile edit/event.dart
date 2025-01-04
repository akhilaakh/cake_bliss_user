import 'package:cake_bliss/Bloc/profile/event.dart';
import 'package:cake_bliss/model/user_model.dart';

class UpdateProfileEvent extends ProfileEvent {
  final UserModel user;

  const UpdateProfileEvent(this.user);

  @override
  List<Object> get props => [user];
}
