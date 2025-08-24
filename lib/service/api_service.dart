import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/store_model.dart';

class ApiService {
  static const String baseUrl = "http://192.168.1.154:8000/api";

  // ------------------------
  // STORE ENDPOINTS
  // ------------------------

  // Fetch all stores with status and latest payment
  static Future<List<Store>> fetchStores() async {
    final response = await http.get(Uri.parse('$baseUrl/stores'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body)['stores'];
      return data.map((json) => Store.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load stores');
    }
  }
  // For Note
  static Future<List<Store>> fetchStoresByDate(DateTime date) async {
  final d = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  final response = await http.get(Uri.parse('$baseUrl/stores/by-date?date=$d'));

  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body)['stores'];
    return data.map((j) => Store.fromJson(j)).toList();
  } else {
    throw Exception('Failed to load stores by date');
  }
}


  // Add a new store
  static Future<void> addStore(Store store) async {
    final response = await http.post(
      Uri.parse('$baseUrl/stores'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(store.toJson()),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to add store');
    }
  }

  // Update existing store
  static Future<void> updateStore(int id, Store store) async {
    final response = await http.put(
      Uri.parse('$baseUrl/stores/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(store.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update store');
    }
  }

  // Delete store by id
  static Future<void> deleteStore(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/stores/$id'));

    if (response.statusCode != 200) {
      throw Exception('Failed to delete store');
    }
  }

  // Save note
  static Future<void> saveNote(int paymentId, String note) async {
    final response = await http.put(
      Uri.parse('$baseUrl/payments/$paymentId/note'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'note': note}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to save note');
    }
  }

  // ------------------------
  // REPORT ENDPOINTS
  // ------------------------

  // Fetch reports for a date range
  static Future<List<Map<String, dynamic>>> fetchReports(
    DateTime from,
    DateTime to,
  ) async {
    final fromStr = from.toIso8601String();
    final toStr = to.toIso8601String();

    final response = await http.get(
      Uri.parse('$baseUrl/reports?from=$fromStr&to=$toStr'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Failed to fetch reports');
    }
  }

  // Export CSV for a date range
  static Future<void> exportReportsCSV(DateTime from, DateTime to) async {
    final fromStr = from.toIso8601String();
    final toStr = to.toIso8601String();

    final response = await http.get(
      Uri.parse('$baseUrl/reports/export?from=$fromStr&to=$toStr'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to export CSV');
    }
  }
}
