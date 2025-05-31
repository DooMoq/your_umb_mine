import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:dio/dio.dart';

class MockApiInterceptor extends Interceptor {
  static final Map<String, String> _codeStore = {};
  static final Map<String, Map<String, String>> _users = {
    "20221317": {
      "email": 'jam6579@sch.ac.kr',
      "name": '홍정민',
      "id": '20221317',
      "password": '111111!',
      "deviceToken":
          'e_4_Mw_1RwWFszxJXBjoPm:APA91bHegritT_66ld-oXb2huwWE87B53cLBhF6gqoDiXFq6RGFARMc0NDvoqYZNW8gmjAGMQu3WwAvZmzP9BA39Nrn2Sarm1SY10LwmtXFWhhW4q0qjgnM',
    },
    "20221318": {
      "email": 'jam657961@sch.ac.kr',
      "name": '임승현',
      "id": '20221318',
      "password": '111111!',
      "deviceToken":
          'e_4_Mw_1RwWFszxJXBjoPm:APA91bHegritT_66ld-oXb2huwWE87B53cLBhF6gqoDiXFq6RGFARMc0NDvoqYZNW8gmjAGMQu3WwAvZmzP9BA39Nrn2Sarm1SY10LwmtXFWhhW4q0qjgnM',
    },
  };

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final path = options.path;
    //개별 우산함 상태 조회
    final RegExp lockerStatusRegex = RegExp(r'^/locker/([^/]+)/status$');
    final match = lockerStatusRegex.firstMatch(options.path);

