import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../collector_screen/collector_screen.dart';
import '../admin_screen/admin_screen.dart';
import '../reports_screen/reports_screen.dart';
import '../dashboard_screen/dashboard_screen.dart';
import '../../providers/dashboard_provider.dart';

const Color appBackgroundColor = Colors.white;

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  int selectedIndex = 0;
  bool showSettings = false;

  final List<Widget> pages = const [
    CollectorScreen(),
    AdminScreen(),
    ReportsScreen(),
    Placeholder(),
    DashboardScreen(),
  ];

  final List<IconData> icons = const [
    Icons.qr_code_scanner,
    Icons.store,
    Icons.bar_chart,
    Icons.settings,
  ];

  final List<String> titles = const [
    "collector.title",
    "admin.title",
    "reports.title",
    "settings.title",
  ];

  @override
  Widget build(BuildContext context) {
    final bool _isKeyboardVisible =
        MediaQuery.of(context).viewInsets.bottom > 0;
    final screenWidth = MediaQuery.of(context).size.width;
    final popupWidth = screenWidth * 0.60;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: appBackgroundColor,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: GestureDetector(
            onTap: () => setState(() => selectedIndex = 4), // Go to Dashboard
            child: CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF295D6B),
              child: const Icon(Icons.person, color: Colors.white),
            ),
          ),
        ),
        title: Text(
          ref.watch(authProvider).user?.name ?? tr("common.guest"),
          style: const TextStyle(color: Colors.black),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(child: pages[selectedIndex]),
              if (!_isKeyboardVisible)
                Container(
                  color: appBackgroundColor,
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(icons.length, (index) {
                      final bool isSelected = showSettings
                          ? index == 3
                          : selectedIndex == index;
                      return GestureDetector(
                        onTap: () {
                          if (index == 3) {
                            setState(() => showSettings = !showSettings);
                          } else {
                            setState(() {
                              selectedIndex = index;
                              showSettings = false;
                            });
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF295D6B)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                icons[index],
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF295D6B),
                              ),
                              AnimatedSize(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                child: isSelected
                                    ? Padding(
                                        padding: const EdgeInsets.only(left: 6),
                                        child: Text(
                                          tr(titles[index]),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      )
                                    : const SizedBox(),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
          if (showSettings)
            GestureDetector(
              onTap: () => setState(() => showSettings = false),
              child: Container(color: Colors.black.withOpacity(0.1)),
            ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            top: 0,
            bottom: MediaQuery.of(context).size.height * 0.15,
            right: showSettings ? 0 : -popupWidth,
            child: Material(
              color: Colors.white,
              elevation: 8,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
              child: SizedBox(
                width: popupWidth,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFF295D6B),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Icon(Icons.settings, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            tr("settings.title"),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.dashboard,
                        color: Color(0xFF295D6B),
                      ),
                      title: Text(tr("settings.dashboard")),
                      onTap: () {
                        setState(() => selectedIndex = 4);
                        setState(() => showSettings = false);
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.language,
                        color: Color(0xFF295D6B),
                      ),
                      title: Text(tr('settings.language')),
                      trailing: Switch(
                        value: context.locale.languageCode == 'en',
                        activeColor: const Color(0xFF295D6B),
                        onChanged: (value) {
                          context.setLocale(
                            value ? const Locale('en') : const Locale('km'),
                          );
                        },
                      ),
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.logout,
                        color: Color(0xFF295D6B),
                      ),
                      title: Text(tr("settings.logout")),
                      onTap: () async {
                        await ref.read(authProvider.notifier).logout();
                        ref.read(adminProvider.notifier).reset();
                        if (!mounted) return;
                        context.go('/login');
                        setState(() => showSettings = false);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
