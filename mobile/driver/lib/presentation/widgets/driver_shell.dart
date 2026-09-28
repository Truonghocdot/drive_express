import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class DriverStatusPill extends StatelessWidget {
  const DriverStatusPill({
    super.key,
    required this.label,
    required this.online,
  });

  final String label;
  final bool online;

  @override
  Widget build(BuildContext context) {
    final tokens = context.driverTokens;
    final color = online ? tokens.primary : tokens.muted;
    return Semantics(
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.32)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DriverShellAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DriverShellAppBar({
    super.key,
    required this.title,
    required this.online,
    this.onSos,
    this.onProfile,
  });

  final String title;
  final bool online;
  final VoidCallback? onSos;
  final VoidCallback? onProfile;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: 72,
      titleSpacing: 16,
      title: Row(
        children: [
          DriverStatusPill(
            label: online ? 'TRỰC TUYẾN' : 'NGOẠI TUYẾN',
            online: online,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'SOS khẩn cấp',
          onPressed: onSos,
          icon: const Icon(Icons.emergency_outlined),
          color: context.driverTokens.danger,
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Semantics(
            button: true,
            label: 'Mở hồ sơ tài xế',
            child: InkWell(
              onTap: onProfile,
              customBorder: const CircleBorder(),
              child: CircleAvatar(
                radius: 19,
                backgroundColor: context.driverTokens.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                child: const Icon(Icons.person_outline, size: 20),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class DriverMetricTile extends StatelessWidget {
  const DriverMetricTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? context.driverTokens.primary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.driverTokens.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.driverTokens.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: tint, size: 20),
          const SizedBox(height: 12),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class DriverSectionTitle extends StatelessWidget {
  const DriverSectionTitle(this.title, {super.key, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        ?action,
      ],
    );
  }
}
