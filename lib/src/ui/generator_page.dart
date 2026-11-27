import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../apk/app_options.dart';
import '../apk/app_spec.dart';
import '../apk/signing_key.dart';
import '../apk_actions.dart';
import '../apk_build.dart';
import '../icon_loader.dart';
import '../l10n.dart';
import '../saved_apps.dart';
import 'advanced_settings_page.dart';
import 'app_preview.dart';
import 'dialogs.dart';
import 'key_page.dart';
import 'my_apps_page.dart';
import 'result_page.dart';
import 'snack.dart';

const _credit = 'Made by devilAPI with <3';
const _repoUrl = 'https://github.com/devilAPI/web2apk';
const _defaultColor = Color(0xFF2196F3);

/// An image file picked by the user.
typedef PickedImage = ({Uint8List bytes, String name});

Future<Uint8List> _loadTemplate() async =>
    (await rootBundle.load('assets/template.apk')).buffer.asUint8List();

Future<PickedImage?> _pickImageFile() async {
  final file = await FilePicker.pickFile(type: FileType.image);
  if (file == null) return null;
  return (bytes: await file.readAsBytes(), name: file.name);
}

/// App name with characters outside `[A-Za-z0-9 _-]` removed, plus `.apk`.
String apkFileName(String name) {
  final clean = name.replaceAll(RegExp(r'[^A-Za-z0-9 _-]'), '').trim();
  return '${clean.isEmpty ? 'app' : clean}.apk';
}

class GeneratorPage extends StatefulWidget {
  const GeneratorPage({
    super.key,
    required this.actions,
    required this.loadKey,
    required this.replaceKey,
    required this.savedApps,
    this.initial,
    this.loadTemplate = _loadTemplate,
    this.pickIcon = _pickImageFile,
    this.showWebKeyNotice = kIsWeb,
  });

  final ApkActions actions;
  final Future<SigningKey> Function() loadKey;
  final Future<void> Function(SigningKey) replaceKey;
  final SavedAppsStore savedApps;

  /// A remembered app to prefill the form with.
  final SavedApp? initial;
  final Future<Uint8List> Function() loadTemplate;

  /// Lets the user choose an icon image; null if cancelled.
  final Future<PickedImage?> Function() pickIcon;

  /// Whether to warn that the signing key lives in browser storage.
  final bool showWebKeyNotice;

  @override
  State<GeneratorPage> createState() => _GeneratorPageState();
}

class _GeneratorPageState extends State<GeneratorPage> {
  final _name = TextEditingController();
  final _url = TextEditingController();
  Color _color = _defaultColor;
  bool _fullscreen = false;
  AppOptions _options = const AppOptions();

  /// The icon source: a square PNG from [loadIcon], or null for the default.
  Uint8List? _icon;
  String? _iconName;

