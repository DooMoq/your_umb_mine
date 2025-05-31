import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:umbrella/services/api_service.dart'; // ApiService import 추가

class SignupOrResetScreen extends StatefulWidget {
  final bool isPasswordReset; // 비밀번호 변경인지 여부를 확인하는 플래그 추가

  const SignupOrResetScreen(
      {super.key, required this.isPasswordReset}); // 플래그를 필수값으로 추가

  @override
  State<SignupOrResetScreen> createState() => _SignupOrResetScreenState();
}

class _SignupOrResetScreenState extends State<SignupOrResetScreen> {
  final TextEditingController _emailController = TextEditingController();
  final RegExp emailRegex = RegExp(r'.+@sch\.ac\.kr$');
  final ApiService _apiService = ApiService();

  void _showSnackBar(String message, {Color backgroundColor = Colors.red}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  Future<void> _validateAndProceed() async {
    String email = _emailController.text.trim();

    if (!emailRegex.hasMatch(email)) {
      _showSnackBar("유효한 SCH Mail이 아닙니다.");
      return;
    }

    try {
      String result =
          await _apiService.sendVerificationCode(email, widget.isPasswordReset);

      if (!mounted) return; // 위젯이 트리에 존재하는지 체크

      if (widget.isPasswordReset) {
        // 비밀번호 변경 시 동작
        if (result == "success") {
          context.push('/signup2', extra: {
            'email': email,
            'isPasswordReset': widget.isPasswordReset, // 이 값을 그대로 넘김
          }); // 비밀번호 변경 절차로 이동
        } else if (result == "changepw_email_not_exists") {
          // 비밀번호 변경 이메일이 존재하지 않으면 처리
          _showSnackBar("비밀번호 변경할 이메일이 존재하지 않습니다. 다시 확인해주세요.");
        } else if (result == "error_timeout") {
          _showSnackBar("네트워크 지연으로 인증번호 발송에 실패했습니다.");
        } else if (result == "error_server_timeout") {
          _showSnackBar("서버 응답이 지연되었습니다. 잠시 후 시도해주세요.");
        } else if (result == "error_network") {
          _showSnackBar("인터넷 연결을 확인해주세요.");
        } else {
          // 기타 오류 처리
          _showSnackBar("비밀번호 변경 이메일 인증 오류가 발생했습니다.");
        }
      } else {
        // 회원가입 로직
        if (result == "success") {
          context.push('/signup2', extra: {
            'email': email,
            'isPasswordReset': widget.isPasswordReset, // 이 값을 그대로 넘김
          }); // 회원가입 절차로 이동
        } else if (result == "signup_email_exists") {
          // 이미 가입된 이메일 처리
          _showSnackBar("이메일이 이미 존재합니다.");
        } else if (result == "error_timeout") {
          _showSnackBar("네트워크 지연으로 인증번호 발송에 실패했습니다.");
        } else if (result == "error_server_timeout") {
          _showSnackBar("서버 응답이 지연되었습니다. 잠시 후 시도해주세요.");
        } else if (result == "error_network") {
          _showSnackBar("인터넷 연결을 확인해주세요.");
        } else if (result == "error") {
          // 인증번호 발송 실패 처리
          _showSnackBar("인증번호 발송 실패. 다시 시도해 주세요.");
        }
      }
    } catch (e) {
      _showSnackBar("인증 요청 중 오류가 발생했습니다. 다시 시도해 주세요.");
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
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
            if (widget.isPasswordReset) {
              context.go('/login');
            } else {
              if (GoRouter.of(context).canPop()) {
                // 이전 페이지가 있으면
                context.pop(); //이전 페이지로 이동
              } else {
                context.go('/'); //이전 페이지가 없으면 /으로
              }
            }
          },
        ),
        title: Text(
          widget.isPasswordReset
              ? "비밀번호 변경"
              : "회원가입", // 비밀번호 변경 시 제목 변경. 참 왼쪽, 거짓 오른쪽
          style: const TextStyle(fontWeight: FontWeight.bold),
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
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: "SCH Mail",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(7),
                    borderSide:
                        const BorderSide(color: Colors.orange, width: 2),
                  ),
                ),
              ),
            ),
            widget.isPasswordReset
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      "가입한 이메일을 입력해주세요.",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  )
                : const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _validateAndProceed, // 이메일 검증 및 서버 요청
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                child: const Text(
                  "인증번호 전송",
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
