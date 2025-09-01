import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../service/api_service.dart';
import '../model/store_model.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  List<Store> stores = [];
  List<Store> filteredStores = [];
  bool isLoading = true;
  DateTime selectedDate = DateTime.now();
  String selectedGroup = "All";
  int currentPage = 0;
  final int rowsPerPage = 6;

  @override
  void initState() {
    super.initState();
    _loadStores();
  }

  Future<void> _loadStores() async {
    setState(() => isLoading = true);
    try {
      stores = await ApiService.fetchStoresByDate(selectedDate);
      _filterStores();
    } catch (e) {
      debugPrint("Error loading stores: $e");
    }
    setState(() => isLoading = false);
  }

  void _filterStores() {
    filteredStores = stores.where((store) {
      final groupMatch = selectedGroup == "All" || store.group == selectedGroup;
      return groupMatch;
    }).toList();

    if (currentPage * rowsPerPage >= filteredStores.length) {
      currentPage = 0;
    }
  }

  String getStatusForSelectedDate(Store store) {
    if (store.latestPayment == null) return "unpaid";
    final paymentDate = DateTime.parse(store.latestPayment!.createdAt);
    return paymentDate.toLocal().toString().split(' ')[0] ==
            selectedDate.toLocal().toString().split(' ')[0]
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
      await _loadStores(); // reload stores for selected date
    }
  }

  Future<void> exportCSV() async {
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

    for (var store in filteredStores) {
      rows.add([
        store.id?.toString() ?? '',
        store.name,
        store.owner,
        store.group ?? '',
        store.defaultAmount.toString(),
        getStatusForSelectedDate(store),
        "${selectedDate.toLocal()}".split(' ')[0],
        store.latestPayment?.transactionId ?? '',
        store.latestPayment?.note ?? '',
      ]);
    }

    rows.add([]);
    rows.add([
      'Total Stores',
      filteredStores.length.toString(),
      '',
      '',
      'Total Paid',
      filteredStores
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

  void _showStoreDetail(Store store) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat("dd-MM-yyyy").format(selectedDate),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "\$${store.defaultAmount} | ${getStatusForSelectedDate(store).toUpperCase()}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: getStatusForSelectedDate(store) == 'paid'
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ],
              ),
              const Divider(),
              _detailRow("Store ID", store.id.toString()),
              _detailRow("Store Name", store.name),
              _detailRow("Owner", store.owner),
              _detailRow("Group", store.group ?? "-"),
              _detailRow("Amount", store.defaultAmount.toString()),
              _detailRow(
                "Transaction ID",
                store.latestPayment?.transactionId ?? "-",
              ),
              _detailRow("Timestamp", store.latestPayment?.createdAt ?? "-"),
              _detailRow("Note", store.latestPayment?.note ?? "-"),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        Text(value, style: const TextStyle(fontSize: 16)),
        const Divider(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    final startIndex = currentPage * rowsPerPage;
    final endIndex = (startIndex + rowsPerPage > filteredStores.length)
        ? filteredStores.length
        : startIndex + rowsPerPage;
    final visibleStores = filteredStores.sublist(startIndex, endIndex);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Reports",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF295D6B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: exportCSV,
                    child: const Text("Export CSV"),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _pickDate,
                    child: Text(
                      "Date: ${DateFormat('dd-MM-yyyy').format(selectedDate)}",
                    ),
                  ),
                  Text(
                    "Paid: ${filteredStores.where((s) => getStatusForSelectedDate(s) == 'paid').length} | Total: ${filteredStores.length}",
                  ),
                ],
              ),
              Row(
                children: [
                  const Text("Group: "),
                  DropdownButton<String>(
                    value: selectedGroup,
                    items: getGroups()
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (val) => setState(() {
                      selectedGroup = val!;
                      _filterStores();
                    }),
                    underline: const SizedBox(),
                  ),
                ],
              ),
              const Divider(),
              Row(
                children: const [
                  Expanded(
                    flex: 1,
                    child: Text(
                      "ID",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(
                      "Store",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      "Group",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      "Status",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const Divider(),
              Column(
                children: visibleStores.map((store) {
                  return InkWell(
                    onTap: () => _showStoreDetail(store),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 1, child: Text(store.id.toString())),
                            Expanded(flex: 4, child: Text(store.name)),
                            Expanded(flex: 2, child: Text(store.group ?? '-')),
                            Expanded(
                              flex: 2,
                              child: Text(
                                getStatusForSelectedDate(store).toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      getStatusForSelectedDate(store) == 'paid'
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Expanded(flex: 1, child: SizedBox()),
                            Expanded(
                              flex: 4,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  "Owner: ${store.owner}",
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                            const Expanded(flex: 2, child: SizedBox()),
                            const Expanded(flex: 2, child: SizedBox()),
                          ],
                        ),
                        const Divider(),
                      ],
                    ),
                  );
                }).toList(),
              ),
              if (filteredStores.length > rowsPerPage)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: currentPage > 0
                          ? () => setState(() => currentPage--)
                          : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Text(
                      "Page ${currentPage + 1} of ${(filteredStores.length / rowsPerPage).ceil()}",
                    ),
                    IconButton(
                      onPressed: endIndex < filteredStores.length
                          ? () => setState(() => currentPage++)
                          : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
