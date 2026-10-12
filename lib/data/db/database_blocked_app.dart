import 'package:flutter/material.dart';
import '../../core/strings/database_strings.dart';

class DatabaseBlockedApp extends StatefulWidget {
  const DatabaseBlockedApp({super.key, required this.retry});
  final Future<void> Function() retry;
  @override
  State<DatabaseBlockedApp> createState() => _DatabaseBlockedAppState();
}

class _DatabaseBlockedAppState extends State<DatabaseBlockedApp> {
  bool _busy = false;
  @override
  Widget build(BuildContext context) => MaterialApp(home: Scaffold(body: SafeArea(
    child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text(DatabaseStrings.title), const SizedBox(height: 16),
      const Text(DatabaseStrings.description), const SizedBox(height: 16),
      const Text(DatabaseStrings.detail), const SizedBox(height: 24),
      FilledButton(onPressed: _busy ? null : () async {
        setState(() { _busy = true; });
        try { await widget.retry(); } finally { if (mounted) setState(() { _busy = false; }); }
      }, child: const Text(DatabaseStrings.retry)),
    ])),
  )));
}
