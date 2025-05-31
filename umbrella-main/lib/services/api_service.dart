import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:umbrella/provider/user_provider.dart';
import 'mock_api_interceptor.dart';
import 'package:umbrella/screens/main_screen.dart';
import 'package:umbrella/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:umbrella/provider/user_provider.dart';

class ApiService {
  final Dio _dio = Dio();
  final String baseUrl = 'https://mock-api.com';

  ApiService() {
    _dio.options.baseUrl = baseUrl;
    _dio.interceptors.add(MockApiInterceptor());
  }

  Future<String> sendVerificationCode(
      //string 반환
      String email,
      bool isPasswordReset) async {
    developer.log(
        "[LOG] 🛠️ 이메일 인증 요청 - 이메일: $email, 비밀번호 변경: $isPasswordReset",
        name: "log");

    try {
      final response = await _dio.post(
        '/send-email',
        data: {"email": email},
        queryParameters: {
          "isPasswordReset": isPasswordReset.toString(),
        },
      );

      if (response.statusCode == 200) {
        return _handleSuccess(isPasswordReset);
      }

      if (isPasswordReset) {
        return _handleError(response, "비밀번호 변경 이메일 인증 오류");
      }

      return _handleError(response, "회원가입 이메일 인증 오류");
    } catch (e) {
      if (e is DioException) {
        return _handleNetworkError(e);
      }
      developer.log("[LOG] ❌ 예외 발생: ${e.toString()}");
      return "error";
    }
  }

  String _handleSuccess(bool isPasswordReset) {
    String logMessage =
        isPasswordReset ? "비밀번호 변경 이메일 인증번호 전송 성공" : "회원가입 이메일 인증번호 전송 성공";
    developer.log("[LOG] ✅ $logMessage");
    return "success";
  }

  String _handleError(Response response, String logPrefix) {
    String errorMessage = _getErrorMessage(response);
    developer.log("[LOG] ❌ $logPrefix: ${response.statusCode} - $errorMessage",
        name: "log");

    if (response.statusCode == 404) {
      if (response.data is Map &&
          response.data['message'] == 'Email not found') {
        return "changepw_email_not_exists";
      } else if (response.data['message'] == 'Email already exists') {
        return "signup_email_exists";
      }
    } else if (response.statusCode == 401) {
      return "error_unauthorized";
    } else if (response.statusCode == 500) {
      return _handleServerError(response);
    }

    return "error";
  }

