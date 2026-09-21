import 'package:equatable/equatable.dart';
import '../models/user_model.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AppStarted extends AuthEvent {}

class LoginWithPhonePin extends AuthEvent {
  final String phone;
  final String pin;

  const LoginWithPhonePin({required this.phone, required this.pin});

  @override
  List<Object?> get props => [phone, pin];
}

class AutoLoginRequested extends AuthEvent {}

class LogoutRequested extends AuthEvent {}

class UpdateUserProfile extends AuthEvent {
  final UserModel user;

  const UpdateUserProfile(this.user);

  @override
  List<Object?> get props => [user];
}
