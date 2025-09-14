import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/store_model.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';

class ReportsState {
  final List<Store> stores;
  final List<Store> filteredStores;
  final bool isLoading;
  final DateTime selectedDate;
  final String selectedGroup;
  final int currentPage;
  final int rowsPerPage;

  ReportsState({
    required this.stores,
    required this.filteredStores,
    required this.isLoading,
    required this.selectedDate,
    required this.selectedGroup,
    required this.currentPage,
    required this.rowsPerPage,
  });

  factory ReportsState.initial() => ReportsState(
        stores: [],
        filteredStores: [],
        isLoading: true,
        selectedDate: DateTime.now(),
        selectedGroup: "All",
        currentPage: 0,
        rowsPerPage: 6,
      );

  List<Store> get visibleStores {
    final start = currentPage * rowsPerPage;
    final end = (start + rowsPerPage > filteredStores.length)
        ? filteredStores.length
        : start + rowsPerPage;
    return filteredStores.sublist(start, end);
  }

  ReportsState copyWith({
    List<Store>? stores,
    List<Store>? filteredStores,
    bool? isLoading,
    DateTime? selectedDate,
    String? selectedGroup,
    int? currentPage,
    int? rowsPerPage,
  }) {
    return ReportsState(
      stores: stores ?? this.stores,
      filteredStores: filteredStores ?? this.filteredStores,
      isLoading: isLoading ?? this.isLoading,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedGroup: selectedGroup ?? this.selectedGroup,
      currentPage: currentPage ?? this.currentPage,
      rowsPerPage: rowsPerPage ?? this.rowsPerPage,
    );
  }
}

class ReportsNotifier extends StateNotifier<ReportsState> {
  ReportsNotifier() : super(ReportsState.initial());

  /// Load stores from API for the selected date
  Future<void> loadStores() async {
    state = state.copyWith(isLoading: true);
    try {
      final stores = await ApiService.fetchStoresByDate(state.selectedDate);
      state = state.copyWith(stores: stores);
      _filterStores(); // Filter after fetching
    } catch (e) {
      debugPrint("Error loading stores: $e");
      state = state.copyWith(isLoading: false);
    }
  }

  /// Filter stores by selected group
  void _filterStores() {
    final filtered = state.stores.where((store) {
      final groupMatch =
          state.selectedGroup == "All" || store.group == state.selectedGroup;
      return groupMatch;
    }).toList();

    int page = state.currentPage;
    if (page * state.rowsPerPage >= filtered.length) page = 0;

    state = state.copyWith(
      filteredStores: filtered,
      currentPage: page,
      isLoading: false,
    );
  }

  /// Update date and reload stores
  void pickDate(DateTime date) {
    state = state.copyWith(selectedDate: date, isLoading: true);
    loadStores();
  }

  /// Change group filter without reloading
  void changeGroup(String group) {
    state = state.copyWith(selectedGroup: group);
    _filterStores();
  }

  /// Pagination controls
  void nextPage() {
    if ((state.currentPage + 1) * state.rowsPerPage < state.filteredStores.length) {
      state = state.copyWith(currentPage: state.currentPage + 1);
    }
  }

  void prevPage() {
    if (state.currentPage > 0) state = state.copyWith(currentPage: state.currentPage - 1);
  }

  /// Return list of groups for dropdown
  List<String> getGroups() {
    final groups = state.stores.map((s) => s.group ?? "").where((g) => g.isNotEmpty).toSet().toList();
    groups.sort();
    groups.insert(0, "All");
    return groups;
  }

  /// Determine if a store is paid/unpaid for the selected date
  String getStatusForSelectedDate(Store store) {
    if (store.latestPayment == null) return "unpaid";
    final paymentDay = DateFormat('yyyy-MM-dd')
        .format(DateTime.parse(store.latestPayment!.createdAt).toLocal());
    final selectedDay = DateFormat('yyyy-MM-dd').format(state.selectedDate);
    return paymentDay == selectedDay ? "paid" : "unpaid";
  }

  /// Export current filtered stores to CSV
  Future<void> exportCSV(BuildContext context) async {
    List<List<String>> rows = [];

    rows.add(['Reports CSV']);
    rows.add([]);
    rows.add([
      'Store ID',
      'Name',
      'Owner',
      'Group',
      'Amount',
      'Status',
      'Date',
      'Transaction ID',
      'Note',
    ]);

    for (var store in state.filteredStores) {
      rows.add([
        store.id?.toString() ?? '',
        store.name,
        store.owner,
        store.group ?? '',
        store.defaultAmount.toString(),
        getStatusForSelectedDate(store),
        "${state.selectedDate.toLocal()}".split(' ')[0],
        store.latestPayment?.transactionId ?? '',
        store.latestPayment?.note ?? '',
      ]);
    }

    rows.add([]);
    rows.add([
      'Total Stores',
      state.filteredStores.length.toString(),
      '',
      '',
      'Total Paid',
      state.filteredStores
          .where((s) => getStatusForSelectedDate(s) == 'paid')
          .length
          .toString(),
      '',
      '',
      '',
    ]);

    String csvData = const ListToCsvConverter().convert(rows);

    Directory directory;
    if (Platform.isAndroid) {
      directory = Directory('/storage/emulated/0/Download/MyCSV');
      if (!await directory.exists()) await directory.create(recursive: true);
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    String path =
        '${directory.path}/stores_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File(path);
    await file.writeAsString(csvData);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('CSV exported to ${directory.path}')),
    );
  }
}

/// Global provider
final reportsProvider = StateNotifierProvider<ReportsNotifier, ReportsState>((ref) {
  final notifier = ReportsNotifier();
  notifier.loadStores();
  return notifier;
});
