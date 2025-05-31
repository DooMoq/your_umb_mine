import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/first_screen.dart';
import 'screens/signup_1_screen.dart';
import 'screens/signup_2_screen.dart';
import 'screens/signup_3_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/weather_screen.dart';
import 'package:provider/provider.dart';
import 'package:umbrella/provider/user_provider.dart';
import 'package:umbrella/services/api_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/user_screen.dart';

String? initialNotificationType;
void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); //Flutter의 바인딩(내부 연결 시스템) 준비 완료. = Flutter 앱이 본격적으로 시작되기 전에 필요한 준비를 완료. (앱 시작 전에 꼭 초기화해야 하는 SharedPreferences (앱에 저장된 데이터 불러올 때) 때문에 사용)
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase 초기화 실패: $e");
  }
  RemoteMessage? initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();

  if (initialMessage != null) {
    // 앱이 종료되었을 때 푸시 클릭으로 진입한 경우
    final type = initialMessage.data['type'];
    if (type == 'expired') {
      initialNotificationType = 'expired';
    }
  }
  final userProvider = UserProvider();
  await userProvider.loadUserFromStorage(); //앱 시작 시 사용자 데이터 로드

  runApp(
    //Flutter 애플리케이션을 시작하는 함수
    MultiProvider(
      //여러 개의 Provider를 한번에 관리하는 컨테이너.
      providers: [
        //Provider는 상태나 의존성을 관리
        ChangeNotifierProvider(
            //상태 관리를 위한 Provider
            create: (_) => //(_): 인자를 사용하지 않고. () => object 형태: 객체 생성하고 반환
                userProvider), //ChangeNotifier를 상속받음. 따라서 notifyListeners()로 상태가 변경되면 이 상태를 구독하고 있는 UI 위젯들이 자동으로 갱신.
        Provider<ApiService>(
            create: (_) =>
                ApiService()), // ApiService를 싱글톤(애플리케이션 전반에서 한 번만 생성되도록)으로 앱에 주입
      ],
      child:
          MyApp(), //MyApp()은 앱의 루트 위젯. MultiProvider를 통해 제공된 상태와 의존성을 MyApp 내에서 사용 가능
    ),
  );
}

class MyApp extends StatelessWidget {
  final GoRouter _router = GoRouter(
    //GoRouter는 네비게이션과 화면 간의 전환을 관리하는 데 사용
    routes: [
      GoRoute(path: '/', builder: (context, state) => const FirstScreen()),
      GoRoute(
        //GoRoute는 실제로 URL 경로(path)와 화면을 연결
        path: '/signup',

        ///signup 경로로 이동할 때
        builder: (context, state) {
          final isPasswordReset = state.extra
                  as bool? ?? //as bool?은 bool? 타입인지를 확인. bool타입 아니면 ClassCastException 에러
              //??: 왼쪽 값(state.extra)이 null인 경우 오른쪽 값을 반환
              false; //isPasswordReset(동적 값) 전달. state.extra를 사용하여 값(email) 전달하고, 이를 화면에서 사용할 수 있게
          return SignupOrResetScreen(
              isPasswordReset:
                  isPasswordReset); //해당 값을 SignupOrResetScreen에서 사용
        },
      ),
      GoRoute(
        path: '/signup2',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final email = extra['email'] as String? ?? '';
          final isPasswordReset = extra['isPasswordReset'] as bool? ?? false;
          return Signup2Screen(email: email, isPasswordReset: isPasswordReset);
        },
      ),
      GoRoute(
        path: '/signup3',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final email = extra['email'] as String? ?? '';
          final isPasswordReset = extra['isPasswordReset'] as bool? ?? false;
          final tempToken = extra['tempToken'] as String? ?? '';
          return Signup3Screen(
              email: email,
              isPasswordReset: isPasswordReset,
              tempToken: tempToken);
        },
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/main', builder: (context, state) => const MainScreen()),
      GoRoute(
        path: '/weather',
        builder: (context, state) => const WeatherScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const UserScreen(),
      ),
    ],
  );

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      //전체 라우팅 시스템을 앱에 적용. MaterialApp: 앱의 루트 위젯, 앱의 기본적인 설정과(애플리케이션의 테마, 네비게이션, 다국어 지원, 라우팅..) 구성을 제공.
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
    );
  }
}
