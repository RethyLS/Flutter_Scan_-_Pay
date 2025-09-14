import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/store_model.dart';
import '../models/user_model.dart';
import 'package:flutter/foundation.dart';

// ------------------------
// API SERVICE
// ------------------------
class ApiService {
  static const String baseUrl = "http://192.168.1.114:8000/api";
  static const storage = FlutterSecureStorage();

  static final Dio dio =
      Dio(
          BaseOptions(
            baseUrl: baseUrl,
            headers: {'Content-Type': 'application/json'},
          ),
        )
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) async {
              final token = await storage.read(key: "token");
              if (token != null) {
                options.headers['Authorization'] = 'Bearer $token';
              }
              return handler.next(options);
            },
          ),
        );

  // ------------------------
  // AUTH ENDPOINTS
  // ------------------------

  static Future<UserModel> login(String email, String password) async {
    final response = await dio.post(
      '/login',
      data: {'email': email, 'password': password},
    );

    if (response.statusCode == 200) {
      final data = response.data;
      final token = data['token'];
      await storage.write(key: "token", value: token);
      return UserModel.fromJson(data['user']);
    } else {
      throw Exception("Login failed: ${response.statusCode}");
    }
  }

  // Register
  static Future<UserModel> register(Map<String, dynamic> body) async {
    final response = await dio.post('/register', data: body);

    if (response.statusCode == 201) {
      final data = response.data;
      final token = data['token'];
      await storage.write(key: "token", value: token);
      return UserModel.fromJson(data['user']);
    } else {
      throw Exception("Register failed: ${response.statusCode}");
    }
  }

  static Future<dynamic> postRegisterUser(Map<String, dynamic> data) async {
    return await post('/register-user', data);
  }

  static Future<void> logout() async {
    await storage.delete(key: "token");
  }

  static Future<String?> getToken() async {
    return await storage.read(key: "token");
  }

  // ------------------------
  // STORE ENDPOINTS
  // ------------------------

  static Future<List<Store>> fetchStores() async {
    final response = await dio.get('/stores');
    final data = response.data is List
        ? response.data
        : response.data['stores'];
    return data.map<Store>((e) => Store.fromJson(e)).toList();
  }

  static Future<List<Store>> fetchStoresByDate(DateTime date) async {
    final d =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    final response = await dio.get(
      '/stores/by-date',
      queryParameters: {'date': d},
    );
    final data = response.data['stores'];
    return data.map<Store>((j) => Store.fromJson(j)).toList();
  }

  static Future<void> saveNote(int paymentId, String note) async {
    final response = await dio.put(
      '/payments/$paymentId/note',
      data: {'note': note},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to save note');
    }
  }

  // ------------------------
  // GENERIC REQUESTS
  // ------------------------

  static Future<dynamic> get(String endpoint) async {
    final response = await dio.get(endpoint);
    return response.data;
  }

  static Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final response = await dio.post(endpoint, data: body);
    return response.data;
  }

  static Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final response = await dio.put(endpoint, data: body);
    return response.data;
  }

  static Future<void> delete(String endpoint) async {
    final response = await dio.delete(endpoint);
    if (response.statusCode != 200) {
      throw Exception('DELETE $endpoint failed: ${response.statusCode}');
    }
  }

  // ------------------------
  // STORE CRUD
  // ------------------------
  static Future<void> addStore(Store store) async {
    final token = await getToken();
    dio.options.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    debugPrint("Adding store: ${store.toJson()}");
    final response = await dio.post('/stores', data: store.toJson());
    debugPrint("AddStore response: ${response.statusCode} ${response.data}");
  }

  static Future<void> updateStore(int id, Map<String, dynamic> payload) async {
    final token = await getToken();
    dio.options.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    debugPrint("Updating store /stores/$id with: $payload");

    final response = await dio.put('/stores/$id', data: payload);

    debugPrint("UpdateStore response: ${response.statusCode} ${response.data}");
  }

  static Future<void> deleteStore(int id) async {
    final token = await getToken();
    dio.options.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    debugPrint("Deleting store /stores/$id");
    final response = await dio.delete('/stores/$id');
    debugPrint("DeleteStore response: ${response.statusCode} ${response.data}");
  }

  // fetch current user
  static Future<Map<String, dynamic>> fetchCurrentUser() async {
    final token = await getToken();
    if (token != null) {
      dio.options.headers['Authorization'] = 'Bearer $token';
    }

    final response = await dio.get(
      '/me',
    );
    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception("Failed to fetch current user");
    }
  }
}
