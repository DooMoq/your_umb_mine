import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

class UserInfoScreen extends StatelessWidget {
  const UserInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: const Text('김사물님의 정보',
            style: TextStyle(color: Colors.black, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 30),
          Stack(
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: Color(0xFFEFEFEF),
                child: Icon(Icons.person, size: 40, color: Colors.grey),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: const Icon(Icons.add_circle,
                      color: Colors.grey, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 50),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _buildInfoTile('이름', '김사물'),
                _buildInfoTile('휴대폰 번호', '010-1234-5678'),
                _buildInfoTile('이메일', 'iotkim1004@sch.ac.kr'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String title, String info) {
    return Column(
      children: [
        ListTile(
          title: Text(title,
              style: const TextStyle(fontSize: 14, color: Colors.black54)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(info,
                  style: const TextStyle(fontSize: 14, color: Colors.black87)),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ],
    );
  }
}
