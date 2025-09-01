import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../model/store_model.dart';
import '../service/api_service.dart';
import 'dart:typed_data';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/rendering.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _formKey = GlobalKey<FormState>();
  final stallIdController = TextEditingController();
  final nameController = TextEditingController();
  final ownerController = TextEditingController();
  final groupController = TextEditingController();
  final defaultAmountController = TextEditingController();
  final GlobalKey qrKey = GlobalKey();

  List<Store> stores = [];
  bool isLoading = true;
  int? editingStoreId;

  @override
  void initState() {
    super.initState();
    _loadStores();
  }

  Future<void> _loadStores() async {
    setState(() => isLoading = true);
    try {
      stores = await ApiService.fetchStores();
    } catch (e) {
      debugPrint("Error fetching stores: $e");
    }
    setState(() => isLoading = false);
  }

  Future<void> _saveStore() async {
    if (!_formKey.currentState!.validate()) return;

    final store = Store(
      stallId: stallIdController.text,
      name: nameController.text,
      owner: ownerController.text,
      group: groupController.text.isEmpty ? null : groupController.text,
      defaultAmount: double.tryParse(defaultAmountController.text) ?? 0,
      status: 'unpaid',
    );

    try {
      if (editingStoreId == null) {
        await ApiService.addStore(store);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Store Added")));
      } else {
        await ApiService.updateStore(editingStoreId!, store);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Store Updated")));
      }
      _clearForm();
      _loadStores();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _deleteStore(int id) async {
    try {
      await ApiService.deleteStore(id);
      _loadStores();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Store Deleted")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _editStore(Store store) {
    stallIdController.text = store.stallId;
    nameController.text = store.name;
    ownerController.text = store.owner;
    groupController.text = store.group ?? '';
    defaultAmountController.text = store.defaultAmount.toString();
    editingStoreId = store.id;
    _showStoreForm();
  }

  void _clearForm() {
    stallIdController.clear();
    nameController.clear();
    ownerController.clear();
    groupController.clear();
    defaultAmountController.clear();
    setState(() => editingStoreId = null);
  }

  Future<void> _saveQrCode() async {
    var status = await Permission.storage.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Storage permission denied")),
      );
      return;
    }

    try {
      RenderRepaintBoundary boundary =
          qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final downloads = Directory('/storage/emulated/0/Download/MyQRCodes');
      if (!downloads.existsSync()) downloads.createSync(recursive: true);

      final file = File(
        '${downloads.path}/qr_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(pngBytes);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("QR saved to ${file.path}")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _showStoreForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final isUpdate = editingStoreId != null;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isUpdate ? "Edit Store" : "Add Store",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _clearForm();
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: stallIdController,
                        decoration: const InputDecoration(
                          labelText: 'Stall ID',
                        ),
                        validator: (val) =>
                            val!.isEmpty ? 'Enter Stall ID' : null,
                      ),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Name'),
                        validator: (val) => val!.isEmpty ? 'Enter Name' : null,
                      ),
                      TextFormField(
                        controller: ownerController,
                        decoration: const InputDecoration(labelText: 'Owner'),
                        validator: (val) => val!.isEmpty ? 'Enter Owner' : null,
                      ),
                      TextFormField(
                        controller: groupController,
                        decoration: const InputDecoration(labelText: 'Group'),
                      ),
                      TextFormField(
                        controller: defaultAmountController,
                        decoration: const InputDecoration(
                          labelText: 'Default Amount',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          _saveStore();
                          Navigator.pop(context);
                        },
                        child: Text(isUpdate ? "Update" : "Add"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _clearForm();
          _showStoreForm();
        },
        child: const Icon(Icons.add),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Stores",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Total: ${stores.length}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Store rows
                stores.isEmpty
                    ? const Text("No store yet")
                    : SizedBox(
                        height: 500,
                        child: ListView.builder(
                          itemCount: stores.length,
                          itemBuilder: (context, index) {
                            final store = stores[index];
                            return Card(
                              child: ListTile(
                                title: Text(store.name),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(store.owner),
                                    Text("Group: ${store.group ?? '-'}"),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.qr_code),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: Text('QR for ${store.name}'),
                                            content: SizedBox(
                                              width: 220,
                                              height: 220,
                                              child: RepaintBoundary(
                                                key: qrKey,
                                                child: QrImageView(
                                                  data:
                                                      'http://192.168.18.45:8000/pay?store_id=${store.id}&amount=${store.defaultAmount}',
                                                  version: QrVersions.auto,
                                                  size: 200,
                                                ),
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: const Text('Close'),
                                              ),
                                              TextButton(
                                                onPressed: _saveQrCode,
                                                child: const Text('Save'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                    // Edit button
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      ),
                                      onPressed: () => _editStore(store),
                                    ),
                                    // Delete button
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _deleteStore(store.id!),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
