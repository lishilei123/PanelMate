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

class PanelContainerPage extends StatefulWidget {
  const PanelContainerPage({
    super.key,
    required this.server,
    this.service = const PanelModuleService(),
  });

  final PanelServerConnectionProfile server;
  final PanelModuleService service;

  @override
  State<PanelContainerPage> createState() => _PanelContainerPageState();
}

class _PanelContainerPageState extends State<PanelContainerPage> {
  PanelPagedPayload<PanelContainerItem>? _payload;
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
      final payload = await widget.service.loadContainers(widget.server);
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

  Future<void> _openStatSheet(PanelContainerItem item) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return FutureBuilder<PanelContainerStat>(
          future: widget.service.loadContainerStat(widget.server, item.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: PanelModuleErrorCard(
                  message: PanelErrorMessageResolver.resolve(snapshot.error!),
                  onRetry: () => Navigator.of(context).pop(),
                ),
              );
            }

            final stat = snapshot.data!;
            return SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  Text(
                    item.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    PanelValueFormatters.optionalText(item.imageName),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF66717F),
                        ),
                  ),
                  const SizedBox(height: 18),
                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.55,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      PanelModuleMetricCard(
                        label: 'CPU',
                        value: PanelValueFormatters.percent(
                          stat.cpuPercent,
                          fractionDigits: 1,
                        ),
                        color: const Color(0xFF1D7D5A),
                      ),
                      PanelModuleMetricCard(
                        label: '内存',
                        value: PanelValueFormatters.megabytes(
                          stat.memoryMegabytes,
                        ),
                        color: const Color(0xFF3A6996),
                      ),
                      PanelModuleMetricCard(
                        label: '读 IO',
                        value: PanelValueFormatters.bytes(
                          stat.ioReadKilobytes * 1024,
                        ),
                        color: const Color(0xFFD17F14),
                      ),
                      PanelModuleMetricCard(
                        label: '写 IO',
                        value: PanelValueFormatters.bytes(
                          stat.ioWriteKilobytes * 1024,
                        ),
                        color: const Color(0xFF8C5E3C),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  PanelCard(
                    child: Column(
                      children: [
                        PanelModuleInfoRow(
                          label: '网络接收',
                          value: PanelValueFormatters.bytes(
                            stat.networkRxKilobytes * 1024,
                          ),
                        ),
                        PanelModuleInfoRow(
                          label: '网络发送',
                          value: PanelValueFormatters.bytes(
                            stat.networkTxKilobytes * 1024,
                          ),
                        ),
                        PanelModuleInfoRow(
                          label: '采样时间',
                          value: PanelValueFormatters.dateTime(stat.shotTime),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final payload = _payload;

    return Scaffold(
      appBar: AppBar(
        title: const Text('容器'),
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
                title: '运行概览',
                subtitle: '真实读取 1Panel 容器搜索与统计接口。',
              ),
              const SizedBox(height: 12),
              _ContainerSummary(payload: payload),
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
                title: '容器列表',
                subtitle: '点击任意容器可继续查看当前资源采样。',
              ),
              const SizedBox(height: 12),
              if (payload.isEmpty)
                const PanelModuleEmptyCard(
                  icon: Icons.inventory_2_outlined,
                  title: '当前没有容器',
                  subtitle: '接口已经接通，但该服务器没有返回任何容器项目。',
                )
              else
                ...payload.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _openStatSheet(item),
                      child: PanelCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                                StatusChip(
                                  label: _stateLabel(item.state),
                                  color: _stateColor(item.state),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              PanelValueFormatters.optionalText(
                                item.imageName,
                                fallback: '未返回镜像信息',
                              ),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: const Color(0xFF66717F)),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: _InlineMetric(
                                    label: '运行时长',
                                    value: PanelValueFormatters.optionalText(
                                      item.runTime,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: _InlineMetric(
                                    label: 'CPU',
                                    value: item.cpuPercent == null
                                        ? '-'
                                        : PanelValueFormatters.percent(
                                            item.cpuPercent,
                                            fractionDigits: 1,
                                          ),
                                  ),
                                ),
                                Expanded(
                                  child: _InlineMetric(
                                    label: '内存',
                                    value: item.memoryPercent == null
                                        ? '-'
                                        : PanelValueFormatters.percent(
                                            item.memoryPercent,
                                            fractionDigits: 1,
                                          ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            PanelModuleInfoRow(
                              label: '网络',
                              value: item.networks.isEmpty
                                  ? '-'
                                  : item.networks.join(' / '),
                            ),
                            PanelModuleInfoRow(
                              label: '端口',
                              value: item.ports.isEmpty
                                  ? '-'
                                  : item.ports.join('\n'),
                            ),
                            PanelModuleInfoRow(
                              label: '创建时间',
                              value:
                                  PanelValueFormatters.dateTime(item.createdAt),
                            ),
                            if (item.appName.isNotEmpty)
                              PanelModuleInfoRow(
                                label: '来源应用',
                                value: item.appName,
                              ),
                          ],
                        ),
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

  Color _stateColor(String state) {
    switch (state.toLowerCase()) {
      case 'running':
        return const Color(0xFF1D7D5A);
      case 'exited':
      case 'dead':
        return const Color(0xFFAF4A3D);
      case 'paused':
      case 'restarting':
        return const Color(0xFFD17F14);
      default:
        return const Color(0xFF66717F);
    }
  }

  String _stateLabel(String state) {
    switch (state.toLowerCase()) {
      case 'running':
        return '运行中';
      case 'exited':
        return '已退出';
      case 'dead':
        return '已停止';
      case 'paused':
        return '已暂停';
      case 'restarting':
        return '重启中';
      case 'created':
        return '已创建';
      default:
        return state.isEmpty ? '未知' : state;
    }
  }
}

class _ContainerSummary extends StatelessWidget {
  const _ContainerSummary({
    required this.payload,
  });

  final PanelPagedPayload<PanelContainerItem> payload;

  @override
  Widget build(BuildContext context) {
    final running = payload.items
        .where((item) => item.state.toLowerCase() == 'running')
        .length;
    final abnormal = payload.items
        .where((item) => item.state.toLowerCase() != 'running')
        .length;
    final fromApps = payload.items.where((item) => item.isFromApp).length;

    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.28,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        PanelModuleMetricCard(
          label: '总容器',
          value: '${payload.total}',
          color: const Color(0xFF1D7D5A),
        ),
        PanelModuleMetricCard(
          label: '运行中',
          value: '$running',
          color: const Color(0xFF3A6996),
        ),
        PanelModuleMetricCard(
          label: '异常/停止',
          value: '$abnormal',
          color: const Color(0xFFD17F14),
        ),
        PanelModuleMetricCard(
          label: '来自应用',
          value: '$fromApps',
          color: const Color(0xFF0E7C86),
        ),
        PanelModuleMetricCard(
          label: '置顶',
          value: '${payload.items.where((item) => item.isPinned).length}',
          color: const Color(0xFF8C5E3C),
        ),
        PanelModuleMetricCard(
          label: 'Compose',
          value: '${payload.items.where((item) => item.isFromCompose).length}',
          color: const Color(0xFF6E5B8C),
        ),
      ],
    );
  }
}

class _InlineMetric extends StatelessWidget {
  const _InlineMetric({
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
                color: const Color(0xFF66717F),
              ),
        ),
      ],
    );
  }
}
