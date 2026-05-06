import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/panel/models/panel_error_message_resolver.dart';
import '../../../core/panel/models/server_connection_profile.dart';
import '../../../core/panel/runtime/panel_server_runtime_state.dart';
import '../../../shared/demo/panel_demo_catalog.dart';
import '../../../shared/formatters/panel_value_formatters.dart';
import '../../../shared/widgets/panel_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../modules/presentation/panel_app_page.dart';
import '../../modules/presentation/panel_backup_page.dart';
import '../../modules/presentation/panel_container_page.dart';
import '../../modules/presentation/panel_database_page.dart';
import '../../modules/presentation/panel_file_page.dart';
import '../../modules/presentation/panel_website_page.dart';
import '../../operations/application/panel_operation_feed_service.dart';

class ServerDetailPage extends StatefulWidget {
  const ServerDetailPage({
    super.key,
    required this.server,
    required this.initialRuntime,
    required this.autoRefreshInterval,
    required this.onRefresh,
    required this.onAutoRefresh,
    this.feedService = const PanelOperationFeedService(),
  });

  final PanelServerConnectionProfile server;
  final PanelServerRuntimeState? initialRuntime;
  final Duration? autoRefreshInterval;
  final Future<PanelServerRuntimeState> Function() onRefresh;
  final Future<PanelServerRuntimeState> Function() onAutoRefresh;
  final PanelOperationFeedService feedService;

  @override
  State<ServerDetailPage> createState() => _ServerDetailPageState();
}

