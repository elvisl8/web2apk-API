import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'apk/app_options.dart';

/// SharedPreferences key for the language preference ('zh' or 'en').
const String languagePrefKey = 'language';

/// The two languages the UI supports.
enum AppLanguage {
  zh,
  en;

  static AppLanguage fromCode(String? code) => code == 'zh' ? zh : en;

  /// Chinese system locale maps to Chinese, everything else to English.
  static AppLanguage fromLocale(Locale locale) =>
      locale.languageCode == 'zh' ? zh : en;
}

/// Holds the current language above the pages and persists the choice.
///
/// Wrap the app's home widget with [L10n]; pages read their strings with
/// [L10n.of] (inside build methods) or [L10n.read] (inside event handlers).
/// When no [L10n] is above the widget — e.g. in widget tests that pump a
/// page directly — the system locale decides the language instead.
class L10n extends StatefulWidget {
  const L10n({super.key, required this.prefs, required this.child});

  final SharedPreferences prefs;
  final Widget child;

  @override
  State<L10n> createState() => _L10nState();

  /// Strings for the current language; registers a dependency so the caller
  /// rebuilds when the language changes. Only call from build methods.
  static AppStrings of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_L10nScope>();
    final language =
        scope?.language ?? _systemLanguage;
    return AppStrings(language);
  }

  /// Strings for the current language without registering a dependency.
  /// Use from event handlers, where [of] is not allowed.
  static AppStrings read(BuildContext context) {
    final element = context.getElementForInheritedWidgetOfExactType<_L10nScope>();
    final scope = element?.widget as _L10nScope?;
    final language = scope?.language ?? _systemLanguage;
    return AppStrings(language);
  }

  static AppLanguage get _systemLanguage => AppLanguage.fromLocale(
    WidgetsBinding.instance.platformDispatcher.locale,
  );

  /// Switches to the other language, persists it and rebuilds the UI.
  /// Does nothing when there is no [L10n] above [context].
  static Future<void> toggleLanguage(BuildContext context) async {
    final state = context.findAncestorStateOfType<_L10nState>();
    if (state != null) await state.toggleLanguage();
  }
}

class _L10nState extends State<L10n> {
  late AppLanguage _language;

  @override
  void initState() {
    super.initState();
    final saved = widget.prefs.getString(languagePrefKey);
    _language = saved == null
        ? AppLanguage.fromLocale(
            WidgetsBinding.instance.platformDispatcher.locale,
          )
        : AppLanguage.fromCode(saved);
  }

  Future<void> toggleLanguage() async {
    final next = _language == AppLanguage.zh
        ? AppLanguage.en
        : AppLanguage.zh;
    setState(() => _language = next);
    await widget.prefs.setString(languagePrefKey, next.name);
  }

  @override
  Widget build(BuildContext context) =>
      _L10nScope(language: _language, child: widget.child);
}

class _L10nScope extends InheritedWidget {
  const _L10nScope({required this.language, required super.child});

  final AppLanguage language;

  @override
  bool updateShouldNotify(_L10nScope old) => language != old.language;
}

/// All user-visible strings, keyed the same in both languages.
class AppStrings {
  AppStrings(this.language);

  final AppLanguage language;

  bool get isChinese => language == AppLanguage.zh;

  /// Looks up [key], replacing `{name}` placeholders with [args].
  /// Falls back to the English text when a translation is missing.
  String t(String key, [Map<String, String> args = const {}]) {
    var text = _strings[language]?[key] ?? _strings[AppLanguage.en]![key] ?? key;
    args.forEach((name, value) {
      text = text.replaceAll('{$name}', value);
    });
    return text;
  }

  /// Localised label of a screen-orientation choice.
  String orientationLabel(AppOrientation value) => switch (value) {
    AppOrientation.auto => t('orientationAuto'),
    AppOrientation.portrait => t('orientationPortrait'),
    AppOrientation.landscape => t('orientationLandscape'),
  };

