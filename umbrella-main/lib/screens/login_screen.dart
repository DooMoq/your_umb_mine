import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:umbrella/services/api_service.dart';
import 'package:umbrella/services/auth_service.dart';
import 'dart:developer' as developer;
import 'package:umbrella/provider/user_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _errorMessage = '';

  // 로그인 버튼 클릭 시 호출되는 함수
  void _validateAndLogin() async {
    try {
      developer.log("🚀 로그인 시도");

      String id = _idController.text.trim();
      String password = _passwordController.text.trim();

      if (id.isEmpty || password.isEmpty) {
        setState(() {
          _errorMessage = '아이디와 비밀번호를 입력해 주세요.';
        });
        return;
      }

      final apiService = context.read<ApiService>();
      final (success, message) =
          await apiService.loginUser(context, id, password);
      developer.log("✅ 로그인 결과: $success / $message");
      if (!mounted) return;

      developer.log("✅ 로그인 결과: $success / $message");

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.green),
        );
        context.go('/main');
      } else {
        setState(() {
          _errorMessage = message;
        });
      }
    } catch (e) {
      developer.log("❗ 로그인 중 예외: ${e.toString()}");
      setState(() {
        _errorMessage = "로그인 처리 중 오류: ${e.toString()}";
      });
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            context.go('/'); // 첫 화면으로 이동
          },
        ),
        title: const Text(
          "로그인",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 50,
              child: TextField(
                controller: _idController,
                decoration: InputDecoration(
                  hintText: "아이디",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(7),
                    borderSide: const BorderSide(color: Colors.grey, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(7),
                    borderSide:
                        const BorderSide(color: Colors.orange, width: 2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              height: 50,
              child: TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "비밀번호",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(7),
                    borderSide: const BorderSide(color: Colors.grey, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(7),
                    borderSide:
                        const BorderSide(color: Colors.orange, width: 2),
                  ),
                ),
              ),
            ),
            // 오류 메시지 표시
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _validateAndLogin, // 로그인 버튼 클릭 시 호출
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                child: const Text(
                  "로그인",
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 25),
            Center(
              child: GestureDetector(
                //사용자의 제스처(터치, 스와이프 등)를 감지하고 특정 동작
                onTap: () {
                  //터치했을 때
                  context.go('/signup', extra: true);
                },
                child: const Text(
                  "비밀번호를 잊어버리셨나요?",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
