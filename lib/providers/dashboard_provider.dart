import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>(
      (ref) => DashboardNotifier(),
    );

class DashboardState {
  final List<Map<String, dynamic>> adminList;
  final List<Map<String, dynamic>> userList;
  final List<Map<String, dynamic>> storeList;
  final List<Map<String, dynamic>> availableAdmins;
  final List<Map<String, dynamic>> availableUsers;
  final int? selectedAdminId;
  final int? selectedUserId;
  final String selectedZone;
  final DateTime selectedDate;
  final String currentRole;

  final int adminCount;
  final int userCount;
  final int storeCount;
  final int paidCount;
  final int unpaidCount;
  final int absencesYesterday;
  final String collection;

  DashboardState({
    this.adminList = const [],
    this.userList = const [],
    this.storeList = const [],
    this.availableAdmins = const [],
    this.availableUsers = const [],
    this.selectedAdminId,
    this.selectedUserId,
    this.selectedZone = "All",
    this.currentRole = "user",
    DateTime? selectedDate,
    this.adminCount = 0,
    this.userCount = 0,
    this.storeCount = 0,
    this.paidCount = 0,
    this.unpaidCount = 0,
    this.absencesYesterday = 0,
    this.collection = "0",
  }) : selectedDate = selectedDate ?? DateTime.now();

  factory DashboardState.initial() => DashboardState();

  DashboardState copyWith({
    List<Map<String, dynamic>>? adminList,
    List<Map<String, dynamic>>? userList,
    List<Map<String, dynamic>>? storeList,
    List<Map<String, dynamic>>? availableAdmins,
    List<Map<String, dynamic>>? availableUsers,
    int? selectedAdminId,
    int? selectedUserId,
    String? selectedZone,
    DateTime? selectedDate,
    String? currentRole,
    int? adminCount,
    int? userCount,
    int? storeCount,
    int? paidCount,
    int? unpaidCount,
    int? absencesYesterday,
    String? collection,
  }) {
    return DashboardState(
      adminList: adminList ?? this.adminList,
      userList: userList ?? this.userList,
      storeList: storeList ?? this.storeList,
      availableAdmins: availableAdmins ?? this.availableAdmins,
      availableUsers: availableUsers ?? this.availableUsers,
      selectedAdminId: selectedAdminId ?? this.selectedAdminId,
      selectedUserId: selectedUserId ?? this.selectedUserId,
      selectedZone: selectedZone ?? this.selectedZone,
      selectedDate: selectedDate ?? this.selectedDate,
      currentRole: currentRole ?? this.currentRole,
      adminCount: adminCount ?? this.adminCount,
      userCount: userCount ?? this.userCount,
      storeCount: storeCount ?? this.storeCount,
      paidCount: paidCount ?? this.paidCount,
      unpaidCount: unpaidCount ?? this.unpaidCount,
      absencesYesterday: absencesYesterday ?? this.absencesYesterday,
      collection: collection ?? this.collection,
    );
  }

  List<String> get visibleTabs {
    if (currentRole == 'super_admin') return ["Admin", "User", "Store"];
    if (currentRole == 'admin') return ["User", "Store"];
    return ["Store"];
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  DashboardNotifier() : super(DashboardState.initial()) {
    init();
  }

  Future<void> init() async {
    await fetchCurrentUserData();
    // await fetchStores();
    await fetchKpi();
  }

  Future<void> refreshDashboard() async {
    state = state.copyWith(
      selectedAdminId: null,
      selectedUserId: null,
      selectedZone: "All",
    );

    await fetchCurrentUserData();
    // await fetchStores();
    await fetchKpi();
  }

  // Fetch the all users type and store
  Future<void> fetchCurrentUserData() async {
    try {
      final currentUser = await ApiService.fetchCurrentUser();
      final role = currentUser['role'] as String? ?? "user";

      final response = await ApiService.get('/users');
      final rawAdmins = response['admins'] ?? [];

      final adminList = <Map<String, dynamic>>[];
      final userList = <Map<String, dynamic>>[];
      final storeList = <Map<String, dynamic>>[];

      for (var a in rawAdmins) {
        final admin = Map<String, dynamic>.from(a);
        adminList.add(admin);

        final children = a['children'] ?? [];
        for (var c in children) {
          final user = Map<String, dynamic>.from(c);
          userList.add(user);

          final stores = c['stores'] ?? [];
          for (var s in stores) {
            storeList.add({
              ...s,
              'user_id': c['id'],
              'admin_id': a['id'],
              'zone': c['zone'] ?? 'N/A',
            });
          }
        }
      }

      if (role == 'super_admin') {
        state = state.copyWith(
          adminList: adminList,
          userList: userList,
          storeList: storeList,
          availableAdmins: adminList,
          availableUsers: userList,
          currentRole: role,
        );
      } else if (role == 'admin') {
        final myUsers = userList
            .where((u) => u['parent_id'] == currentUser['id'])
            .toList();
        state = state.copyWith(
          adminList: [], // admin tab hidden
          userList: myUsers,
          storeList: storeList,
          availableAdmins: [],
          availableUsers: myUsers,
          currentRole: role,
        );
      } else {
        // user role
        state = state.copyWith(
          adminList: [],
          userList: [],
          storeList: storeList,
          currentRole: role,
        );
      }
    } catch (e) {
      debugPrint("fetchCurrentUserData error: $e");
    }
  }

  Future<void> fetchKpi() async {
    try {
      final filteredUsers = state.availableUsers.where((u) {
        return state.selectedAdminId == null ||
            u['parent_id'] == state.selectedAdminId;
      }).toList();

      final filteredStores = state.storeList.where((s) {
        final adminMatch =
            state.selectedAdminId == null ||
            s['admin_id'] == state.selectedAdminId;
        final userMatch =
            state.selectedUserId == null ||
            s['user_id'] == state.selectedUserId;
        final zoneMatch =
            state.selectedZone == "All" || s['zone'] == state.selectedZone;
        return adminMatch && userMatch && zoneMatch;
      }).toList();

      state = state.copyWith(
        adminCount: state.currentRole == 'super_admin'
            ? state.availableAdmins.length
            : 0, // adminCount visible only to super admin
        userCount: filteredUsers.length,
        storeCount: filteredStores.length,
        paidCount: filteredStores.where((s) => s['status'] == 'paid').length,
        unpaidCount: filteredStores
            .where((s) => s['status'] == 'unpaid')
            .length,
        absencesYesterday: 5,
        collection: "1.2M",
      );
    } catch (e) {
      debugPrint("fetchKpi error: $e");
    }
  }

  void changeAdmin(int? adminId) {
    final filteredUsers = adminId == null
        ? state.availableUsers
        : state.availableUsers.where((u) => u['parent_id'] == adminId).toList();

    state = state.copyWith(
      selectedAdminId: adminId,
      selectedUserId: null,
      userList: filteredUsers,
    );

    fetchKpi();
  }

  void changeUser(int? userId) {
    state = state.copyWith(selectedUserId: userId);
    fetchKpi();
  }

  void changeZone(String? zone) {
    state = state.copyWith(selectedZone: zone ?? "All");
    fetchKpi();
  }

  void setSelectedDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }
}
