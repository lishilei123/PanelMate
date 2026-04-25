class PanelValueFormatters {
  const PanelValueFormatters._();

  static String percent(
    num? value, {
    bool treatAsRatio = false,
    int fractionDigits = 0,
  }) {
    if (value == null) {
      return '-';
    }

    final resolved = treatAsRatio ? value * 100 : value.toDouble();
    return '${resolved.toStringAsFixed(fractionDigits)}%';
  }

  static String bytes(num? value) {
    if (value == null) {
      return '-';
    }

    const units = <String>['B', 'KB', 'MB', 'GB', 'TB'];
    var size = value.toDouble();
    var unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex += 1;
    }

    final digits = size >= 100 ? 0 : (size >= 10 ? 1 : 2);
    return '${size.toStringAsFixed(digits)} ${units[unitIndex]}';
  }

  static String megabytes(num? value) {
    if (value == null) {
      return '-';
    }
    return '${value.toStringAsFixed(value >= 100 ? 0 : 1)} MB';
  }

  static String optionalText(String? value, {String fallback = '-'}) {
    final resolved = value?.trim();
    if (resolved == null || resolved.isEmpty) {
      return fallback;
    }
    return resolved;
  }

  static String dateTime(DateTime? value) {
    if (value == null) {
      return '-';
    }

    final local = value.toLocal();
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  static String relativeTime(DateTime? value) {
    if (value == null) {
      return '-';
    }

    final now = DateTime.now();
    final local = value.toLocal();
    final difference = now.difference(local);

    if (difference.isNegative) {
      final future = local.difference(now);
      if (future.inSeconds < 60) {
        return '即将到期';
      }
      if (future.inMinutes < 60) {
        return '${future.inMinutes} 分钟后';
      }
      if (future.inHours < 24) {
        return '${future.inHours} 小时后';
      }
      if (future.inDays < 30) {
        return '${future.inDays} 天后';
      }
      return dateTime(local);
    }

    if (difference.inSeconds < 60) {
      return '刚刚';
    }
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} 分钟前';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours} 小时前';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays} 天前';
    }
    return dateTime(local);
  }
}