    if (path == '/send-email') {
      String email = options.data?["email"] ?? '';
      bool isPasswordReset =
          options.queryParameters['isPasswordReset'] == 'true';

      if (isPasswordReset) {
        bool emailExists = _users.values.any((user) => user["email"] == email);

        if (emailExists) {
          String code = (Random().nextInt(900000) + 100000).toString();
          _codeStore[email] = code;
          print("📩 Mock 인증번호 발송 (비밀번호 변경): $code");
          developer.log("[LOG] 📩 Mock 인증번호 발송 (비밀번호 변경): $code");
          handler.resolve(Response(requestOptions: options, statusCode: 200));
        } else {
          developer.log("[LOG] ❌ 비밀번호 변경 실패 - 존재하지 않는 이메일: $email");
          handler.resolve(Response(
              requestOptions: options,
              statusCode: 404,
              data: {"message": "Email not found"}));
        }
      } else {
        bool emailExists = _users.values.any((user) => user["email"] == email);

        if (emailExists) {
          handler.resolve(Response(
            requestOptions: options,
            statusCode: 404,
            data: {"message": "Email already exists"},
          ));
        } else {
          String code = (Random().nextInt(900000) + 100000).toString();
          _codeStore[email] = code;
          print("📩 Mock 인증번호 발송: $code");
          developer.log("[LOG] 📩 Mock 인증번호 발송: $code");
          handler.resolve(Response(requestOptions: options, statusCode: 200));
        }
      }
    } else if (path == '/verify-code') {
      String? email = options.data?["email"];
      String? code = options.data?["code"];

      if (_codeStore[email] == code) {
        developer.log("[LOG] ✅ 인증번호 검증 성공!");
        handler.resolve(Response(requestOptions: options, statusCode: 200));
      } else {
        developer.log("[LOG] ❌ 인증번호 검증 실패! 저장된 인증번호: ${_codeStore[email]}",
            name: "log");
        handler.reject(DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          message: "인증번호가 올바르지 않습니다.",
        ));
      }
    } else if (path == '/changePw-verify-code') {
      // ✅ 비밀번호 변경용 인증번호 확인 + 임시 토큰 발급
      String? email = options.data?["email"];
      String? code = options.data?["code"];

      if (_codeStore[email] == code) {
        final userEntry = _users.entries.firstWhere(
          (entry) => entry.value["email"] == email,
          orElse: () => const MapEntry('', {}),
        );

        if (userEntry.key.isEmpty) {
          handler.reject(DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            message: "해당 이메일의 유저가 없습니다.",
          ));
          return;
        }

        final payload = {
          "id": userEntry.key,
          "email": email,
          "exp": DateTime.now()
                  .add(const Duration(minutes: 5))
                  .millisecondsSinceEpoch ~/
              1000,
        };
        final header =
            base64Url.encode(utf8.encode('{"alg":"HS256","typ":"JWT"}'));
        final encodedPayload =
            base64Url.encode(utf8.encode(jsonEncode(payload)));
        final tempToken = "$header.$encodedPayload.mock-signature";

        developer.log("[LOG] ✅ 비번 재설정용 토큰 발급 완료: $tempToken");
        handler.resolve(Response(
          requestOptions: options,
          statusCode: 200,
          data: {"tempToken": tempToken},
        ));
      } else {
        developer.log("[LOG] ❌ 비밀번호 인증 실패: ${_codeStore[email]}");
        handler.reject(DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          message: "인증번호가 올바르지 않습니다.",
        ));
      }
    } else if (path == '/register') {
      String? name = options.data?["name"];
      String? id = options.data?["id"];
      String? password = options.data?["password"];
      String? email = options.data?["email"];
      String? deviceToken = options.data?["deviceToken"];

      if (name == null || name.isEmpty) {
        handler.reject(DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          message: "이름이 없습니다.",
        ));
        return;
      }

      if (id == null ||
          id.isEmpty ||
          id.length != 8 ||
          !RegExp(r'^\d{8}$').hasMatch(id)) {
        handler.reject(DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          message: "아이디는 8자리 숫자여야 합니다.",
        ));
        return;
      }

      if (password == null ||
          password.isEmpty ||
          password.length < 7 ||
          !RegExp(r'[@$!%*?&]').hasMatch(password)) {
        handler.reject(DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          message: "비밀번호는 7자 이상이고 특수문자가 포함되어야 합니다.",
        ));
        return;
      }

      if (_users.containsKey(id)) {
        handler.reject(DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: options,
            statusCode: 400,
            data: {"message": "아이디가 이미 존재합니다."},
          ),
        ));
        return;
      }

      if (deviceToken == null || deviceToken.isEmpty) {
        handler.reject(DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          message: "디바이스토큰이 없습니다.",
        ));
        return;
      }

      _users[id] = {
        "email": email!,
        "name": name,
        "id": id,
        "password": password,
        "deviceToken": deviceToken,
      };
      developer.log("[LOG] ✅ Mock 회원가입 성공: ${_users[id]}");
      handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: {"message": "회원가입 성공!"},
      ));
    } else if (path == '/login') {
      String? id = options.data?["id"];
      String? password = options.data?["password"];

      if (!_users.containsKey(id)) {
        handler.reject(DioException(
          requestOptions: options,
          response: Response(
            requestOptions: options,
            statusCode: 400,
            data: {"message": "아이디가 존재하지 않습니다."},
          ),
          type: DioExceptionType.badResponse,
          message: "아이디가 존재하지 않습니다.",
        ));
        return;
      }

      if (_users[id]?["password"] != password) {
        handler.reject(DioException(
          requestOptions: options,
          response: Response(
            requestOptions: options,
            statusCode: 401,
            data: {"message": "비밀번호가 틀립니다."},
          ),
          type: DioExceptionType.badResponse,
          message: "비밀번호가 틀립니다.",
        ));
        developer.log("비밀번호가 틀립니다.");
        return;
      }
      final payload = {
        "id": _users[id]!["id"],
        "name": _users[id]!["name"],
        "email": _users[id]!["email"],
        "exp": DateTime.now()
                .add(const Duration(days: 1))
                .millisecondsSinceEpoch ~/
            1000,
      };
      final header =
          base64Url.encode(utf8.encode('{"alg":"HS256","typ":"JWT"}'));
      final encodedPayload = base64Url.encode(utf8.encode(jsonEncode(payload)));
      final mockToken = "$header.$encodedPayload.mock-signature";

      handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: {"message": "로그인 성공!", "token": mockToken},
      ));
      print("로그인 성공! ${mockToken}");
      return;
    } else if (path == '/profile') {
      final authHeader = options.headers['Authorization'];
      developer.log("[LOG] 🔐 Authorization header: $authHeader");

      if (authHeader == null || !authHeader.toString().startsWith('Bearer ')) {
        handler.reject(DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          message: "Authorization header missing or invalid",
        ));
        return;
      }

      final token = authHeader.toString().substring(7);
      final payload = _decodeJwtPayload(token);
      final userId = payload['id'];

      if (!_users.containsKey(userId)) {
        handler.reject(DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          message: "사용자 정보 없음",
        ));
        return;
      }

      final user = _users[userId]!;

      handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: {
          "id": user["id"],
          "name": user["name"],
          "email": user["email"],
        },
      ));
    } else if (path == '/changePw') {
      String email = options.data?["email"] ?? '';
      String newPassword = options.data?["newPassword"] ?? '';
      developer.log("[LOG] 🔐 changePw 요청 - email: $email, newPw: $newPassword",
          name: "log");

      // 임시 토큰을 Authorization 헤더로 받기
      final authHeader = options.headers['Authorization'];
      if (authHeader == null || !authHeader.toString().startsWith('Bearer ')) {
        handler.reject(DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          message: "Authorization header missing or invalid",
        ));
        return;
      }

      final token = authHeader.toString().substring(7); // "Bearer " 이후의 토큰 추출
      final payload = _decodeJwtPayload(token);
      final emailFromToken = payload['email'];
      developer.log("[LOG] 🔐 token payload email: $emailFromToken");
      // 이메일이 토큰에서 추출된 이메일과 일치하는지 확인
      if (email != emailFromToken) {
        handler.reject(DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          message: "이메일이 토큰과 일치하지 않습니다.",
        ));
        return;
      }

      final userEntry = _users.entries.firstWhere(
        (entry) => entry.value["email"] == email,
        orElse: () => const MapEntry('', {}),
      );

      if (userEntry.key.isEmpty) {
        handler.reject(DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          message: "해당 이메일의 유저가 없습니다.",
        ));
        return;
      }

      // 비밀번호 변경
      _users[userEntry.key]?["password"] = newPassword;

      developer.log("[LOG] ✅ 비밀번호 변경 성공 (mock)");
      handler.resolve(Response(requestOptions: options, statusCode: 200));
    }

    // ✅ 우산함 상태 응답 처리
    else if (options.path == '/umbrella-status') {
      final boxId = options.queryParameters['id'];

      if (boxId == '1') {
        return handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              "umbrella": 5,
              "emptySlot": 3,
            },
          ),
        );
      } else if (boxId == '2') {
        return handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              "umbrella": 0,
              "emptySlot": 8,
            },
          ),
        );
      } else {
        return handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 404,
            data: {
              "message": "해당 우산함을 찾을 수 없습니다.",
            },
          ),
        );
      }
    } else if (options.path == '/locker-status') {
      // 여기서 응답 시뮬레이션
      final mockResponse = {
        'action': 'rent', // 또는 'return'
        'roomId': 'mockRoom123', // 웹소켓 룸 ID
      };

      return handler.resolve(
        Response(
          requestOptions: options,
          data: mockResponse,
          statusCode: 200,
        ),
      );
    } else if (path == '/updateDeviceToken') {
      final String? token = options.data?["token"];
      final String? deviceTokenFromClient = options.data?["deviceToken"];

      if (token == null || deviceTokenFromClient == null) {
        handler.reject(DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          message: "토큰 또는 디바이스 토큰 누락",
        ));
        return;
      }

      final payload = _decodeJwtPayload(token);
      final userId = payload['id'];

      if (!_users.containsKey(userId)) {
        handler.reject(DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          message: "사용자 정보 없음",
        ));
        return;
      }

      final user = _users[userId]!;
      final serverToken = user["deviceToken"];

      if (serverToken == null) {
        // 디바이스 토큰이 없는 경우 새로 저장
        user["deviceToken"] = deviceTokenFromClient;
        developer.log("[LOG] 📱 디바이스 토큰 최초 저장: $deviceTokenFromClient");
      } else if (serverToken != deviceTokenFromClient) {
        // 서버 토큰과 클라이언트 토큰이 다른 경우 서버 값을 갱신
        user["deviceToken"] = deviceTokenFromClient;
        developer.log("[LOG] 🔄 디바이스 토큰 변경됨: $deviceTokenFromClient");
      } else {
        // 서버 토큰과 클라이언트 토큰이 같으면 아무것도 하지 않음
        developer.log("[LOG] ✅ 디바이스 토큰 동일, 갱신 생략");
      }

      handler.resolve(Response(requestOptions: options, statusCode: 200));
    } else if (options.path == '/lockers/status' && options.method == 'GET') {
      return handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: [
          {
            "lockerId": "locker1",
            "umbrellaCount": 5,
          },
          {
            "lockerId": "locker2",
            "umbrellaCount": 2,
          }
        ],
      ));
    } else if (match != null && options.method == 'GET') {
      final lockerId = match.group(1);

      final mockData = {
        "locker1": {"umbrellaCount": 3},
        "locker2": {"umbrellaCount": 1},
      };

      final data = mockData[lockerId] ?? {"umbrellaCount": 0};

      return handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: data,
      ));
    } // ✅ 연체 여부 확인용 API 처리
    else if (path == '/overdue') {
      final authHeader = options.headers['Authorization'];
      if (authHeader == null || !authHeader.toString().startsWith('Bearer ')) {
        handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            message: "인증 토큰이 없습니다.",
          ),
        );
        return;
      }

      final token = authHeader.toString().substring(7);
      final parts = token.split('.');
      if (parts.length < 2) {
        handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            message: "잘못된 토큰 형식입니다.",
          ),
        );
        return;
      }

      final payload = jsonDecode(
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      final userId = payload['id'];
      print("디코딩된 userId: $userId (${userId.runtimeType})");

      if (userId.toString() == '20221317') {
        print("✅ 연체된 사용자로 간주함");
        const releaseDateStr = "2025-06-20T23:59:59";
        final releaseDate = DateTime.parse(releaseDateStr);

        handler.resolve(Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            "isOverdue": true,
            "releaseDate": releaseDate.toIso8601String(),
          },
        ));
      } else {
        // ✅ 그 외 유저는 연체 아님
        handler.resolve(Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            "isOverdue": false,
          },
        ));
      }
      return;
    } else {
      handler.next(options);
    }
  }

  Map<String, dynamic> _decodeJwtPayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return {};
    try {
      final payload =
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      return jsonDecode(payload);
    } catch (e) {
      developer.log("[LOG] ❌ JWT 디코딩 실패: $e");
      return {};
    }
  }
}
