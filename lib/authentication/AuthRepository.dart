import 'package:dio/dio.dart';
import 'package:tazaquiznew/API/api_endpoint.dart';

class Authrepository {
  final Dio _dio;
  Authrepository(this._dio);

  Future<Response> loginUser(Map<String, dynamic> data) async {
    FormData formData = FormData.fromMap(data);
    return await _dio.post(BaseUrl.loginEndpoint, data: formData);
  }

  Future<Response> signupVerifyOTP(Map<String, dynamic> data) async {
    FormData formData = FormData.fromMap(data);
    return await _dio.post(BaseUrl.signupVerifyOTPEndpoint, data: formData);
  }
}
