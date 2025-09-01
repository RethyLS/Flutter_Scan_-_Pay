import 'package:flutter/material.dart';
import '../screen/collector_page.dart';
import '../screen/admin_page.dart';
import '../screen/reports_page.dart';

void main() {
  runApp(const MyApp());
}

const Color appBackgroundColor = Colors.white;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(scaffoldBackgroundColor: appBackgroundColor),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;

  final List<Widget> pages = const [
    CollectorPage(),
    AdminPage(),
    ReportsPage(),
    Placeholder(),
  ];

  final List<IconData> icons = const [
    Icons.qr_code_scanner, // Collector
    Icons.admin_panel_settings, // Admin
    Icons.bar_chart, // Reports
    Icons.settings, // Settings
  ];

  final List<String> titles = const [
    "Collector",
    "Admin",
    "Reports",
    "Settings",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: appBackgroundColor),
      body: Column(
        children: [
          Expanded(child: pages[selectedIndex]),

          // Custom bottom nav
          Container(
            color: appBackgroundColor,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(icons.length, (index) {
                final bool isSelected = selectedIndex == index;
                return GestureDetector(
                  onTap: () {
                    setState(() => selectedIndex = index);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Color(0xFF295D6B) // stays darker when selected
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          icons[index],
                          color: isSelected
                              ? Colors
                                    .white // brighter white when selected
                              : Color(0xFF295D6B), // dimmer when not selected
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: isSelected
                              ? Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: Text(
                                    titles[index],
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
    );
  }
}
