import 'package:flutter/material.dart';

import '../l10n.dart';
import '../saved_apps.dart';

/// Lists remembered apps; tapping one hands it to [onOpen], the trailing
/// button deletes it after confirmation.
class MyAppsPage extends StatefulWidget {
  const MyAppsPage({super.key, required this.store, required this.onOpen});

  final SavedAppsStore store;
  final void Function(SavedApp) onOpen;

  @override
  State<MyAppsPage> createState() => _MyAppsPageState();
}

class _MyAppsPageState extends State<MyAppsPage> {
  late List<SavedApp> _apps = _load();

  /// Reads the store; a corrupt value shows as an empty list plus a SnackBar.
  List<SavedApp> _load() {
    try {
      return widget.store.load();
    } on FormatException {
      // Context is not usable for a SnackBar until the first frame is built.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              L10n.read(context).t('savedAppsCouldNotBeRead'),
            ),
          ),
        );
      });
      return const [];
    }
  }

  Future<void> _delete(SavedApp app) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          L10n.of(ctx).t('deleteApp', {'name': app.name}),
        ),
        content: Text(L10n.of(ctx).t('deleteAppNote')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(L10n.of(ctx).t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(L10n.of(ctx).t('delete')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.store.remove(app.packageId);
    } on FormatException {
      // Corrupt store: nothing to remove; reload reports it.
    }
    if (mounted) setState(() => _apps = _load());
  }

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.t('myApps'))),
      body: _apps.isEmpty
          ? Center(child: Text(strings.t('noSavedApps')))
          : ListView(
              children: [
                for (final app in _apps)
                  ListTile(
                    key: ValueKey(app.packageId),
                    leading: _leading(app),
                    title: Text(app.name),
                    subtitle: Text(app.packageId),
                    onTap: () => widget.onOpen(app),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: strings.t('delete'),
                      onPressed: () => _delete(app),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _leading(SavedApp app) {
    final icon = app.icon;
    if (icon == null) {
      return CircleAvatar(backgroundColor: Color(app.color), radius: 20);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.memory(icon, width: 40, height: 40, fit: BoxFit.cover),
    );
  }
}
