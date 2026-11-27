@TestOn('vm')
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web2apk/src/apk/signing_key.dart';
import 'package:web2apk/src/l10n.dart';
import 'package:web2apk/src/saved_apps.dart';
import 'package:web2apk/src/ui/generator_page.dart';

import 'fakes.dart';

void main() {
  late SigningKey key;
  setUpAll(() => key = SigningKey.generate());

  Future<(SharedPreferences, SavedAppsStore)> pumpPage(
    WidgetTester tester, {
    String? language,
  }) async {
    SharedPreferences.setMockInitialValues(
      language == null ? {} : {languagePrefKey: language},
    );
    final prefs = await SharedPreferences.getInstance();
    final store = SavedAppsStore(prefs);
    await tester.pumpWidget(
      MaterialApp(
        home: L10n(
          prefs: prefs,
          child: GeneratorPage(
            actions: FakeActions(),
            savedApps: store,
            loadKey: () async => key,
            replaceKey: (_) async {},
          ),
        ),
      ),
    );
    return (prefs, store);
  }

  testWidgets('Chinese preference renders Chinese UI', (tester) async {
    await pumpPage(tester, language: 'zh');
    expect(find.text('生成'), findsOneWidget);
    expect(find.text('应用名称'), findsOneWidget);
    expect(find.text('网址'), findsOneWidget);
    expect(find.byTooltip('我的应用'), findsOneWidget);
    expect(find.text('Generate'), findsNothing);
    expect(find.text('EN'), findsOneWidget);
  });

  testWidgets('English preference renders English UI', (tester) async {
    await pumpPage(tester, language: 'en');
    expect(find.text('Generate'), findsOneWidget);
    expect(find.text('App name'), findsOneWidget);
    expect(find.text('中文'), findsOneWidget);
    expect(find.text('生成'), findsNothing);
  });

  testWidgets('language toggle switches and persists the choice',
      (tester) async {
    final (prefs, _) = await pumpPage(tester, language: 'zh');
    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();
    expect(find.text('Generate'), findsOneWidget);
    expect(prefs.getString(languagePrefKey), 'en');

    await tester.tap(find.text('中文'));
    await tester.pumpAndSettle();
    expect(find.text('生成'), findsOneWidget);
    expect(prefs.getString(languagePrefKey), 'zh');
  });

  testWidgets('without a provider the UI falls back to the system locale',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      MaterialApp(
        home: GeneratorPage(
          actions: FakeActions(),
          savedApps: SavedAppsStore(prefs),
          loadKey: () async => key,
          replaceKey: (_) async {},
        ),
      ),
    );
    // The test environment reports an English locale.
    expect(find.text('Generate'), findsOneWidget);
  });
}
