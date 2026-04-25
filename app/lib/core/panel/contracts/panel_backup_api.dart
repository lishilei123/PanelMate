abstract class PanelBackupApi {
  Future<Map<String, dynamic>> searchBackupAccounts({
    Map<String, dynamic>? body,
  });

  Future<Map<String, dynamic>> searchBackupRecords(Map<String, dynamic> body);

  Future<Map<String, dynamic>> searchBackupRecordsByCronjob(
    Map<String, dynamic> body,
  );
}
