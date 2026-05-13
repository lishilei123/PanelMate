import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/panel/models/panel_security_settings.dart';
import '../../../core/panel/storage/panel_app_settings_repository.dart';
import '../../../shared/widgets/panel_card.dart';

class PanelSecurityGate extends StatefulWidget {
  const PanelSecurityGate({
    super.key,
    required this.securitySettings,
    required this.child,
  });

  final PanelSecuritySettings securitySettings;
  final Widget child;

  @override
  State<PanelSecurityGate> createState() => _PanelSecurityGateState();
}

class _PanelSecurityGateState extends State<PanelSecurityGate>
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
  void didUpdateWidget(covariant PanelSecurityGate oldWidget) {
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
    if (widget.securitySettings.backgroundBlurEnabled &&
        !_privacyOverlayVisible) {
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