  /// Localised label of a dark-mode choice.
  String darkModeLabel(AppDarkMode value) => switch (value) {
    AppDarkMode.off => t('darkModeOff'),
    AppDarkMode.system => t('darkModeSystem'),
    AppDarkMode.always => t('darkModeAlways'),
  };

  /// Translates a URL error thrown by `normalizeUrl` (see app_spec.dart).
  /// Unknown messages are returned unchanged.
  String urlError(String message) {
    if (message == 'URL is empty') return t('urlEmpty');
    if (message == 'Invalid URL') return t('urlInvalid');
    if (message == 'URL has no host') return t('urlNoHost');
    const prefix = 'Unsupported URL scheme: ';
    if (message.startsWith(prefix)) {
      return t('urlUnsupportedScheme', {'scheme': message.substring(prefix.length)});
    }
    return message;
  }

  /// Translates an icon error thrown by `loadIcon` (see icon_loader.dart).
  /// Unknown messages are returned unchanged.
  String imageError(String message) =>
      message == 'Not a supported image' ? t('imageNotSupported') : message;

  static const Map<AppLanguage, Map<String, String>> _strings = {
    AppLanguage.en: {
      'webKeyNotice':
          'Your signing key is stored in this browser. Clearing site data loses it: '
          'apps you generated can still be installed, but no longer updated in '
          'place. For a key that lasts, install a web2apk build from the Releases '
          'page, or back the key up via Signing key.',
      'savedIcon': 'Saved icon',
      'couldNotOpenImage': 'Could not open the image: {error}',
      'preparing': 'Preparing…',
      'buildingApk': 'Building APK…',
      'couldNotSaveApp': 'The app could not be saved to My apps: {error}',
      'couldNotBuildApk': 'Could not build the APK: {error}',
      'openOnGitHub': 'Open on GitHub',
      'couldNotOpenUrl': 'Could not open {url}',
      'couldNotOpenUrlError': 'Could not open {url}: {error}',
      'newApp': 'New app',
      'myApps': 'My apps',
      'signingKey': 'Signing key',
      'about': 'About',
      'appName': 'App name',
      'websiteUrl': 'Website URL',
      'color': 'Color',
      'icon': 'Icon',
      'defaultIcon': 'Default icon',
      'fullscreen': 'Fullscreen',
      'hideTitleBar': 'Hide the title bar',
      'packageTapToChange': 'Package: {package} — tap to change',
      'advancedSettings': 'Advanced settings',
      'advancedSettingsSubtitle': 'Orientation, links, dark mode and more',
      'generate': 'Generate',
      'preview': 'Preview',
      'switchLanguage': 'Switch language',
      'urlEmpty': 'URL is empty',
      'urlInvalid': 'Invalid URL',
      'urlUnsupportedScheme': 'Unsupported URL scheme: {scheme}',
      'urlNoHost': 'URL has no host',
      'imageNotSupported': 'Not a supported image',
      'resetToDefaults': 'Reset to defaults',
      'display': 'Display',
      'screenOrientation': 'Screen orientation',
      'darkModeForWebsites': 'Dark mode for websites',
      'android13AndNewer': 'Android 13 and newer',
      'hideSystemBars': 'Hide status and navigation bars',
      'hideSystemBarsSubtitle': 'Swipe from the screen edge to show them',
      'keepScreenOn': 'Keep screen on',
      'keepScreenOnSubtitle': 'For dashboards and kiosks',
      'loadingColor': 'Color while loading',
      'loadingColorSubtitle':
          'Show the app color instead of white until the page appears',
      'browsing': 'Browsing',
      'externalLinks': 'Open other sites in the browser',
      'externalLinksSubtitle':
          'Keep only links to this website in the app. May break '
          'logins that run on another site',
      'progressBar': 'Loading bar',
      'progressBarSubtitle': 'Thin bar at the top while a page loads',
      'offlinePage': 'Offline page',
      'offlinePageSubtitle': 'Show a Retry button when a page cannot be loaded',
      'reloadButton': 'Reload button',
      'reloadNeedsTitleBar': 'Needs the title bar: turn off Fullscreen',
      'reloadInTitleBar': 'In the title bar',
      'pinchZoom': 'Pinch to zoom',
      'pinchZoomSubtitle': 'Websites can still turn this off',
      'identity': 'Identity',
      'desktopMode': 'Desktop mode',
      'desktopModeSubtitle': 'Ask websites for their desktop version',
      'customUserAgent': 'Custom user agent',
      'userAgentHelper': 'Empty uses the default. Overrides Desktop mode',
      'appVersion': 'App version',
      'orientationAuto': 'Automatic',
      'orientationPortrait': 'Portrait',
      'orientationLandscape': 'Landscape',
      'darkModeOff': 'Off',
      'darkModeSystem': 'Follow the system',
      'darkModeAlways': 'Always',
      'backupWarning':
          'Anyone with this file can publish updates to your apps. Keep it private.',
      'restoreWarning':
          'This replaces your current signing key. Apps signed with the current '
          'key can then no longer be updated in place, unless you restore it again.',
      'cancel': 'Cancel',
      'continueAction': 'Continue',
      'replaceKey': 'Replace key',
      'keyBackupSaved': 'Key backup saved',
      'couldNotSaveBackup': 'Could not save the backup',
      'notValidKeyFile': 'Not a valid web2apk key file',
      'signingKeyRestored': 'Signing key restored',
      'couldNotRestoreKey': 'Could not restore the key',
      'couldNotReadKey': 'The signing key could not be read: {error}',
      'keyIntro':
          'Apps you generate are signed with this key. Back it up '
          'to keep updating them in place.',
      'fingerprint': 'Certificate SHA-256 fingerprint',
      'backUpKey': 'Back up key',
      'restoreKey': 'Restore key',
      'ok': 'OK',
      'presets': 'Presets',
      'custom': 'Custom',
      'packageName': 'Package name',
      'ownPackageId': 'This ID belongs to web2apk itself',
      'packageHint': 'Use dot-separated segments like org.example.app',
      'yourWebsite': 'Your website',
      'apkReady': 'Your APK is ready',
      'failed': 'Failed: {error}',
      'install': 'Install',
      'allowInstalls':
          'Allow installs from web2apk in the settings, then tap Install again.',
      'save': 'Save',
      'saved': 'Saved',
      'share': 'Share',
      'savedAppsCouldNotBeRead': 'Saved apps could not be read',
      'deleteApp': 'Delete {name}?',
      'deleteAppNote':
          'It is only removed from this list. The APK you installed is not affected.',
      'delete': 'Delete',
      'noSavedApps': 'No saved apps yet',
    },
    AppLanguage.zh: {
      'webKeyNotice':
          '签名密钥保存在当前浏览器中。清除网站数据会丢失它：已生成的应用仍可安装，但无法再原地更新。'
          '如需长期保存，请从 Releases 页面安装 web2apk 应用，或通过“签名密钥”备份。',
      'savedIcon': '已保存的图标',
      'couldNotOpenImage': '无法打开图片：{error}',
      'preparing': '准备中…',
      'buildingApk': '正在生成 APK…',
      'couldNotSaveApp': '无法保存到“我的应用”：{error}',
      'couldNotBuildApk': '无法生成 APK：{error}',
      'openOnGitHub': '在 GitHub 上打开',
      'couldNotOpenUrl': '无法打开 {url}',
      'couldNotOpenUrlError': '无法打开 {url}：{error}',
      'newApp': '新建应用',
      'myApps': '我的应用',
      'signingKey': '签名密钥',
      'about': '关于',
      'appName': '应用名称',
      'websiteUrl': '网址',
      'color': '颜色',
      'icon': '图标',
      'defaultIcon': '默认图标',
      'fullscreen': '全屏',
      'hideTitleBar': '隐藏标题栏',
      'packageTapToChange': '包名：{package} —— 点按修改',
      'advancedSettings': '高级设置',
      'advancedSettingsSubtitle': '屏幕方向、链接、深色模式等',
      'generate': '生成',
      'preview': '预览',
      'switchLanguage': '切换语言',
      'urlEmpty': '网址为空',
      'urlInvalid': '网址无效',
      'urlUnsupportedScheme': '不支持的网址协议：{scheme}',
      'urlNoHost': '网址没有主机名',
      'imageNotSupported': '不支持的图片格式',
      'resetToDefaults': '恢复默认',
      'display': '显示',
      'screenOrientation': '屏幕方向',
      'darkModeForWebsites': '网站深色模式',
      'android13AndNewer': 'Android 13 及以上',
      'hideSystemBars': '隐藏状态栏和导航栏',
      'hideSystemBarsSubtitle': '从屏幕边缘滑动可重新显示',
      'keepScreenOn': '保持屏幕常亮',
      'keepScreenOnSubtitle': '适用于仪表盘和自助终端',
      'loadingColor': '加载时显示应用颜色',
      'loadingColorSubtitle': '在页面出现前显示应用颜色而非白色',
      'browsing': '浏览',
      'externalLinks': '在浏览器中打开其他网站',
      'externalLinksSubtitle': '仅保留本站链接在应用内打开。可能导致使用其他网站登录的功能失效',
      'progressBar': '加载进度条',
      'progressBarSubtitle': '页面加载时在顶部显示细进度条',
      'offlinePage': '离线页面',
      'offlinePageSubtitle': '页面无法加载时显示“重试”按钮',
      'reloadButton': '刷新按钮',
      'reloadNeedsTitleBar': '需要标题栏：请关闭全屏',
      'reloadInTitleBar': '位于标题栏',
      'pinchZoom': '双指缩放',
      'pinchZoomSubtitle': '网站仍可禁用此功能',
      'identity': '标识',
      'desktopMode': '桌面模式',
      'desktopModeSubtitle': '向网站请求桌面版页面',
      'customUserAgent': '自定义 User Agent',
      'userAgentHelper': '留空使用默认值。会覆盖桌面模式',
      'appVersion': '应用版本',
      'orientationAuto': '自动',
      'orientationPortrait': '竖屏',
      'orientationLandscape': '横屏',
      'darkModeOff': '关闭',
      'darkModeSystem': '跟随系统',
      'darkModeAlways': '始终开启',
      'backupWarning': '持有此文件的人可以发布你应用的更新。请妥善保管。',
      'restoreWarning':
          '这将替换你当前的签名密钥。之后用当前密钥签名的应用将无法再原地更新，除非你重新恢复该密钥。',
      'cancel': '取消',
      'continueAction': '继续',
      'replaceKey': '替换密钥',
      'keyBackupSaved': '密钥备份已保存',
      'couldNotSaveBackup': '无法保存备份',
      'notValidKeyFile': '不是有效的 web2apk 密钥文件',
      'signingKeyRestored': '签名密钥已恢复',
      'couldNotRestoreKey': '无法恢复密钥',
      'couldNotReadKey': '无法读取签名密钥：{error}',
      'keyIntro': '你生成的应用都使用此密钥签名。请备份它，以便日后原地更新应用。',
      'fingerprint': '证书 SHA-256 指纹',
      'backUpKey': '备份密钥',
      'restoreKey': '恢复密钥',
      'ok': '确定',
      'presets': '预设',
      'custom': '自定义',
      'packageName': '包名',
      'ownPackageId': '此 ID 属于 web2apk 自身',
      'packageHint': '使用点号分隔的段，如 org.example.app',
      'yourWebsite': '你的网站',
      'apkReady': '你的 APK 已就绪',
      'failed': '失败：{error}',
      'install': '安装',
      'allowInstalls': '请在设置中允许从 web2apk 安装应用，然后再次点按“安装”。',
      'save': '保存',
      'saved': '已保存',
      'share': '分享',
      'savedAppsCouldNotBeRead': '无法读取已保存的应用',
      'deleteApp': '删除“{name}”？',
      'deleteAppNote': '仅从此列表中移除。已安装的 APK 不受影响。',
      'delete': '删除',
      'noSavedApps': '暂无已保存的应用',
    },
  };
}
