import 'package:flutter/material.dart';
import '../screen/collector_page.dart';
import '../screen/admin_page.dart';
import '../screen/reports_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Scan & Pay',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        backgroundColor: const Color(0xFF00B17C),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),

          // Top row: buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(child: buildPageButton('Collector', 0)),
                const SizedBox(width: 8),
                Expanded(child: buildPageButton('Admin', 1)),
                const SizedBox(width: 8),
                Expanded(child: buildPageButton('Reports', 2)),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Expanded(child: pages[selectedIndex]),
        ],
      ),
    );
  }

  Widget buildPageButton(String title, int index) {
    final bool isSelected = selectedIndex == index;

    return OutlinedButton(
      onPressed: () {
        setState(() {
          selectedIndex = index;
        });
      },
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? const Color(0xFF009966) : const Color(0xFF00B17C),
        side: const BorderSide(color: Color(0xFF00B17C), width: 1),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}
