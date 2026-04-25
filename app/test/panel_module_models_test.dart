import 'package:flutter_test/flutter_test.dart';
import 'package:panelmate/features/modules/models/panel_module_models.dart';

void main() {
  group('PanelAppItem.fromMap', () {
    test('maps real v2 app payload fields and nested links', () {
      final item = PanelAppItem.fromMap(const <String, dynamic>{
        'id': 2,
        'name': 'openresty',
        'appName': 'OpenResty',
        'appKey': 'openresty',
        'version': '1.27.1.2-5-1-focal',
        'status': 'Running',
        'message': '',
        'appType': 'runtime',
        'path': '/opt/1panel/apps/openresty/openresty',
        'httpPort': 80,
        'httpsPort': 443,
        'canUpdate': false,
        'container': '1Panel-openresty-jKIN',
        'serviceName': 'openresty',
        'webUI': '',
        'favorite': false,
        'createdAt': '2026-03-17T21:32:58.118215166+08:00',
        'app': <String, dynamic>{
          'website': 'https://openresty.org',
          'document': 'http://openresty.org/cn/getting-started.html',
          'github': 'https://github.com/openresty/openresty',
        },
      });

      expect(item.appName, 'OpenResty');
      expect(item.appType, 'runtime');
      expect(item.container, '1Panel-openresty-jKIN');
      expect(item.serviceName, 'openresty');
      expect(item.webUi, isEmpty);
      expect(item.websiteUrl, 'https://openresty.org');
      expect(
        item.documentUrl,
        'http://openresty.org/cn/getting-started.html',
      );
      expect(item.githubUrl, 'https://github.com/openresty/openresty');
    });
  });

  group('PanelWebsiteItem.fromMap', () {
    test('maps real v2 website payload fields', () {
      final item = PanelWebsiteItem.fromMap(const <String, dynamic>{
        'id': 2,
        'createdAt': '2026-03-26T23:12:13.982168977+08:00',
        'protocol': 'HTTP',
        'primaryDomain': 'kr-telegram.972971617.xyz',
        'type': 'static',
        'alias': 'kr-telegram.972971617.xyz',
        'remark': '',
        'status': 'Running',
        'sitePath': '/opt/1panel/www/sites/kr-telegram.972971617.xyz',
        'appName': '',
        'runtimeName': '',
        'sslExpireDate': '0001-01-01T00:00:00Z',
        'sslStatus': 'danger',
        'appInstallId': 0,
        'childSites': <Map<String, dynamic>>[
          <String, dynamic>{'id': 10},
          <String, dynamic>{'id': 11},
        ],
        'parentSite': '',
        'runtimeType': '',
        'favorite': false,
        'IPV6': true,
      });

      expect(item.primaryDomain, 'kr-telegram.972971617.xyz');
      expect(item.protocol, 'HTTP');
      expect(item.type, 'static');
      expect(item.childSiteCount, 2);
      expect(item.ipv6Enabled, isTrue);
      expect(item.sslExpireDate, isNull);
    });
  });
}
