import 'package:flutter/material.dart';

import '../../../core/panel/models/server_connection_profile.dart';
import '../../../core/panel/runtime/panel_server_runtime_state.dart';
import '../../../shared/demo/panel_demo_catalog.dart';
import '../../../shared/formatters/panel_value_formatters.dart';
import '../../../shared/widgets/panel_card.dart';
import '../../../shared/widgets/status_chip.dart';

enum _OverviewFilter {
  all,
  online,
  offline,
}

enum _ServerCardAction {
  edit,
  delete,
}

class OverviewPage extends StatefulWidget {
  const OverviewPage({
    super.key,
    required this.servers,
    required this.onAddServer,
    required this.onEditServer,
    required this.onOpenServer,
    required this.onRemoveServer,
    required this.resolveRuntime,
  });

  final List<PanelServerConnectionProfile> servers;
  final VoidCallback onAddServer;
  final Future<void> Function(PanelServerConnectionProfile server) onEditServer;
  final ValueChanged<PanelServerConnectionProfile> onOpenServer;
  final Future<void> Function(PanelServerConnectionProfile server)
      onRemoveServer;
  final PanelServerRuntimeState? Function(PanelServerConnectionProfile server)
      resolveRuntime;

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  final TextEditingController _searchController = TextEditingController();
  _OverviewFilter _selectedFilter = _OverviewFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final records = widget.servers.map((server) {
      final runtime = widget.resolveRuntime(server);
      return (
        server: server,
        runtime: runtime,
        snapshot: PanelDemoCatalog.snapshotFor(server, runtime: runtime),
      );
    }).toList(growable: false);

    final query = _searchController.text.trim().toLowerCase();
    final onlineCount =
        records.where((record) => record.snapshot.isOnline).length;
    final offlineCount = records.length - onlineCount;

    final filtered = records.where((record) {
      final matchesQuery = query.isEmpty ||
          record.server.name.toLowerCase().contains(query) ||
          record.server.baseUrl.toLowerCase().contains(query) ||
          record.snapshot.groupLabel.toLowerCase().contains(query) ||
          record.server.tags.any(
            (tag) => tag.toLowerCase().contains(query),
          );
      if (!matchesQuery) {
        return false;
      }

      return switch (_selectedFilter) {
        _OverviewFilter.all => true,
        _OverviewFilter.online => record.snapshot.isOnline,
        _OverviewFilter.offline => !record.snapshot.isOnline,
      };
    }).toList()
      ..sort((left, right) {
        final byHealth = right.snapshot.health.priority
            .compareTo(left.snapshot.health.priority);
        if (byHealth != 0) {
          return byHealth;
        }
        final leftSyncedAt = left.snapshot.lastSyncedAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final rightSyncedAt = right.snapshot.lastSyncedAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return rightSyncedAt.compareTo(leftSyncedAt);
      });

    final hasSearchText = query.isNotEmpty;
    final hasMatches = filtered.isNotEmpty;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _OverviewHeader(
                  totalCount: records.length,
                  onlineCount: onlineCount,
                  onAddServer: widget.onAddServer,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: '搜索服务器名称、地址或标签',
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.70),
                    suffixIcon: hasSearchText
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.close),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 14),
                _OverviewFilterBar(
                  totalCount: records.length,
                  onlineCount: onlineCount,
                  offlineCount: offlineCount,
                  selectedFilter: _selectedFilter,
                  onSelectFilter: (filter) {
                    if (_selectedFilter == filter) {
                      return;
                    }
                    setState(() => _selectedFilter = filter);
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        if (hasMatches)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
            sliver: SliverList.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final record = filtered[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ServerCard(
                    key: ValueKey(record.server.credentialStorageKey),
                    server: record.server,
                    snapshot: record.snapshot,
                    runtime: record.runtime,
                    onTap: () => widget.onOpenServer(record.server),
                    onActionSelected: (action) =>
                        _handleServerAction(record.server, action),
                  ),
                );
              },
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
            sliver: SliverToBoxAdapter(
              child: widget.servers.isEmpty
                  ? const _EmptyOverviewCard(
                      icon: Icons.dns_outlined,
                      title: '还没有服务器',
                      message: '添加一台 1Panel V2 服务器后，这里会显示实时资源和健康状态。',
                    )
                  : const _EmptyOverviewCard(
                      icon: Icons.search_off_outlined,
                      title: '没有匹配结果',
                      message: '换一个名称、地址或标签继续搜索。',
                    ),
            ),
          ),
      ],
    );
  }

  Future<void> _handleServerAction(
    PanelServerConnectionProfile server,
    _ServerCardAction action,
  ) async {
    switch (action) {
      case _ServerCardAction.edit:
        await widget.onEditServer(server);
      case _ServerCardAction.delete:
        await _confirmRemoveServer(server);
    }
  }

  Future<void> _confirmRemoveServer(PanelServerConnectionProfile server) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除服务器'),
          content: Text('确认删除 ${server.name} 的本地连接配置和凭证吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await widget.onRemoveServer(server);
  }
}

class _OverviewHeader extends StatelessWidget {
  const _OverviewHeader({
    required this.totalCount,
    required this.onlineCount,
    required this.onAddServer,
  });

