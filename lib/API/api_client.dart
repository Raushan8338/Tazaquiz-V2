import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:tazaquiznew/API/api_endpoint.dart';

class Api_Client {
  // Implementation of API client using Dio package
  static String baseUrl = BaseUrl.baseUrl;
  static late Dio dio;

  static void init() {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: Duration(seconds: 10),
        receiveTimeout: Duration(seconds: 10),
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

  static void addInterceptors() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          print("FULL URL => ${options.uri}");
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
