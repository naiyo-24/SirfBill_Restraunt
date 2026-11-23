import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_constants.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();

  late final Dio dio;

  factory ApiClient() {
    return _instance;
  }

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Bypass SSL certificate verification on Windows/native platforms.
    // Some restaurant PCs have missing/outdated root CA certificates
    // (e.g. ISRG Root X1 for Let's Encrypt / GitHub), causing
    // CERTIFICATE_VERIFY_FAILED / HandshakeException errors.
    if (!kIsWeb) {
      dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          client.badCertificateCallback =
              (X509Certificate cert, String host, int port) => true;
          return client;
        },
      );
    }

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Dynamically refresh baseUrl in case user configured server IP
          options.baseUrl = ApiConstants.baseUrl;

          // Only attach backend JWT Authorization token to backend requests, never to external URLs like GitHub
          final baseUri = Uri.tryParse(ApiConstants.baseUrl);
          final reqHost = options.uri.host;
          final isBackend = reqHost.isEmpty ||
              (baseUri != null && reqHost == baseUri.host) ||
              reqHost.contains('192.168.') ||
              reqHost.contains('127.0.0.1') ||
              reqHost.contains('localhost') ||
              reqHost.contains('naiyo24.com') ||
              reqHost.contains('vwings247.me');

          if (isBackend) {
            final prefs = await SharedPreferences.getInstance();
            final token = prefs.getString('access_token');
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          // Centralized error logging
          // ignore: avoid_print
          print(
            'API Error [${e.response?.statusCode}]: ${e.requestOptions.path}',
          );
          // ignore: avoid_print
          print('Response Data: ${e.response?.data}');
          // ignore: avoid_print
          print('Message: ${e.message}');

          final baseUri = Uri.tryParse(ApiConstants.baseUrl);
          final reqHost = e.requestOptions.uri.host;
          final isBackend = reqHost.isEmpty ||
              (baseUri != null && reqHost == baseUri.host) ||
              reqHost.contains('192.168.') ||
              reqHost.contains('127.0.0.1') ||
              reqHost.contains('localhost') ||
              reqHost.contains('naiyo24.com') ||
              reqHost.contains('vwings247.me');

          if (isBackend && e.response?.statusCode == 401) {
            // ignore: avoid_print
            print(
              'Unauthorized [401] on: ${e.requestOptions.path} - Access restricted or token unauthorized for this resource.',
            );
          }

          return handler.next(e);
        },
      ),
    );

    // Add PrettyDioLogger for debugging
    dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: false, // Set to false to avoid printing huge binary arrays
        responseHeader: false,
        error: true,
        compact: true,
        maxWidth: 90,
      ),
    );
  }
}
