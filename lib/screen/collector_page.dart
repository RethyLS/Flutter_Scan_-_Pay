import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../model/store_model.dart';
import '../service/api_service.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';

class CollectorPage extends StatefulWidget {
  const CollectorPage({super.key});

  @override
  State<CollectorPage> createState() => _CollectorPageState();
}

class _CollectorPageState extends State<CollectorPage> {
  List<Store> stores = [];
  List<Store> filteredStores = [];
  Store? selectedStore;
  bool isLoading = true;

  DateTime? selectedDate;
  String? selectedGroup;

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now(); // default to today
    _loadStores();
  }

  // Future<void> _loadStores() async {
  //   setState(() => isLoading = true);
  //   try {
  //     stores = await ApiService.fetchStores();
  //     _filterStores();
  //   } catch (e) {
  //     debugPrint("Error loading stores: $e");
  //   }
  //   if (!mounted) return;
  //   setState(() => isLoading = false);
  // }
  Future<void> _loadStores() async {
    setState(() => isLoading = true);
    try {
      if (selectedDate != null) {
        stores = await ApiService.fetchStoresByDate(selectedDate!);
      } else {
        stores = await ApiService.fetchStores(); // fallback
      }
      _filterStores();
    } catch (e) {
      debugPrint("Error loading stores: $e");
    }
    if (!mounted) return;
    setState(() => isLoading = false);
  }

  // Store filter
  void _filterStores() {
    filteredStores = stores.where((store) {
      final groupMatch =
          selectedGroup == null ||
          selectedGroup == "All" ||
          store.group == selectedGroup;

      return groupMatch; // show all stores in the selected group
    }).toList();

    // Reset selected store if it’s not in filtered list
    if (selectedStore != null && !filteredStores.contains(selectedStore)) {
      selectedStore = null;
    }
  }

  
  // Compute status for selected date without overwriting backend status
  // String getStatusForSelectedDate(Store store) {
  //   if (store.latestPayment == null || selectedDate == null) return "unpaid";

  //   final paymentDate = DateTime.parse(store.latestPayment!.createdAt);
  //   return paymentDate.toLocal().toString().split(' ')[0] ==
  //           selectedDate!.toLocal().toString().split(' ')[0]
  //       ? "paid"
  //       : "unpaid";
  // }
  String getStatusForSelectedDate(Store store) {
    // If the API returned a payment for that selected date, it's paid
    return store.latestPayment != null ? "paid" : "unpaid";
  }

  Future<void> exportCSV() async {
    List<List<String>> rows = [];

    // Add a title row
    rows.add(['Store Payment Report']);
    rows.add([]); // empty row for spacing

    // Add headers
    rows.add(['Name', 'Owner', 'Group', 'Amount', 'Status', 'Date']);

    // Add store rows
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

    // Add a summary row
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

    // Determine folder
    Directory directory;
    if (Platform.isAndroid) {
      directory = Directory('/storage/emulated/0/Download/MyCSV');
      if (!await directory.exists()) await directory.create(recursive: true);
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    // Save CSV file
    String path =
        '${directory.path}/stores_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File(path);
    await file.writeAsString(csvData);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('CSV exported to ${directory.path}')),
    );
  }

  List<String> getGroups() {
    final groups = stores
        .map((s) => s.group ?? "")
        .where((g) => g.isNotEmpty)
        .toSet()
        .toList();
    groups.sort();
    groups.insert(0, "All"); // Add "All" option
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Box 1: Scan to Pay
              SizedBox(
                height: 150,
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: Colors.white,
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Row 1
                        Row(
                          children: [
                            Flexible(
                              child: TextField(
                                readOnly: true,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                decoration: InputDecoration(
                                  labelText:
                                      "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}",
                                  labelStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                onTap: () async {
                                  // final picked = await showDatePicker(
                                  //   context: context,
                                  //   initialDate: selectedDate!,
                                  //   firstDate: DateTime(2020),
                                  //   lastDate: DateTime(2100),
                                  // );
                                  //   if (picked != null) {
                                  //     setState(() {
                                  //       selectedDate = picked;
                                  //       _filterStores();
                                  //     });
                                  //   }
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDate!,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2100),
                                  );

                                  if (picked != null) {
                                    setState(() {
                                      selectedDate = picked;
                                    });
                                    await _loadStores(); // reload stores for selected date
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            //group icon
                            DropdownButton<String>(
                              value: selectedGroup,
                              underline: const SizedBox(), // remove underline
                              icon: const Icon(
                                Icons.group,
                                color: Colors.blue,
                                size: 30,
                              ),
                              items: getGroups()
                                  .map(
                                    (g) => DropdownMenuItem(
                                      value: g,
                                      child: Text(
                                        g,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                setState(() {
                                  selectedGroup = val;
                                  _filterStores();
                                });
                              },
                            ),
                          ],
                        ),

                        // Row 2
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<Store>(
                                icon: const SizedBox.shrink(),
                                decoration: const InputDecoration(
                                  labelText: "Select Store",
                                  labelStyle: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                value: selectedStore,
                                items: filteredStores
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(
                                          s.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  setState(() => selectedStore = val);
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.qr_code,
                                color: Colors.blue,
                                size: 30,
                              ),
                              onPressed: () {
                                if (selectedStore != null) {
                                  showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      title: Center(
                                        child: Text(
                                          "QR for ${selectedStore!.name}",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          QrImageView(
                                            data:
                                                'http://192.168.1.154:8000/pay?store_id=${selectedStore!.id}&amount=${selectedStore!.defaultAmount}&date=${selectedDate!.toIso8601String()}',
                                            version: QrVersions.auto,
                                            size: 200,
                                          ),
                                        ],
                                      ),
                                      actionsAlignment:
                                          MainAxisAlignment.center,
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text("Close"),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Box 2: Today's Status
              SizedBox(
                height: 500,
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: Colors.white,
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Today's Status",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Stats Row
                        Row(
                          children: [
                            Expanded(
                              child: Text("Stores: ${filteredStores.length}"),
                            ),
                            Expanded(
                              child: Text(
                                "Paid: ${filteredStores.where((s) => getStatusForSelectedDate(s) == 'paid').length}",
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Store list
                        Expanded(
                          child: ListView.builder(
                            itemCount: selectedStore != null
                                ? 1
                                : filteredStores.length,
                            itemBuilder: (context, index) {
                              final store =
                                  selectedStore ?? filteredStores[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ListTile(
                                  title: Text(store.name),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text("Owner: ${store.owner}"),
                                      Text("Amount: ${store.defaultAmount}\$"),
                                      if (store.latestPayment?.note != null &&
                                          store.latestPayment!.note!.isNotEmpty)
                                        Text(
                                          "Note: ${store.latestPayment!.note!}",
                                        ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      // Status text
                                      Text(
                                        getStatusForSelectedDate(
                                          store,
                                        ).toUpperCase(),
                                        style: TextStyle(
                                          color:
                                              getStatusForSelectedDate(store) ==
                                                  "paid"
                                              ? Colors.green
                                              : Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Note icon
                                      IconButton(
                                        icon: const Icon(
                                          Icons.note_add,
                                          color: Colors.blue,
                                        ),
                                        onPressed: () async {
                                          final controller =
                                              TextEditingController(
                                                text:
                                                    store.latestPayment?.note ??
                                                    "",
                                              );
                                          final result = await showDialog<String>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: Text(
                                                "Add Note for ${store.name}",
                                              ),
                                              content: TextField(
                                                controller: controller,
                                                decoration:
                                                    const InputDecoration(
                                                      hintText: "Enter note",
                                                    ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: const Text("Cancel"),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        controller.text,
                                                      ),
                                                  child: const Text("Save"),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (result != null &&
                                              store.latestPayment != null) {
                                            try {
                                              await ApiService.saveNote(
                                                store.latestPayment!.id,
                                                result,
                                              );
                                              setState(() {
                                                store.latestPayment!.note =
                                                    result; // update UI
                                              });
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    "Note saved successfully",
                                                  ),
                                                ),
                                              );
                                            } catch (e) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    "Failed to save note",
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        // Export Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: exportCSV,
                            child: const Text("Export CSV"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
