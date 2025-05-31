import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:umbrella/widgets/use_button.dart';

class LockerDetailWidget extends StatefulWidget {
  final DateTime? releaseDate;
  final bool isOverdue;
  final String locationName;
  final int umbrellaCount;
  final int emptySlotCount;
  final VoidCallback onTapUse;

  const LockerDetailWidget({
    super.key,
    this.releaseDate,
    required this.isOverdue,
    required this.locationName,
    required this.umbrellaCount,
    required this.emptySlotCount,
    required this.onTapUse,
  });
  @override
  State<LockerDetailWidget> createState() => _LockerDetailWidgetState();
}

class _LockerDetailWidgetState extends State<LockerDetailWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 230,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 3,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 227, 227, 227),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.locationName,
                style: const TextStyle(
                  fontSize: 18,
                  color: Color.fromARGB(255, 78, 78, 78),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 50,
                child: Column(
                  children: [
                    Text(
                      "${widget.umbrellaCount}",
                      style: const TextStyle(
                        fontSize: 40,
                        color: Color(0xFF0061FF),
                        fontWeight: FontWeight.w100,
                      ),
                    ),
                    const Text("우산", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              Container(
                height: 50,
                width: 1,
                color: Colors.grey[300],
                margin: const EdgeInsets.symmetric(horizontal: 30),
              ),
              SizedBox(
                width: 50,
                child: Column(
                  children: [
                    Text(
                      "${widget.emptySlotCount}",
                      style: const TextStyle(
                        fontSize: 40,
                        color: Color(0xFFFF0000),
                        fontWeight: FontWeight.w100,
                      ),
                    ),
                    const Text("빈 슬롯", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: UseButton(
              releaseDate: widget.releaseDate,
              isOverdue: widget.isOverdue,
              onPressed: widget.onTapUse,
            ),
          ),
        ],
      ),
    );
  }
}

class LockerStatus {
  final String lockerId;
  final double latitude;
  final double longitude;
  final int umbrellaCount;

  LockerStatus({
    required this.lockerId,
    required this.latitude,
    required this.longitude,
    required this.umbrellaCount,
  });

  factory LockerStatus.fromJson(Map<String, dynamic> json) {
    return LockerStatus(
      lockerId: json['lockerId'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      umbrellaCount: json['umbrellaCount'],
    );
  }
}
