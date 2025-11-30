import 'package:flutter/material.dart';

class ShortcutHint extends StatelessWidget {
  final String action;
  final String shortcut;

  const ShortcutHint({
    super.key,
    required this.action,
    required this.shortcut,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            action,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              shortcut,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

