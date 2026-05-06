import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/panel/models/panel_error_message_resolver.dart';
import '../../../core/panel/models/server_connection_profile.dart';
import '../../../shared/widgets/panel_card.dart';
import '../application/panel_module_service.dart';
import '../models/panel_module_models.dart';
import 'panel_module_widgets.dart';

class PanelWebsiteLogPage extends StatefulWidget {
  const PanelWebsiteLogPage({
    super.key,
    required this.server,
    required this.websiteId,
    required this.websiteLabel,
    this.service = const PanelModuleService(),
  });

  final PanelServerConnectionProfile server;
  final int websiteId;
  final String websiteLabel;
  final PanelModuleService service;

  @override
  State<PanelWebsiteLogPage> createState() => _PanelWebsiteLogPageState();
}

class _PanelWebsiteLogPageState extends State<PanelWebsiteLogPage> {
  static const _pageSizeOptions = <int>[100, 500, 1000, 2000];

  final ScrollController _scrollController = ScrollController();

  PanelWebsiteLogResult? _result;
  String? _errorMessage;
  bool _isLoading = true;
  String _logType = 'access';
  int _pageSize = 500;

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
      final result = await widget.service.loadWebsiteLog(
        widget.server,
        websiteId: widget.websiteId,
        logType: _logType,
        pageSize: _pageSize,
      );
      if (!mounted) return;

      setState(() {
        _result = result;
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
    final content = _result?.content;
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
    final result = _result;
    final hasContent = result != null && result.content.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text('日志 · ${widget.websiteLabel}'),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'access',
                  label: Text('访问日志'),
                  icon: Icon(Icons.swap_horiz_outlined),
                ),
                ButtonSegment(
                  value: 'error',
                  label: Text('错误日志'),
                  icon: Icon(Icons.error_outline),
                ),
              ],
              selected: <String>{_logType},
              onSelectionChanged: (selection) {
                final value = selection.first;
                if (value == _logType) return;
                setState(() => _logType = value);
                unawaited(_load());
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _PageSizeChip(
                  value: _pageSize,
                  options: _pageSizeOptions,
                  onChanged: (value) {
                    if (value == null || value == _pageSize) return;
                    setState(() => _pageSize = value);
                    unawaited(_load());
                  },
                ),
                if (result != null && result.path.isNotEmpty)
                  Text(
                    result.path,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF66717F),
                        ),
                  ),
              ],
            ),
          ),
          if (result != null && !result.enabled)
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 4, 12, 4),
              child: _LogDisabledBanner(),
            ),
          if (_isLoading && result == null)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_errorMessage != null && result == null)
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
                                  result.content,
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

class _PageSizeChip extends StatelessWidget {
  const _PageSizeChip({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final int value;
  final List<int> options;
  final ValueChanged<int?> onChanged;

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
            '行数  ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF66717F),
                ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value,
              isDense: true,
              items: options
                  .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                  .toList(growable: false),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _LogDisabledBanner extends StatelessWidget {
  const _LogDisabledBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: const [
          Icon(Icons.info_outline, size: 18, color: Color(0xFFD17F14)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '该站点未启用日志记录，下方内容可能为空或滞后。',
              style: TextStyle(color: Color(0xFF8C5E14), fontSize: 12),
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
