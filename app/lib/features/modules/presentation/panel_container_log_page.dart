import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/panel/models/panel_error_message_resolver.dart';
import '../../../core/panel/models/server_connection_profile.dart';
import '../../../shared/widgets/panel_card.dart';
import '../application/panel_module_service.dart';
import 'panel_module_widgets.dart';

class PanelContainerLogPage extends StatefulWidget {
  const PanelContainerLogPage({
    super.key,
    required this.server,
    required this.containerName,
    this.service = const PanelModuleService(),
  });

  final PanelServerConnectionProfile server;
  final String containerName;
  final PanelModuleService service;

  @override
  State<PanelContainerLogPage> createState() => _PanelContainerLogPageState();
}

class _PanelContainerLogPageState extends State<PanelContainerLogPage> {
  static const _tailOptions = <int>[100, 500, 1000, 5000];
  static const _sinceOptions = <_SinceOption>[
    _SinceOption(label: '全部', value: null),
    _SinceOption(label: '近 5 分钟', value: '5m'),
    _SinceOption(label: '近 30 分钟', value: '30m'),
    _SinceOption(label: '近 1 小时', value: '1h'),
    _SinceOption(label: '近 24 小时', value: '24h'),
  ];

  final ScrollController _scrollController = ScrollController();

  String? _logContent;
  String? _errorMessage;
  bool _isLoading = true;
  int _tail = 500;
  String? _since;
  bool _showTimestamp = true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final content = await widget.service.loadContainerLog(
        widget.server,
        name: widget.containerName,
        tail: _tail,
        since: _since,
        timestamp: _showTimestamp,
      );
      if (!mounted) return;

      setState(() {
        _logContent = content;
        _isLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(
            _scrollController.position.maxScrollExtent,
          );
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = PanelErrorMessageResolver.resolve(error);
        _isLoading = false;
      });
    }
  }

  Future<void> _copyAll() async {
    final content = _logContent;
    if (content == null || content.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: content));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('日志已复制到剪贴板。')),
    );
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = _logContent;
    final hasContent = content != null && content.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text('日志 · ${widget.containerName}'),
        actions: [
          IconButton(
            tooltip: '复制全部',
            onPressed: hasContent ? _copyAll : null,
            icon: const Icon(Icons.copy_outlined),
          ),
          IconButton(
            tooltip: '刷新',
            onPressed: _isLoading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: hasContent
          ? FloatingActionButton.small(
              onPressed: _scrollToBottom,
              tooltip: '滚到底部',
              child: const Icon(Icons.vertical_align_bottom),
            )
          : null,
      body: Column(
        children: [
          _FilterBar(
            tail: _tail,
            tailOptions: _tailOptions,
            since: _since,
            sinceOptions: _sinceOptions,
            showTimestamp: _showTimestamp,
            onTailChanged: (value) {
              if (value == null || value == _tail) return;
              setState(() => _tail = value);
              unawaited(_load());
            },
            onSinceChanged: (value) {
              if (value == _since) return;
              setState(() => _since = value);
              unawaited(_load());
            },
            onTimestampChanged: (value) {
              if (value == _showTimestamp) return;
              setState(() => _showTimestamp = value);
              unawaited(_load());
            },
          ),
          if (_isLoading && content == null)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_errorMessage != null && content == null)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: PanelModuleErrorCard(
                  message: _errorMessage!,
                  onRetry: _load,
                ),
              ),
            )
          else
            Expanded(
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                    child: PanelCard(
                      padding: const EdgeInsets.all(12),
                      child: hasContent
                          ? Scrollbar(
                              controller: _scrollController,
                              child: SingleChildScrollView(
                                controller: _scrollController,
                                child: SelectableText(
                                  content,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                    height: 1.45,
                                    color: Color(0xFF24303F),
                                  ),
                                ),
                              ),
                            )
                          : const _EmptyLogHint(),
                    ),
                  ),
                  if (_isLoading)
                    const Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.tail,
    required this.tailOptions,
    required this.since,
    required this.sinceOptions,
    required this.showTimestamp,
    required this.onTailChanged,
    required this.onSinceChanged,
    required this.onTimestampChanged,
  });

  final int tail;
  final List<int> tailOptions;
  final String? since;
  final List<_SinceOption> sinceOptions;
  final bool showTimestamp;
  final ValueChanged<int?> onTailChanged;
  final ValueChanged<String?> onSinceChanged;
  final ValueChanged<bool> onTimestampChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _DropdownChip<int>(
            label: '行数',
            value: tail,
            items: tailOptions
                .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                .toList(growable: false),
            onChanged: onTailChanged,
          ),
          _DropdownChip<String?>(
            label: '范围',
            value: since,
            items: sinceOptions
                .map(
                  (option) => DropdownMenuItem<String?>(
                    value: option.value,
                    child: Text(option.label),
                  ),
                )
                .toList(growable: false),
            onChanged: onSinceChanged,
          ),
          FilterChip(
            label: const Text('显示时间戳'),
            selected: showTimestamp,
            onSelected: onTimestampChanged,
          ),
        ],
      ),
    );
  }
}

class _DropdownChip<T> extends StatelessWidget {
  const _DropdownChip({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label  ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF66717F),
                ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isDense: true,
              items: items,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyLogHint extends StatelessWidget {
  const _EmptyLogHint();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.notes_outlined,
            size: 36,
            color: Color(0xFF8A95A4),
          ),
          const SizedBox(height: 8),
          Text(
            '当前条件下没有返回任何日志。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF66717F),
                ),
          ),
        ],
      ),
    );
  }
}

class _SinceOption {
  const _SinceOption({required this.label, required this.value});
  final String label;
  final String? value;
}
