import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/panel/models/panel_error_message_resolver.dart';
import '../../../core/panel/models/server_connection_profile.dart';
import '../../../shared/formatters/panel_value_formatters.dart';
import '../../../shared/widgets/panel_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../application/panel_module_service.dart';
import '../models/panel_module_models.dart';
import 'panel_module_widgets.dart';

class PanelWebsitePage extends StatefulWidget {
  const PanelWebsitePage({
    super.key,
    required this.server,
    this.service = const PanelModuleService(),
  });

  final PanelServerConnectionProfile server;
  final PanelModuleService service;

  @override
  State<PanelWebsitePage> createState() => _PanelWebsitePageState();
}

class _PanelWebsitePageState extends State<PanelWebsitePage> {
  PanelPagedPayload<PanelWebsiteItem>? _payload;
  String? _errorMessage;
  bool _isLoading = true;
  final Set<int> _operatingIds = <int>{};

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _operate(PanelWebsiteItem item, String action) async {
    final label = _actionLabel(action);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$label 网站'),
        content: Text('确定要$label「${item.primaryDomain}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: action == 'stop'
                  ? Theme.of(ctx).colorScheme.error
                  : Theme.of(ctx).colorScheme.primary,
            ),
            child: Text(label),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _operatingIds.add(item.id));
    try {
      await widget.service.operateWebsite(
        widget.server,
        websiteId: item.id,
        operation: action,
      );
      if (!mounted) return;
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '操作失败：${PanelErrorMessageResolver.resolve(error)}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _operatingIds.remove(item.id));
    }
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final payload = await widget.service.loadWebsites(widget.server);
      if (!mounted) {
        return;
      }

      setState(() {
        _payload = payload;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = PanelErrorMessageResolver.resolve(error);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final payload = _payload;

    return Scaffold(
      appBar: AppBar(
        title: const Text('网站'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            if (_isLoading && payload == null)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null && payload == null)
              PanelModuleErrorCard(
                message: _errorMessage!,
                onRetry: _load,
              )
            else if (payload != null) ...[
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(),
                ),
              const PanelModuleSectionTitle(
                title: '站点概览',
                subtitle: '真实读取网站搜索接口，展示域名、协议、SSL 与运行状态。',
              ),
              const SizedBox(height: 12),
              _WebsiteSummary(payload: payload),
              const SizedBox(height: 18),
              if (_errorMessage != null) ...[
                PanelCard(
                  child: Text(
                    _errorMessage!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF8C3030),
                        ),
                  ),
                ),
                const SizedBox(height: 18),
              ],
              const PanelModuleSectionTitle(
                title: '网站列表',
                subtitle: '点击状态标签可切换站点启停，操作前会二次确认。',
              ),
              const SizedBox(height: 12),
              if (payload.isEmpty)
                const PanelModuleEmptyCard(
                  icon: Icons.language_outlined,
                  title: '当前没有网站',
                  subtitle: '接口已经接通，但该服务器没有返回任何网站条目。',
                )
              else
                ...payload.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: PanelCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.primaryDomain,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                              if (_operatingIds.contains(item.id))
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              else
                                GestureDetector(
                                  onTap: () => _operate(
                                    item,
                                    item.status.toLowerCase() == 'running'
                                        ? 'stop'
                                        : 'start',
                                  ),
                                  child: StatusChip(
                                    label: _statusLabel(item.status),
                                    color: _statusColor(item.status),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              StatusChip(label: item.protocol),
                              StatusChip(label: item.type),
                              if (item.appName.isNotEmpty)
                                StatusChip(label: item.appName),
                              if (item.ipv6Enabled)
                                const StatusChip(label: 'IPv6'),
                              if (item.sslStatus.isNotEmpty)
                                StatusChip(
                                  label: '证书 ${_sslLabel(item.sslStatus)}',
                                  color: _sslColor(item.sslStatus),
                                ),
                              if (item.favorite)
                                const StatusChip(
                                  label: '已收藏',
                                  color: Color(0xFFD17F14),
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          PanelModuleInfoRow(
                            label: '站点目录',
                            value: PanelValueFormatters.optionalText(
                                item.sitePath),
                          ),
                          if (item.alias.isNotEmpty &&
                              item.alias != item.primaryDomain)
                            PanelModuleInfoRow(
                              label: '别名',
                              value: item.alias,
                            ),
                          if (_resolvedRuntimeLabel(item).isNotEmpty)
                            PanelModuleInfoRow(
                              label: '运行时',
                              value: _resolvedRuntimeLabel(item),
                            ),
                          if (item.remark.isNotEmpty)
                            PanelModuleInfoRow(
                              label: '备注',
                              value: item.remark,
                            ),
                          PanelModuleInfoRow(
                            label: '证书到期',
                            value: item.sslExpireDate == null
                                ? '未返回证书到期时间'
                                : '${PanelValueFormatters.dateTime(item.sslExpireDate)} (${PanelValueFormatters.relativeTime(item.sslExpireDate)})',
                          ),
                          PanelModuleInfoRow(
                            label: '创建时间',
                            value:
                                PanelValueFormatters.dateTime(item.createdAt),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _actionLabel(String action) {
    switch (action) {
      case 'start':
        return '启动';
      case 'stop':
        return '停止';
      default:
        return action;
    }
  }

  Color _statusColor(String status) {
    if (status.toLowerCase() == 'running') {
      return const Color(0xFF1D7D5A);
    }
    return const Color(0xFFAF4A3D);
  }

  Color _sslColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'ready':
        return const Color(0xFF1D7D5A);
      case 'warning':
        return const Color(0xFFD17F14);
      default:
        return const Color(0xFFAF4A3D);
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'running':
        return '运行中';
      case 'stopped':
      case 'stop':
        return '已停止';
      case 'error':
      case 'failed':
        return '异常';
      default:
        return status.isEmpty ? '未知' : status;
    }
  }

  String _resolvedRuntimeLabel(PanelWebsiteItem item) {
    final values = <String>[
      if (item.runtimeName.isNotEmpty) item.runtimeName,
      if (item.runtimeKind.isNotEmpty) item.runtimeKind,
      if (item.appName.isNotEmpty) item.appName,
    ];
    return values.join(' / ');
  }

  String _sslLabel(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'ready':
        return '正常';
      case 'warning':
        return '预警';
      case 'failed':
      case 'error':
        return '异常';
      default:
        return status.isEmpty ? '未知' : status;
    }
  }
}

class _WebsiteSummary extends StatelessWidget {
  const _WebsiteSummary({
    required this.payload,
  });

  final PanelPagedPayload<PanelWebsiteItem> payload;

  @override
  Widget build(BuildContext context) {
    final running = payload.items
        .where((item) => item.status.toLowerCase() == 'running')
        .length;
    final https = payload.items
        .where((item) => item.protocol.toLowerCase().contains('https'))
        .length;
    final sslReady = payload.items
        .where(
          (item) =>
              item.sslStatus.toLowerCase() == 'success' ||
              item.sslStatus.toLowerCase() == 'ready',
        )
        .length;

    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.7,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        PanelModuleMetricCard(
          label: '总站点',
          value: '${payload.total}',
          color: const Color(0xFF1D7D5A),
        ),
        PanelModuleMetricCard(
          label: '运行中',
          value: '$running',
          color: const Color(0xFF3A6996),
        ),
        PanelModuleMetricCard(
          label: 'HTTPS',
          value: '$https',
          color: const Color(0xFF0E7C86),
        ),
        PanelModuleMetricCard(
          label: '证书正常',
          value: '$sslReady',
          color: const Color(0xFFD17F14),
        ),
      ],
    );
  }
}