  /// Whether [_icon] came from a saved app rather than a picked file, so the
  /// subtitle can show a localised "saved icon" label instead of a file name.
  bool _savedIcon = false;
  String? _iconError;
  String? _manualPackage;
  String? _progress;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) _fill(initial);
  }

  /// Fills the form from [app]; its package id is kept even if the URL changes.
  void _fill(SavedApp app) {
    _name.text = app.name;
    _url.text = app.url;
    _color = Color(app.color);
    _fullscreen = app.fullscreen;
    _options = app.options;
    _icon = app.icon;
    _iconName = null;
    _savedIcon = app.icon != null;
    _iconError = null;
    _manualPackage = app.packageId;
  }

  /// Back to an empty form with the package derived from the URL again.
  void _reset() {
    _name.clear();
    _url.clear();
    _color = _defaultColor;
    _fullscreen = false;
    _options = const AppOptions();
    _icon = null;
    _iconName = null;
    _savedIcon = false;
    _iconError = null;
    _manualPackage = null;
  }

  Future<void> _openMyApps() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (ctx) => MyAppsPage(
          store: widget.savedApps,
          onOpen: (app) {
            Navigator.of(ctx).pop();
            setState(() => _fill(app));
          },
        ),
      ),
    );
  }

  Future<void> _openAdvanced() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => AdvancedSettingsPage(
        initial: _options,
        fullscreen: _fullscreen,
        onChanged: (options) => setState(() => _options = options),
      ),
    ),
  );

  Future<void> _openKeyPage() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => KeyPage(
        loadKey: widget.loadKey,
        replaceKey: widget.replaceKey,
        actions: widget.actions,
      ),
    ),
  );

  @override
  void dispose() {
    _name.dispose();
    _url.dispose();
    super.dispose();
  }

  String? get _normalizedUrl {
    try {
      return normalizeUrl(_url.text);
    } on FormatException {
      return null;
    }
  }

  String? get _urlError {
    if (_url.text.trim().isEmpty) return null;
    try {
      normalizeUrl(_url.text);
      return null;
    } on FormatException catch (e) {
      return L10n.read(context).urlError(e.message);
    }
  }

  String? get _packageId {
    if (_manualPackage != null) return _manualPackage;
    final u = _normalizedUrl;
    return u == null ? null : packageIdFromUrl(u);
  }

  bool get _valid =>
      _name.text.trim().isNotEmpty &&
      _normalizedUrl != null &&
      _packageId != null &&
      isValidPackageId(_packageId!);

  Future<void> _pickColor() async {
    final picked = await showDialog<Color>(
      context: context,
      builder: (_) => ColorDialog(initial: _color),
    );
    if (picked != null) setState(() => _color = picked);
  }

  Future<void> _pickIcon() async {
    try {
      final picked = await widget.pickIcon();
      if (picked == null) return;
      final icon = await loadIcon(picked.bytes);
      if (!mounted) return;
      setState(() {
        _icon = icon;
        _iconName = picked.name;
        _savedIcon = false;
        _iconError = null;
      });
    } on FormatException catch (e) {
      if (mounted) {
        setState(() => _iconError = L10n.read(context).imageError(e.message));
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _iconError = L10n.read(
            context,
          ).t('couldNotOpenImage', {'error': '$e'}),
        );
      }
    }
  }

  Future<void> _editPackage() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => PackageDialog(initial: _packageId ?? ''),
    );
    if (result != null) setState(() => _manualPackage = result);
  }

  void _showError(String message) {
    if (mounted) showSnack(context, message);
  }

  Future<void> _generate() async {
    // Taken before any await: BuildContext must not be used across async
    // gaps (use_build_context_synchronously), so all strings below reuse
    // this snapshot. The language button is disabled while generating, so
    // the language cannot change mid-build.
    final strings = L10n.read(context);
    final name = _name.text.trim();
    final spec = AppSpec(
      name: name,
      url: _normalizedUrl!,
      color: _color.toARGB32(),
      fullscreen: _fullscreen,
      packageId: _packageId!,
      icon: _icon,
      options: _options,
    );
    try {
      setState(() => _progress = strings.t('preparing'));
      final key = await widget.loadKey();
      final template = await widget.loadTemplate();
      if (mounted) {
        setState(() => _progress = strings.t('buildingApk'));
      }
      final apk = await buildSignedApk(
        template: template,
        spec: spec,
        key: key,
      );
      try {
        // _icon is already the 192 px square the saved app keeps.
        await widget.savedApps.upsert(SavedApp.fromSpec(spec, icon192: _icon));
      } catch (e) {
        // The APK is built; a failed save must not keep it from the user.
        _showError(
          strings.t('couldNotSaveApp', {'error': '$e'}),
        );
      }
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ResultPage(
            apk: apk,
            fileName: apkFileName(name),
            actions: widget.actions,
          ),
        ),
      );
    } catch (e) {
      _showError(strings.t('couldNotBuildApk', {'error': '$e'}));
    } finally {
      if (mounted) setState(() => _progress = null);
    }
  }

  void _about() {
    final strings = L10n.read(context);
    showAboutDialog(
      context: context,
      applicationName: 'web2apk',
      applicationLegalese: '$_credit\n$_repoUrl',
      children: [
        const SizedBox(height: 16),
        OutlinedButton.icon(
          key: const Key('open-github'),
          icon: const Icon(Icons.open_in_new),
          label: Text(strings.t('openOnGitHub')),
          onPressed: _openRepo,
        ),
      ],
    );
  }

  Future<void> _openRepo() async {
    final strings = L10n.read(context);
    try {
      final ok = await launchUrl(
        Uri.parse(_repoUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!ok) _showError(strings.t('couldNotOpenUrl', {'url': _repoUrl}));
    } catch (e) {
      _showError(
        strings.t('couldNotOpenUrlError', {'url': _repoUrl, 'error': '$e'}),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    final busy = _progress != null;
    final pkg = _packageId;
    return Scaffold(
      appBar: AppBar(
        title: const Text('web2apk'),
        actions: [
          Tooltip(
            message: strings.t('switchLanguage'),
            child: TextButton(
              onPressed: busy
                  ? null
                  : () => L10n.toggleLanguage(context),
              child: Text(strings.isChinese ? 'EN' : '中文'),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: strings.t('newApp'),
            onPressed: busy ? null : () => setState(_reset),
          ),
          IconButton(
            icon: const Icon(Icons.apps),
            tooltip: strings.t('myApps'),
            onPressed: busy ? null : _openMyApps,
          ),
          IconButton(
            icon: const Icon(Icons.key),
            tooltip: strings.t('signingKey'),
            onPressed: busy ? null : _openKeyPage,
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: strings.t('about'),
            onPressed: _about,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 760;
          final preview = AppPreview(
            name: _name.text,
            url: _normalizedUrl,
            color: _color,
            fullscreen: _fullscreen,
            icon: _icon,
            options: _options,
          );
          final form = ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (widget.showWebKeyNotice) ...[
                Card(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(strings.t('webKeyNotice')),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              TextField(
                key: const Key('name-field'),
                controller: _name,
                maxLength: 50,
                enabled: !busy,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(labelText: strings.t('appName')),
              ),
              TextField(
                key: const Key('url-field'),
                controller: _url,
                enabled: !busy,
                keyboardType: TextInputType.url,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: strings.t('websiteUrl'),
                  errorText: _urlError,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(strings.t('color')),
                trailing: CircleAvatar(backgroundColor: _color, radius: 14),
                enabled: !busy,
                onTap: _pickColor,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(strings.t('icon')),
                subtitle: Text(
                  _iconError ??
                      _iconName ??
                      (_savedIcon
                          ? strings.t('savedIcon')
                          : strings.t('defaultIcon')),
                ),
                trailing: _icon == null
                    ? const Icon(Icons.image_outlined)
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.memory(
                          _icon!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                      ),
                enabled: !busy,
                onTap: _pickIcon,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(strings.t('fullscreen')),
                subtitle: Text(strings.t('hideTitleBar')),
                value: _fullscreen,
                onChanged: busy ? null : (v) => setState(() => _fullscreen = v),
              ),
              ListTile(
                key: const Key('package-tile'),
                contentPadding: EdgeInsets.zero,
                title: Text(
                  strings.t('packageTapToChange', {'package': pkg ?? '—'}),
                ),
                enabled: !busy,
                onTap: _editPackage,
              ),
              ListTile(
                key: const Key('advanced-settings'),
                contentPadding: EdgeInsets.zero,
                title: Text(strings.t('advancedSettings')),
                subtitle: Text(strings.t('advancedSettingsSubtitle')),
                trailing: const Icon(Icons.chevron_right),
                enabled: !busy,
                onTap: _openAdvanced,
              ),
              const SizedBox(height: 24),
              FilledButton(
                key: const Key('generate'),
                onPressed: _valid && !busy ? _generate : null,
                child: busy
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 12),
                          Flexible(child: Text(_progress!)),
                        ],
                      )
                    : Text(strings.t('generate')),
              ),
              if (!wide) ...[
                const SizedBox(height: 24),
                Text(
                  strings.t('preview'),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 12),
                preview,
              ],
            ],
          );
          if (!wide) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: form,
              ),
            );
          }
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: form,
                ),
              ),
              const SizedBox(width: 8),
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: preview,
              ),
            ],
          );
        },
      ),
    );
  }
}
