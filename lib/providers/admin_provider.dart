import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/store_model.dart';
import '../services/api_service.dart';
import 'dart:typed_data';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/rendering.dart';

final adminProvider = StateNotifierProvider<AdminNotifier, AdminState>(
  (ref) => AdminNotifier(),
);

class AdminState {
  final List<Store> stores;
  final bool isLoading;
  final int? editingStoreId;
  final Map<String, dynamic>? currentUser;

  AdminState({
    required this.stores,
    required this.isLoading,
    this.editingStoreId,
    this.currentUser,
  });

  AdminState copyWith({
    List<Store>? stores,
    bool? isLoading,
    int? editingStoreId,
    Map<String, dynamic>? currentUser,
  }) {
    return AdminState(
      stores: stores ?? this.stores,
      isLoading: isLoading ?? this.isLoading,
      editingStoreId: editingStoreId ?? this.editingStoreId,
      currentUser: currentUser ?? this.currentUser,
    );
  }
}

class AdminNotifier extends StateNotifier<AdminState> {
  AdminNotifier() : super(AdminState(stores: [], isLoading: true)) {
    init();
  }

  // Form controllers
  final stallIdController = TextEditingController();
  final nameController = TextEditingController();
  final ownerController = TextEditingController();
  final groupController = TextEditingController();
  final defaultAmountController = TextEditingController();

  // QR key
  final GlobalKey qrKey = GlobalKey();

  // Dropdowns
  int? selectedAdminId; // super_admin selects admin
  int? selectedUserId; // admin or super_admin selects user
  List<Map<String, dynamic>> availableUsers = [];
  List<Map<String, dynamic>> availableAdmins = [];
  List<Map<String, dynamic>> usersUnderSelectedAdmin = [];

  List<Map<String, dynamic>> _normalizeUsersResponse(dynamic resp) {
    try {
      if (resp == null) return [];

      if (resp is List) {
        // Flat list
        return List<Map<String, dynamic>>.from(
          resp.map((e) => Map<String, dynamic>.from(e)),
        );
      }

      if (resp is Map) {
        if (resp.containsKey('users')) {
          // Admin or normal user
          final u = resp['users'];
          return List<Map<String, dynamic>>.from(
            (u as List).map((e) => Map<String, dynamic>.from(e)),
          );
        }

        if (resp.containsKey('admins')) {
          // Super admin: return admins + flatten their children
          final a = resp['admins'];
          List<Map<String, dynamic>> result = [];
          for (var admin in a) {
            result.add(Map<String, dynamic>.from(admin)); // add admin itself
            if (admin['children'] != null) {
              for (var child in admin['children']) {
                result.add(Map<String, dynamic>.from(child)); // add child
              }
            }
          }
          return result;
        }

        if (resp.containsKey('data') && resp['data'] is List) {
          // Generic data wrapper
          return List<Map<String, dynamic>>.from(
            (resp['data'] as List).map((e) => Map<String, dynamic>.from(e)),
          );
        }
      }
    } catch (e) {
      debugPrint('normalizeUsersResponse error: $e');
    }
    return [];
  }

  Future<void> init() async {
    try {
      final user = await ApiService.fetchCurrentUser();
      state = state.copyWith(currentUser: user);

      final rawUsers = await ApiService.get('/users');
      final users = _normalizeUsersResponse(rawUsers);

      if (user['role'] == 'admin') {
        // admin sees only their users
        availableUsers = users
            .where((u) => u['parent_id'] == user['id'])
            .toList();
      } else if (user['role'] == 'super_admin') {
        // super admin sees all admins
        availableAdmins = users.where((u) => u['role'] == 'admin').toList();

        // also collect all users under those admins
        final adminIds = availableAdmins.map((a) => a['id']).toSet();
        usersUnderSelectedAdmin = users
            .where((u) => adminIds.contains(u['parent_id']))
            .toList();

        // auto-select first admin if exists
        if (availableAdmins.isNotEmpty) {
          selectedAdminId = availableAdmins.first['id'];

          // filter users under the selected admin
          usersUnderSelectedAdmin = users
              .where((u) => u['parent_id'] == selectedAdminId)
              .toList();
        }
      }

      debugPrint(
        'init: role=${user['role']}, admins=${availableAdmins.length}, '
        'users=${availableUsers.length}, usersUnderSelected=${usersUnderSelectedAdmin.length}',
      );
    } catch (e) {
      debugPrint('init error: $e');
    }

    await loadStores();
  }

