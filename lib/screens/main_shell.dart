import 'package:flutter/material.dart';
import 'package:quotation/screens/archive_screen.dart';
import 'package:quotation/screens/home_screen.dart';
import 'package:quotation/screens/settings_screen.dart';
import 'package:quotation/widgets/pixel_bottom_nav.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _navIndex,
        children: [
          const HomeScreen(),
          const ArchiveScreen(),
          SettingsScreen(
            onBack: () => setState(() => _navIndex = 0),
          ),
        ],
      ),
      bottomNavigationBar: PixelBottomNav(
        currentIndex: _navIndex,
        onTap: (index) => setState(() => _navIndex = index),
      ),
    );
  }
}
