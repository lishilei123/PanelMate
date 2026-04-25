import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panelmate/core/panel/models/api_version.dart';
import 'package:panelmate/core/panel/models/server_connection_profile.dart';
import 'package:panelmate/features/overview/presentation/overview_page.dart';

void main() {
  testWidgets('search matches any server tag instead of only the first one', (
    tester,
  ) async {
    const server = PanelServerConnectionProfile(
      name: 'Tokyo',
      baseUrl: 'panel.example.com',
      protocol: 'https',
      port: 9443,
      apiVersion: PanelApiVersion.v2,
      authMode: PanelAuthMode.apiKey,
      tags: <String>['prod', 'asia'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OverviewPage(
            servers: const <PanelServerConnectionProfile>[server],
            onAddServer: () {},
            onEditServer: (_) async {},
            onOpenServer: (_) {},
            onRemoveServer: (_) async {},
            resolveRuntime: (_) => null,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tokyo'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'asia');
    await tester.pumpAndSettle();

    expect(find.text('Tokyo'), findsOneWidget);
  });
}
