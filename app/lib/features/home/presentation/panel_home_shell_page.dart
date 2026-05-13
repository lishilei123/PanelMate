import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../app/panel_gradient_theme.dart';
import '../../../core/panel/models/panel_error_message_resolver.dart';
import '../../../core/panel/models/panel_security_settings.dart';
import '../../../core/panel/models/server_connection_profile.dart';
import '../../../core/panel/runtime/panel_runtime_service.dart';
import '../../../core/panel/runtime/panel_server_runtime_state.dart';
import '../../../core/panel/storage/panel_app_settings_repository.dart';
import '../../../core/panel/storage/panel_server_repository.dart';
import '../../ai/presentation/ai_page.dart';
import '../../overview/presentation/overview_page.dart';
import '../../servers/presentation/add_server_page.dart';
import '../../servers/presentation/server_detail_page.dart';
import '../../settings/presentation/settings_page.dart';

class PanelHomeShellPage extends StatefulWidget {
  const PanelHomeShellPage({
    super.key,
    this.repository = const PanelServerRepository(),
    this.settingsRepository = const PanelAppSettingsRepository(),
    required this.gradientThemeId,
    required this.gradientTheme,
    required this.customGradientTheme,
    required this.securitySettings,
    required this.onGradientThemeChanged,
    required this.onCustomGradientThemeChanged,
    required this.onSecuritySettingsChanged,
  });

  final PanelServerRepository repository;
  final PanelAppSettingsRepository settingsRepository;
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
  State<PanelHomeShellPage> createState() => _PanelHomeShellPageState();
}

class _PanelHomeShellPageState extends State<PanelHomeShellPage> {
  static const PanelRuntimeService _runtimeService = PanelRuntimeService();

  int _currentIndex = 0;
  bool _isRestoringServers = true;
  bool _isAutoRefreshing = false;
  String _pollingInterval = PanelAppSettingsRepository.defaultPollingInterval;
  final Map<String, PanelServerRuntimeState> _runtimeByServer =
      <String, PanelServerRuntimeState>{};
  final Set<String> _refreshingServerKeys = <String>{};

