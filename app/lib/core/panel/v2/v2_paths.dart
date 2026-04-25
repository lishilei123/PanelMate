class V2Paths {
  const V2Paths._();

  static const captcha = '/api/v2/core/auth/captcha';
  static const login = '/api/v2/core/auth/login';
  static const mfaLogin = '/api/v2/core/auth/mfalogin';
  static const logout = '/api/v2/core/auth/logout';
  static const dashboardCurrent =
      '/api/v2/dashboard/current/:ioOption/:netOption';
  static const dashboardBase = '/api/v2/dashboard/base/:ioOption/:netOption';
  static const dashboardBaseOs = '/api/v2/dashboard/base/os';
  static const operationLogsSearch = '/api/v2/core/logs/operation';
  static const containersSearch = '/api/v2/containers/search';
  static const containersOperate = '/api/v2/containers/operate';
  static const containersLogs = '/api/v2/containers/search/log';
  static const containersListStats = '/api/v2/containers/list/stats';
  static const containersStats = '/api/v2/containers/stats/:id';
  static const websitesSearch = '/api/v2/websites/search';
  static const websitesOperate = '/api/v2/websites/operate';
  static const websitesLog = '/api/v2/websites/log';
  static const websitesSslSearch = '/api/v2/websites/ssl/search';
  static const websitesSslByWebsiteId =
      '/api/v2/websites/ssl/website/:websiteId';
  static const appsInstalledSearch = '/api/v2/apps/installed/search';
  static const appsInstalledOp = '/api/v2/apps/installed/op';
  static const databasesSearch = '/api/v2/databases/search';
  static const databasesStatus = '/api/v2/databases/status';
  static const backupsSearch = '/api/v2/backups/search';
  static const backupRecordsSearch = '/api/v2/backups/record/search';
  static const backupRecordsByCronjob =
      '/api/v2/backups/record/search/bycronjob';
  static const filesSearch = '/api/v2/files/search';
  static const filesContent = '/api/v2/files/content';
  static const filesRead = '/api/v2/files/read';
}
