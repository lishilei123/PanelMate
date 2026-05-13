import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/panel/storage/panel_app_settings_repository.dart';
import '../core/panel/storage/panel_server_repository.dart';
import '../features/home/presentation/panel_home_shell_page.dart';
import '../shared/widgets/panel_card.dart';
import 'panel_gradient_theme.dart';
import 'panel_theme.dart';

class PanelMateApp extends StatefulWidget {
  const PanelMateApp({
    super.key,
    this.repository = const PanelServerRepository(),
    this.settingsRepository = const PanelAppSettingsRepository(),
  });

  final PanelServerRepository repository;
  final PanelAppSettingsRepository settingsRepository;

  @override
  State<PanelMateApp> createState() => _PanelMateAppState();
}

class _PanelMateAppState extends State<PanelMateApp> {
  String _gradientThemeId = PanelAppSettingsRepository.defaultGradientThemeId;
  PanelCustomGradientThemeColors _customGradientThemeColors =
      const PanelCustomGradientThemeColors(
    primaryValue: PanelAppSettingsRepository.defaultCustomGradientPrimaryValue,
    secondaryValue:
        PanelAppSettingsRepository.defaultCustomGradientSecondaryValue,
    tertiaryValue:
        PanelAppSettingsRepository.defaultCustomGradientTertiaryValue,
  );
  PanelSecuritySettings _securitySettings = const PanelSecuritySettings(
    appLockEnabled: PanelAppSettingsRepository.defaultAppLockEnabled,
    backgroundBlurEnabled:
        PanelAppSettingsRepository.defaultBackgroundBlurEnabled,
    autoLockInterval: PanelAppSettingsRepository.defaultAutoLockInterval,
  );

  @override
  void initState() {
    super.initState();
    _restoreGradientTheme();
    _restoreSecuritySettings();
  }

