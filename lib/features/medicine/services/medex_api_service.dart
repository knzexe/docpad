import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../models/catalog_page.dart';
import '../models/medex_brand.dart';
import 'medex_parser.dart';

abstract class MedicineCatalogApi {
  Future<CatalogHealth> checkHealth();

  Future<List<MedExBrand>> searchMedicines({
    required String query,
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  });

  Future<MedicineSearchPage<MedExBrand>> searchMedicinesPage({
    required String query,
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  });

  Future<MedExBrand> getMedicineDetails(String id, {CancelToken? cancelToken});

  Future<List<dynamic>> searchGenerics({
    required String query,
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  });

  Future<GenericSearchPage> searchGenericsPage({
    required String query,
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  });
}

class MedExApiService implements MedicineCatalogApi {
  MedExApiService(this.dio);

  final Dio dio;

  @override
  Future<CatalogHealth> checkHealth() async {
    final response = await _get('/api/v1/health');
    return parseHealth(response.data);
  }

  @override
  Future<List<MedExBrand>> searchMedicines({
    required String query,
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    final result = await searchMedicinesPage(
      query: query,
      page: page,
      limit: limit,
      cancelToken: cancelToken,
    );
    return result.items;
  }

  @override
  Future<MedicineSearchPage<MedExBrand>> searchMedicinesPage({
    required String query,
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    final response = await _get(
      '/api/v1/medicines/search',
      queryParameters: _paging(query, page, limit),
      cancelToken: cancelToken,
    );
    return parseMedicineSearch(response.data);
  }

  @override
  Future<MedExBrand> getMedicineDetails(
    String id, {
    CancelToken? cancelToken,
  }) async {
    final response = await _get(
      '/api/v1/medicines/${Uri.encodeComponent(id)}',
      cancelToken: cancelToken,
    );
    return parseMedicineDetails(response.data);
  }

  @override
  Future<List<dynamic>> searchGenerics({
    required String query,
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    final result = await searchGenericsPage(
      query: query,
      page: page,
      limit: limit,
      cancelToken: cancelToken,
    );
    return result.items;
  }

  @override
  Future<GenericSearchPage> searchGenericsPage({
    required String query,
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    final response = await _get(
      '/api/v1/generics/search',
      queryParameters: _paging(query, page, limit),
      cancelToken: cancelToken,
    );
    return parseGenericSearch(response.data);
  }

  Map<String, dynamic> _paging(String query, int page, int limit) {
    final trimmed = query.trim();
    if (trimmed.isEmpty || trimmed.length > 200) {
      throw const AppException(
        'Enter a catalog search between 1 and 200 characters.',
        code: 'validation_error',
      );
    }
    return {
      'q': trimmed,
      'page': page < 1 ? 1 : page,
      'limit': limit.clamp(1, 100),
    };
  }

  Future<Response<dynamic>> _get(
    String path, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    try {
      return await dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
      );
    } on DioException catch (error) {
      if (error.type == DioExceptionType.cancel) {
        rethrow;
      }
      throw _mapDio(error);
    }
  }

  AppException _mapDio(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const AppException(
          'The catalog request timed out. Drafts on this device are unchanged.',
          code: 'timeout',
        );
      case DioExceptionType.connectionError:
        return const AppException(
          'Could not reach the medicine catalog. Check the address and your network. Drafts on this device are unchanged.',
          code: 'offline',
        );
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        final message = _apiMessage(error.response?.data);
        if (status == 404) {
          return AppException(
            message ?? 'That catalog record was not found.',
            code: 'not_found',
          );
        }
        if (status == 429) {
          return const AppException(
            'The catalog is rate limiting requests. Wait a moment and try again.',
            code: 'rate_limited',
          );
        }
        if (status == 400) {
          return AppException(
            message ?? 'The catalog rejected that request.',
            code: 'validation_error',
          );
        }
        return AppException(
          message ?? 'The catalog returned an error.',
          code: 'http',
        );
      default:
        return const AppException(
          'Could not complete the catalog request.',
          code: 'network',
        );
    }
  }

  String? _apiMessage(dynamic data) {
    if (data is Map && data['error'] is Map) {
      final message = (data['error'] as Map)['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }
    return null;
  }
}

Dio createDio(String baseUrl) {
  return Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 8),
      responseType: ResponseType.json,
      headers: const {'Accept': 'application/json'},
    ),
  );
}
