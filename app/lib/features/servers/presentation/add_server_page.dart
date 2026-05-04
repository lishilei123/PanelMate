import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/network/panel_endpoint_parser.dart';
import '../../../core/panel/models/api_version.dart';
import '../../../core/panel/models/compatibility_flags.dart';
import '../../../core/panel/models/panel_error_message_resolver.dart';
import '../../../core/panel/models/server_connection_profile.dart';
import '../../../core/panel/probe/panel_version_probe_result.dart';
import '../../../core/panel/runtime/panel_login_captcha.dart';
import '../../../shared/widgets/panel_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../application/server_connection_tester.dart';

class AddServerPage extends StatefulWidget {
  const AddServerPage({
    super.key,
    this.initialServer,
  });

  final PanelServerConnectionProfile? initialServer;

  @override
  State<AddServerPage> createState() => _AddServerPageState();
}

class _AddServerPageState extends State<AddServerPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _hostController = TextEditingController();
  final _hostFocusNode = FocusNode();
  final _portController = TextEditingController(text: '443');
  final _entranceCodeController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _remarkController = TextEditingController();
  final _tagsController = TextEditingController();

  PanelAuthMode _authMode = PanelAuthMode.accountPassword;
  String _protocol = 'https';
  PanelVersionProbeResult? _probeResult;
  String? _testErrorMessage;
  bool _didTest = false;
  bool _isTesting = false;
  bool _isApplyingParsedAddress = false;
  String? _lastAutoFilledEntranceCode;

  bool get _isEditMode => widget.initialServer != null;

  @override
  void initState() {
    super.initState();
    _hostFocusNode.addListener(_handleHostFocusChange);
    _applyInitialServer();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _hostFocusNode.dispose();
    _portController.dispose();
    _entranceCodeController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _apiKeyController.dispose();
    _remarkController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _applyInitialServer() {
    final server = widget.initialServer;
    if (server == null) {
      return;
    }

    _nameController.text = server.name;
    _hostController.text = server.baseUrl;
    _protocol = server.protocol;
    _portController.text = server.port.toString();
    _entranceCodeController.text = server.entranceCode ?? '';
    _authMode = server.authMode;
    _usernameController.text = server.username ?? '';
    _passwordController.text = server.password ?? '';
    _apiKeyController.text = server.apiKey ?? '';
    _remarkController.text = server.remark ?? '';
    _tagsController.text = server.tags.join(', ');
  }

  Future<void> _runConnectionTest() async {
    _autoParseAddressInput();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isTesting = true;
      _didTest = true;
      _probeResult = null;
      _testErrorMessage = null;
    });

    try {
      final result = await ServerConnectionTester.test(
        _buildProfile(),
        captchaResolver: _resolveLoginCaptcha,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _probeResult = result;
        _testErrorMessage = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = PanelErrorMessageResolver.resolve(error);
      setState(() {
        _probeResult = null;
        _testErrorMessage = message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('连接测试失败：$message')),
      );
    } finally {
      if (mounted) {
        setState(() => _isTesting = false);
      }
    }
  }

  Future<String?> _resolveLoginCaptcha(
    PanelLoginCaptchaChallenge challenge,
  ) {
    if (!mounted) {
      return Future<String?>.value();
    }
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _CaptchaInputDialog(challenge: challenge),
    );
  }

  void _submit() {
    _autoParseAddressInput();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final profile = _buildProfile();
    final canReuseInitialCompatibility = _canReuseInitialCompatibility(profile);
    if (_probeResult == null && !canReuseInitialCompatibility) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先执行连接测试。')),
      );
      return;
    }

    final compatibilityFlags = _resolveCompatibilityFlagsForSubmit(profile);
    Navigator.of(context).pop(
      profile.copyWith(compatibilityFlags: compatibilityFlags),
    );
  }

  void _invalidateTestResult() {
    if (!_didTest && _probeResult == null && _testErrorMessage == null) {
      return;
    }

    setState(() {
      _didTest = false;
      _probeResult = null;
      _testErrorMessage = null;
    });
  }

  void _handleHostFocusChange() {
    if (!_hostFocusNode.hasFocus) {
      _autoParseAddressInput();
    }
  }

  void _autoParseAddressInput() {
    if (_isApplyingParsedAddress) {
      return;
    }

    final rawInput = _hostController.text.trim();
    if (rawInput.isEmpty) {
      return;
    }

    try {
      final endpoint = PanelEndpointParser.parse(
        rawInput,
        defaultScheme: _protocol,
      );
      final normalizedHost = endpoint.host;
      final nextProtocol = endpoint.scheme ?? _protocol;
      final nextPortText = endpoint.port?.toString();
      final nextEntranceCode = endpoint.pathSegments.isEmpty
          ? null
          : endpoint.pathSegments.join('/');
      final currentEntranceCode = _entranceCodeController.text.trim();
      final shouldUpdateEntranceCode = nextEntranceCode != null &&
          nextEntranceCode.isNotEmpty &&
          (currentEntranceCode.isEmpty ||
              currentEntranceCode == _lastAutoFilledEntranceCode);
      final shouldClearAutoFilledEntranceCode =
          (nextEntranceCode == null || nextEntranceCode.isEmpty) &&
              currentEntranceCode.isNotEmpty &&
              currentEntranceCode == _lastAutoFilledEntranceCode;

      _isApplyingParsedAddress = true;
      try {
        if (rawInput != normalizedHost) {
          _hostController.value = TextEditingValue(
            text: normalizedHost,
            selection: TextSelection.collapsed(offset: normalizedHost.length),
          );
        }

        if (nextPortText != null &&
            nextPortText != _portController.text.trim()) {
          _portController.value = TextEditingValue(
            text: nextPortText,
            selection: TextSelection.collapsed(offset: nextPortText.length),
          );
        }

        if (shouldUpdateEntranceCode) {
          _entranceCodeController.value = TextEditingValue(
            text: nextEntranceCode,
            selection: TextSelection.collapsed(offset: nextEntranceCode.length),
          );
          _lastAutoFilledEntranceCode = nextEntranceCode;
        } else if (shouldClearAutoFilledEntranceCode) {
          _entranceCodeController.clear();
          _lastAutoFilledEntranceCode = null;
        }
      } finally {
        _isApplyingParsedAddress = false;
      }

      if (nextProtocol != _protocol && mounted) {
        setState(() => _protocol = nextProtocol);
      }
    } on FormatException {
      // Ignore incomplete input and keep raw text until the endpoint is parseable.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? '编辑服务器' : '新增服务器'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ConnectionIntro(isEditMode: _isEditMode),
              const SizedBox(height: 16),
              _Section(
                title: '基础信息',
                subtitle: '可以直接粘贴完整面板地址，系统会自动拆分协议、端口和安全入口。',
                child: Column(
                  children: [
                    TextFormField(
                      key: const ValueKey('add_server.name'),
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: '服务器名称'),
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const ValueKey('add_server.address'),
                      focusNode: _hostFocusNode,
                      controller: _hostController,
                      decoration: const InputDecoration(
                        labelText: '地址',
                      ),
                      validator: _validateHost,
                      onChanged: (_) => _invalidateTestResult(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            key: const ValueKey('add_server.protocol'),
                            initialValue: _protocol,
                            decoration: const InputDecoration(labelText: '协议'),
                            items: const [
                              DropdownMenuItem(
                                value: 'https',
                                child: Text('HTTPS'),
                              ),
                              DropdownMenuItem(
                                value: 'http',
                                child: Text('HTTP'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) {
                                return;
                              }
                              setState(() => _protocol = value);
                              _invalidateTestResult();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            key: const ValueKey('add_server.port'),
                            controller: _portController,
                            decoration: const InputDecoration(
                              labelText: '端口',
                            ),
                            keyboardType: TextInputType.number,
                            validator: _validatePort,
                            onChanged: (_) => _invalidateTestResult(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _Section(
                title: '认证信息',
                subtitle: '凭证只写入安全存储，普通配置不会保存密码或 API Key。',
                child: Column(
                  children: [
                    TextFormField(
                      key: const ValueKey('add_server.entrance_code'),
                      controller: _entranceCodeController,
                      decoration: const InputDecoration(
                        labelText: 'EntranceCode',
                        helperText: '如果面板启用了安全入口，请填写对应入口码',
                      ),
                      onChanged: (_) {
                        if (!_isApplyingParsedAddress &&
                            _entranceCodeController.text.trim() !=
                                _lastAutoFilledEntranceCode) {
                          _lastAutoFilledEntranceCode = null;
                        }
                        _invalidateTestResult();
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<PanelAuthMode>(
                      key: const ValueKey('add_server.auth_mode'),
                      initialValue: _authMode,
                      decoration: const InputDecoration(labelText: '登录方式'),
                      items: PanelAuthMode.values
                          .map(
                            (mode) => DropdownMenuItem(
                              value: mode,
                              child: Text(mode.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() => _authMode = value);
                        _invalidateTestResult();
                      },
                    ),
                    const SizedBox(height: 12),
                    if (_authMode == PanelAuthMode.accountPassword) ...[
                      TextFormField(
                        key: const ValueKey('add_server.username'),
                        controller: _usernameController,
                        decoration: const InputDecoration(labelText: '用户名'),
                        validator: _required,
                        onChanged: (_) => _invalidateTestResult(),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: const ValueKey('add_server.password'),
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: '密码'),
                        validator: _required,
                        onChanged: (_) => _invalidateTestResult(),
                      ),
                    ] else ...[
                      TextFormField(
                        key: const ValueKey('add_server.api_key'),
                        controller: _apiKeyController,
                        decoration: const InputDecoration(
                          labelText: 'API Key / Token',
                        ),
                        validator: _required,
                        onChanged: (_) => _invalidateTestResult(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _Section(
                title: '补充信息',
                subtitle: '标签会参与概览页搜索和分组展示。',
                child: Column(
                  children: [
                    TextFormField(
                      key: const ValueKey('add_server.remark'),
                      controller: _remarkController,
                      decoration: const InputDecoration(labelText: '备注'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const ValueKey('add_server.tags'),
                      controller: _tagsController,
                      decoration: const InputDecoration(
                        labelText: '标签',
                        helperText: '多个标签使用英文逗号分隔',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _Section(
                title: '连接测试',
                subtitle: '保存前固定检查 1Panel V2 API 能力。',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        key: const ValueKey('add_server.test_connection'),
                        onPressed: _isTesting ? null : _runConnectionTest,
                        icon: _isTesting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.lan_outlined),
                        label: Text(_isTesting ? '正在测试连接' : '测试连接'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_testErrorMessage != null) ...[
                      _ErrorNotice(message: _testErrorMessage!),
                      const SizedBox(height: 12),
                    ],
                    if (_probeResult != null)
                      _ProbeResultView(result: _probeResult!)
                    else if (_testErrorMessage == null)
                      Text(
                        _isEditMode
                            ? '修改了连接相关配置后，请重新执行连接测试。'
                            : '执行测试后会显示 V2 API 能力检查结果。',
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton(
          key: const ValueKey('add_server.submit'),
          onPressed: _isTesting ? null : _submit,
          child: Text(_isEditMode ? '保存修改' : '保存并接入'),
        ),
      ),
    );
  }

  PanelServerConnectionProfile _buildProfile() {
    final endpoint = PanelEndpointParser.parse(
      _hostController.text,
      defaultScheme: _protocol,
    );

    return PanelServerConnectionProfile(
      name: _nameController.text.trim(),
      baseUrl: endpoint.host,
      protocol: endpoint.scheme ?? _protocol,
      port: endpoint.port ?? int.parse(_portController.text.trim()),
      apiVersion: PanelApiVersion.v2,
      authMode: _authMode,
      username: _authMode == PanelAuthMode.accountPassword
          ? _usernameController.text.trim()
          : null,
      password: _authMode == PanelAuthMode.accountPassword
          ? _passwordController.text
          : null,
      apiKey: _authMode == PanelAuthMode.apiKey
          ? _apiKeyController.text.trim()
          : null,
      entranceCode: _entranceCodeController.text.trim().isEmpty
          ? null
          : _entranceCodeController.text.trim(),
      remark: _remarkController.text.trim().isEmpty
          ? null
          : _remarkController.text.trim(),
      tags: _tagsController.text
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(),
      certificateFingerprint: widget.initialServer?.certificateFingerprint,
    );
  }

  bool _canReuseInitialCompatibility(PanelServerConnectionProfile profile) {
    final initial = widget.initialServer;
    if (initial == null) {
      return false;
    }

    return initial.baseUrl == profile.baseUrl &&
        initial.protocol == profile.protocol &&
        initial.port == profile.port &&
        initial.authMode == profile.authMode &&
        _normalizeNullable(initial.username) ==
            _normalizeNullable(profile.username) &&
        _normalizeNullable(initial.password) ==
            _normalizeNullable(profile.password) &&
        _normalizeNullable(initial.apiKey) ==
            _normalizeNullable(profile.apiKey) &&
        _normalizeNullable(initial.entranceCode) ==
            _normalizeNullable(profile.entranceCode);
  }

  PanelCompatibilityFlags? _resolveCompatibilityFlagsForSubmit(
    PanelServerConnectionProfile profile,
  ) {
    if (_probeResult != null) {
      return _probeResult!.compatibilityFlags;
    }
    if (_canReuseInitialCompatibility(profile)) {
      return widget.initialServer?.compatibilityFlags;
    }
    return null;
  }

  String _normalizeNullable(String? value) {
    return value?.trim() ?? '';
  }

  String? _validateHost(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '必填';
    }

    try {
      PanelEndpointParser.parse(value, defaultScheme: _protocol);
      return null;
    } on FormatException {
      return '地址格式无效';
    }
  }

  String? _validatePort(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '必填';
    }

    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed <= 0 || parsed > 65535) {
      return '端口无效';
    }

    return null;
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '必填';
    }
    return null;
  }
}

class _CaptchaInputDialog extends StatefulWidget {
  const _CaptchaInputDialog({
    required this.challenge,
  });

  final PanelLoginCaptchaChallenge challenge;

  @override
  State<_CaptchaInputDialog> createState() => _CaptchaInputDialogState();
}

class _CaptchaInputDialogState extends State<_CaptchaInputDialog> {
  final _controller = TextEditingController();
  String? _fieldError;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final errorMessage = widget.challenge.errorMessage;

    return AlertDialog(
      title: Text(widget.challenge.attempt > 1 ? '重新输入验证码' : '输入验证码'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (errorMessage != null) ...[
              Text(
                errorMessage,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
            ],
            Container(
              width: double.infinity,
              height: 96,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF6FAFA),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFD9E6E6)),
              ),
              child: _CaptchaImage(imagePath: widget.challenge.imagePath),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: '验证码',
                errorText: _fieldError,
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('继续登录'),
        ),
      ],
    );
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() => _fieldError = '请输入验证码');
      return;
    }
    Navigator.of(context).pop(value);
  }
}

class _CaptchaImage extends StatelessWidget {
  const _CaptchaImage({
    required this.imagePath,
  });

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    final bytes = _decodeCaptchaBytes(imagePath);
    if (bytes != null) {
      return Image.memory(
        bytes,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        filterQuality: FilterQuality.none,
      );
    }

    final uri = Uri.tryParse(imagePath.trim());
    if (uri != null && uri.hasScheme) {
      return Image.network(
        imagePath.trim(),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Text('验证码图片加载失败');
        },
      );
    }

    return const Text('验证码图片无法显示，请重试');
  }

  Uint8List? _decodeCaptchaBytes(String value) {
    var normalized = value.trim();
    try {
      normalized = Uri.decodeComponent(normalized);
    } on FormatException {
      // Keep the original value if it is not URL encoded.
    }

    final commaIndex = normalized.indexOf(',');
    if (normalized.startsWith('data:image') && commaIndex >= 0) {
      normalized = normalized.substring(commaIndex + 1);
    }

    normalized = normalized.replaceAll(RegExp(r'\s'), '');
    if (normalized.isEmpty) {
      return null;
    }

    try {
      return base64Decode(normalized);
    } on FormatException {
      return null;
    }
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PanelCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF647181),
                ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ConnectionIntro extends StatelessWidget {
  const _ConnectionIntro({
    required this.isEditMode,
  });

  final bool isEditMode;

  @override
  Widget build(BuildContext context) {
    return PanelCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(
                    alpha: 0.08,
                  ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isEditMode ? Icons.tune_outlined : Icons.add_link_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditMode ? '更新连接配置' : '接入新的 1Panel 服务器',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    StatusChip(label: 'V2 API'),
                    StatusChip(label: '本地保存'),
                    StatusChip(label: '凭证安全存储'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorNotice extends StatelessWidget {
  const _ErrorNotice({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5B5B5)),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF9F2F2F),
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _ProbeResultView extends StatelessWidget {
  const _ProbeResultView({
    required this.result,
  });

  final PanelVersionProbeResult result;

  @override
  Widget build(BuildContext context) {
    final flags = result.compatibilityFlags;
    final rows = <MapEntry<String, bool>>[
      MapEntry('V2 API 校验通过', result.apiVersionMatched),
      MapEntry('使用 core/auth', flags.useCoreAuth),
      MapEntry('使用 :id 路由参数', flags.useColonRouteParams),
      MapEntry('使用 GET 概览接口', flags.useDashboardCurrentGet),
      MapEntry('使用 GET 容器日志', flags.useContainerLogGet),
      MapEntry('登录需要 EntranceCode', flags.requireEntranceCodeOnLogin),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...rows.map(
          (row) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(child: Text(row.key)),
                Icon(
                  row.value ? Icons.check_circle : Icons.cancel_outlined,
                  color: row.value ? Colors.green : Colors.red,
                ),
              ],
            ),
          ),
        ),
        if (result.mismatchHint != null) ...[
          const SizedBox(height: 8),
          _ErrorNotice(message: result.mismatchHint!),
        ],
      ],
    );
  }
}
