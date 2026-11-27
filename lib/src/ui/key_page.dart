import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../apk/signing_key.dart';
import '../apk_actions.dart';
import '../l10n.dart';
import 'snack.dart';

const keyBackupFileName = 'web2apk-signing-key.json';
const keyBackupFormat = 'web2apk-signing-key-v1';

/// Shows the signing key's fingerprint and lets the user back it up to a file
/// or restore it from one.
class KeyPage extends StatefulWidget {
  const KeyPage({
    super.key,
    required this.loadKey,
    required this.replaceKey,
    required this.actions,
    this.pickFile,
  });

  final Future<SigningKey> Function() loadKey;
  final Future<void> Function(SigningKey) replaceKey;
  final ApkActions actions;

  /// Returns the bytes of the chosen key file, or null if cancelled. Defaults
  /// to a file picker for `.json` files.
  final Future<Uint8List?> Function()? pickFile;

  @override
  State<KeyPage> createState() => _KeyPageState();
}

class _KeyPageState extends State<KeyPage> {
  late Future<SigningKey> _key = widget.loadKey();
  bool _busy = false;

  Future<Uint8List?> _pick() async {
    final custom = widget.pickFile;
    if (custom != null) return custom();
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    return file?.readAsBytes();
  }

  void _snack(String message) {
    if (mounted) showSnack(context, message);
  }

  Future<bool> _confirm(String text, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          content: Text(text),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(L10n.read(ctx).t('cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _guard(Future<void> Function() body, String failure) async {
    setState(() => _busy = true);
    try {
      await body();
    } catch (e) {
      _snack('$failure: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _backup(SigningKey key) async {
    final strings = L10n.read(context);
    if (!await _confirm(
      strings.t('backupWarning'),
      strings.t('continueAction'),
    )) {
      return;
    }
    await _guard(() async {
      final json = jsonEncode({...key.toJson(), 'format': keyBackupFormat});
      final ok = await widget.actions.saveFile(
        Uint8List.fromList(utf8.encode(json)),
        keyBackupFileName,
        mimeType: 'application/json',
      );
      if (ok) _snack(strings.t('keyBackupSaved'));
    }, strings.t('couldNotSaveBackup'));
  }

  /// Parses a backup file; null if it is not a valid web2apk key file.
  SigningKey? _parse(Uint8List bytes) {
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map<String, dynamic> ||
          decoded['format'] != keyBackupFormat) {
        return null;
      }
      return SigningKey.fromJson(decoded);
    } on FormatException {
      return null;
    }
  }

  Future<void> _restore() async {
    final strings = L10n.read(context);
    await _guard(() async {
      final bytes = await _pick();
      if (bytes == null) return;
      final key = _parse(bytes);
      if (key == null) {
        _snack(strings.t('notValidKeyFile'));
        return;
      }
      if (!await _confirm(
        strings.t('restoreWarning'),
        strings.t('replaceKey'),
      )) {
        return;
      }
      await widget.replaceKey(key);
      if (!mounted) return;
      final reloaded = widget.loadKey();
      setState(() {
        _key = reloaded;
      });
      _snack(strings.t('signingKeyRestored'));
    }, strings.t('couldNotRestoreKey'));
  }

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.t('signingKey'))),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: FutureBuilder<SigningKey>(
            future: _key,
            builder: (context, snap) {
              if (snap.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    strings.t('couldNotReadKey', {'error': '${snap.error}'}),
                  ),
                );
              }
              final key = snap.data;
              if (key == null) return const CircularProgressIndicator();
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(strings.t('keyIntro')),
                  const SizedBox(height: 16),
                  Text(
                    strings.t('fingerprint'),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    key.certificateSha256,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    icon: const Icon(Icons.save_alt),
                    label: Text(strings.t('backUpKey')),
                    onPressed: _busy ? null : () => _backup(key),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.upload_file),
                    label: Text(strings.t('restoreKey')),
                    onPressed: _busy ? null : _restore,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
