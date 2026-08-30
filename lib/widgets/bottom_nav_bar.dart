import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.memory_outlined),
          selectedIcon: Icon(Icons.memory),
          label: 'System',
        ),
        NavigationDestination(
          icon: Icon(Icons.note_outlined),
          selectedIcon: Icon(Icons.note),
          label: 'Notes',
        ),
        NavigationDestination(
          icon: Icon(Icons.info_outline),
          selectedIcon: Icon(Icons.info),
          label: 'App',
        ),
      ],
    );
  }
}
