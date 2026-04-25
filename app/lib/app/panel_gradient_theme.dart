import 'package:flutter/material.dart';

class PanelGradientTheme {
  const PanelGradientTheme({
    required this.id,
    required this.label,
    required this.description,
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.backgroundColors,
    required this.backgroundStops,
    required this.veilColors,
    required this.accentColors,
  });

  final String id;
  final String label;
  final String description;
  final Color primary;
  final Color secondary;
  final Color tertiary;
  final List<Color> backgroundColors;
  final List<double> backgroundStops;
  final List<Color> veilColors;
  final List<Color> accentColors;

  static const String defaultId = 'mint';
  static const String customId = 'custom';

  static PanelGradientTheme custom({
    Color primary = const Color(0xFF168F8F),
    Color secondary = const Color(0xFF55A8D7),
    Color tertiary = const Color(0xFFFF9C6E),
  }) {
    final firstBackground = Color.lerp(Colors.white, primary, 0.13)!;
    final secondBackground = Color.lerp(Colors.white, secondary, 0.10)!;
    final thirdBackground = Color.lerp(Colors.white, tertiary, 0.12)!;

    return PanelGradientTheme(
      id: customId,
      label: '自定义',
      description: '从调色板选择颜色',
      primary: primary,
      secondary: secondary,
      tertiary: tertiary,
      backgroundColors: <Color>[
        firstBackground,
        const Color(0xFFF8FCFF),
        secondBackground,
        thirdBackground,
      ],
      backgroundStops: const <double>[0.0, 0.36, 0.72, 1.0],
      veilColors: <Color>[
        Colors.white.withValues(alpha: 0.70),
        Colors.white.withValues(alpha: 0.18),
        primary.withValues(alpha: 0.16),
      ],
      accentColors: <Color>[
        primary.withValues(alpha: 0.13),
        Colors.transparent,
        tertiary.withValues(alpha: 0.10),
      ],
    );
  }

  static const List<PanelGradientTheme> builtIns = <PanelGradientTheme>[
    PanelGradientTheme(
      id: defaultId,
      label: '薄荷清晨',
      description: '清水蓝、薄荷绿和轻暖色',
      primary: Color(0xFF168F8F),
      secondary: Color(0xFF47A975),
      tertiary: Color(0xFFFF8A5C),
      backgroundColors: <Color>[
        Color(0xFFE8FBF6),
        Color(0xFFF8FCFF),
        Color(0xFFEAF4FF),
        Color(0xFFF7FFF9),
      ],
      backgroundStops: <double>[0.0, 0.38, 0.72, 1.0],
      veilColors: <Color>[
        Color(0xADFFFFFF),
        Color(0x2EFFFFFF),
        Color(0x2E78DCCB),
      ],
      accentColors: <Color>[
        Color(0x1F8FE7E2),
        Colors.transparent,
        Color(0x14FFB58F),
      ],
    ),
    PanelGradientTheme(
      id: 'ocean',
      label: '海盐蓝',
      description: '浅蓝、青绿和柔白雾感',
      primary: Color(0xFF1677A3),
      secondary: Color(0xFF2AAE8E),
      tertiary: Color(0xFFFFA35C),
      backgroundColors: <Color>[
        Color(0xFFEAF8FF),
        Color(0xFFF7FCFF),
        Color(0xFFE7F7F2),
        Color(0xFFFFFBF5),
      ],
      backgroundStops: <double>[0.0, 0.36, 0.74, 1.0],
      veilColors: <Color>[
        Color(0xB3FFFFFF),
        Color(0x33FFFFFF),
        Color(0x2478BEEA),
      ],
      accentColors: <Color>[
        Color(0x1F5BC8E8),
        Colors.transparent,
        Color(0x1438CFA1),
      ],
    ),
    PanelGradientTheme(
      id: 'garden',
      label: '青柠花园',
      description: '青柠绿、晴空蓝和浅杏色',
      primary: Color(0xFF2E8F69),
      secondary: Color(0xFF55A8D7),
      tertiary: Color(0xFFFF9C6E),
      backgroundColors: <Color>[
        Color(0xFFF0FCEB),
        Color(0xFFF9FEFF),
        Color(0xFFE9F6FF),
        Color(0xFFFFF7EF),
      ],
      backgroundStops: <double>[0.0, 0.34, 0.70, 1.0],
      veilColors: <Color>[
        Color(0xB8FFFFFF),
        Color(0x30FFFFFF),
        Color(0x225DCE9A),
      ],
      accentColors: <Color>[
        Color(0x1F9AEF9A),
        Colors.transparent,
        Color(0x145AAFE4),
      ],
    ),
    PanelGradientTheme(
      id: 'dawn',
      label: '晨曦苏打',
      description: '淡桃、苏打蓝和清透绿',
      primary: Color(0xFF0F8E9A),
      secondary: Color(0xFFFF8F75),
      tertiary: Color(0xFF62B86F),
      backgroundColors: <Color>[
        Color(0xFFFFF2EC),
        Color(0xFFF7FDFF),
        Color(0xFFEAF7FF),
        Color(0xFFF4FFF4),
      ],
      backgroundStops: <double>[0.0, 0.35, 0.73, 1.0],
      veilColors: <Color>[
        Color(0xB3FFFFFF),
        Color(0x2BFFFFFF),
        Color(0x22FFAA8C),
      ],
      accentColors: <Color>[
        Color(0x1CFFA987),
        Colors.transparent,
        Color(0x1459D5C5),
      ],
    ),
  ];

  static PanelGradientTheme resolve(
    String? id, {
    PanelGradientTheme? customTheme,
  }) {
    if (id == customId) {
      return customTheme ?? custom();
    }
    for (final theme in builtIns) {
      if (theme.id == id) {
        return theme;
      }
    }
    return builtIns.first;
  }
}
