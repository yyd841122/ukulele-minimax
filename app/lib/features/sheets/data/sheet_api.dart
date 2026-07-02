import 'package:dio/dio.dart';

import '../../../core/constants.dart';
import 'local_sheet_source.dart';
import 'sheet_model.dart';

/// 曲谱数据源（双模式）
///
/// MVP 阶段：优先本地 assets，离线可用
/// 未来：可切换为云端 API
class SheetApiClient {
  SheetApiClient({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConstants.apiBaseUrl,
                connectTimeout: const Duration(seconds: 3),
                receiveTimeout: const Duration(seconds: 5),
                headers: <String, String>{
                  'Content-Type': 'application/json',
                },
              ),
            );

  final Dio _dio;

  /// 是否启用云端（默认 false：纯本地）
  static const bool useCloud = false;

  /// 获取曲谱列表
  Future<List<Sheet>> listSheets({
    String? instrument,
    String? difficulty,
    String? search,
    int limit = 30,
    int offset = 0,
  }) async {
    if (!useCloud) {
      // 本地模式
      final List<Sheet> all = await LocalSheetSource.filter(
        instrument: instrument,
        difficulty: difficulty,
        search: search,
      );
      return all.skip(offset).take(limit).toList();
    }

    // 云端模式（备用）
    final Map<String, dynamic> query = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (instrument != null) query['instrument'] = instrument;
    if (difficulty != null) query['difficulty'] = difficulty;
    if (search != null) query['search'] = search;

    final Response<dynamic> response = await _dio.get<dynamic>(
      '/sheets',
      queryParameters: query,
    );
    final List<dynamic> data = response.data as List<dynamic>;
    return data
        .cast<Map<String, dynamic>>()
        .map(Sheet.fromJson)
        .toList();
  }

  /// 获取单个曲谱
  Future<Sheet> getSheet(int id) async {
    if (!useCloud) {
      return (await LocalSheetSource.getById(id))!;
    }
    final Response<dynamic> response =
        await _dio.get<dynamic>('/sheets/$id');
    return Sheet.fromJson(response.data as Map<String, dynamic>);
  }
}