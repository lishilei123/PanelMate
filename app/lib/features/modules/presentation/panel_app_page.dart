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

class PanelAppPage extends StatefulWidget {
  const PanelAppPage({
    super.key,
    required this.server,
    this.service = const PanelModuleService(),
  });

  final PanelServerConnectionProfile server;
  final PanelModuleService service;

  @override
  State<PanelAppPage> createState() => _PanelAppPageState();
}

class _PanelAppPageState extends State<PanelAppPage> {
  PanelPagedPayload<PanelAppItem>? _payload;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final payload = await widget.service.loadApps(widget.server);
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
        title: const Text('应用'),
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
                title: '应用概览',
                subtitle: '真实读取已安装应用列表，展示版本、运行状态和访问端口。',
              ),
              const SizedBox(height: 12),
              _AppSummary(payload: payload),
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
                title: '已安装应用',
                subtitle: '当前先做真实只读展示，后续再补应用操作。',
              ),
              const SizedBox(height: 12),
              if (payload.isEmpty)
                const PanelModuleEmptyCard(
                  icon: Icons.widgets_outlined,
                  title: '当前没有已安装应用',
                  subtitle: '接口已经接通，但当前服务器没有返回已安装应用。',
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
                                  item.appName.isEmpty
                                      ? item.name
                                      : item.appName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                              StatusChip(
                                label: _statusLabel(item.status),
                                color: _statusColor(item.status),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${item.name} · ${item.version}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: const Color(0xFF66717F)),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (item.appKey.isNotEmpty)
                                StatusChip(label: item.appKey),
                              if (item.appType.isNotEmpty)
                                StatusChip(label: item.appType),
                              if (item.serviceName.isNotEmpty)
                                StatusChip(label: item.serviceName),
                              if (item.httpPort != null)
                                StatusChip(label: 'HTTP ${item.httpPort}'),
                              if (item.httpsPort != null)
                                StatusChip(label: 'HTTPS ${item.httpsPort}'),
                              if (item.favorite)
                                const StatusChip(
                                  label: '已收藏',
                                  color: Color(0xFFD17F14),
                                ),
                              if (item.canUpdate)
                                const StatusChip(
                                  label: '可升级',
                                  color: Color(0xFFD17F14),
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          PanelModuleInfoRow(
                            label: '安装路径',
                            value: PanelValueFormatters.optionalText(item.path),
                          ),
                          if (item.container.isNotEmpty)
                            PanelModuleInfoRow(
                              label: '容器',
                              value: item.container,
                            ),
                          if (_resolvedAccessEntry(item).isNotEmpty)
                            PanelModuleInfoRow(
                              label: 'Web 管理页',
                              value: _resolvedAccessEntry(item),
                            ),
                          if (item.message.isNotEmpty)
                            PanelModuleInfoRow(
                              label: '消息',
                              value: item.message,
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

  Color _statusColor(String status) {
    if (status.toLowerCase() == 'running') {
      return const Color(0xFF1D7D5A);
    }
    if (status.toLowerCase().contains('install')) {
      return const Color(0xFFD17F14);
    }
    return const Color(0xFFAF4A3D);
  }

  String _statusLabel(String status) {
    final lower = status.toLowerCase();
    if (lower == 'running') {
      return '运行中';
    }
    if (lower.contains('install')) {
      return '安装中';
    }
    if (lower == 'waiting') {
      return '等待中';
    }
    if (lower == 'stopped' || lower == 'exited') {
      return '已停止';
    }
    if (lower == 'failed' || lower == 'error') {
      return '异常';
    }
    return status.isEmpty ? '未知' : status;
  }

  String _resolvedAccessEntry(PanelAppItem item) {
    final values = <String>{
      if (item.webUi.isNotEmpty) item.webUi,
      if (item.websiteUrl.isNotEmpty) item.websiteUrl,
      if (item.documentUrl.isNotEmpty) item.documentUrl,
      if (item.githubUrl.isNotEmpty) item.githubUrl,
    };
    return values.join('\n');
  }
}

class _AppSummary extends StatelessWidget {
  const _AppSummary({
    required this.payload,
  });

  final PanelPagedPayload<PanelAppItem> payload;

  @override
  Widget build(BuildContext context) {
    final running = payload.items
        .where((item) => item.status.toLowerCase() == 'running')
        .length;
    final updatable = payload.items.where((item) => item.canUpdate).length;
    final withWebUi = payload.items
        .where(
          (item) =>
              item.webUi.isNotEmpty ||
              item.websiteUrl.isNotEmpty ||
              item.documentUrl.isNotEmpty ||
              item.githubUrl.isNotEmpty,
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
          label: '总应用',
          value: '${payload.total}',
          color: const Color(0xFF1D7D5A),
        ),
        PanelModuleMetricCard(
          label: '运行中',
          value: '$running',
          color: const Color(0xFF3A6996),
        ),
        PanelModuleMetricCard(
          label: '可升级',
          value: '$updatable',
          color: const Color(0xFFD17F14),
        ),
        PanelModuleMetricCard(
          label: '含管理页',
          value: '$withWebUi',
          color: const Color(0xFF0E7C86),
        ),
      ],
    );
  }
}
