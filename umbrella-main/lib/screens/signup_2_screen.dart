import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:umbrella/services/api_service.dart';

class Signup2Screen extends StatefulWidget {
  final String email;
  final bool isPasswordReset;

  const Signup2Screen({
    super.key,
    required this.email,
    required this.isPasswordReset,
  });

  @override
  _Signup2ScreenState createState() => _Signup2ScreenState();
}

class _Signup2ScreenState extends State<Signup2Screen> {
  final TextEditingController _codeController = TextEditingController();
  int _remainingSeconds = 8;
  Timer? _timer;
  bool _isTimeOver = false;
  final RegExp _codeRegex = RegExp(r'^\d{6}$'); // 6자리 숫자 정규식
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    //위젯이 생성될 때 호출되는 메서드
    super.initState();
    _startCountdown(); //위젯이 화면에 처음 표시될 때 타이머나 카운트다운을 시작
  }

  // 타이머 시작
  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--; //시간 감소
        });
      } else {
        setState(() {
          _isTimeOver = true; //타이머 종료
        });
        timer.cancel();
      }
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return "$minutes:${secs.toString().padLeft(2, '0')}";
  }

  // 인증번호 재발송 함수
  void _resendCode() async {
    setState(() {
      _remainingSeconds = 4;
      _isTimeOver = false;
    });
    _startCountdown();

    try {
      String sent = await _apiService.sendVerificationCode(
        widget.email,
        widget.isPasswordReset,
      );

      if (!mounted) return;

      if (sent == "success") {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar() //..: 연속적으로 호출하는 방식
          ..showSnackBar(const SnackBar(
            content: Text("새 인증번호가 전송되었습니다."),
          ));
      } else {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(
            content: Text("인증번호 전송 실패."),
          ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text("인증번호 전송 중 오류가 발생했습니다. 다시 시도해 주세요."),
        ));
    }
  }

  // 인증번호 검증 함수
  Future<void> _validateCode() async {
    String email = widget.email;

    if (_isTimeOver) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text("인증번호 입력 시간이 만료되었습니다."),
            backgroundColor: Colors.red,
          ),
        );
      return;
    }

    if (_codeRegex.hasMatch(_codeController.text.trim())) {
      final code = _codeController.text.trim();

      if (!mounted) return;

      if (widget.isPasswordReset) {
        String? tempToken = await _apiService.changPwverifyCode(email, code);

        if (tempToken != null) {
          context.push('/signup3', extra: {
            'email': email,
            'tempToken': tempToken,
            'isPasswordReset': true,
          });
        } else {
          _showSnackBar("인증번호를 확인해주세요.");
        }
      } else {
        bool isValid = await _apiService.verifyCode(email, code);

        if (isValid) {
          context.push('/signup3', extra: {
            'email': email,
            'isPasswordReset': false,
          });
        } else {
          _showSnackBar("인증번호를 확인해주세요.");
        }
      }
    } else {
      _showSnackBar("인증번호는 6자리 숫자여야 합니다.");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
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
            if (GoRouter.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: Text(
          widget.isPasswordReset ? "비밀번호 변경" : "회원가입",
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
                controller: _codeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "인증번호",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(7),
                    borderSide:
                        const BorderSide(color: Colors.orange, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(7),
                    borderSide:
                        const BorderSide(color: Colors.orange, width: 2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _isTimeOver
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: _resendCode,
                      child: const Text(
                        "인증번호 재발송",
                        style: TextStyle(color: Colors.blue, fontSize: 14),
                      ),
                    ),
                  )
                : RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                      children: [
                        const TextSpan(text: "메일로 전송된 인증번호를 입력해 주세요.\n"),
                        const TextSpan(
                            text: "제한 시간이 지나면 다시 요청해야 합니다. (남은 시간: "),
                        TextSpan(
                          text: _formatTime(_remainingSeconds),
                          style: const TextStyle(
                              color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: ")"),
                      ],
                    ),
                  ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _validateCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                child: const Text(
                  "확인",
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