  String _handleNetworkError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout) {
      developer.log("[LOG] ❌ 네트워크 연결 시간 초과");
      return "error_timeout";
    } else if (e.type == DioExceptionType.receiveTimeout) {
      developer.log("[LOG] ❌ 서버 응답 시간 초과");
      return "error_server_timeout";
    } else if (e.type == DioExceptionType.unknown) {
      developer.log("[LOG] ❌ 네트워크 오류: ${e.toString()}");
      return "error_network";
    }
    return "error";
  }

  String _handleServerError(Response response) {
    developer.log("[LOG] ❌ 서버 오류: ${response.statusCode}");
    return "error_server";
  }

  String _getErrorMessage(Response response) {
    if (response.data != null) {
      return response.data['message'] ??
          response.data['error'] ??
          response.data['error_message'] ??
          'Unknown error';
    }
    return 'Unknown error';
  }

  Future<bool> verifyCode(String email, String code) async {
    try {
      final response = await _dio.post(
        '/verify-code',
        data: {"email": email, "code": code},
      );

      if (response.statusCode == 200) {
        developer.log("[LOG] ✅ 인증번호 검증 성공");
        return true;
      } else {
        developer.log("[LOG] ❌ 인증번호 검증 실패, 상태 코드: ${response.statusCode}",
            name: "log");
        return false;
      }
    } catch (e) {
      developer.log("[LOG] ❌ 인증번호 검증 오류: $e");
      return false;
    }
  }

  Future<String?> changPwverifyCode(String email, String code) async {
    try {
      final response = await _dio.post(
        '/changePw-verify-code',
        data: {
          'email': email,
          'code': code,
        },
      );

      if (response.statusCode == 200) {
        final token = response.data['tempToken'];
        return token; // 이 토큰을 나중에 사용
      } else {
        developer.log('❌ 인증번호 실패: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      developer.log('❌ 인증번호 요청 중 오류: $e');
      return null;
    }
  }

  Future<bool> registerUser(
    String name,
    String id,
    String password,
    String email,
    String deviceToken,
  ) async {
    try {
      developer.log(
          "🛠️ 회원가입 요청 - 이름: $name, 아이디: $id, 비밀번호: $password, 이메일: $email",
          name: "log");

      final response = await _dio.post('/register', data: {
        "name": name,
        "id": id,
        "password": password,
        "email": email,
        'deviceToken': deviceToken,
      });

      developer.log("[LOG] ✅ 회원가입 성공: ${response.data}");
      return true;
    } on DioException catch (e) {
      final errorMsg = e.response?.data["message"] ?? "알 수 없는 오류 발생1";
      developer.log("[LOG] ❌ 회원가입 오류: $errorMsg");
      throw errorMsg;
    } catch (e) {
      developer.log("[LOG] ❌ 예외 발생: $e");
      throw "알 수 없는 오류 발생2";
    }
  }

  /// ✅ 로그인 요청 → 성공 시 provider에 토큰 저장
  Future<(bool, String)> loginUser(
      BuildContext context, String id, String password) async {
    developer.log("🚀 loginUser 진입");
    try {
      final response = await _dio.post('/login', data: {
        "id": id,
        "password": password,
      });
      developer.log("✅ Dio 응답 수신 완료");

      if (response.statusCode == 200) {
        final token = response.data['token'];
        developer.log("✅ 토큰 추출 완료");
        await context.read<UserProvider>().saveToken(token);
        return (true, "로그인 성공");
      } else {
        return (false, "로그인 실패");
      }
    } on DioException catch (e) {
      developer.log("❗ DioException 발생:");
      final dynamic data = e.response?.data;
      String errorMessage;

      if (data is Map && data['message'] is String) {
        errorMessage = data['message'];
      } else if (e.message != null) {
        errorMessage = e.message!;
      } else {
        errorMessage = "로그인 중 알 수 없는 오류가 발생했습니다.";
      }

      return (false, errorMessage);
    } catch (e) {
      developer.log("❗ 예기치 못한 오류 발생:");
      return (false, "예기치 못한 오류: ${e.toString()}");
    }
  }

  Future<bool> changePw({
    required String tempToken,
    required String newPassword,
    required String email,
  }) async {
    try {
      final response = await _dio.post(
        '/changePw',
        data: {
          'email': email,
          'newPassword': newPassword,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $tempToken',
          },
        ),
      );

      if (response.statusCode == 200) {
        developer.log("[LOG] ✅ 비번 변경 성공");
        return true;
      } else {
        developer.log("[LOG] ❌ 비번 변경 실패: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      developer.log("[LOG] ❌ 비밀번호 변경 중 오류: $e");
      return false;
    }
  }

  /// ✅ 예시: 대여 이력 조회
  Future<List<dynamic>?> getRentalHistory(BuildContext context) async {
    final token = context.read<UserProvider>().token;
    if (token == null) return null;

    try {
      final response = await _dio.get(
        '/rental-history',
        options: Options(headers: {
          'Authorization': 'Bearer $token',
        }),
      );

      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      developer.log("[LOG] ❌ 대여 이력 조회 오류: $e");
      return null;
    }
  }

  /// ✅ 사용자 프로필 조회
  Future<Map<String, dynamic>?> getUserProfile(BuildContext context) async {
    final userToken = context.read<UserProvider>().token;
    if (userToken == null) return null;

    try {
      final response = await _dio.get(
        '/profile',
        options: Options(headers: {
          'Authorization': 'Bearer $userToken',
        }),
      );

      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      developer.log("[LOG] ❌ 프로필 조회 오류: $e");
      return null;
    }
  }

  Future<Map<String, int>> fetchUmbrellaStatus(String boxId) async {
    try {
      final response = await _dio.get('/umbrella-status', queryParameters: {
        'id': boxId,
      });

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final data = response.data;

        return {
          "umbrella": data["umbrella"] ?? 0,
          "emptySlot": data["emptySlot"] ?? 0,
        };
      } else {
        throw Exception('잘못된 응답입니다: ${response.statusCode}');
      }
    } catch (e) {
      developer.log("❌ fetchUmbrellaStatus 에러: $e");
      throw Exception("서버에서 우산 상태를 불러오는 데 실패했습니다.");
    }
  }

  Future<Map<String, dynamic>> sendLockerIdAndToken(
      BuildContext context, String lockerId) async {
    // UserProvider에서 user_token 가져오기
    final userToken = context.read<UserProvider>().token;

    if (userToken == null) {
      developer.log("[LOG] ❌ 사용자 토큰 없음");
      throw "로그인이 필요합니다.";
    }

    try {
      final response = await _dio.post(
        '/locker-status', // 서버 엔드포인트
        options: Options(
          headers: {
            'Authorization': 'Bearer $userToken', // Bearer 토큰 추가
          },
        ),
        data: {
          'lockerId': lockerId, // 우산함 ID 전송
        },
      );

      if (response.statusCode == 200) {
        developer.log("[LOG] ✅ 우산 사용 정보 전송 완료");
        return response.data; // 서버 응답 반환
      } else {
        developer
            .log("[LOG] ❌ 서버 응답 오류: ${response.statusCode} ${response.data}");
        throw "서버 응답 오류";
      }
    } catch (e) {
      developer.log("[LOG] ❌ 우산 사용 정보 전송 실패: $e");
      rethrow; // 오류 발생 시 다시 던짐
    }
  }

  Future<void> sendUmbrellaRent({
    required String userId,
    required String umbrellaBoxId,
  }) async {
    try {
      final response = await _dio.post(
        '/umb_box',
        data: {
          "user_id": userId,
          "umbrella_box_id": umbrellaBoxId,
        },
        options: Options(
          headers: {"Content-Type": "application/json"},
        ),
      );
    } catch (e) {}
  }

  // 예시로 디바이스 토큰을 서버에 갱신하는 API 요청 메서드 추가
  Future<void> updateDeviceToken(String token, String deviceToken) async {
    try {
      final response = await _dio.post(
        '/updateDeviceToken',
        data: {
          'token': token,
          'deviceToken': deviceToken,
        },
      ).timeout(const Duration(seconds: 5)); // 타임아웃 설정

      if (response.statusCode == 200) {
        developer.log('디바이스 토큰 갱신 성공');
      } else {
        developer.log('디바이스 토큰 갱신 실패: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('디바이스 토큰 갱신 중 오류 발생: $e');
    }
  }

  Future<Map<String, dynamic>> fetchLockerStatus(String lockerId) async {
    try {
      final response = await _dio.get(
        '/locker/$lockerId/status',
      );
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('서버 오류: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<LockerStatus>> fetchAllLockerStatuses() async {
    try {
      final response = await _dio.get('/lockers/status');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((e) => LockerStatus.fromJson(e)).toList();
      } else {
        throw Exception("전체 우산함 상태 불러오기 실패");
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> checkOverdueStatus(String token) async {
    final response = await _dio.get(
      '/overdue',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    print('🛰 응답 상태코드: ${response.statusCode}');
    print('📦 응답 데이터 타입: ${response.data.runtimeType}');
    print('📦 응답 데이터 내용: ${response.data}');

    if (response.statusCode == 200) {
      if (response.data is Map<String, dynamic>) {
        return response.data;
      } else if (response.data is Map) {
        return Map<String, dynamic>.from(response.data);
      } else {
        throw Exception('Unexpected response format: not a JSON object');
      }
    } else {
      throw Exception(
          'Failed to check overdue status (status: ${response.statusCode})');
    }
  }
}
