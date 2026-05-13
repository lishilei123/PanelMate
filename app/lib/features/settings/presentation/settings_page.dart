import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../app/panel_gradient_theme.dart';
import '../../../core/panel/models/server_connection_profile.dart';
import '../../../core/panel/runtime/panel_server_runtime_state.dart';
import '../../../core/panel/storage/panel_app_settings_repository.dart';
import '../../../shared/demo/panel_demo_catalog.dart';
import '../../../shared/widgets/panel_card.dart';

enum _CustomColorRole {
  primary,
  secondary,
  tertiary,
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.servers,
    required this.resolveRuntime,
    required this.pollingInterval,
    required this.onPollingIntervalChanged,
    required this.gradientThemeId,
    required this.gradientTheme,
    required this.customGradientTheme,
    required this.securitySettings,
    required this.onGradientThemeChanged,
    required this.onCustomGradientThemeChanged,
    required this.onSecuritySettingsChanged,
  });

  final List<PanelServerConnectionProfile> servers;
  final PanelServerRuntimeState? Function(PanelServerConnectionProfile server)
      resolveRuntime;
  final String pollingInterval;
  final Future<void> Function(String value) onPollingIntervalChanged;
  final String gradientThemeId;
  final PanelGradientTheme gradientTheme;
  final PanelGradientTheme customGradientTheme;
  final PanelSecuritySettings securitySettings;
  final Future<void> Function(String value) onGradientThemeChanged;
  final Future<void> Function(PanelGradientTheme gradientTheme)
      onCustomGradientThemeChanged;
  final Future<void> Function(PanelSecuritySettings settings)
      onSecuritySettingsChanged;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Future<void> _handleSecuritySettingsChange(
    PanelSecuritySettings settings,
  ) async {
    try {
      await widget.onSecuritySettingsChanged(settings);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('安全设置已更新')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存安全设置失败：$error')),
      );
    }
  }

  Future<void> _openAutoLockIntervalSheet() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return _AutoLockIntervalSheet(
          selectedInterval: widget.securitySettings.autoLockInterval,
        );
      },
    );

    if (result == null) {
      return;
    }

    await _handleSecuritySettingsChange(
      widget.securitySettings.copyWith(autoLockInterval: result),
    );
  }

  Future<void> _handleGradientThemeSelection(
    PanelGradientTheme gradientTheme,
  ) async {
    if (widget.gradientThemeId == gradientTheme.id) {
      return;
    }

    try {
      await widget.onGradientThemeChanged(gradientTheme.id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('主题已切换为 ${gradientTheme.label}')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存主题设置失败：$error')),
      );
    }
  }

  Future<void> _handleCustomGradientThemeSelection(
    PanelGradientTheme gradientTheme,
  ) async {
    try {
      await widget.onCustomGradientThemeChanged(gradientTheme);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('自定义主题已应用')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存自定义主题失败：$error')),
      );
    }
  }

  Future<void> _openCustomGradientThemePalette() async {
    final result = await showModalBottomSheet<PanelGradientTheme>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.18),
      builder: (context) {
        return _CustomGradientThemeSheet(
          initialTheme: widget.customGradientTheme,
        );
      },
    );

    if (result == null) {
      return;
    }
    await _handleCustomGradientThemeSelection(result);
  }

  Future<void> _openGradientThemePalette() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.18),
      builder: (sheetContext) {
        return _GradientThemePaletteSheet(
          selectedThemeId: widget.gradientThemeId,
          customGradientTheme: widget.customGradientTheme,
          onSelect: (gradientTheme) {
            Navigator.of(sheetContext).pop();
            unawaited(_handleGradientThemeSelection(gradientTheme));
          },
          onCustomize: () {
            Navigator.of(sheetContext).pop();
            unawaited(_openCustomGradientThemePalette());
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final snapshots = widget.servers
        .map(
          (server) => PanelDemoCatalog.snapshotFor(
            server,
            runtime: widget.resolveRuntime(server),
          ),
        )
        .toList(growable: false);
    final onlineCount = snapshots.where((item) => item.isOnline).length;
    final riskCount = snapshots
        .where(
          (item) =>
              item.health == PanelServerHealth.warning ||
              item.health == PanelServerHealth.critical ||
              item.health == PanelServerHealth.offline,
        )
        .length;
    final currentGradientTheme = widget.gradientTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        PanelCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.shield_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PanelMate',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '移动端巡检与轻量运维设置',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFF647181),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _HeaderStat(
                      label: '已接入',
                      value: '${widget.servers.length}',
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Expanded(
                    child: _HeaderStat(
                      label: '在线',
                      value: '$onlineCount',
                      color: const Color(0xFF1D7D5A),
                    ),
                  ),
                  Expanded(
                    child: _HeaderStat(
                      label: '异常',
                      value: '$riskCount',
                      color: riskCount == 0
                          ? const Color(0xFF647181)
                          : const Color(0xFFC44848),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const _SectionTitle(
          title: '主题样式',
          subtitle: '渐变背景与主色方案。',
        ),
        const SizedBox(height: 12),
        PanelCard(
          padding: EdgeInsets.zero,
          child: _CurrentGradientThemeTile(
            gradientTheme: currentGradientTheme,
            onTap: _openGradientThemePalette,
          ),
        ),
        const SizedBox(height: 18),
        const _SectionTitle(
          title: '安全设置',
          subtitle: '凭证走安全存储，业务数据不落地。',
        ),
        const SizedBox(height: 12),
        PanelCard(
          child: Column(
            children: [
              SwitchListTile.adaptive(
                key: const ValueKey('settings.app_lock'),
                contentPadding: EdgeInsets.zero,
                value: widget.securitySettings.appLockEnabled,
                onChanged: (value) {
                  unawaited(
                    _handleSecuritySettingsChange(
                      widget.securitySettings.copyWith(appLockEnabled: value),
                    ),
                  );
                },
                title: const Text('启用应用锁'),
                subtitle: const Text('应用闲置或从后台返回后显示锁定遮罩'),
              ),
              const Divider(),
              SwitchListTile.adaptive(
                key: const ValueKey('settings.background_blur'),
                contentPadding: EdgeInsets.zero,
                value: widget.securitySettings.backgroundBlurEnabled,
                onChanged: (value) {
                  unawaited(
                    _handleSecuritySettingsChange(
                      widget.securitySettings.copyWith(
                        backgroundBlurEnabled: value,
                      ),
                    ),
                  );
                },
                title: const Text('后台自动模糊'),
                subtitle: const Text('应用切到后台或任务切换时隐藏敏感信息'),
              ),
              const Divider(),
              ListTile(
                key: const ValueKey('settings.auto_lock_interval'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.timer_outlined),
                title: const Text('自动锁定时间'),
                subtitle: Text(
                  _autoLockIntervalDescription(
                    widget.securitySettings.autoLockInterval,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _openAutoLockIntervalSheet,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const _SectionTitle(
          title: '轮询设置',
          subtitle: '控制前台实时数据的刷新节奏。',
        ),
        const SizedBox(height: 12),
        PanelCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '前台轮询间隔',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final option
                      in PanelAppSettingsRepository.supportedPollingIntervals)
                    _PollingChip(
                      label: option,
                      selected: widget.pollingInterval == option,
                      onTap: () {
                        unawaited(widget.onPollingIntervalChanged(option));
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const _SectionTitle(
          title: '帮助与产品信息',
          subtitle: '版本、说明和服务器管理摘要。',
        ),
        const SizedBox(height: 12),
        PanelCard(
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.dns_outlined),
                title: const Text('服务器管理'),
                subtitle: Text('当前已接入 ${widget.servers.length} 台服务器'),
              ),
              const Divider(),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.description_outlined),
                title: Text('产品说明'),
                subtitle: Text('纯前端 Flutter 项目，直接调用 1Panel V2 API'),
              ),
              const Divider(),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.info_outline),
                title: Text('版本信息'),
                subtitle: Text('PanelMate 0.1.0+1'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _autoLockIntervalDescription(String value) {
  switch (PanelAppSettingsRepository.normalizeAutoLockInterval(value)) {
    case PanelAppSettingsRepository.disabledAutoLockInterval:
      return '关闭';
    case '1m':
      return '1 分钟无操作后锁定';
    case '5m':
      return '5 分钟无操作后锁定';
    case '15m':
      return '15 分钟无操作后锁定';
    case '30m':
      return '30 分钟无操作后锁定';
    default:
      return '5 分钟无操作后锁定';
  }
}

class _AutoLockIntervalSheet extends StatelessWidget {
  const _AutoLockIntervalSheet({
    required this.selectedInterval,
  });

  final String selectedInterval;

  @override
  Widget build(BuildContext context) {
    final selected =
        PanelAppSettingsRepository.normalizeAutoLockInterval(selectedInterval);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '自动锁定时间',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '应用锁开启后，前台闲置或从后台返回超过设定时间会显示锁定遮罩。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF66717F),
                  ),
            ),
            const SizedBox(height: 12),
            for (final option
                in PanelAppSettingsRepository.supportedAutoLockIntervals)
              ListTile(
                key: ValueKey('settings.auto_lock_interval.$option'),
                contentPadding: EdgeInsets.zero,
                title: Text(_autoLockIntervalDescription(option)),
                trailing: selected == option
                    ? Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () => Navigator.of(context).pop(option),
              ),
          ],
        ),
      ),
    );
  }
}

class _CurrentGradientThemeTile extends StatelessWidget {
  const _CurrentGradientThemeTile({
    required this.gradientTheme,
    required this.onTap,
  });

  final PanelGradientTheme gradientTheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const ValueKey('settings.open_gradient_theme_palette'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            _GradientThemePreview(
              gradientTheme: gradientTheme,
              height: 44,
              width: 56,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '渐变主题',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    gradientTheme.label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF60717B),
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.palette_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Color(0xFF6A7584)),
          ],
        ),
      ),
    );
  }
}

