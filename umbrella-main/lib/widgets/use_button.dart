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
    print("🔄 UseButton didUpdateWidget");
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

  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 40,
      decoration: BoxDecoration(
        color: _isOverdue
            ? const Color.fromARGB(255, 220, 220, 220)
            : const Color(0xFF00B2FF),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            offset: const Offset(0, 3), // 하단으로 그림자 이동
            blurRadius: 6, // 그림자 퍼짐 정도
          ),
        ],
      ),
      child: TextButton(
        onPressed: _isOverdue ? null : widget.onPressed,
        style: TextButton.styleFrom(
          backgroundColor: Colors.transparent, // Container가 배경색 담당
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
        ),
        child: Center(
          child: Text(
            _isOverdue ? (_countdownText ?? '') : '이용하기',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: _isOverdue ? Colors.white : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