  Future<void> _restoreGradientTheme() async {
    late final String gradientThemeId;
    late final PanelCustomGradientThemeColors customGradientThemeColors;
    try {
      gradientThemeId = await widget.settingsRepository.loadGradientThemeId();
      customGradientThemeColors =
          await widget.settingsRepository.loadCustomGradientThemeColors();
    } catch (error, stackTrace) {
      debugPrint('[PanelMate] Failed to restore gradient theme: $error\n$stackTrace');
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _gradientThemeId = gradientThemeId;
      _customGradientThemeColors = customGradientThemeColors;
    });
  }

  Future<void> _restoreSecuritySettings() async {
    late final PanelSecuritySettings securitySettings;
    try {
      securitySettings = await widget.settingsRepository.loadSecuritySettings();
    } catch (error, stackTrace) {
      debugPrint(
        '[PanelMate] Failed to restore security settings: $error\n$stackTrace',
      );
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() => _securitySettings = securitySettings);
  }

  Future<void> _updateGradientTheme(String value) async {
    final normalizedValue =
        PanelAppSettingsRepository.normalizeGradientThemeId(value);
    if (_gradientThemeId == normalizedValue) {
      return;
    }

    final previousValue = _gradientThemeId;
    setState(() => _gradientThemeId = normalizedValue);
    try {
      await widget.settingsRepository.saveGradientThemeId(normalizedValue);
    } catch (_) {
      if (mounted) {
        setState(() => _gradientThemeId = previousValue);
      }
      rethrow;
    }
  }

  Future<void> _updateCustomGradientTheme(
      PanelGradientTheme gradientTheme) async {
    final nextColors = PanelCustomGradientThemeColors(
      primaryValue: gradientTheme.primary.toARGB32(),
      secondaryValue: gradientTheme.secondary.toARGB32(),
      tertiaryValue: gradientTheme.tertiary.toARGB32(),
    );
    final previousThemeId = _gradientThemeId;
    final previousColors = _customGradientThemeColors;

    setState(() {
      _gradientThemeId = PanelGradientTheme.customId;
      _customGradientThemeColors = nextColors;
    });

    try {
      await widget.settingsRepository.saveCustomGradientThemeColors(nextColors);
      await widget.settingsRepository.saveGradientThemeId(
        PanelGradientTheme.customId,
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _gradientThemeId = previousThemeId;
          _customGradientThemeColors = previousColors;
        });
      }
      rethrow;
    }
  }

  Future<void> _updateSecuritySettings(PanelSecuritySettings value) async {
    final normalizedValue = value.copyWith(
      autoLockInterval: PanelAppSettingsRepository.normalizeAutoLockInterval(
        value.autoLockInterval,
      ),
    );
    final previousValue = _securitySettings;
    setState(() => _securitySettings = normalizedValue);

    try {
      await widget.settingsRepository.saveSecuritySettings(normalizedValue);
    } catch (_) {
      if (mounted) {
        setState(() => _securitySettings = previousValue);
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final customGradientTheme = PanelGradientTheme.custom(
      primary: Color(_customGradientThemeColors.primaryValue),
      secondary: Color(_customGradientThemeColors.secondaryValue),
      tertiary: Color(_customGradientThemeColors.tertiaryValue),
    );
    final gradientTheme = PanelGradientTheme.resolve(
      _gradientThemeId,
      customTheme: customGradientTheme,
    );

    return MaterialApp(
      title: 'PanelMate',
      debugShowCheckedModeBanner: false,
      theme: PanelTheme.light(gradientTheme),
      builder: (context, child) {
        return _PanelGlassBackdrop(
          gradientTheme: gradientTheme,
          child: _PanelSecurityGate(
            securitySettings: _securitySettings,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      home: PanelHomeShellPage(
        repository: widget.repository,
        settingsRepository: widget.settingsRepository,
        gradientThemeId: _gradientThemeId,
        gradientTheme: gradientTheme,
        customGradientTheme: customGradientTheme,
        securitySettings: _securitySettings,
        onGradientThemeChanged: _updateGradientTheme,
        onCustomGradientThemeChanged: _updateCustomGradientTheme,
        onSecuritySettingsChanged: _updateSecuritySettings,
      ),
    );
  }
}

class _PanelSecurityGate extends StatefulWidget {
  const _PanelSecurityGate({
    required this.securitySettings,
    required this.child,
  });

  final PanelSecuritySettings securitySettings;
  final Widget child;

  @override
  State<_PanelSecurityGate> createState() => _PanelSecurityGateState();
}

class _PanelSecurityGateState extends State<_PanelSecurityGate>
    with WidgetsBindingObserver {
  Timer? _idleTimer;
  DateTime? _backgroundedAt;
  bool _privacyOverlayVisible = false;
  bool _locked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncIdleTimer();
  }

  @override
  void didUpdateWidget(covariant _PanelSecurityGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.securitySettings != widget.securitySettings) {
      if (!widget.securitySettings.backgroundBlurEnabled && !_locked) {
        _privacyOverlayVisible = false;
      }
      if (!widget.securitySettings.appLockEnabled && _locked) {
        _locked = false;
        _privacyOverlayVisible = false;
      }
      _syncIdleTimer();
    }
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _handleBackgrounded();
      case AppLifecycleState.resumed:
        _handleResumed();
    }
  }

  void _handleBackgrounded() {
    _backgroundedAt = DateTime.now();
    _idleTimer?.cancel();
    if (widget.securitySettings.backgroundBlurEnabled && !_privacyOverlayVisible) {
      setState(() => _privacyOverlayVisible = true);
    }
  }

  void _handleResumed() {
    final backgroundedAt = _backgroundedAt;
    final autoLockDuration = PanelAppSettingsRepository
        .durationForAutoLockInterval(widget.securitySettings.autoLockInterval);
    final shouldLock = widget.securitySettings.appLockEnabled &&
        backgroundedAt != null &&
        autoLockDuration != null &&
        DateTime.now().difference(backgroundedAt) >= autoLockDuration;

    if (_locked != shouldLock || _privacyOverlayVisible != shouldLock) {
      setState(() {
        _locked = shouldLock;
        _privacyOverlayVisible = shouldLock;
      });
    }
    _backgroundedAt = null;
    _syncIdleTimer();
  }

  void _handleUserInteraction() {
    if (_locked || !widget.securitySettings.appLockEnabled) {
      return;
    }
    if (PanelAppSettingsRepository.durationForAutoLockInterval(
          widget.securitySettings.autoLockInterval,
        ) ==
        null) {
      return;
    }
    _syncIdleTimer();
  }

  void _syncIdleTimer() {
    _idleTimer?.cancel();
    final autoLockDuration = PanelAppSettingsRepository
        .durationForAutoLockInterval(widget.securitySettings.autoLockInterval);
    if (!widget.securitySettings.appLockEnabled ||
        autoLockDuration == null ||
        _locked) {
      _idleTimer = null;
      return;
    }

    _idleTimer = Timer(autoLockDuration, () {
      if (!mounted || !widget.securitySettings.appLockEnabled) {
        return;
      }
      setState(() {
        _locked = true;
        _privacyOverlayVisible = true;
      });
    });
  }

  void _unlock() {
    setState(() {
      _locked = false;
      _privacyOverlayVisible = false;
    });
    _syncIdleTimer();
  }

  @override
  Widget build(BuildContext context) {
    final showOverlay = _privacyOverlayVisible || _locked;

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _handleUserInteraction(),
      onPointerSignal: (_) => _handleUserInteraction(),
      child: Stack(
        children: [
          widget.child,
          if (showOverlay)
            Positioned.fill(
              child: _PanelSecurityOverlay(
                locked: _locked,
                onUnlock: _locked ? _unlock : null,
              ),
            ),
        ],
      ),
    );
  }
}

class _PanelSecurityOverlay extends StatelessWidget {
  const _PanelSecurityOverlay({
    required this.locked,
    required this.onUnlock,
  });

  final bool locked;
  final VoidCallback? onUnlock;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: AbsorbPointer(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: ColoredBox(
                  color: const Color(0xFFEFFAF7).withValues(alpha: 0.88),
                ),
              ),
            ),
          ),
          Center(
            child: SizedBox(
              width: 300,
              child: PanelCard(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      locked
                          ? Icons.lock_outline
                          : Icons.visibility_off_outlined,
                      size: 42,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      locked ? 'PanelMate 已锁定' : '已隐藏敏感信息',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      locked
                          ? '应用长时间未操作或从后台返回，已显示锁定遮罩。'
                          : '应用处于后台或任务切换状态，敏感内容已被遮挡。',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF647181),
                          ),
                    ),
                    if (locked) ...[
                      const SizedBox(height: 18),
                      FilledButton(
                        key: const ValueKey('security_gate.continue'),
                        onPressed: onUnlock,
                        child: const Text('继续使用'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelGlassBackdrop extends StatelessWidget {
  const _PanelGlassBackdrop({
    required this.gradientTheme,
    required this.child,
  });

  final PanelGradientTheme gradientTheme;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientTheme.backgroundColors,
          stops: gradientTheme.backgroundStops,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientTheme.veilColors,
                  stops: const [0.0, 0.52, 1.0],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientTheme.accentColors,
                  stops: const [0.0, 0.55, 1.0],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
