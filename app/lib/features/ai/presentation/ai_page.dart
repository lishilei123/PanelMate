import 'package:flutter/material.dart';

import '../../../shared/widgets/panel_card.dart';
import '../../../shared/widgets/status_chip.dart';

class AiPage extends StatelessWidget {
  const AiPage({super.key});

  @override
  Widget build(BuildContext context) {
    final modules = <({
      String title,
      String subtitle,
      String source,
      IconData icon,
      Color color
    })>[
      (
        title: '智能巡检',
        subtitle: '自动汇总多台服务器的运行状态，并生成可读巡检摘要。',
        source: '资源、健康状态、模块统计',
        icon: Icons.health_and_safety_outlined,
        color: const Color(0xFF166C5A),
      ),
      (
        title: '日志问答',
        subtitle: '结合操作日志与模块数据，提供自然语言问答入口。',
        source: '操作日志、网站、容器',
        icon: Icons.forum_outlined,
        color: const Color(0xFF356EA3),
      ),
      (
        title: '变更建议',
        subtitle: '基于近期操作和异常状态，生成风险提示与处理建议。',
        source: '近期操作、异常服务器',
        icon: Icons.tips_and_updates_outlined,
        color: const Color(0xFFD17F14),
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF17212B),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '巡检、问答和建议能力入口',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF647181),
                        ),
                  ),
                ],
              ),
            ),
            const StatusChip(label: '规划中', color: Color(0xFFD17F14)),
          ],
        ),
        const SizedBox(height: 14),
        PanelCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(
                        alpha: 0.08,
                      ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.auto_awesome_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI 工作台',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '面向运维场景的智能助手，辅助分析与日常运维。',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF647181),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          '能力模块',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 12),
        ...modules.map(
          (module) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PanelCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: module.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(module.icon, color: module.color),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          module.title,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          module.subtitle,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFF66717F),
                                  ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            StatusChip(
                              label: '规划中',
                              color: module.color,
                            ),
                            StatusChip(label: module.source),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
