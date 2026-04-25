import '../../network/panel_http_client.dart';
import '../models/compatibility_flags.dart';
import '../models/server_connection_profile.dart';
import '../v2/v2_app_api.dart';
import '../v2/v2_auth_api.dart';
import '../v2/v2_backup_api.dart';
import '../v2/v2_container_api.dart';
import '../v2/v2_database_api.dart';
import '../v2/v2_file_api.dart';
import '../v2/v2_overview_api.dart';
import '../v2/v2_website_api.dart';
import 'panel_api_bundle.dart';

class PanelApiFactory {
  const PanelApiFactory._();

  static PanelApiBundle create({
    required PanelServerConnectionProfile server,
    required PanelHttpClient httpClient,
  }) {
    final flags = server.compatibilityFlags ??
        PanelCompatibilityFlags.forVersion(server.apiVersion);

    return PanelApiBundle(
      auth: V2AuthApi(httpClient),
      overview: V2OverviewApi(httpClient),
      container: V2ContainerApi(httpClient),
      website: V2WebsiteApi(httpClient),
      app: V2AppApi(httpClient),
      database: V2DatabaseApi(httpClient),
      backup: V2BackupApi(httpClient),
      file: V2FileApi(httpClient),
      compatibilityFlags: flags,
    );
  }
}
