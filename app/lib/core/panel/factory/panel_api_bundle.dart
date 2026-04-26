import '../contracts/panel_app_api.dart';
import '../contracts/panel_auth_api.dart';
import '../contracts/panel_backup_api.dart';
import '../contracts/panel_container_api.dart';
import '../contracts/panel_database_api.dart';
import '../contracts/panel_file_api.dart';
import '../contracts/panel_generic_api.dart';
import '../contracts/panel_overview_api.dart';
import '../contracts/panel_website_api.dart';
import '../models/compatibility_flags.dart';

class PanelApiBundle {
  const PanelApiBundle({
    required this.auth,
    required this.overview,
    required this.container,
    required this.website,
    required this.app,
    required this.database,
    required this.backup,
    required this.file,
    required this.generic,
    required this.compatibilityFlags,
  });

  final PanelAuthApi auth;
  final PanelOverviewApi overview;
  final PanelContainerApi container;
  final PanelWebsiteApi website;
  final PanelAppApi app;
  final PanelDatabaseApi database;
  final PanelBackupApi backup;
  final PanelFileApi file;
  final PanelGenericApi generic;
  final PanelCompatibilityFlags compatibilityFlags;
}
