import 'package:flutter_test/flutter_test.dart';
import 'package:panelmate/core/network/panel_web_debug_proxy.dart';

void main() {
  group('PanelWebDebugProxy', () {
    test('returns target uri when disabled', () {
      final target = Uri.parse(
        'http://panel.example.com:8443/api/v2/dashboard/current/all/all',
      );

      final result = PanelWebDebugProxy.buildRequestUri(
        target,
        enabled: false,
      );

      expect(result, target);
    });

    test('wraps target uri into proxy request when enabled', () {
      final target = Uri.parse(
        'http://panel.example.com:8443/api/v2/dashboard/current/all/all?scope=all',
      );

      final result = PanelWebDebugProxy.buildRequestUri(
        target,
        enabled: true,
        proxyOrigin: 'http://127.0.0.1:8787',
        proxyPath: '/proxy',
      );

      expect(
        result.toString(),
        'http://127.0.0.1:8787/proxy?target=${Uri.encodeQueryComponent(target.toString())}',
      );
    });

    test('keeps proxy base path when origin already has path', () {
      final target = Uri.parse('http://panel.example.com:8443/api/v2/apps');

      final result = PanelWebDebugProxy.buildRequestUri(
        target,
        enabled: true,
        proxyOrigin: 'http://127.0.0.1:8787/dev-tools',
        proxyPath: 'proxy',
      );

      expect(
        result.toString(),
        'http://127.0.0.1:8787/dev-tools/proxy?target=${Uri.encodeQueryComponent(target.toString())}',
      );
    });
  });
}