class _GradientThemePaletteSheet extends StatelessWidget {
  const _GradientThemePaletteSheet({
    required this.selectedThemeId,
    required this.customGradientTheme,
    required this.onSelect,
    required this.onCustomize,
  });

  final String selectedThemeId;
  final PanelGradientTheme customGradientTheme;
  final ValueChanged<PanelGradientTheme> onSelect;
  final VoidCallback onCustomize;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.72;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Material(
              color: Colors.white.withValues(alpha: 0.76),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF8AA0A7,
                            ).withValues(alpha: 0.40),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '选择主题',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          IconButton(
                            tooltip: '关闭',
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          const spacing = 10.0;
                          final columns = constraints.maxWidth >= 460 ? 3 : 2;
                          final itemWidth =
                              (constraints.maxWidth - spacing * (columns - 1)) /
                                  columns;

                          return Wrap(
                            spacing: spacing,
                            runSpacing: spacing,
                            children: [
                              for (final gradientTheme
                                  in PanelGradientTheme.builtIns)
                                SizedBox(
                                  width: itemWidth,
                                  child: _GradientThemeOption(
                                    gradientTheme: gradientTheme,
                                    selected:
                                        selectedThemeId == gradientTheme.id,
                                    onTap: () => onSelect(gradientTheme),
                                  ),
                                ),
                              SizedBox(
                                width: itemWidth,
                                child: _GradientThemeOption(
                                  gradientTheme: customGradientTheme,
                                  selected: selectedThemeId ==
                                      PanelGradientTheme.customId,
                                  onTap: onCustomize,
                                  actionIcon: Icons.tune_outlined,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientThemeOption extends StatelessWidget {
  const _GradientThemeOption({
    required this.gradientTheme,
    required this.selected,
    required this.onTap,
    this.actionIcon,
  });

  final PanelGradientTheme gradientTheme;
  final bool selected;
  final VoidCallback onTap;
  final IconData? actionIcon;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Ink(
          key: ValueKey('settings.gradient_theme.${gradientTheme.id}'),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.10)
                : Colors.white.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.34)
                  : Colors.white.withValues(alpha: 0.58),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GradientThemePreview(
                gradientTheme: gradientTheme,
                height: 58,
                selected: selected,
                actionIcon: actionIcon,
              ),
              const SizedBox(height: 9),
              Text(
                gradientTheme.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: selected ? color : const Color(0xFF1F3842),
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                gradientTheme.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF60717B),
                      height: 1.25,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradientThemePreview extends StatelessWidget {
  const _GradientThemePreview({
    required this.gradientTheme,
    required this.height,
    this.width,
    this.selected = false,
    this.actionIcon,
  });

  final PanelGradientTheme gradientTheme;
  final double height;
  final double? width;
  final bool selected;
  final IconData? actionIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientTheme.backgroundColors,
          stops: gradientTheme.backgroundStops,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientTheme.accentColors,
                  stops: const [0.0, 0.55, 1.0],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          if (selected)
            Positioned(
              top: 6,
              right: 6,
              child: Icon(
                Icons.check_circle,
                size: 20,
                color: gradientTheme.primary,
              ),
            ),
          if (!selected && actionIcon != null)
            Positioned(
              top: 6,
              right: 6,
              child: Icon(
                actionIcon,
                size: 19,
                color: gradientTheme.primary,
              ),
            ),
        ],
      ),
    );
  }
}

class _CustomGradientThemeSheet extends StatefulWidget {
  const _CustomGradientThemeSheet({
    required this.initialTheme,
  });

  final PanelGradientTheme initialTheme;

  @override
  State<_CustomGradientThemeSheet> createState() =>
      _CustomGradientThemeSheetState();
}

class _CustomGradientThemeSheetState extends State<_CustomGradientThemeSheet> {
  static const List<Color> _swatches = <Color>[
    Color(0xFF168F8F),
    Color(0xFF0EA5A6),
    Color(0xFF14B8A6),
    Color(0xFF22C55E),
    Color(0xFF84CC16),
    Color(0xFF2E8F69),
    Color(0xFF1677A3),
    Color(0xFF2563EB),
    Color(0xFF55A8D7),
    Color(0xFF7C3AED),
    Color(0xFF9333EA),
    Color(0xFFDB2777),
    Color(0xFFFF8A5C),
    Color(0xFFFF9C6E),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF64748B),
    Color(0xFF334155),
  ];

  late Color _primary;
  late Color _secondary;
  late Color _tertiary;
  _CustomColorRole _selectedRole = _CustomColorRole.primary;

  @override
  void initState() {
    super.initState();
    _primary = widget.initialTheme.primary;
    _secondary = widget.initialTheme.secondary;
    _tertiary = widget.initialTheme.tertiary;
  }

  PanelGradientTheme get _previewTheme {
    return PanelGradientTheme.custom(
      primary: _primary,
      secondary: _secondary,
      tertiary: _tertiary,
    );
  }

  Color get _selectedColor {
    return switch (_selectedRole) {
      _CustomColorRole.primary => _primary,
      _CustomColorRole.secondary => _secondary,
      _CustomColorRole.tertiary => _tertiary,
    };
  }

  void _updateSelectedColor(Color color) {
    setState(() {
      switch (_selectedRole) {
        case _CustomColorRole.primary:
          _primary = color;
        case _CustomColorRole.secondary:
          _secondary = color;
        case _CustomColorRole.tertiary:
          _tertiary = color;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.82;
    final previewTheme = _previewTheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Material(
              color: Colors.white.withValues(alpha: 0.78),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF8AA0A7,
                            ).withValues(alpha: 0.40),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '自定义主题',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          IconButton(
                            tooltip: '关闭',
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _GradientThemePreview(
                        gradientTheme: previewTheme,
                        height: 96,
                      ),
                      const SizedBox(height: 14),
                      SegmentedButton<_CustomColorRole>(
                        segments: const [
                          ButtonSegment<_CustomColorRole>(
                            value: _CustomColorRole.primary,
                            label: Text('主色'),
                          ),
                          ButtonSegment<_CustomColorRole>(
                            value: _CustomColorRole.secondary,
                            label: Text('辅色'),
                          ),
                          ButtonSegment<_CustomColorRole>(
                            value: _CustomColorRole.tertiary,
                            label: Text('点缀'),
                          ),
                        ],
                        selected: {_selectedRole},
                        onSelectionChanged: (selection) {
                          setState(() => _selectedRole = selection.first);
                        },
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final color in _swatches)
                            _ColorSwatchButton(
                              color: color,
                              selected:
                                  color.toARGB32() == _selectedColor.toARGB32(),
                              onTap: () => _updateSelectedColor(color),
                            ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          key: const ValueKey(
                            'settings.apply_custom_gradient_theme',
                          ),
                          onPressed: () =>
                              Navigator.of(context).pop(previewTheme),
                          icon: const Icon(Icons.check),
                          label: const Text('应用自定义主题'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorSwatchButton extends StatelessWidget {
  const _ColorSwatchButton({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Ink(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.onSurface
                  : Colors.white.withValues(alpha: 0.72),
              width: selected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.20),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: selected
              ? const Icon(Icons.check, color: Colors.white, size: 20)
              : null,
        ),
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF647181),
                  ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PollingChip extends StatelessWidget {
  const _PollingChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.24)
                : Colors.white.withValues(alpha: 0.50),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : const Color(0xFF5F6978),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
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
