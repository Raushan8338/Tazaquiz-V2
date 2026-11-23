import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:tazaquiznew/API/api_endpoint.dart';

class Api_Client {
  // Implementation of API client using Dio package
  static String baseUrl = BaseUrl.baseUrl;
  static String baseUrl_main = BaseUrl.baseUrl_main;
  static late Dio dio;

  static void init() {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        // 10 s was too short on weak mobile data: the first try failed, "Retry" then worked.
        connectTimeout: Duration(seconds: 15),
        receiveTimeout: Duration(seconds: 20),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      ),
    );
    addInterceptors();
    // 🔴 DEV ONLY — SSL BYPASS
    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final HttpClient client = HttpClient();
      client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
      return client;
    };
  }

  /// Runs [call] and, on a network blip (timeout, no connection, 5xx), tries once more
  /// before giving up — so the user does not have to press "Retry" themselves.
  /// ONLY for calls that just read data. Never wrap payment, quiz submit or anything
  /// that saves, or it could run twice.
  static Future<T> withRetry<T>(Future<T> Function() call, {int attempts = 2}) async {
    for (int i = 1;; i++) {
      try {
        return await call();
      } catch (e) {
        if (i >= attempts || !isNetworkError(e)) rethrow;
        await Future.delayed(Duration(milliseconds: 800 * i));
      }
    }
  }

  static bool isNetworkError(Object e) {
    if (e is TimeoutException || e is SocketException) return true;
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          return true;
        case DioExceptionType.badResponse:
          return (e.response?.statusCode ?? 0) >= 500;
        case DioExceptionType.unknown:
          return e.error is SocketException || e.error is HttpException;
        default:
          return false;
      }
    }
    return false;
  }

  static bool isTimeout(Object e) =>
      e is TimeoutException ||
      (e is DioException &&
          (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.sendTimeout ||
              e.type == DioExceptionType.receiveTimeout));

  static void addInterceptors() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // print("FULL URL => ${options.uri}");
          // You can add authorization headers or logging here

          return handler.next(options);
        },
        onResponse: (response, handler) {
          // Handle responses globally
          return handler.next(response);
        },
        onError: (DioError e, handler) {
          // Handle errors globally
          return handler.next(e);
        },
      ),
    );
  }
}
