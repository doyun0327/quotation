import 'dart:async';

import 'package:flutter/material.dart';
import 'package:quotation/screens/archive_screen.dart';
import 'package:quotation/screens/dday_screen.dart';
import 'package:quotation/screens/home_screen.dart';
import 'package:quotation/screens/settings_screen.dart';
import 'package:quotation/widgets/pixel_bottom_nav.dart';
import 'package:quotation/widgets/ios_transparent_guide.dart';

/// Together tab is index 1, the same place as tapping a room name.
final ValueNotifier<int> mainShellTab = ValueNotifier<int>(0);

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    _navIndex = mainShellTab.value;
    mainShellTab.addListener(_onTabRequest);
    if (_navIndex == _togetherTab) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onTogetherOpened());
    }
  }

  static const _togetherTab = 1;

  /// iPhone: first visit to 같이 explains the transparent widget photo.
  void _onTogetherOpened() {
    if (!mounted) return;
    unawaited(IosTransparentGuide.maybeShowIntro(context));
  }

  @override
  void dispose() {
    mainShellTab.removeListener(_onTabRequest);
    super.dispose();
  }

  void _onTabRequest() {
    if (!mounted || _navIndex == mainShellTab.value) return;
    setState(() => _navIndex = mainShellTab.value);
    if (_navIndex == _togetherTab) _onTogetherOpened();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _navIndex,
        children: [
          const HomeScreen(),
          const DdayScreen(),
          const ArchiveScreen(),
          SettingsScreen(
            onBack: () => setState(() => _navIndex = 0),
          ),
        ],
      ),
      bottomNavigationBar: PixelBottomNav(
        currentIndex: _navIndex,
        onTap: (index) {
          // mainShellTab's listener switches the tab (and shows the iPhone
          // transparent intro on 같이).
          mainShellTab.value = index;
          setState(() => _navIndex = index);
        },
      ),
    );
  }
}
