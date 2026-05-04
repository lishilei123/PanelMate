import 'package:flutter_test/flutter_test.dart';
import 'package:panelmate/core/panel/models/api_version.dart';
import 'package:panelmate/core/panel/models/server_connection_profile.dart';
import 'package:panelmate/core/panel/runtime/panel_live_overview_data.dart';
import 'package:panelmate/core/panel/runtime/panel_server_runtime_state.dart';
import 'package:panelmate/shared/demo/panel_demo_catalog.dart';

void main() {
  group('PanelDemoCatalog', () {
    const server = PanelServerConnectionProfile(
      name: 'Oracle',
      baseUrl: 'panel.example.com',
      protocol: 'https',
      port: 443,
      apiVersion: PanelApiVersion.v2,
      authMode: PanelAuthMode.accountPassword,
    );

    test('does not synthesize uptime or sync time after first sync failure',
        () {
      final snapshot = PanelDemoCatalog.snapshotFor(
        server,
        runtime: PanelServerRuntimeState.failed('ErrCaptchaCode'),
      );

      expect(snapshot.isOnline, false);
      expect(snapshot.hasLiveData, false);
      expect(snapshot.uptimeText, '--');
      expect(snapshot.lastSyncedAt, isNull);
      expect(snapshot.networkInText, '--');
    });

    test('keeps stale live data offline after a later sync failure', () {
      final overview = PanelLiveOverviewData.fromMap(
        _livePayload(shotTime: '2026-04-06T10:00:00Z'),
      );
      final snapshot = PanelDemoCatalog.snapshotFor(
        server,
        runtime: PanelServerRuntimeState.failed(
          'offline',
          previousOverview: overview,
          previousSyncedAt: overview.shotTime,
        ),
      );

      expect(snapshot.isOnline, false);
      expect(snapshot.health, PanelServerHealth.offline);
      expect(snapshot.hasLiveData, true);
      expect(snapshot.uptimeText, '12 days');
      expect(snapshot.lastSyncedAt, overview.shotTime);
    });
  });
}

Map<String, Object> _livePayload({
  required String shotTime,
}) {
  return <String, Object>{
    'cpuUsedPercent': 20,
    'memoryUsedPercent': 10,
    'cpuTotal': 4,
    'memoryTotal': 17179869184,
    'memoryUsed': 8589934592,
    'netBytesRecv': 2097152,
    'netBytesSent': 3145728,
    'load1': 0.8,
    'load5': 0.6,
    'load15': 0.4,
    'uptime': 1036800,
    'timeSinceUptime': '12 days',
    'shotTime': shotTime,
    'diskData': const <Map<String, Object>>[
      {
        'path': '/',
        'usedPercent': 14,
      },
    ],
  };
}