  final int totalCount;
  final int onlineCount;
  final VoidCallback onAddServer;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '概览',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF132F3A),
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                totalCount == 0
                    ? '多服务器状态、搜索和快速进入'
                    : '$onlineCount/$totalCount 台在线',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF60717B),
                    ),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          key: const ValueKey('overview.add_server_button'),
          tooltip: '新增服务器',
          onPressed: onAddServer,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

class _EmptyOverviewCard extends StatelessWidget {
  const _EmptyOverviewCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return PanelCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 26),
      child: Column(
        children: [
          Icon(icon, size: 34, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF60717B),
                ),
          ),
        ],
      ),
    );
  }
}

class _OverviewFilterBar extends StatelessWidget {
  const _OverviewFilterBar({
    required this.totalCount,
    required this.onlineCount,
    required this.offlineCount,
    required this.selectedFilter,
    required this.onSelectFilter,
  });

  final int totalCount;
  final int onlineCount;
  final int offlineCount;
  final _OverviewFilter selectedFilter;
  final ValueChanged<_OverviewFilter> onSelectFilter;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _FilterChip(
          label: '全部',
          count: totalCount,
          selected: selectedFilter == _OverviewFilter.all,
          onTap: () => onSelectFilter(_OverviewFilter.all),
        ),
        _FilterChip(
          label: '在线',
          count: onlineCount,
          selected: selectedFilter == _OverviewFilter.online,
          onTap: () => onSelectFilter(_OverviewFilter.online),
        ),
        _FilterChip(
          label: '离线',
          count: offlineCount,
          selected: selectedFilter == _OverviewFilter.offline,
          onTap: () => onSelectFilter(_OverviewFilter.offline),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.14)
                : Colors.white.withValues(alpha: 0.54),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.28)
                  : Colors.white.withValues(alpha: 0.68),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected ? color : const Color(0xFF52666F),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? color.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.56),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: selected ? color : const Color(0xFF52666F),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServerCard extends StatelessWidget {
  const _ServerCard({
    super.key,
    required this.server,
    required this.snapshot,
    required this.runtime,
    required this.onTap,
    required this.onActionSelected,
  });

  final PanelServerConnectionProfile server;
  final PanelServerSnapshot snapshot;
  final PanelServerRuntimeState? runtime;
  final VoidCallback onTap;
  final ValueChanged<_ServerCardAction> onActionSelected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: PanelCard(
        padding: const EdgeInsets.all(14),
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
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    server.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                if (runtime?.isLoading == true)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                StatusChip(
                  label: snapshot.health.label,
                  color: snapshot.health.color,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatusChip(label: server.authMode.label),
                for (final tag in server.tags.take(3)) StatusChip(label: tag),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _MetricCell(
                    label: 'CPU',
                    value: PanelDemoCatalog.percent(snapshot.cpuUsage),
                    usage: snapshot.cpuUsage,
                    color: const Color(0xFF28A071),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricCell(
                    label: '内存',
                    value: PanelDemoCatalog.percent(snapshot.memoryUsage),
                    usage: snapshot.memoryUsage,
                    color: const Color(0xFF3486B8),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricCell(
                    label: '磁盘',
                    value: PanelDemoCatalog.percent(snapshot.diskUsage),
                    usage: snapshot.diskUsage,
                    color: const Color(0xFFFF8A5C),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _TrafficSummaryRow(
              realtimeText:
                  '↓ ${snapshot.networkInText}  ↑ ${snapshot.networkOutText}',
              totalText:
                  '↓ ${snapshot.networkTotalInText}  ↑ ${snapshot.networkTotalOutText}',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (snapshot.isOnline)
                  const Spacer()
                else
                  Expanded(
                    child: Text(
                      snapshot.lastSyncedAt == null
                          ? '尚未成功同步'
                          : '离线 ${PanelValueFormatters.relativeTime(snapshot.lastSyncedAt!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF60717B),
                          ),
                    ),
                  ),
                PopupMenuButton<_ServerCardAction>(
                  key: ValueKey(
                    'overview.server.more.${server.credentialStorageKey}',
                  ),
                  tooltip: '更多操作',
                  position: PopupMenuPosition.under,
                  icon: const Icon(
                    Icons.more_horiz,
                    color: Color(0xFF6A7584),
                  ),
                  onSelected: (action) => onActionSelected(action),
                  itemBuilder: (context) => const [
                    PopupMenuItem<_ServerCardAction>(
                      value: _ServerCardAction.edit,
                      child: Text('编辑'),
                    ),
                    PopupMenuItem<_ServerCardAction>(
                      value: _ServerCardAction.delete,
                      child: Text('删除'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TrafficSummaryRow extends StatelessWidget {
  const _TrafficSummaryRow({
    required this.realtimeText,
    required this.totalText,
  });

  final String realtimeText;
  final String totalText;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: const Color(0xFF60717B),
          fontWeight: FontWeight.w600,
        );

    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                realtimeText,
                maxLines: 1,
                style: style,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                totalText,
                maxLines: 1,
                style: style,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({
    required this.label,
    required this.value,
    required this.usage,
    required this.color,
  });

  final String label;
  final String value;
  final double usage;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: usage,
            minHeight: 5,
            color: color,
            backgroundColor: color.withValues(alpha: 0.12),
          ),
        ),
        const SizedBox(height: 5),
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
