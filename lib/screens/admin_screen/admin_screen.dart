import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/store_model.dart';
import '../../providers/admin_provider.dart';
import 'dart:typed_data';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/rendering.dart';
import 'package:easy_localization/easy_localization.dart';

// Global RouteObserver
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> with RouteAware {
  late AdminNotifier notifier;

  @override
  void initState() {
    super.initState();
    notifier = ref.read(adminProvider.notifier);
    Future.microtask(() async {
      await notifier.loadStores();
      await notifier.refreshUsers(); // ensure users/admins are fetched
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    notifier.loadStores();
    notifier.refreshUsers();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          notifier.clearForm();
          notifier.state = notifier.state.copyWith(editingStoreId: null);
          await notifier.refreshUsers();
          _showStoreForm(context, ref, isUpdate: false);
        },
        child: const Icon(Icons.add),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tr("admin.stores_title"),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        tr(
                          "admin.total",
                          args: [state.stores.length.toString()],
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: state.stores.isEmpty
                        ? Center(child: Text(tr("admin.no_store")))
                        : ListView.builder(
                            itemCount: state.stores.length,
                            itemBuilder: (context, index) {
                              final store = state.stores[index];
                              return Card(
                                child: ListTile(
                                  title: Text(store.name),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(store.owner),
                                      Text(
                                        "${tr("admin.group")}: ${store.group ?? '-'}",
                                      ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.qr_code),
                                        onPressed: () =>
                                            _showQrDialog(context, store),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.blue,
                                        ),
                                        onPressed: () async {
                                          notifier.editStore(store);
                                          await notifier.refreshUsers();
                                          Future.microtask(() {
                                            _showStoreForm(context, ref);
                                          });
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () =>
                                            notifier.deleteStore(store.id!),
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
    );
  }

  // Add and Update store's form
  static void _showStoreForm(
    BuildContext context,
    WidgetRef ref, {
    bool? isUpdate,
  }) {
    final notifier = ref.read(adminProvider.notifier);
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: StatefulBuilder(
          builder: (context, setState) {
            final state = ref.watch(adminProvider);
            final isEditing = isUpdate ?? (state.editingStoreId != null);

            DropdownButtonFormField<int> buildUserDropdown({
              required List<Map<String, dynamic>> list,
              required int? value,
              required void Function(int?)? onChanged,
              required String label,
            }) {
              final items = list.isNotEmpty
                  ? list
                        .map(
                          (u) => DropdownMenuItem<int>(
                            value: u['id'],
                            child: Text(u['name'] ?? '-'),
                          ),
                        )
                        .toList()
                  : [
                      DropdownMenuItem<int>(
                        value: null,
                        child: Text(tr("admin.no_store")),
                      ),
                    ];

              return DropdownButtonFormField<int>(
                value: list.isNotEmpty ? value : null,
                items: items,
                onChanged: list.isNotEmpty ? onChanged : null,
                decoration: InputDecoration(labelText: label),
                validator: (val) => list.isNotEmpty && val == null
                    ? tr("admin.please_choose_user")
                    : null,
              );
            }

            final isAdmin = state.currentUser?['role'] == 'admin';
            final isSuper = state.currentUser?['role'] == 'super_admin';

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing
                            ? tr("admin.edit_store")
                            : tr("admin.add_store"),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          notifier.clearForm();
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                  Form(
                    key: formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: notifier.stallIdController,
                          decoration: InputDecoration(
                            labelText: tr("admin.stall_id"),
                          ),
                          validator: (val) =>
                              val!.isEmpty ? tr("admin.stall_id") : null,
                        ),
                        TextFormField(
                          controller: notifier.nameController,
                          decoration: InputDecoration(
                            labelText: tr("admin.name"),
                          ),
                          validator: (val) =>
                              val!.isEmpty ? tr("admin.name") : null,
                        ),
                        TextFormField(
                          controller: notifier.ownerController,
                          decoration: InputDecoration(
                            labelText: tr("admin.owner"),
                          ),
                          validator: (val) =>
                              val!.isEmpty ? tr("admin.owner") : null,
                        ),
                        TextFormField(
                          controller: notifier.groupController,
                          decoration: InputDecoration(
                            labelText: tr("admin.group"),
                          ),
                        ),
                        TextFormField(
                          controller: notifier.defaultAmountController,
                          decoration: InputDecoration(
                            labelText: tr("admin.default_amount"),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        if (isAdmin)
                          buildUserDropdown(
                            list: notifier.availableUsers,
                            value: notifier.selectedUserId,
                            onChanged: (val) =>
                                setState(() => notifier.selectedUserId = val),
                            label: tr("admin.assign_to_user"),
                          ),
                        if (isSuper) ...[
                          DropdownButtonFormField<int>(
                            value: notifier.selectedAdminId,
                            items: notifier.availableAdmins.isNotEmpty
                                ? notifier.availableAdmins
                                      .map(
                                        (a) => DropdownMenuItem<int>(
                                          value: a['id'],
                                          child: Text(a['name'] ?? '-'),
                                        ),
                                      )
                                      .toList()
                                : [
                                    DropdownMenuItem<int>(
                                      value: null,
                                      child: Text(tr("admin.no_store")),
                                    ),
                                  ],
                            onChanged: notifier.availableAdmins.isNotEmpty
                                ? (val) async {
                                    if (val != null) {
                                      await notifier.onAdminSelected(val);
                                      setState(() {});
                                    }
                                  }
                                : null,
                            decoration: InputDecoration(
                              labelText: tr("admin.select_admin"),
                            ),
                            validator: (val) =>
                                notifier.availableAdmins.isNotEmpty &&
                                    val == null
                                ? tr("admin.please_choose_admin")
                                : null,
                          ),
                          const SizedBox(height: 12),
                          buildUserDropdown(
                            list: notifier.usersUnderSelectedAdmin,
                            value: notifier.selectedUserId,
                            onChanged: (val) =>
                                setState(() => notifier.selectedUserId = val),
                            label: tr("admin.assign_to_user"),
                          ),
                        ],
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              try {
                                await notifier.saveStore();
                                Navigator.pop(context);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      tr("admin.error", args: [e.toString()]),
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          child: Text(
                            isEditing ? tr("admin.update") : tr("admin.add"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  static void _showQrDialog(BuildContext context, Store store) {
    final qrKey = GlobalKey();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr("admin.qr_for", args: [store.name])),
        content: SizedBox(
          width: 220,
          height: 220,
          child: RepaintBoundary(
            key: qrKey,
            child: QrImageView(
              data:
                  'http://192.168.1.114:8000/pay?store_id=${store.id}&amount=${store.defaultAmount}',
              version: QrVersions.auto,
              size: 200,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr("admin.close")),
          ),
          TextButton(
            onPressed: () => _saveQrCode(qrKey, context),
            child: Text(tr("admin.save")),
          ),
        ],
      ),
    );
  }

  static Future<void> _saveQrCode(GlobalKey qrKey, BuildContext context) async {
    var status = await Permission.storage.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr("admin.storage_permission_denied"))),
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr("admin.qr_saved", args: [file.path]))),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr("admin.error", args: [e.toString()]))),
      );
    }
  }
}
