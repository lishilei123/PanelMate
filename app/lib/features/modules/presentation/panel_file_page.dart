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

class PanelFilePage extends StatefulWidget {
  const PanelFilePage({
    super.key,
    required this.server,
    this.service = const PanelModuleService(),
  });

  final PanelServerConnectionProfile server;
  final PanelModuleService service;

  @override
  State<PanelFilePage> createState() => _PanelFilePageState();
}

class _PanelFilePageState extends State<PanelFilePage> {
  final TextEditingController _pathController =
      TextEditingController(text: '/opt/1panel');

  PanelFileDirectoryData? _directory;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _load({String? path}) async {
    final resolvedPath = (path ?? _pathController.text).trim();
    if (resolvedPath.isEmpty) {
      return;
    }

    _pathController.text = resolvedPath;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final directory = await widget.service.loadDirectory(
        widget.server,
        path: resolvedPath,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _directory = directory;
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

  Future<void> _openFile(PanelFileEntry entry) async {
    if (entry.isDir) {
      await _load(path: entry.path);
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return FutureBuilder<PanelFileContentData>(
          future: widget.service.loadFileContent(
            widget.server,
            path: entry.path,
          ),
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

            final content = snapshot.data!;
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 8,
                  bottom: 20 + MediaQuery.of(context).padding.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      content.path,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF66717F),
                          ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '大小 ${PanelValueFormatters.bytes(content.size)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        Text(
                          PanelValueFormatters.dateTime(content.modTime),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: const Color(0xFF66717F),
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.55,
                      child: SingleChildScrollView(
                        child: SelectableText(
                          content.content.isEmpty ? '(空文件)' : content.content,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontFamily: 'monospace',
                                    height: 1.45,
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final directory = _directory;

    return Scaffold(
      appBar: AppBar(
        title: const Text('文件'),
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
            if (_isLoading && directory == null)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null && directory == null)
              PanelModuleErrorCard(
                message: _errorMessage!,
                onRetry: () => _load(),
              )
            else ...[
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(),
                ),
              const PanelModuleSectionTitle(
                title: '文件浏览',
                subtitle: '真实读取文件搜索与文件内容接口，当前只提供只读浏览。',
              ),
              const SizedBox(height: 12),
              PanelCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _pathController,
                      decoration: InputDecoration(
                        hintText: '输入服务器路径，例如 /opt/1panel',
                        suffixIcon: IconButton(
                          onPressed: () => _load(path: _pathController.text),
                          icon: const Icon(Icons.arrow_forward),
                        ),
                      ),
                      onSubmitted: (value) => _load(path: value),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final path in const <String>[
                          '/',
                          '/opt',
                          '/opt/1panel',
                          '/opt/1panel/www',
                        ])
                          ActionChip(
                            label: Text(path),
                            onPressed: () => _load(path: path),
                          ),
                      ],
                    ),
                    if (directory != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '当前目录 ${directory.path}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          if (_parentPath(directory.path) != null)
                            TextButton.icon(
                              onPressed: () => _load(
                                path: _parentPath(directory.path),
                              ),
                              icon: const Icon(Icons.arrow_upward),
                              label: const Text('上一级'),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
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
              if (directory != null) ...[
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.7,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    PanelModuleMetricCard(
                      label: '当前条目',
                      value: '${directory.itemTotal}',
                      color: const Color(0xFF1D7D5A),
                    ),
                    PanelModuleMetricCard(
                      label: '目录',
                      value:
                          '${directory.items.where((item) => item.isDir).length}',
                      color: const Color(0xFF3A6996),
                    ),
                    PanelModuleMetricCard(
                      label: '文件',
                      value:
                          '${directory.items.where((item) => !item.isDir).length}',
                      color: const Color(0xFFD17F14),
                    ),
                    PanelModuleMetricCard(
                      label: '最后修改',
                      value:
                          PanelValueFormatters.relativeTime(directory.modTime),
                      color: const Color(0xFF0E7C86),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const PanelModuleSectionTitle(
                  title: '目录内容',
                  subtitle: '点击目录继续下钻，点击文件读取文本内容。',
                ),
                const SizedBox(height: 12),
                if (directory.items.isEmpty)
                  const PanelModuleEmptyCard(
                    icon: Icons.folder_open_outlined,
                    title: '目录为空',
                    subtitle: '当前目录没有返回任何文件或子目录。',
                  )
                else
                  ...directory.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => _openFile(item),
                        child: PanelCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    item.isDir
                                        ? Icons.folder_outlined
                                        : Icons.description_outlined,
                                    color: item.isDir
                                        ? const Color(0xFF3A6996)
                                        : const Color(0xFF66717F),
                                  ),
                                  const SizedBox(width: 10),
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
                                  if (item.isHidden)
                                    const StatusChip(
                                      label: '隐藏',
                                      color: Color(0xFFD17F14),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              PanelModuleInfoRow(
                                label: '路径',
                                value: item.path,
                              ),
                              PanelModuleInfoRow(
                                label: '权限',
                                value:
                                    '${item.mode}  ${item.user}:${item.group}',
                              ),
                              PanelModuleInfoRow(
                                label: '大小',
                                value: item.isDir
                                    ? '目录'
                                    : PanelValueFormatters.bytes(item.size),
                              ),
                              PanelModuleInfoRow(
                                label: '修改时间',
                                value:
                                    PanelValueFormatters.dateTime(item.modTime),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  String? _parentPath(String path) {
    if (path == '/' || path.isEmpty) {
      return null;
    }

    final normalized = path.endsWith('/') && path.length > 1
        ? path.substring(0, path.length - 1)
        : path;
    final index = normalized.lastIndexOf('/');
    if (index <= 0) {
      return '/';
    }
    return normalized.substring(0, index);
  }
}
