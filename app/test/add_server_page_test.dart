import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panelmate/core/panel/models/api_version.dart';
import 'package:panelmate/core/panel/models/compatibility_flags.dart';
import 'package:panelmate/core/panel/models/server_connection_profile.dart';
import 'package:panelmate/features/servers/presentation/add_server_page.dart';

void main() {
  testWidgets(
      'auto parses full url into host, protocol, port and entrance code',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AddServerPage(),
      ),
    );

    final addressField = find.byKey(const ValueKey('add_server.address'));
    final nameField = find.byKey(const ValueKey('add_server.name'));

    await tester.enterText(
      addressField,
      'http://panel.example.com:9443/entrance-code',
    );
    await tester.pump();

    await tester.tap(nameField);
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextFormField>(addressField).controller!.text,
      'panel.example.com',
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('add_server.port')))
          .controller!
          .text,
      '9443',
    );
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const ValueKey('add_server.entrance_code')),
          )
          .controller!
          .text,
      'entrance-code',
    );
    expect(
      tester
          .widget<DropdownButtonFormField<String>>(
            find.byKey(const ValueKey('add_server.protocol')),
          )
          .initialValue,
      'http',
    );
  });

  testWidgets(
    'edit mode prefills server values and saves without retesting when unchanged',
    (tester) async {
      final server = PanelServerConnectionProfile(
        name: 'Tokyo',
        baseUrl: 'panel.example.com',
        protocol: 'https',
        port: 9443,
        apiVersion: PanelApiVersion.v2,
        authMode: PanelAuthMode.accountPassword,
        username: 'admin',
        password: 'secret',
        entranceCode: 'entrance-code',
        remark: 'primary',
        tags: const ['prod', 'asia'],
        compatibilityFlags: const PanelCompatibilityFlags(
          useCoreAuth: true,
          useColonRouteParams: true,
          useDashboardCurrentGet: true,
          useContainerLogGet: true,
          requireEntranceCodeOnLogin: false,
        ),
      );

      PanelServerConnectionProfile? savedProfile;
      final pageScrollView = find.byType(Scrollable).first;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed: () async {
                      savedProfile = await Navigator.of(context)
                          .push<PanelServerConnectionProfile>(
                        MaterialPageRoute(
                          builder: (_) => AddServerPage(initialServer: server),
                        ),
                      );
                    },
                    child: const Text('open'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('编辑服务器'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(
                find.byKey(const ValueKey('add_server.name')))
            .controller!
            .text,
        'Tokyo',
      );
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('add_server.address')),
            )
            .controller!
            .text,
        'panel.example.com',
      );
      expect(
        tester
            .widget<TextFormField>(
                find.byKey(const ValueKey('add_server.port')))
            .controller!
            .text,
        '9443',
      );
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('add_server.entrance_code')),
            )
            .controller!
            .text,
        'entrance-code',
      );
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('add_server.username')),
            )
            .controller!
            .text,
        'admin',
      );
      expect(
        tester
            .widget<DropdownButtonFormField<String>>(
              find.byKey(const ValueKey('add_server.protocol')),
            )
            .initialValue,
        'https',
      );
      expect(
        tester
            .widget<DropdownButtonFormField<PanelAuthMode>>(
              find.byKey(const ValueKey('add_server.auth_mode')),
            )
            .initialValue,
        PanelAuthMode.accountPassword,
      );

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('add_server.remark')),
        300,
        scrollable: pageScrollView,
      );
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('add_server.remark')),
            )
            .controller!
            .text,
        'primary',
      );
      expect(
        tester
            .widget<TextFormField>(
                find.byKey(const ValueKey('add_server.tags')))
            .controller!
            .text,
        'prod, asia',
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('add_server.submit')),
        300,
        scrollable: pageScrollView,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('add_server.submit')));
      await tester.pumpAndSettle();

      expect(savedProfile, isNotNull);
      expect(savedProfile!.name, 'Tokyo');
      expect(savedProfile!.baseUrl, 'panel.example.com');
      expect(savedProfile!.port, 9443);
      expect(savedProfile!.username, 'admin');
      expect(savedProfile!.remark, 'primary');
      expect(savedProfile!.tags, const ['prod', 'asia']);
      expect(savedProfile!.compatibilityFlags?.requireEntranceCodeOnLogin,
          isFalse);
    },
  );
}