  Future<void> refreshUsers() async {
    try {
      final rawUsers = await ApiService.get('/users');
      final users = _normalizeUsersResponse(rawUsers);

      final user = state.currentUser;
      if (user == null) return;

      if (user['role'] == 'admin') {
        // admin → only their direct users
        availableUsers = users
            .where((u) => u['parent_id'] == user['id'])
            .toList();
      } else if (user['role'] == 'super_admin') {
        // super admin → all admins
        availableAdmins = users.where((u) => u['role'] == 'admin').toList();

        // if an admin already selected, fetch its users
        if (selectedAdminId != null) {
          usersUnderSelectedAdmin = users
              .where((u) => u['parent_id'] == selectedAdminId)
              .toList();
        } else {
          // otherwise collect all users under all admins
          final adminIds = availableAdmins.map((a) => a['id']).toSet();
          usersUnderSelectedAdmin = users
              .where((u) => adminIds.contains(u['parent_id']))
              .toList();
        }
      }

      debugPrint(
        'refreshUsers: role=${user['role']}, '
        'admins=${availableAdmins.length}, users=${availableUsers.length}, usersUnderSelected=${usersUnderSelectedAdmin.length}',
      );

      state = state.copyWith();
    } catch (e) {
      debugPrint('refreshUsers error: $e');
    }
  }

  // Fetch stores
  Future<void> loadStores() async {
    state = state.copyWith(isLoading: true);
    try {
      final stores = await ApiService.fetchStores();
      state = state.copyWith(stores: stores);
      debugPrint('loadStores fetched ${stores.length}');
    } catch (e) {
      debugPrint("Error fetching stores: $e");
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  void clearForm() {
    stallIdController.clear();
    nameController.clear();
    ownerController.clear();
    groupController.clear();
    defaultAmountController.clear();
    selectedUserId = null;
    selectedAdminId = null;
    usersUnderSelectedAdmin = [];
    state = state.copyWith(editingStoreId: null);
  }

  void editStore(Store store) {
    stallIdController.text = store.stallId;
    nameController.text = store.name;
    ownerController.text = store.owner;
    groupController.text = store.group ?? '';
    defaultAmountController.text = store.defaultAmount.toString();
    state = state.copyWith(editingStoreId: store.id);
  }

  Future<void> onAdminSelected(int adminId) async {
    selectedAdminId = adminId;
    selectedUserId = null;

    final rawUsers = await ApiService.get('/users');
    final allUsers = _normalizeUsersResponse(rawUsers);

    // Filter only normal users
    final normalUsers = allUsers.where((u) => u['role'] == 'user').toList();

    // Then filter by selected admin
    usersUnderSelectedAdmin = normalUsers
        .where((u) => u['parent_id'] == adminId)
        .toList();

    debugPrint(
      'onAdminSelected adminId=$adminId -> users ${usersUnderSelectedAdmin.length}',
    );

    state = state.copyWith(); // rebuild UI
  }

  void reset() {
    // Clear dropdowns and controllers
    selectedUserId = null;
    selectedAdminId = null;
    availableUsers = [];
    availableAdmins = [];
    usersUnderSelectedAdmin = [];
    stallIdController.clear();
    nameController.clear();
    ownerController.clear();
    groupController.clear();
    defaultAmountController.clear();

    // Reset editingStoreId and state
    state = AdminState(
      stores: [],
      isLoading: true,
      editingStoreId: null,
      currentUser: null,
    );
  }

  // Save or update store
  Future<void> saveStore() async {
    int? userId;

    if (state.currentUser?['role'] == 'user') {
      userId = state.currentUser?['id'];
    } else if (state.currentUser?['role'] == 'admin') {
      if (selectedUserId == null) throw Exception("Select a user");
      userId = selectedUserId;
    } else if (state.currentUser?['role'] == 'super_admin') {
      if (selectedAdminId == null) throw Exception("Select an admin");
      if (selectedUserId == null) throw Exception("Select a user");
      userId = selectedUserId;
    }

    final store = Store(
      stallId: stallIdController.text,
      name: nameController.text,
      owner: ownerController.text,
      group: groupController.text.isEmpty ? null : groupController.text,
      defaultAmount: double.tryParse(defaultAmountController.text) ?? 0,
      status: 'unpaid',
      userId: userId,
    );

    if (state.editingStoreId == null) {
      await ApiService.addStore(store); // addStore still accepts Store
    } else {
      await ApiService.updateStore(
        state.editingStoreId!,
        store.toJson(), // convert Store to Map<String, dynamic>
      );
    }

    clearForm();
    state = state.copyWith(editingStoreId: null); // extra safety
    await loadStores();
  }

  Future<void> deleteStore(int id) async {
    try {
      await ApiService.deleteStore(id);
      await loadStores();
    } catch (e) {
      debugPrint("Error deleting store: $e");
    }
  }

  Future<void> saveQrCode() async {
    var status = await Permission.storage.request();
    if (!status.isGranted) return;

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

      debugPrint('QR saved to ${file.path}');
    } catch (e) {
      debugPrint('Error saving QR: $e');
    }
  }
}
