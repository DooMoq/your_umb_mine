import 'dart:async';
import 'package:flutter/material.dart';

class UseButton extends StatefulWidget {
  final DateTime? releaseDate;
  final bool isOverdue;
  final VoidCallback onPressed;
  final VoidCallback? onOverdueLifted;

  const UseButton({
    super.key,
    required this.releaseDate,
    required this.isOverdue,
    required this.onPressed,
    this.onOverdueLifted,
  });

  @override
  State<UseButton> createState() => _UseButtonState();
}

class _UseButtonState extends State<UseButton> {
  Timer? _timer;
  bool _isOverdue = false;
  String? _countdownText;

  @override
  void initState() {
    super.initState();
    _isOverdue = widget.isOverdue;
    if (_isOverdue && widget.releaseDate != null) {
      _startCountdown(widget.releaseDate!);
    }
  }

  @override
  void didUpdateWidget(covariant UseButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isOverdue != oldWidget.isOverdue ||
        widget.releaseDate != oldWidget.releaseDate) {
      _timer?.cancel();

      _isOverdue = widget.isOverdue;

      if (_isOverdue && widget.releaseDate != null) {
        _startCountdown(widget.releaseDate!);
      } else {
        setState(() {
          _countdownText = null;
        });
      }
    }
  }

  void _startCountdown(DateTime releaseDate) {
    _updateCountdown(releaseDate); // 첫 계산
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCountdown(releaseDate);
    });
  }

  void _updateCountdown(DateTime releaseDate) {
    final now = DateTime.now();
    final difference = releaseDate.difference(now);

    if (!mounted) return;

    if (difference.isNegative) {
      setState(() {
        _isOverdue = false;
        _countdownText = null;
        _timer?.cancel();
      });
      widget.onOverdueLifted?.call();
    } else {
      setState(() {
        if (difference.inDays >= 1) {
          _countdownText = "${difference.inDays}일 후 이용 가능";
        } else {
          final hours =
              difference.inHours.remainder(24).toString().padLeft(2, '0');
          final minutes =
              difference.inMinutes.remainder(60).toString().padLeft(2, '0');
          final seconds =
              difference.inSeconds.remainder(60).toString().padLeft(2, '0');
          _countdownText = "$hours:$minutes:$seconds 후 이용 가능";
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: ElevatedButton(
        onPressed: _isOverdue ? null : widget.onPressed,
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.disabled)) {
              return const Color.fromARGB(255, 213, 213, 213); // 비활성화일 때 배경색
            }
            return const Color(0xFF00B2FF); // 활성화일 때 배경색
          }),
          foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.disabled)) {
              return Colors.black54; // 비활성화일 때 텍스트 색상
            }
            return Colors.white; // 활성화일 때 텍스트 색상
          }),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40),
            ),
          ),
        ),
        child: Text(
          _isOverdue ? (_countdownText ?? '') : '이용하기',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
