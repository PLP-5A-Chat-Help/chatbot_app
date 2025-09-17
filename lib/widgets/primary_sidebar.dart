import 'package:flutter/material.dart';

import '../variables.dart';

class PrimarySidebar extends StatelessWidget {
  const PrimarySidebar({
    super.key,
    required this.selectedIndex,
    this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    const icons = <IconData>[
      Icons.chat_bubble_outline,
      Icons.folder_copy_outlined,
      Icons.analytics_outlined,
      Icons.settings_outlined,
    ];

    return Container(
      width: 88,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border(
          right: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Image.asset('assets/logo.png', fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 32),
          for (var index = 0; index < icons.length; index++)
            _SidebarButton(
              icon: icons[index],
              active: index == selectedIndex,
              onTap: () => _handleTap(index),
            ),
          const Spacer(),
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            child: CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFF1F2937),
              child: Text(
                user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleTap(int index) {
    if (index == selectedIndex) {
      return;
    }
    onDestinationSelected?.call(index);
  }
}

class _SidebarButton extends StatelessWidget {
  const _SidebarButton({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: active ? const Color(0xFF1F2937) : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: active
                  ? Colors.white.withOpacity(0.25)
                  : Colors.white.withOpacity(0.06),
            ),
          ),
          child: Icon(
            icon,
            color: active ? Colors.white : Colors.white60,
          ),
        ),
      ),
    );
  }
}
