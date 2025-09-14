import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/store_model.dart';
import '../services/api_service.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';

final collectorProvider = ChangeNotifierProvider<CollectorNotifier>((ref) {
  return CollectorNotifier();
});

class CollectorNotifier extends ChangeNotifier {
  List<Store> stores = [];
  List<Store> filteredStores = [];
  Store? selectedStore;
  bool isLoading = true; // initial full load
  bool isListLoading = false; // for just store list refresh
  bool isExpanded = false;

  DateTime? selectedDate;
  String? selectedGroup;

  CollectorNotifier() {
    selectedDate = DateTime.now();
    loadStores();
  }

  Future<void> refreshStores() async {
    isListLoading = true;
    notifyListeners();

    try {
      if (selectedDate != null) {
        stores = await ApiService.fetchStoresByDate(selectedDate!);
      } else {
        stores = await ApiService.fetchStores();
      }
      filterStores();
    } catch (e) {
      debugPrint("Error loading stores: $e");
    }

    isListLoading = false;
    notifyListeners();
  }

  Future<void> loadStores() async {
    isLoading = true;
    notifyListeners();

    try {
      if (selectedDate != null) {
        stores = await ApiService.fetchStoresByDate(selectedDate!);
      } else {
        stores = await ApiService.fetchStores();
      }
      filterStores();
    } catch (e) {
      debugPrint("Error loading stores: $e");
    }

    isLoading = false;
    notifyListeners();
  }

  void filterStores() {
    filteredStores = stores.where((store) {
      final groupMatch =
          selectedGroup == null ||
          selectedGroup == "All" ||
          store.group == selectedGroup;
      return groupMatch;
    }).toList();

    if (selectedStore != null && !filteredStores.contains(selectedStore)) {
      selectedStore = null;
    }
    notifyListeners();
  }

  String getStatusForSelectedDate(Store store) {
    if (store.latestPayment == null) return "unpaid";

    final paymentDate = DateTime.parse(store.latestPayment!.createdAt);
    return paymentDate.toLocal().toString().split(' ')[0] ==
            selectedDate!.toLocal().toString().split(' ')[0]
        ? "paid"
        : "unpaid";
  }

  List<String> getGroups() {
    final groups = stores
        .map((s) => s.group ?? "")
        .where((g) => g.isNotEmpty)
        .toSet()
        .toList();
    groups.sort();
    groups.insert(0, "All");
    return groups;
  }

  void toggleExpanded() {
    isExpanded = !isExpanded;
    notifyListeners();
  }

  void setSelectedDate(DateTime date) {
    selectedDate = date;
    refreshStores(); // only refresh store list
  }

  void setSelectedGroup(String? group) {
    selectedGroup = group;
    filterStores(); // only filter
  }

  void setSelectedStore(Store? store) {
    selectedStore = store;
    notifyListeners();
  }

  Future<void> exportCSV(BuildContext context) async {
    List<List<String>> rows = [];
    rows.add(['Collector CSV']);
    rows.add([]);
    rows.add(['Name', 'Owner', 'Group', 'Amount', 'Status', 'Date']);

    for (var store in filteredStores) {
      rows.add([
        store.name,
        store.owner,
        store.group ?? '',
        store.defaultAmount.toString(),
        getStatusForSelectedDate(store),
        selectedDate != null ? "${selectedDate!.toLocal()}".split(' ')[0] : '',
      ]);
    }

    rows.add([]);
    rows.add([
      'Total Stores',
      filteredStores.length.toString(),
      '',
      'Total Paid',
      filteredStores
          .where((s) => getStatusForSelectedDate(s) == 'paid')
          .length
          .toString(),
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
