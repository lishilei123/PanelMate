import 'package:flutter_test/flutter_test.dart';
import 'package:panelmate/core/panel/runtime/panel_live_overview_data.dart';

void main() {
  group('PanelLiveOverviewData', () {
    test('normalizes dashboard percentage values from the API 0 to 100 scale',
        () {
      final current = PanelLiveOverviewData.fromMap(
        _payload(
          shotTime: '2026-04-06T10:00:00Z',
          netBytesRecv: 2048,
          netBytesSent: 1024,
          cpuUsedPercent: 0.5,
          memoryUsedPercent: 41,
          diskUsedPercent: 63,
        ),
      );

      expect(current.cpuUsedPercent, closeTo(0.005, 0.0001));
      expect(current.memoryUsedPercent, closeTo(0.41, 0.0001));
      expect(current.diskUsedPercent, closeTo(0.63, 0.0001));
    });

    test('derives network speed and top processes from consecutive samples',
        () {
      final previous = PanelLiveOverviewData.fromMap(_payload(
        shotTime: '2026-04-06T10:00:00Z',
        netBytesRecv: 1000,
        netBytesSent: 500,
      ));

      final current = PanelLiveOverviewData.fromMap(
        _payload(
          shotTime: '2026-04-06T10:00:05Z',
          netBytesRecv: 6000,
          netBytesSent: 2500,
          topCpuItems: const <Map<String, Object>>[
            {
              'pid': 101,
              'name': 'nginx',
              'user': 'root',
              'cmd': 'nginx -g daemon off;',
              'percent': 12.3,
              'memory': 104857600,
            },
          ],
          topMemItems: const <Map<String, Object>>[
            {
              'pid': 202,
              'name': 'mysqld',
              'user': 'mysql',
              'cmd': '/usr/sbin/mysqld',
              'percent': 32.1,
              'memory': 209715200,
            },
          ],
        ),
        previous: previous,
      );

      expect(current.netBytesRecvPerSecond, closeTo(1000, 0.001));
      expect(current.netBytesSentPerSecond, closeTo(400, 0.001));
      expect(current.topCpuProcesses, hasLength(1));
      expect(current.topCpuProcesses.first.name, 'nginx');
      expect(current.topMemoryProcesses, hasLength(1));
      expect(current.topMemoryProcesses.first.pid, 202);
    });

    test('does not fabricate network speed without a prior sample', () {
      final current = PanelLiveOverviewData.fromMap(
        _payload(
          shotTime: '2026-04-06T10:00:00Z',
          netBytesRecv: 2048,
          netBytesSent: 1024,
        ),
      );

      expect(current.netBytesRecvPerSecond, isNull);
      expect(current.netBytesSentPerSecond, isNull);
    });
  });
}

Map<String, Object> _payload({
  required String shotTime,
  required int netBytesRecv,
  required int netBytesSent,
  num cpuUsedPercent = 52,
  num memoryUsedPercent = 41,
  num diskUsedPercent = 63,
  List<Map<String, Object>> topCpuItems = const <Map<String, Object>>[],
  List<Map<String, Object>> topMemItems = const <Map<String, Object>>[],
}) {
  return <String, Object>{
    'cpuUsedPercent': cpuUsedPercent,
    'memoryUsedPercent': memoryUsedPercent,
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
    'diskData': <Map<String, Object>>[
      {
        'path': '/',
        'usedPercent': diskUsedPercent,
      },
    ],
    'topCPUItems': topCpuItems,
    'topMemItems': topMemItems,
  };
}