  late final List<PanelServerConnectionProfile> _servers =
      <PanelServerConnectionProfile>[];
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    unawaited(_restoreServers());
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isRestoringServers) {
      return const Scaffold(
        body: SafeArea(
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    final pages = <Widget>[
      OverviewPage(
        servers: _servers,
        onAddServer: _openAddServerPage,
        onEditServer: _openEditServerPage,
        onOpenServer: _openServerDetail,
        onRemoveServer: _removeServer,
        resolveRuntime: _resolveRuntime,
      ),
      const AiPage(),
      SettingsPage(
        servers: _servers,
        resolveRuntime: _resolveRuntime,
        pollingInterval: _pollingInterval,
        onPollingIntervalChanged: _updatePollingInterval,
        gradientThemeId: widget.gradientThemeId,
        gradientTheme: widget.gradientTheme,
        customGradientTheme: widget.customGradientTheme,
        securitySettings: widget.securitySettings,
        onGradientThemeChanged: widget.onGradientThemeChanged,
        onCustomGradientThemeChanged: widget.onCustomGradientThemeChanged,
        onSecuritySettingsChanged: widget.onSecuritySettingsChanged,
      ),
    ];

    return Scaffold(
      body: SafeArea(child: pages[_currentIndex]),
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.78),
                  const Color(0xFFF1FFFC).withValues(alpha: 0.60),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.78)),
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: NavigationBar(
              height: 68,
              backgroundColor: Colors.transparent,
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() => _currentIndex = index);
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  label: '概览',
                ),
                NavigationDestination(
                  icon: Icon(Icons.auto_awesome_outlined),
                  label: 'AI',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  label: '我的',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openAddServerPage() async {
    final result =
        await Navigator.of(context).push<PanelServerConnectionProfile>(
      MaterialPageRoute(
        builder: (_) => const AddServerPage(),
      ),
    );

    if (result == null) {
      return;
    }

    final key = _serverKey(result);
    setState(() {
      _servers.removeWhere((server) => _serverKey(server) == key);
      _servers.insert(0, result);
      _currentIndex = 0;
    });

    await _persistServers();
    await _refreshServer(result, showSuccessMessage: true);
  }

  Future<void> _openEditServerPage(
    PanelServerConnectionProfile server,
  ) async {
    final originalKey = _serverKey(server);
    final result =
        await Navigator.of(context).push<PanelServerConnectionProfile>(
      MaterialPageRoute(
        builder: (_) => AddServerPage(initialServer: server),
      ),
    );

    if (result == null) {
      return;
    }

    final nextKey = _serverKey(result);
    final updatedServers = List<PanelServerConnectionProfile>.of(_servers);
    final hadDuplicateTarget = updatedServers.any(
      (item) => _serverKey(item) == nextKey && _serverKey(item) != originalKey,
    );

    updatedServers.removeWhere(
      (item) => _serverKey(item) == nextKey && _serverKey(item) != originalKey,
    );

    final replaceIndex = updatedServers.indexWhere(
      (item) => _serverKey(item) == originalKey,
    );
    if (replaceIndex == -1) {
      return;
    }

    updatedServers[replaceIndex] = result;

    setState(() {
      _servers
        ..clear()
        ..addAll(updatedServers);
      if (originalKey != nextKey) {
        _runtimeByServer.remove(originalKey);
        _refreshingServerKeys.remove(originalKey);
      }
      if (hadDuplicateTarget) {
        _runtimeByServer.remove(nextKey);
        _refreshingServerKeys.remove(nextKey);
      }
      _currentIndex = 0;
    });

    await _persistServers();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${result.name} 配置已更新。')),
    );
    await _refreshServer(result, showSuccessMessage: false);
  }

  void _openServerDetail(PanelServerConnectionProfile server) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ServerDetailPage(
          server: server,
          initialRuntime: _resolveRuntime(server),
          autoRefreshInterval:
              PanelAppSettingsRepository.durationForPollingInterval(
            _pollingInterval,
          ),
          onRefresh: () => _refreshServer(server, showSuccessMessage: true),
          onAutoRefresh: () => _refreshServer(
            server,
            showSuccessMessage: false,
            showFailureMessage: false,
            showLoadingState: false,
          ),
        ),
      ),
    );
  }

  PanelServerRuntimeState? _resolveRuntime(
    PanelServerConnectionProfile server,
  ) {
    return _runtimeByServer[_serverKey(server)];
  }

  Future<void> _restoreServers() async {
    final pollingIntervalFuture =
        widget.settingsRepository.loadPollingInterval();
    final serversFuture = widget.repository.loadServers();
    var pollingInterval = PanelAppSettingsRepository.defaultPollingInterval;

    try {
      pollingInterval = await pollingIntervalFuture;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('恢复轮询配置失败：$error')),
        );
      }
    }

    try {
      final storedServers = await serversFuture;
      if (!mounted) {
        return;
      }

      setState(() {
        _pollingInterval = pollingInterval;
        _servers
          ..clear()
          ..addAll(storedServers);
        _isRestoringServers = false;
      });
      _syncAutoRefreshTimer();

      if (storedServers.isNotEmpty) {
        unawaited(_refreshPersistedServers(storedServers));
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _pollingInterval = pollingInterval;
        _isRestoringServers = false;
      });
      _syncAutoRefreshTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('恢复本地服务器配置失败：$error')),
      );
    }
  }

  Future<void> _refreshPersistedServers(
    List<PanelServerConnectionProfile> servers,
  ) async {
    for (final server in List<PanelServerConnectionProfile>.of(servers)) {
      await _refreshServer(
        server,
        showSuccessMessage: false,
        showFailureMessage: false,
      );
    }
  }

  void _syncAutoRefreshTimer() {
    _autoRefreshTimer?.cancel();
    final interval =
        PanelAppSettingsRepository.durationForPollingInterval(_pollingInterval);
    if (interval == null) {
      _autoRefreshTimer = null;
      return;
    }
    _autoRefreshTimer = Timer.periodic(interval, (_) {
      unawaited(_refreshServersInBackground());
    });
  }

  Future<void> _updatePollingInterval(String value) async {
    final normalizedValue =
        PanelAppSettingsRepository.normalizePollingInterval(value);
    if (_pollingInterval == normalizedValue) {
      return;
    }

    final previousValue = _pollingInterval;
    setState(() {
      _pollingInterval = normalizedValue;
    });
    _syncAutoRefreshTimer();

    try {
      await widget.settingsRepository.savePollingInterval(normalizedValue);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('前台轮询已切换为 $normalizedValue')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _pollingInterval = previousValue;
      });
      _syncAutoRefreshTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存轮询配置失败：$error')),
      );
    }
  }

  Future<void> _refreshServersInBackground() async {
    if (_isRestoringServers || _servers.isEmpty || _isAutoRefreshing) {
      return;
    }

    _isAutoRefreshing = true;
    try {
      for (final server in List<PanelServerConnectionProfile>.of(_servers)) {
        await _refreshServer(
          server,
          showSuccessMessage: false,
          showFailureMessage: false,
          showLoadingState: false,
        );
      }
    } finally {
      _isAutoRefreshing = false;
    }
  }

  Future<void> _persistServers() async {
    await widget.repository.saveServers(_servers);
  }

  Future<void> _removeServer(PanelServerConnectionProfile server) async {
    final key = _serverKey(server);

    setState(() {
      _servers.removeWhere((item) => _serverKey(item) == key);
      _runtimeByServer.remove(key);
    });

    try {
      await _persistServers();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${server.name} 已从本地配置中移除。')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除后保存本地配置失败：$error')),
      );
    }
  }

  Future<PanelServerRuntimeState> _refreshServer(
    PanelServerConnectionProfile server, {
    bool showSuccessMessage = false,
    bool showFailureMessage = true,
    bool showLoadingState = true,
  }) async {
    final key = _serverKey(server);
    final previous = _runtimeByServer[key];

    if (_refreshingServerKeys.contains(key)) {
      // A refresh is already in flight for this server. Show loading so the
      // user gets visual feedback; the in-flight request will update the state
      // when it completes.
      if (showLoadingState && mounted) {
        setState(() {
          _runtimeByServer[key] = PanelServerRuntimeState.loading(
            previousOverview: previous?.overview,
            previousSyncedAt: previous?.syncedAt,
          );
        });
      }
      return previous ?? PanelServerRuntimeState.idle();
    }

    _refreshingServerKeys.add(key);

    if (showLoadingState) {
      setState(() {
        _runtimeByServer[key] = PanelServerRuntimeState.loading(
          previousOverview: previous?.overview,
          previousSyncedAt: previous?.syncedAt,
        );
      });
    }

    try {
      final runtime = await _runtimeService.loadRuntime(
        server,
        previousOverview: previous?.overview,
      );
      if (!mounted) {
        return runtime;
      }

      setState(() {
        _runtimeByServer[key] = runtime;
      });

      if (showSuccessMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${server.name} 数据已刷新。')),
        );
      }

      return runtime;
    } catch (error) {
      final message = PanelErrorMessageResolver.resolve(error);
      final failedState = PanelServerRuntimeState.failed(
        message,
        previousOverview: previous?.overview,
        previousSyncedAt: previous?.syncedAt,
      );
      if (!mounted) {
        return failedState;
      }

      setState(() {
        _runtimeByServer[key] = failedState;
      });

      if (showFailureMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${server.name} 同步失败：$message')),
        );
      }

      return failedState;
    } finally {
      _refreshingServerKeys.remove(key);
    }
  }

  String _serverKey(PanelServerConnectionProfile server) {
    return server.credentialStorageKey;
  }
}
