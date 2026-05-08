import 'package:flutter/material.dart';

import '../app_background_scaffold.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      AppBackgroundScaffold(scrollContent: false, child: child);
}
