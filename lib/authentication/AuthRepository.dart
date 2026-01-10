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

  Future<Response> fetchAppBanner() async {
    return await _dio.get(BaseUrl.app_banner);
  }

  Future<Response> fetchNotificationCount(Map<String, dynamic> data) async {
    FormData formData = FormData.fromMap(data);
    return await _dio.post(BaseUrl.notification_count, data: formData);
  }

  Future<Response> fetchNotificationHistory(Map<String, dynamic> data) async {
    FormData formData = FormData.fromMap(data);
    return await _dio.post(BaseUrl.noification_history, data: formData);
  }

  Future<Response> fetchHomeWeeklyProgress(Map<String, dynamic> params) async {
    return await _dio.get(BaseUrl.home_weekly_progress, queryParameters: params);
  }

  Future<Response> fetchHomePageData() async {
    return await _dio.get(BaseUrl.get_home_page_data);
  }

  Future<Response> fetchQuizQuestion(Map<String, dynamic> data) async {
    FormData formData = FormData.fromMap(data);
    return await _dio.post(BaseUrl.get_Quiz_Question, data: formData);
  }

  Future<Response> submitQuizAnswers(Map<String, dynamic> data) async {
    FormData formData = FormData.fromMap(data);
    return await _dio.post(BaseUrl.submit_quiz_answers, data: formData);
  }

  Future<Response> finalSubmitQuiz(Map<String, dynamic> data) async {
    FormData formData = FormData.fromMap(data);
    return await _dio.post(BaseUrl.final_submit_quiz, data: formData);
  }

  Future<Response> fetchStudyLevels() async {
    return await _dio.get(BaseUrl.get_study_levels);
  }

  Future<Response> fetchStudyCategory(Map<String, dynamic> data) async {
    FormData formData = FormData.fromMap(data);
    return await _dio.post(BaseUrl.get_study_category, data: formData);
  }

  Future<Response> fetchStudySubjectCategory(Map<String, dynamic> data) async {
    FormData formData = FormData.fromMap(data);
    return await _dio.post(BaseUrl.get_study_subject_category, data: formData);
  }

  Future<Response> fetchStudyMaterialsDetails(Map<String, dynamic> data) async {
    FormData formData = FormData.fromMap(data);
    return await _dio.post(BaseUrl.get_study_materials_details, data: formData);
  }

  Future<Response> generateServiceRequest(Map<String, dynamic> data) async {
    FormData formData = FormData.fromMap(data);
    return await _dio.post(BaseUrl.gsubmit_service_requestet, data: formData);
  }

  Future<Response> fetchTicketStatus(Map<String, dynamic> data) async {
    FormData formData = FormData.fromMap(data);
    return await _dio.post(BaseUrl.fetch_ticket_status, data: formData);
  }

  Future<Response> fetchReferralList(Map<String, dynamic> data) async {
    FormData formData = FormData.fromMap(data);
    return await _dio.post(BaseUrl.fetch_referral_list, data: formData);
  }

  Future<Response> createPaymentOrder(Map<String, dynamic> data) async {
    FormData formData = FormData.fromMap(data);
    return await _dio.post(BaseUrl.create_payment_order, data: formData);
  }

  Future<Response> savePaymentStatus(Map<String, dynamic> data) async {
    FormData formData = FormData.fromMap(data);
    return await _dio.post(BaseUrl.save_payment_status, data: formData);
  }

  Future<Response> fetchCheckoutDetails(Map<String, dynamic> data) async {
    FormData formData = FormData.fromMap(data);
    return await _dio.post(BaseUrl.fetch_checkout_details, data: formData);
  }

  Future<Response> applyCoupon(Map<String, dynamic> data) async {
    FormData formData = FormData.fromMap(data);
    return await _dio.post(BaseUrl.apply_coupon_code, data: formData);
  }
   Future<Response> get_quizId_wise_details(Map<String, dynamic> data) async {
    FormData formData = FormData.fromMap(data);
    return await _dio.post(BaseUrl.get_id_wise_quiz, data: formData);
  }
   Future<Response> get_study_wise_details(Map<String, dynamic> data) async {
    FormData formData = FormData.fromMap(data);
    return await _dio.post(BaseUrl.get_id_wise_studyM_Details, data: formData);
  }

}