class _ServerDetailPageState extends State<ServerDetailPage> {
  late PanelServerRuntimeState? _runtime;
  List<PanelOperationLogEntry> _operations = const <PanelOperationLogEntry>[];
  bool _isLoadingOperations = true;
  String? _operationsErrorMessage;
  bool _isRefreshingRuntime = false;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _runtime = widget.initialRuntime;
    _startAutoRefresh();
    if (_runtime?.hasLiveData != true) {
      unawaited(
        _refreshRuntime(
          refreshAction: widget.onAutoRefresh,
          showLoadingState: _runtime?.overview == null,
        ),
      );
    }
    unawaited(_loadOperations());
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ServerDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.autoRefreshInterval != widget.autoRefreshInterval) {
      _startAutoRefresh();
    }
  }

  Future<void> _refresh() async {
    await Future.wait<void>(<Future<void>>[
      _refreshRuntime(
        refreshAction: widget.onRefresh,
        showLoadingState: true,
      ),
      _loadOperations(),
    ]);
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    final interval = widget.autoRefreshInterval;
    if (interval == null) {
      _autoRefreshTimer = null;
      return;
    }
    _autoRefreshTimer = Timer.periodic(interval, (_) {
      unawaited(
        _refreshRuntime(
          refreshAction: widget.onAutoRefresh,
        ),
      );
    });
  }

  Future<void> _refreshRuntime({
    required Future<PanelServerRuntimeState> Function() refreshAction,
    bool showLoadingState = false,
  }) async {
    if (_isRefreshingRuntime) {
      return;
    }

    final previous = _runtime;
    _isRefreshingRuntime = true;

    if (showLoadingState) {
      setState(() {
        _runtime = PanelServerRuntimeState.loading(
          previousOverview: previous?.overview,
          previousSyncedAt: previous?.syncedAt,
        );
      });
    }

    try {
      final runtime = await refreshAction();
      if (!mounted) {
        return;
      }

      setState(() {
        _runtime = runtime;
      });
    } finally {
      _isRefreshingRuntime = false;
    }
  }

  Future<void> _loadOperations() async {
    setState(() {
      _isLoadingOperations = true;
      _operationsErrorMessage = null;
    });

    try {
      final result = await widget.feedService.loadServerOperations(
        widget.server,
        limit: 6,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _operations = result.items;
        _isLoadingOperations = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _operationsErrorMessage = PanelErrorMessageResolver.resolve(error);
        _isLoadingOperations = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final server = widget.server;
    final runtime = _runtime;
    final snapshot = PanelDemoCatalog.snapshotFor(server, runtime: runtime);
    final modules = <_ServerRealModuleShortcut>[
      _ServerRealModuleShortcut(
        label: '容器',
        subtitle: '状态、统计与日志',
        icon: Icons.inventory_2_outlined,
        color: const Color(0xFF1D7D5A),
        builder: (server) => PanelContainerPage(server: server),
      ),
      _ServerRealModuleShortcut(
        label: '网站',
        subtitle: '域名、证书与状态',
        icon: Icons.language_outlined,
        color: const Color(0xFF3A6996),
        builder: (server) => PanelWebsitePage(server: server),
      ),
      _ServerRealModuleShortcut(
        label: '应用',
        subtitle: '安装记录与版本',
        icon: Icons.widgets_outlined,
        color: const Color(0xFFD17F14),
        builder: (server) => PanelAppPage(server: server),
      ),
      _ServerRealModuleShortcut(
        label: '数据库',
        subtitle: '数据库与状态',
        icon: Icons.storage_outlined,
        color: const Color(0xFF8C5E3C),
        builder: (server) => PanelDatabasePage(server: server),
      ),
      _ServerRealModuleShortcut(
        label: '文件',
        subtitle: '目录浏览与文件读取',
        icon: Icons.folder_open_outlined,
        color: const Color(0xFF4A6A8A),
        builder: (server) => PanelFilePage(server: server),
      ),
      _ServerRealModuleShortcut(
        label: '备份',
        subtitle: '账户与记录',
        icon: Icons.backup_outlined,
        color: const Color(0xFF0E7C86),
        builder: (server) => PanelBackupPage(server: server),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(server.name),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            _HeroCard(
              server: server,
              snapshot: snapshot,
              runtime: runtime,
            ),
            if (runtime?.hasError == true) ...[
              const SizedBox(height: 18),
              PanelCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '最近一次同步失败',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(runtime!.message!),
                    if (runtime.hasLiveData) ...[
                      const SizedBox(height: 8),
                      Text(
                        '当前页面保留上次成功同步的数据，实时状态以重新同步成功后为准。',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF647181),
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            const _SectionTitle(
              title: '实时资源',
              subtitle: '查看 CPU、内存、磁盘等实时负载情况。',
            ),
            const SizedBox(height: 12),
            PanelCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _MetricTile(
                          label: 'CPU',
                          value: PanelDemoCatalog.percent(snapshot.cpuUsage),
                          color: const Color(0xFF1D7D5A),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetricTile(
                          label: '内存',
                          value: PanelDemoCatalog.percent(snapshot.memoryUsage),
                          color: const Color(0xFF3A6996),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetricTile(
                          label: '磁盘',
                          value: PanelDemoCatalog.percent(snapshot.diskUsage),
                          color: const Color(0xFFD17F14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _UsageRow(
                    label: 'CPU 使用率',
                    value: snapshot.cpuUsage,
                    color: const Color(0xFF1D7D5A),
                  ),
                  const SizedBox(height: 12),
                  _UsageRow(
                    label: '内存占用',
                    value: snapshot.memoryUsage,
                    color: const Color(0xFF3A6996),
                  ),
                  const SizedBox(height: 12),
                  _UsageRow(
                    label: '磁盘占用',
                    value: snapshot.diskUsage,
                    color: const Color(0xFFD17F14),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoCell(
                          label: '上行',
                          value: snapshot.networkOutText,
                        ),
                      ),
                      Expanded(
                        child: _InfoCell(
                          label: '下行',
                          value: snapshot.networkInText,
                        ),
                      ),
                      Expanded(
                        child: _InfoCell(
                          label: '负载',
                          value: snapshot.loadText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const _SectionTitle(
              title: '功能模块',
              subtitle: '点击进入对应模块，查看详细数据与执行操作。',
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: modules.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.48,
              ),
              itemBuilder: (context, index) {
                final module = modules[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => module.builder(server),
                      ),
                    );
                  },
                  child: PanelCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: module.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(module.icon, color: module.color),
                        ),
                        const Spacer(),
                        Text(
                          module.label,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          module.subtitle,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: const Color(0xFF66717F),
                                  ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            const _SectionTitle(
              title: '面板操作日志',
              subtitle: '展示面板最近的操作记录，便于快速定位变更与排查问题。',
            ),
            const SizedBox(height: 12),
            if (_isLoadingOperations && _operations.isEmpty)
              _buildAsyncStateCard(
                context,
                message: '正在加载最近操作...',
                showProgress: true,
              )
            else ...[
              if (_operationsErrorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildAsyncStateCard(
                    context,
                    message: _operationsErrorMessage!,
                    onRetry: _loadOperations,
                  ),
                ),
              if (!_isLoadingOperations &&
                  _operations.isEmpty &&
                  _operationsErrorMessage == null)
                _buildAsyncStateCard(
                  context,
                  message: '当前没有返回最近操作日志。',
                )
              else
                PanelCard(
                  child: Column(
                    children: [
                      for (var index = 0;
                          index < _operations.length;
                          index++) ...[
                        _OperationRow(operation: _operations[index]),
                        if (index != _operations.length - 1)
                          const SizedBox(height: 14),
                      ],
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAsyncStateCard(
    BuildContext context, {
    required String message,
    bool showProgress = false,
    Future<void> Function()? onRetry,
  }) {
    return PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showProgress) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 12),
          ],
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () {
                unawaited(onRetry());
              },
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ],
      ),
    );
  }

}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.server,
    required this.snapshot,
    required this.runtime,
  });

  final PanelServerConnectionProfile server;
  final PanelServerSnapshot snapshot;
  final PanelServerRuntimeState? runtime;

  @override
  Widget build(BuildContext context) {
    final hasError = runtime?.hasError == true;
    final hasSyncedData = snapshot.lastSyncedAt != null;
    final uptimeLabel = hasError && snapshot.hasLiveData ? '上次运行时长' : '运行时长';
    final syncLabel = !hasSyncedData
        ? '同步状态'
        : hasError
            ? '最后成功同步'
            : '最后同步';
    final syncValue = hasSyncedData
        ? PanelValueFormatters.relativeTime(snapshot.lastSyncedAt!)
        : runtime?.isLoading == true
            ? '同步中'
            : '尚未成功';

    return PanelCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          snapshot.health.icon,
                          color: snapshot.health.color,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        StatusChip(
                          label: snapshot.health.label,
                          color: snapshot.health.color,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      server.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      server.endpointLabel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF647181),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusChip(label: server.authMode.label),
              if (runtime?.isLoading == true) const StatusChip(label: '同步中'),
              for (final tag in server.tags) StatusChip(label: tag),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  label: uptimeLabel,
                  value: snapshot.uptimeText,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroMetric(
                  label: syncLabel,
                  value: syncValue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.52)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF647181),
                ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(label),
        ],
      ),
    );
  }
}

class _UsageRow extends StatelessWidget {
  const _UsageRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text(
              PanelDemoCatalog.percent(value),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _InfoCell extends StatelessWidget {
  const _InfoCell({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF687483),
              ),
        ),
      ],
    );
  }
}

class _OperationRow extends StatelessWidget {
  const _OperationRow({
    required this.operation,
  });

  final PanelOperationLogEntry operation;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(operation.status);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: statusColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                operation.title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                operation.subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF66717F),
                    ),
              ),
              if (operation.path.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  operation.path,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF5C6777),
                      ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          PanelValueFormatters.relativeTime(operation.createdAt),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF66717F),
              ),
        ),
      ],
    );
  }

  static Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'done':
      case 'finished':
        return const Color(0xFF1D7D5A);
      case 'waiting':
      case 'running':
        return const Color(0xFFD17F14);
      case 'failed':
      case 'error':
        return const Color(0xFFC44848);
      default:
        return const Color(0xFF2E6A95);
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF66717F),
              ),
        ),
      ],
    );
  }
}

class _ServerRealModuleShortcut {
  const _ServerRealModuleShortcut({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.builder,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget Function(PanelServerConnectionProfile server) builder;
}
