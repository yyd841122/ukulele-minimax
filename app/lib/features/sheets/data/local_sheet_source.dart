import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'sheet_model.dart';

/// 本地曲谱数据源（从打包的 assets 加载，离线可用）
class LocalSheetSource {
  static List<Sheet>? _cached;

  /// 加载所有曲谱（首次从 assets 读，后续走内存缓存）
  ///
  /// 本地 JSON 没有 id 字段，按数组下标自动分配 1..N
  static Future<List<Sheet>> loadAll() async {
    if (_cached != null) return _cached!;
    final String raw = await rootBundle.loadString(
      'assets/sheets/ukulele_30.json',
    );
    final Map<String, dynamic> data = jsonDecode(raw) as Map<String, dynamic>;
    final List<dynamic> sheets = data['sheets'] as List<dynamic>;
    _cached = <Sheet>[];
    for (int i = 0; i < sheets.length; i++) {
      final Map<String, dynamic> raw = sheets[i] as Map<String, dynamic>;
      // 注入 id（如果缺失）
      raw['id'] = (raw['id'] as int?) ?? (i + 1);
      // 注入 instrument（如果缺失 → ukulele）
      raw['instrument'] = (raw['instrument'] as String?) ?? 'ukulele';
      // 注入 view_count / favorite_count
      raw['view_count'] = (raw['view_count'] as int?) ?? 0;
      raw['favorite_count'] = (raw['favorite_count'] as int?) ?? 0;
      _cached!.add(Sheet.fromJson(raw));
    }
    return _cached!;
  }

  /// 按 ID 获取单首曲谱
  static Future<Sheet?> getById(int id) async {
    final List<Sheet> all = await loadAll();
    for (final Sheet s in all) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// 按条件筛选
  static Future<List<Sheet>> filter({
    String? instrument,
    String? difficulty,
    String? search,
  }) async {
    final List<Sheet> all = await loadAll();
    return all.where((Sheet s) {
      if (instrument != null && s.instrument != instrument) return false;
      if (difficulty != null && s.difficulty != difficulty) return false;
      if (search != null && search.isNotEmpty) {
        final String q = search.toLowerCase();
        if (!s.title.toLowerCase().contains(q) &&
            !(s.titleEn?.toLowerCase().contains(q) ?? false) &&
            !(s.artist?.toLowerCase().contains(q) ?? false)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  /// 清空缓存（测试用）
  static void clearCache() {
    _cached = null;
  }
}