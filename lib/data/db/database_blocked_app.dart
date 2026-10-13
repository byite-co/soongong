import 'package:flutter/material.dart';

import '../../core/strings/database_strings.dart';
import '../../core/theme/app_presentation.dart';
import '../../core/widgets/app_button.dart';

class DatabaseBlockedApp extends StatefulWidget {
  const DatabaseBlockedApp({super.key, required this.retry});
  final Future<void> Function() retry;
  @override
  State<DatabaseBlockedApp> createState() => _DatabaseBlockedAppState();
}

class _DatabaseBlockedAppState extends State<DatabaseBlockedApp> {
  bool _busy = false;
  Future<void> _retry() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.retry();
    } on Object {
      // Keep non-destructive guidance; never expose storage paths or keys.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => StartupApp(
    home: Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Semantics(
                      header: true,
                      child: Text(DatabaseStrings.title),
                    ),
                    const SizedBox(height: 16),
                    const Text(DatabaseStrings.description),
                    const SizedBox(height: 16),
                    const Text(DatabaseStrings.detail),
                    const SizedBox(height: 24),
                    AppButton(
                      label: DatabaseStrings.retry,
                      busy: _busy,
                      onPressed: _retry,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class DatabasePreparingApp extends StatelessWidget {
  const DatabasePreparingApp({super.key});
  @override
  Widget build(BuildContext context) => StartupApp(
    home: Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Builder(
              builder: (context) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (MediaQuery.disableAnimationsOf(context))
                    const Icon(Icons.hourglass_empty, size: 32)
                  else
                    const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  const Semantics(
                    liveRegion: true,
                    child: Text(DatabaseStrings.preparing),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
