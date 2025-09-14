import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/dashboard_provider.dart';
import '../../../providers/admin_provider.dart';
import 'adduserform.dart';
import '../../models/store_model.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  bool showDropdowns = false;
  bool showKpi = true;

  bool isKpiLoading = false;
  bool isListLoading = false;

  String activeTab = 'Admin';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listen<DashboardState>(dashboardProvider, (prev, next) {
        if (prev?.currentRole != next.currentRole) {
          _reloadData();
        }
      });
      _reloadData();
    });
  }

  Future<void> _reloadData() async {
    // Use the notifier safely after widget is mounted
    final dashboardNotifier = ref.read(dashboardProvider.notifier);

    // Reset dashboard state
    dashboardNotifier.state = DashboardState.initial();

    setState(() {
      isKpiLoading = true;
      isListLoading = true;
    });

    try {
      await dashboardNotifier.fetchCurrentUserData();
      // await dashboardNotifier.fetchStores();
      await dashboardNotifier.fetchKpi();
    } catch (e) {
      // Handle error
      debugPrint("Error reloading dashboard: $e");
    } finally {
      if (mounted) {
        setState(() {
          isKpiLoading = false;
          isListLoading = false;
        });
      }
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: ref.read(dashboardProvider).selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      ref.read(dashboardProvider.notifier).setSelectedDate(picked);
    }
  }

  void _toggleKpi() => setState(() => showKpi = !showKpi);

  @override
  Widget build(BuildContext context) {
    final dashboard = ref.watch(dashboardProvider);
    final tabs = dashboard.visibleTabs;
    if (!tabs.contains(activeTab) && tabs.isNotEmpty) {
      activeTab = tabs.first;
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _buildSearchFilter(dashboard),
              const SizedBox(height: 8),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Column(
                  children: [
                    if (showKpi)
                      isKpiLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _buildSingleKpiCard(dashboard),
                    Center(
                      child: IconButton(
                        onPressed: _toggleKpi,
                        icon: Icon(
                          showKpi
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: tabs.map((tab) {
                  final isActive = tab == activeTab;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isActive
                              ? const Color(0xFF295D6B)
                              : Colors.grey[300],
                        ),
                        onPressed: () {
                          setState(() => activeTab = tab);
                        },
                        child: Text(
                          tab,
                          style: TextStyle(
                            color: isActive ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: isListLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildListCard(activeTab, dashboard),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchFilter(DashboardState dashboard) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Search...",
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.search, size: 20),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _pickDate,
                icon: const Icon(
                  Icons.date_range,
                  size: 24,
                  color: Color(0xFF295D6B),
                ),
              ),
              if (dashboard.currentRole != 'user') ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () =>
                      setState(() => showDropdowns = !showDropdowns),
                  icon: Icon(
                    Icons.filter_alt,
                    size: 24,
                    color: showDropdowns
                        ? Colors.white
                        : const Color(0xFF295D6B),
                  ),
                ),
              ],
              const SizedBox(width: 4),
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.file_download,
                  size: 24,
                  color: Color(0xFF295D6B),
                ),
              ),
            ],
          ),
          if (showDropdowns && dashboard.currentRole != 'user')
            _buildDropdowns(dashboard),
        ],
      ),
    );
  }

  Widget _buildDropdowns(DashboardState dashboard) {
    int? adminValue = dashboard.selectedAdminId;
    if (!dashboard.availableAdmins.any((a) => a['id'] == adminValue))
      adminValue = null;

    int? userValue = dashboard.selectedUserId;
    if (!dashboard.availableUsers.any((u) => u['id'] == userValue))
      userValue = null;

    String zoneValue =
        ["All", "Zone A", "Zone B"].contains(dashboard.selectedZone)
        ? dashboard.selectedZone
        : "All";

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (dashboard.currentRole == 'super_admin')
            Expanded(
              child: DropdownButton<int?>(
                isExpanded: true,
                value: adminValue,
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text("All")),
                  ...dashboard.availableAdmins.map(
                    (a) => DropdownMenuItem<int?>(
                      value: a['id'],
                      child: Text(a['name'] ?? 'Unknown'),
                    ),
                  ),
                ],
                onChanged: (val) {
                  ref.read(dashboardProvider.notifier).changeAdmin(val);
                },
              ),
            ),
          const SizedBox(width: 8),
          if (dashboard.currentRole != 'user')
            Expanded(
              child: DropdownButton<int?>(
                isExpanded: true,
                value: userValue,
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text("All")),
                  ...dashboard.availableUsers.map(
                    (u) => DropdownMenuItem<int?>(
                      value: u['id'],
                      child: Text(u['name'] ?? 'Unknown'),
                    ),
                  ),
                ],
                onChanged: (val) {
                  ref.read(dashboardProvider.notifier).changeUser(val);
                },
              ),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<String>(
              isExpanded: true,
              value: zoneValue,
              onChanged: (value) =>
                  ref.read(dashboardProvider.notifier).changeZone(value),
              items: [
                "All",
                "Zone A",
                "Zone B",
              ].map((z) => DropdownMenuItem(value: z, child: Text(z))).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleKpiCard(DashboardState dashboard) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (dashboard.currentRole == 'super_admin')
                  _KpiRow(
                    title: "Admins",
                    value: "${dashboard.adminCount}",
                    icon: Icons.admin_panel_settings,
                  ),
                const SizedBox(height: 8),
                _KpiRow(
                  title: "Users",
                  value: "${dashboard.userCount}",
                  icon: Icons.people,
                ),
                const SizedBox(height: 8),
                _KpiRow(
                  title: "Stores",
                  value: "${dashboard.storeCount}",
                  icon: Icons.store,
                ),
                const SizedBox(height: 8),
                _KpiRow(
                  title: "Collection (KHR)",
                  value: "${dashboard.collection}",
                  icon: Icons.attach_money,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _KpiRow(
                  title: "Paid",
                  value: "${dashboard.paidCount}",
                  icon: Icons.check_circle,
                ),
                const SizedBox(height: 8),
                _KpiRow(
                  title: "Unpaid",
                  value: "${dashboard.unpaidCount}",
                  icon: Icons.cancel,
                ),
                const SizedBox(height: 8),
                _KpiRow(
                  title: "Absences Yesterday",
                  value: "${dashboard.absencesYesterday}",
                  icon: Icons.event_busy,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListCard(String tab, DashboardState dashboard) {
    List<Map<String, dynamic>> items;
    if (tab == "Admin") {
      items = dashboard.adminList;
    } else if (tab == "User") {
      items = dashboard.userList.where((u) {
        final matchAdmin =
            dashboard.selectedAdminId == null ||
            u['parent_id'] == dashboard.selectedAdminId;
        final matchUser =
            dashboard.selectedUserId == null ||
            u['id'] == dashboard.selectedUserId;
        return matchAdmin && matchUser;
      }).toList();
    } else {
      items = dashboard.storeList.where((s) {
        final matchAdmin =
            dashboard.selectedAdminId == null ||
            s['admin_id'] == dashboard.selectedAdminId;
        final matchUser =
            dashboard.selectedUserId == null ||
            s['user_id'] == dashboard.selectedUserId;
        final matchZone =
            dashboard.selectedZone == "All" ||
            s['zone'] == dashboard.selectedZone;
        return matchAdmin && matchUser && matchZone;
      }).toList();
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          if (tab != "Store")
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "List",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF295D6B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                        ),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) {
                              if (tab == "Admin")
                                return const AddEditUserForm();
                              return const AddEditUserForm(
                                useUserRegister: true,
                              );
                            },
                          );
                        },
                        child: Text(
                          "Add $tab",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _reloadData,
                        icon: const Icon(
                          Icons.refresh,
                          color: Color(0xFF295D6B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Flexible(
            child: items.isEmpty
                ? const Center(child: Text("No items found"))
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: index % 2 == 0
                              ? const Color(0xFFEFEFEF)
                              : const Color(0xFFF6F6F6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        child: ListTile(
                          dense: true,
                          title: Text(item["name"] ?? "Unknown"),
                          subtitle: Text(
                            tab == "Store"
                                ? "Admin ID: ${item['admin_id'] ?? '-'} | User ID: ${item['user_id'] ?? '-'} | Zone: ${item['zone'] ?? 'N/A'}"
                                : item['email'] ?? '',
                          ),
                          trailing: tab != "Store"
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      ),
                                      onPressed: () {},
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () {},
                                    ),
                                  ],
                                )
                              : null,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _KpiRow extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  const _KpiRow({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Tooltip(
          message: title,
          child: Icon(icon, size: 18, color: Colors.black54),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
