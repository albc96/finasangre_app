import 'package:flutter/material.dart';

import 'app_colors.dart';

class SidebarItem {
  const SidebarItem(this.label, this.icon, this.onTap);
  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

class SidebarMenu extends StatelessWidget {
  const SidebarMenu({super.key, required this.items, this.onLogout});

  final List<SidebarItem> items;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) => Container(
        width: 232,
        color: AppColors.panel,
        child: SafeArea(
          child: Column(children: [
            const Padding(
              padding: EdgeInsets.all(18),
              child: Row(children: [
                Icon(Icons.workspace_premium, color: AppColors.gold),
                SizedBox(width: 8),
                Text('FINASANGRE',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              ]),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: items
                    .map((item) => ListTile(
                          leading: Icon(item.icon, color: AppColors.cyan),
                          title: Text(item.label),
                          onTap: item.onTap,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ))
                    .toList(),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.red),
              title: const Text('Cerrar sesión'),
              onTap: onLogout,
            ),
          ]),
        ),
      );
}
