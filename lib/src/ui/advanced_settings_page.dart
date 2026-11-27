import 'package:flutter/material.dart';

import '../apk/app_options.dart';
import '../l10n.dart';

/// The rarely needed settings of a generated app. Every change goes straight
/// to [onChanged], so leaving the page needs no confirmation.
class AdvancedSettingsPage extends StatefulWidget {
  const AdvancedSettingsPage({
    super.key,
    required this.initial,
    required this.fullscreen,
    required this.onChanged,
  });

  final AppOptions initial;

  /// Whether the app has no title bar, which the reload button lives in.
  final bool fullscreen;
  final ValueChanged<AppOptions> onChanged;

  @override
  State<AdvancedSettingsPage> createState() => _AdvancedSettingsPageState();
}

class _AdvancedSettingsPageState extends State<AdvancedSettingsPage> {
  late AppOptions _options = widget.initial;
  late final _userAgent = TextEditingController(text: _options.userAgent);
  late final _version = TextEditingController(text: _options.versionName);

  @override
  void dispose() {
    _userAgent.dispose();
    _version.dispose();
    super.dispose();
  }

  void _set(AppOptions options) {
    setState(() => _options = options);
    widget.onChanged(options);
  }

  void _resetAll() {
    _userAgent.clear();
    _version.clear();
    _set(const AppOptions());
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 4),
    child: Text(title, style: Theme.of(context).textTheme.titleSmall),
  );

  Widget _switch(
    String key,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool>? onChanged,
  ) => SwitchListTile(
    key: Key(key),
    contentPadding: EdgeInsets.zero,
    title: Text(title),
    subtitle: Text(subtitle),
    value: value,
    onChanged: onChanged,
  );

  Widget _choice<T extends Enum>(
    String key,
    String title,
    String? subtitle,
    T value,
    Map<T, String> labels,
    ValueChanged<T> onChanged,
  ) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(title),
    subtitle: subtitle == null ? null : Text(subtitle),
    trailing: DropdownButton<T>(
      key: Key(key),
      value: value,
      underline: const SizedBox.shrink(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
      items: [
        for (final e in labels.entries)
          DropdownMenuItem(value: e.key, child: Text(e.value)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final o = _options;
    final strings = L10n.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('advancedSettings')),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: strings.t('resetToDefaults'),
            onPressed: _resetAll,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              _section(strings.t('display')),
              _choice(
                'orientation',
                strings.t('screenOrientation'),
                null,
                o.orientation,
                {for (final v in AppOrientation.values) v: strings.orientationLabel(v)},
                (v) => _set(o.copyWith(orientation: v)),
              ),
              _choice(
                'dark-mode',
                strings.t('darkModeForWebsites'),
                strings.t('android13AndNewer'),
                o.darkMode,
                {for (final v in AppDarkMode.values) v: strings.darkModeLabel(v)},
                (v) => _set(o.copyWith(darkMode: v)),
              ),
              _switch(
                'hide-system-bars',
                strings.t('hideSystemBars'),
                strings.t('hideSystemBarsSubtitle'),
                o.hideSystemBars,
                (v) => _set(o.copyWith(hideSystemBars: v)),
              ),
              _switch(
                'keep-screen-on',
                strings.t('keepScreenOn'),
                strings.t('keepScreenOnSubtitle'),
                o.keepScreenOn,
                (v) => _set(o.copyWith(keepScreenOn: v)),
              ),
              _switch(
                'loading-color',
                strings.t('loadingColor'),
                strings.t('loadingColorSubtitle'),
                o.loadingColor,
                (v) => _set(o.copyWith(loadingColor: v)),
              ),
              _section(strings.t('browsing')),
              _switch(
                'external-links',
                strings.t('externalLinks'),
                strings.t('externalLinksSubtitle'),
                o.externalLinks,
                (v) => _set(o.copyWith(externalLinks: v)),
              ),
              _switch(
                'progress-bar',
                strings.t('progressBar'),
                strings.t('progressBarSubtitle'),
                o.progressBar,
                (v) => _set(o.copyWith(progressBar: v)),
              ),
              _switch(
                'offline-page',
                strings.t('offlinePage'),
                strings.t('offlinePageSubtitle'),
                o.offlinePage,
                (v) => _set(o.copyWith(offlinePage: v)),
              ),
              _switch(
                'reload-button',
                strings.t('reloadButton'),
                widget.fullscreen
                    ? strings.t('reloadNeedsTitleBar')
                    : strings.t('reloadInTitleBar'),
                o.reloadButton && !widget.fullscreen,
                widget.fullscreen
                    ? null
                    : (v) => _set(o.copyWith(reloadButton: v)),
              ),
              _switch(
                'pinch-zoom',
                strings.t('pinchZoom'),
                strings.t('pinchZoomSubtitle'),
                o.pinchZoom,
                (v) => _set(o.copyWith(pinchZoom: v)),
              ),
              _section(strings.t('identity')),
              _switch(
                'desktop-mode',
                strings.t('desktopMode'),
                strings.t('desktopModeSubtitle'),
                o.desktopMode,
                (v) => _set(o.copyWith(desktopMode: v)),
              ),
              TextField(
                key: const Key('user-agent'),
                controller: _userAgent,
                onChanged: (v) => _set(o.copyWith(userAgent: v)),
                decoration: InputDecoration(
                  labelText: strings.t('customUserAgent'),
                  helperText: strings.t('userAgentHelper'),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('version-name'),
                controller: _version,
                maxLength: 50,
                onChanged: (v) => _set(o.copyWith(versionName: v)),
                decoration: InputDecoration(
                  labelText: strings.t('appVersion'),
                  hintText: '1.0',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
