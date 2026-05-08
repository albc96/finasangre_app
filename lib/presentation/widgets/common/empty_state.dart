import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  const EmptyState(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(message, style: const TextStyle(color: Colors.white70)),
        ),
      );
}
