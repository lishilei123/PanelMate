import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panelmate/core/panel/models/api_version.dart';
import 'package:panelmate/core/panel/models/server_connection_profile.dart';
import 'package:panelmate/core/panel/runtime/panel_live_overview_data.dart';
import 'package:panelmate/core/panel/runtime/panel_server_runtime_state.dart';
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

  testWidgets('server card hides endpoint and shows compact network traffic', (
    tester,
  ) async {
    const server = PanelServerConnectionProfile(
      name: 'Web Node',
      baseUrl: 'hidden.example.com',
      protocol: 'https',
      port: 9443,
      apiVersion: PanelApiVersion.v2,
      authMode: PanelAuthMode.apiKey,
    );
    final previous = PanelLiveOverviewData.fromMap(
      _livePayload(
        shotTime: '2026-04-06T10:00:00Z',
        netBytesRecv: 2095104,
        netBytesSent: 3144704,
      ),
    );
    final current = PanelLiveOverviewData.fromMap(
      _livePayload(
        shotTime: '2026-04-06T10:00:01Z',
        netBytesRecv: 2097152,
        netBytesSent: 3145728,
      ),
      previous: previous,
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
            resolveRuntime: (_) => PanelServerRuntimeState.connected(current),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Web Node'), findsOneWidget);
    expect(find.textContaining('hidden.example.com'), findsNothing);
    expect(find.text('V2 集群'), findsNothing);
    expect(find.text('API Key'), findsOneWidget);
    expect(find.text('↓ 2.0 KB/s  ↑ 1.0 KB/s'), findsOneWidget);
    expect(find.text('↓ 2.00 MB  ↑ 3.00 MB'), findsOneWidget);
    expect(find.textContaining('实时'), findsNothing);
    expect(find.textContaining('累计'), findsNothing);
    expect(find.textContaining('同步'), findsNothing);
  });

  testWidgets('server card shows offline time only when offline', (
    tester,
  ) async {
    const server = PanelServerConnectionProfile(
      name: 'Offline Node',
      baseUrl: 'offline.example.com',
      protocol: 'https',
      port: 9443,
      apiVersion: PanelApiVersion.v2,
      authMode: PanelAuthMode.apiKey,
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
            resolveRuntime: (_) => PanelServerRuntimeState.failed(
              'offline',
              previousSyncedAt: DateTime.now(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('同步'), findsNothing);
    expect(find.textContaining('离线'), findsWidgets);
  });
}

Map<String, Object> _livePayload({
  required String shotTime,
  required int netBytesRecv,
  required int netBytesSent,
}) {
  return <String, Object>{
    'cpuUsedPercent': 20,
    'memoryUsedPercent': 10,
    'cpuTotal': 4,
    'memoryTotal': 17179869184,
    'memoryUsed': 8589934592,
    'netBytesRecv': netBytesRecv,
    'netBytesSent': netBytesSent,
    'load1': 0.8,
    'load5': 0.6,
    'load15': 0.4,
    'uptime': 86400,
    'timeSinceUptime': '1 day',
    'shotTime': shotTime,
    'diskData': const <Map<String, Object>>[
      {
        'path': '/',
        'usedPercent': 14,
      },
    ],
  };
}
