import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import 'package:dio/dio.dart';

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  AuthState({this.user, this.isLoading = false, this.error});

  AuthState copyWith({UserModel? user, bool? isLoading, String? error}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService apiService;

  AuthNotifier(this.apiService) : super(AuthState());

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await ApiService.login(
        email,
        password,
      );
      state = state.copyWith(user: user, isLoading: false);
    }
    catch (e) {
      String message = "Something went wrong";

      if (e is DioException) {
        if (e.response != null && e.response!.data != null) {
          final data = e.response!.data;
          if (data is Map<String, dynamic> && data['message'] != null) {
            message = data['message'];
          }
        } else if (e.type == DioExceptionType.connectionTimeout) {
          message = "Connection timed out. Please try again.";
        } else if (e.type == DioExceptionType.receiveTimeout) {
          message = "Server not responding. Try again later.";
        }
      }

      state = state.copyWith(isLoading: false, error: message);
    }
  }

  Future<void> register(Map<String, dynamic> body) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await ApiService.register(body); // returns UserModel
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> logout() async {
    await ApiService.logout();
    state = AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ApiService());
});
