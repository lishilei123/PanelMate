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

class PanelDatabasePage extends StatefulWidget {
  const PanelDatabasePage({
    super.key,
    required this.server,
    this.service = const PanelModuleService(),
  });

  final PanelServerConnectionProfile server;
  final PanelModuleService service;

  @override
  State<PanelDatabasePage> createState() => _PanelDatabasePageState();
}

class _PanelDatabasePageState extends State<PanelDatabasePage> {
  PanelPagedPayload<PanelDatabaseItem>? _payload;
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
      final payload = await widget.service.loadDatabases(widget.server);
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
        title: const Text('数据库'),
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
                title: '数据库概览',
                subtitle: '展示已接入的数据库列表、库名与来源信息。',
              ),
              const SizedBox(height: 12),
              _DatabaseSummary(payload: payload),
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
                title: '数据库列表',
                subtitle: '查看面板已接入的数据库及其基础信息。',
              ),
              const SizedBox(height: 12),
              if (payload.isEmpty)
                const PanelModuleEmptyCard(
                  icon: Icons.storage_outlined,
                  title: '当前没有数据库',
                  subtitle: '当前服务器暂无数据库记录。',
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
                                  item.database.isEmpty
                                      ? item.name
                                      : item.database,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                              StatusChip(
                                label: _sourceLabel(item.from),
                                color: item.from.toLowerCase() == 'local'
                                    ? const Color(0xFF1D7D5A)
                                    : const Color(0xFF3A6996),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          PanelModuleInfoRow(
                            label: '数据库名',
                            value: PanelValueFormatters.optionalText(
                                item.database),
                          ),
                          PanelModuleInfoRow(
                            label: '实例名',
                            value: PanelValueFormatters.optionalText(item.name),
                          ),
                          PanelModuleInfoRow(
                            label: '来源',
                            value: _sourceLabel(item.from),
                          ),
                          PanelModuleInfoRow(
                            label: '编号',
                            value: '${item.id}',
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

  String _sourceLabel(String source) {
    switch (source.toLowerCase()) {
      case 'local':
        return '本地';
      case 'remote':
        return '远程';
      default:
        return source.isEmpty ? '未知' : source;
    }
  }
}

class _DatabaseSummary extends StatelessWidget {
  const _DatabaseSummary({
    required this.payload,
  });

  final PanelPagedPayload<PanelDatabaseItem> payload;

  @override
  Widget build(BuildContext context) {
    final local = payload.items
        .where((item) => item.from.toLowerCase() == 'local')
        .length;
    final remote = payload.items
        .where((item) => item.from.toLowerCase() == 'remote')
        .length;

    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.28,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        PanelModuleMetricCard(
          label: '总记录',
          value: '${payload.total}',
          color: const Color(0xFF1D7D5A),
        ),
        PanelModuleMetricCard(
          label: '本地',
          value: '$local',
          color: const Color(0xFF3A6996),
        ),
        PanelModuleMetricCard(
          label: '远程',
          value: '$remote',
          color: const Color(0xFFD17F14),
        ),
      ],
    );
  }
}
