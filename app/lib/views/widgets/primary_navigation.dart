import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../utils/app_palette.dart';
import '../../variables.dart';

class PrimaryNavigation extends StatelessWidget {
  const PrimaryNavigation({
    super.key,
    required this.palette,
    required this.activeIndex,
    this.isHorizontal = false,
    this.onChatPressed,
    this.onMailsPressed,
    this.onSettingsPressed,
  });

  final AppPalette palette;
  final int activeIndex;
  final bool isHorizontal;
  final VoidCallback? onChatPressed;
  final VoidCallback? onMailsPressed;
  final VoidCallback? onSettingsPressed;

  @override
  Widget build(BuildContext context) {
    final navButtons = <Widget>[
      _NavIcon(
        palette: palette,
        icon: Icons.chat_bubble_outline,
        active: activeIndex == 0,
        onTap: onChatPressed,
      ),
      _NavIcon(
        palette: palette,
        icon: Icons.folder_copy_outlined,
        active: activeIndex == 1,
        onTap: onMailsPressed,
      ),
      _NavIcon(
        palette: palette,
        icon: Icons.settings_outlined,
        active: activeIndex == 2,
        onTap: onSettingsPressed,
      ),
    ];

    final avatar = AnimatedBuilder(
      animation: user,
      builder: (context, _) {
        final avatarImage = resolveAvatarImage(user.avatarPath);
        final initials = user.username.isNotEmpty ? user.username[0].toUpperCase() : 'U';
        final circle = CircleAvatar(
          radius: 22,
          backgroundColor: palette.mutedSurface,
          backgroundImage: avatarImage,
          child: avatarImage == null
              ? Text(
                  initials,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        );

        return Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onSettingsPressed,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: circle,
            ),
          ),
        );
      },
    );

    if (isHorizontal) {
      return Container(
        height: 88,
        decoration: BoxDecoration(
          color: palette.surface,
          border: Border(bottom: BorderSide(color: palette.border)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 24),
            _buildLogo(),
            const SizedBox(width: 24),
            ...navButtons,
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(right: 24),
              child: avatar,
            ),
          ],
        ),
      );
    }

    return Container(
      width: 88,
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(right: BorderSide(color: palette.border)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          _buildLogo(),
          const SizedBox(height: 32),
          ...navButtons,
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: avatar,
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return SizedBox(
      width: 48,
      height: 48,
      child: Image.asset(
        'assets/logo.png',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.palette,
    required this.icon,
    this.active = false,
    this.onTap,
  });

  final AppPalette palette;
  final IconData icon;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = active ? palette.primary : palette.textMuted;
    final background = active ? palette.mutedSurface : Colors.transparent;
    final borderColor = active ? palette.strongBorder : palette.border;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
          ),
          child: Icon(icon, color: foreground),
        ),
      ),
    );
  }
}

ImageProvider? resolveAvatarImage(String? avatarPath) {
  if (avatarPath == null || avatarPath.isEmpty) {
    return null;
  }
  if (avatarPath.startsWith('http')) {
    return NetworkImage(avatarPath);
  }
  if (kIsWeb) {
    return null;
  }
  final file = File(avatarPath);
  if (file.existsSync()) {
    return FileImage(file);
  }
  return null;
}
