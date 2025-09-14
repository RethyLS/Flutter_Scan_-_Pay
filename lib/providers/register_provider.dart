import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import 'package:dio/dio.dart';

// ----------------------
// Shared State
// ----------------------
class RegisterState {
  final bool loading;
  final String? message;

  RegisterState({this.loading = false, this.message});
}

// ----------------------
// Admin Register Provider (uses /register)
// ----------------------
final registerProvider = StateNotifierProvider<RegisterNotifier, RegisterState>(
  (ref) => RegisterNotifier(),
);

class RegisterNotifier extends StateNotifier<RegisterState> {
  RegisterNotifier() : super(RegisterState());

  Future<void> registerUser({
    required String name,
    required String email,
    required String password,
    String? zone,
  }) async {
    state = RegisterState(loading: true);
    try {
      final response = await ApiService.post('/register', {
        'name': name,
        'email': email,
        'password': password,
        'zone': zone,
      });

      if (response['user'] != null) {
        state = RegisterState(
          loading: false,
          message: 'Admin registered successfully',
        );
      } else {
        state = RegisterState(
          loading: false,
          message: response['message'] ?? 'Something went wrong',
        );
      }
    } on DioError catch (e) {
      final msg = e.response?.data['message'] ?? 'Something went wrong';
      state = RegisterState(loading: false, message: msg);
    } catch (e) {
      state = RegisterState(loading: false, message: 'Something went wrong');
    }
  }
}

// ----------------------
// User Register Provider (uses /register-user)
// ----------------------
final userRegisterProvider =
    StateNotifierProvider<UserRegisterNotifier, RegisterState>(
      (ref) => UserRegisterNotifier(),
    );

class UserRegisterNotifier extends StateNotifier<RegisterState> {
  UserRegisterNotifier() : super(RegisterState());

  Future<void> registerUser({
    required String name,
    required String email,
    required String password,
    String? zone,
  }) async {
    state = RegisterState(loading: true);
    try {
      final response = await ApiService.post('/register-user', {
        'name': name,
        'email': email,
        'password': password,
        'zone': zone,
      });

      if (response['user'] != null) {
        state = RegisterState(
          loading: false,
          message: 'User registered successfully',
        );
      } else {
        state = RegisterState(
          loading: false,
          message: response['message'] ?? 'Something went wrong',
        );
      }
    } on DioError catch (e) {
      final msg = e.response?.data['message'] ?? 'Something went wrong';
      state = RegisterState(loading: false, message: msg);
    } catch (e) {
      state = RegisterState(loading: false, message: 'Something went wrong');
    }
  }
}
