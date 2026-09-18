import 'dart:io';
import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../../shared/models/media_info.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(minutes: 5),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
  }

  String get _baseUrl => ApiConfig.baseUrl;

  Future<MediaInfo> getMediaInfo(String url) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/api/multi/info',
        data: {'url': url},
      );
      if (response.statusCode == 200) {
        return MediaInfo.fromJson(response.data);
      }
      throw Exception('Falha ao obter metadados: Status ${response.statusCode}');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<File> downloadMedia({
    required String url,
    required String quality,
    required String format,
    required String savePath,
    void Function(int count, int total)? onProgress,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/api/multi/download',
        data: {
          'url': url,
          'quality': quality,
          'format': format,
        },
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
        ),
        onReceiveProgress: onProgress,
      );

      final file = File(savePath);
      await file.writeAsBytes(response.data);
      return file;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return Exception(
        'O servidor demorou muito para responder. Verifique o backend Python.',
      );
    }
    if (error.type == DioExceptionType.connectionError) {
      return Exception(
        'Não foi possível conectar a $_baseUrl. Verifique a URL do backend e a conexão de rede.',
      );
    }
    if (error.response != null) {
      final msg = error.response?.data is Map && error.response?.data['detail'] != null
          ? error.response?.data['detail']
          : 'Erro no servidor: ${error.response?.statusCode}';
      return Exception(msg);
    }
    return Exception('Erro de rede inesperado: ${error.message}');
  }
}
