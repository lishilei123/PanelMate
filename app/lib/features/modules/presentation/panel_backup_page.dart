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

class PanelBackupPage extends StatefulWidget {
  const PanelBackupPage({
    super.key,
    required this.server,
    this.service = const PanelModuleService(),
  });

  final PanelServerConnectionProfile server;
  final PanelModuleService service;

  @override
  State<PanelBackupPage> createState() => _PanelBackupPageState();
}

class _PanelBackupPageState extends State<PanelBackupPage> {
  PanelBackupPageData? _data;
  String? _errorMessage;
  String? _selectedType;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load({String? preferredType}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await widget.service.loadBackups(
        widget.server,
        preferredType: preferredType ?? _selectedType,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _data = data;
        _selectedType = data.recordType;
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
    final data = _data;

    return Scaffold(
      appBar: AppBar(
        title: const Text('备份'),
        actions: [
          IconButton(
            onPressed: () => _load(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            if (_isLoading && data == null)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null && data == null)
              PanelModuleErrorCard(
                message: _errorMessage!,
                onRetry: () => _load(),
              )
            else if (data != null) ...[
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(),
                ),
              const PanelModuleSectionTitle(
                title: '备份概览',
                subtitle: '查看备份账户与备份记录（当前为只读巡检页）。',
              ),
              const SizedBox(height: 12),
              _BackupSummary(data: data),
              const SizedBox(height: 18),
              if (data.recordWarning != null) ...[
                PanelCard(
                  child: Text(
                    data.recordWarning!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF8C3030),
                        ),
                  ),
                ),
                const SizedBox(height: 18),
              ],
              const PanelModuleSectionTitle(
                title: '备份账户',
                subtitle: '先展示备份账户配置，再展示对应类型的最近记录。',
              ),
              const SizedBox(height: 12),
              if (data.accounts.isEmpty)
                const PanelModuleEmptyCard(
                  icon: Icons.backup_outlined,
                  title: '当前没有备份账户',
                  subtitle: '当前服务器暂无备份账户。',
                )
              else ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final account in data.accounts.items)
                      ChoiceChip(
                        label: Text('${account.name} (${account.type})'),
                        selected: account.type == data.recordType,
                        onSelected: (_) => _load(preferredType: account.type),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                ...data.accounts.items.map(
                  (account) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: PanelCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  account.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                              StatusChip(
                                label: account.type,
                                color: const Color(0xFF3A6996),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          PanelModuleInfoRow(
                            label: '备份路径',
                            value: PanelValueFormatters.optionalText(
                              account.backupPath,
                            ),
                          ),
                          if (account.bucket.isNotEmpty)
                            PanelModuleInfoRow(
                              label: '存储桶',
                              value: account.bucket,
                            ),
                          PanelModuleInfoRow(
                            label: '公开访问',
                            value: account.isPublic ? '是' : '否',
                          ),
                          PanelModuleInfoRow(
                            label: '创建时间',
                            value: PanelValueFormatters.dateTime(
                                account.createdAt),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              PanelModuleSectionTitle(
                title: '最近记录',
                subtitle: data.recordType == null
                    ? '当前没有可查询的备份类型。'
                    : '当前筛选类型：${data.recordType}',
              ),
              const SizedBox(height: 12),
              if (data.records.isEmpty)
                const PanelModuleEmptyCard(
                  icon: Icons.history_outlined,
                  title: '当前没有备份记录',
                  subtitle: '当前类型还没有返回任何历史记录。',
                )
              else
                ...data.records.items.map(
                  (record) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: PanelCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  record.name.isEmpty ? '未命名记录' : record.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                              if (record.status.isNotEmpty)
                                StatusChip(
                                  label: _recordStatusLabel(record.status),
                                  color: _recordStatusColor(record.status),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          PanelModuleInfoRow(
                            label: '明细名',
                            value: PanelValueFormatters.optionalText(
                              record.detailName,
                            ),
                          ),
                          PanelModuleInfoRow(
                            label: '文件名',
                            value: PanelValueFormatters.optionalText(
                              record.fileName,
                            ),
                          ),
                          PanelModuleInfoRow(
                            label: '类型',
                            value:
                                PanelValueFormatters.optionalText(record.type),
                          ),
                          PanelModuleInfoRow(
                            label: '大小',
                            value: record.size == null
                                ? '-'
                                : PanelValueFormatters.bytes(record.size),
                          ),
                          PanelModuleInfoRow(
                            label: '时间',
                            value:
                                PanelValueFormatters.dateTime(record.createdAt),
                          ),
                          if (record.message.isNotEmpty)
                            PanelModuleInfoRow(
                              label: '消息',
                              value: record.message,
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

  Color _recordStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'done':
      case 'finished':
        return const Color(0xFF1D7D5A);
      case 'waiting':
      case 'running':
        return const Color(0xFFD17F14);
      default:
        return const Color(0xFFAF4A3D);
    }
  }

  String _recordStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'done':
      case 'finished':
        return '成功';
      case 'waiting':
      case 'running':
        return '进行中';
      case 'failed':
      case 'error':
        return '失败';
      default:
        return status.isEmpty ? '未知' : status;
    }
  }
}

class _BackupSummary extends StatelessWidget {
  const _BackupSummary({
    required this.data,
  });

  final PanelBackupPageData data;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.7,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        PanelModuleMetricCard(
          label: '账户数',
          value: '${data.accounts.total}',
          color: const Color(0xFF1D7D5A),
        ),
        PanelModuleMetricCard(
          label: '记录数',
          value: '${data.records.total}',
          color: const Color(0xFF3A6996),
        ),
        PanelModuleMetricCard(
          label: '当前类型',
          value: data.recordType ?? '-',
          color: const Color(0xFFD17F14),
        ),
        PanelModuleMetricCard(
          label: '公开账户',
          value: '${data.accounts.items.where((item) => item.isPublic).length}',
          color: const Color(0xFF0E7C86),
        ),
      ],
    );
  }
}
