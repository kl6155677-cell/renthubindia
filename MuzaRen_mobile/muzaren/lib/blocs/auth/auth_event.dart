import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AppStarted extends AuthEvent {}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  const LoginRequested(this.email, this.password);

  @override
  List<Object?> get props => [email, password];
}

class FirebaseLoginRequested extends AuthEvent {
  final String idToken;

  const FirebaseLoginRequested(this.idToken);

  @override
  List<Object?> get props => [idToken];
}

class RegisterRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;
  final String? phone;

  const RegisterRequested({
    required this.name,
    required this.email,
    required this.password,
    this.phone,
  });

  @override
  List<Object?> get props => [name, email, password, phone];
}

class LogoutRequested extends AuthEvent {}
class UpdateProfileRequested extends AuthEvent {
  final String name;
  final String? phone;
  final String? city;
  final String? country;
  final String? currency;
  final String? avatarPath;

  const UpdateProfileRequested({
    required this.name,
    this.phone,
    this.city,
    this.country,
    this.currency,
    this.avatarPath,
  });

  @override
  List<Object?> get props => [name, phone, city, country, currency, avatarPath];
}
