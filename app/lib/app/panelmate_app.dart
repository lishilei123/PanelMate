import 'package:flutter/material.dart';

import '../core/panel/models/panel_custom_gradient_theme_colors.dart';
import '../core/panel/models/panel_security_settings.dart';
import '../core/panel/storage/panel_app_settings_repository.dart';
import '../core/panel/storage/panel_server_repository.dart';
import '../features/home/presentation/panel_home_shell_page.dart';
import '../features/security/presentation/panel_security_gate.dart';
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
    final idFuture = widget.settingsRepository.loadGradientThemeId();
    final colorsFuture = widget.settingsRepository.loadCustomGradientThemeColors();
    late final String gradientThemeId;
    late final PanelCustomGradientThemeColors customGradientThemeColors;
    try {
      gradientThemeId = await idFuture;
      customGradientThemeColors = await colorsFuture;
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
      await Future.wait<void>([
        widget.settingsRepository.saveCustomGradientThemeColors(nextColors),
        widget.settingsRepository.saveGradientThemeId(
          PanelGradientTheme.customId,
        ),
      ]);
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
          child: PanelSecurityGate(
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
