import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:umbrella/provider/user_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:umbrella/services/api_service.dart';
import 'dart:developer' as developer;

class FirstScreen extends StatefulWidget {
  //FirstScreen이라는 화면(위젯) 클래스를 만듦
  const FirstScreen({super.key}); //화면 생성자 (super.key는 Flutter 내부에서 고유 키를 관리해줌)

  @override //밑에 있는 createState()는 부모 클래스의 것을 재정의
  FirstScreenState createState() =>
      FirstScreenState(); //진짜 화면 내용(build 메소드 같은 거)은 FirstScreenState 안에 만들 거야.
}

class FirstScreenState extends State<FirstScreen>
    with SingleTickerProviderStateMixin {
  //애니메이션에 필요한 Ticker(시간을 재는 시계)를 제공해주는 역할 (vsync를 위해 필요)
  late AnimationController _controller; //애니메이션을 직접 시작, 중지, 리셋 할 수 있게 하는 컨트롤러
  bool _animationFinished = false; //애니메이션이 끝났는지 체크하는 변수

  @override
  void initState() {
    super.initState(); //부모 클래스의 initState 실행

    _controller = AnimationController(
      //_controller를 설정해서 애니메이션 준비
      vsync: this, //애니메이션을 위한 vsync(애니메이션이 화면 프레임에 맞춰 부드럽게 돌게 함) 설정
      duration: const Duration(milliseconds: 3000),
    );

    // forward()	애니메이션을 시작, .whenComplete()	애니메이션이 끝난 "후에" 실행할 코드 작성 (로그인 상태 체크)
    _controller.forward().whenComplete(() async {
      setState(() {
        _animationFinished = true; //애니메이션 끝났다고 표시해서 화면 다시 그림
      });

      // 로그인 되어 있으면 main으로 이동
      final userProvider = context.read<UserProvider>();
      await userProvider.loadUserFromStorage().catchError((e) {
        developer.log("[LOG] 토큰 로딩 오류: $e");
      }); // 저장된 JWT 토큰을 불러와 로그인 상태 확인

      if (!mounted) return; //(안전장치) 현재 위젯이 살아있을 때만 다음 코드 실행

      if (userProvider.isLoggedIn && mounted) {
        // 로그인 되어 있으면 디바이스 토큰을 서버에 갱신 또는 유지
        await _getAndSendDeviceToken(userProvider); // 디바이스 토큰을 가져와 서버에 갱신
        if (mounted) {
          context.go('/main');
        } // 로그인 되어 있으면 main으로 이동
      }
    });
  }

  Future<void> _getAndSendDeviceToken(UserProvider userProvider) async {
    try {
      final FirebaseMessaging messaging = FirebaseMessaging.instance;

      // 디바이스 토큰 가져오기 (5초 제한)
      String? deviceToken =
          await messaging.getToken().timeout(const Duration(seconds: 5));

      if (!mounted) return;
      if (deviceToken != null) {
        developer.log("[LOG] 디바이스토큰: ${deviceToken.substring(0, 20)}...",
            name: "log");

        // 서버 전송도 timeout 설정
        await context
            .read<ApiService>()
            .updateDeviceToken(userProvider.token!, deviceToken)
            .timeout(const Duration(seconds: 5));
      }
    } catch (e) {
      developer.log("[LOG] 디바이스 토큰 처리 중 오류: $e");
    }
  }

  @override
  void dispose() {
    //위젯이 화면에서 사라질 때(dispose() 호출될 때) 만든 리소스(AnimationController) 안 정리하면 메모리 누수, 앱 느려, 죽음(크래시)
    //dispose하면 좋은거(TextEditingController, AnimationController, StreamController, FocusNode, Timer, PageController, ScrollController, ValueNotifier 등)
    //메모리 자원을 명시적으로 할당하거나 해제하는 자원을 dispose
    _controller.dispose(); //애니메이션 컨트롤러가 쓰던 리소스(메모리)를 정리
    super
        .dispose(); //State라는 Flutter 기본 클래스도 자기 내부에서 정리해야 할 것이 있을 수 있음. 순서중요. 내꺼 정리 → 부모꺼 정리
  }

  @override
  Widget build(BuildContext context) {
    //위젯이 화면에 어떻게 생겼는지 그리는 함수
    return Scaffold(
      backgroundColor: const Color(0xFF26539C),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(80, 0, 80, 160),
              child: _animationFinished
                  ? Image.asset(
                      'lib/assets/anim_last_frame.jpg') //_animationFinished가 true일 때
                  : Image.asset('lib/assets/anim.gif',
                      gaplessPlayback:
                          true), //false. gaplessPlayback 깜빡임 없이 부드럽게
            ),
            if (_animationFinished) ...[
              //...[]: 여러 개의 위젯을 나열할 수 있는 리스트
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 80, vertical: 10),
                child: ElevatedButton(
                  onPressed: () {
                    context.push('/signup');
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 5,
                    shadowColor: Colors.black,
                    backgroundColor: const Color(0xff0088ff),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    minimumSize: const Size(double.infinity, 45),
                  ),
                  child: const Text(
                    "회원가입",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  context.push('/login');
                },
                child: const Text(
                  "로그인",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 50),
            ],
          ],
        ),
      ),
    );
  }
}
