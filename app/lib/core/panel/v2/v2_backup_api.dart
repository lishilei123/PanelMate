import '../../network/panel_http_client.dart';
import '../contracts/panel_backup_api.dart';
import 'v2_paths.dart';

class V2BackupApi implements PanelBackupApi {
  V2BackupApi(this._client);

  final PanelHttpClient _client;

  @override
  Future<Map<String, dynamic>> searchBackupAccounts({
    Map<String, dynamic>? body,
  }) {
    return _client.post(V2Paths.backupsSearch, body: body ?? const {});
  }

  @override
  Future<Map<String, dynamic>> searchBackupRecords(Map<String, dynamic> body) {
    return _client.post(V2Paths.backupRecordsSearch, body: body);
  }

  @override
  Future<Map<String, dynamic>> searchBackupRecordsByCronjob(
    Map<String, dynamic> body,
  ) {
    return _client.post(V2Paths.backupRecordsByCronjob, body: body);
  }
}
