import 'package:flutter/material.dart';
import '../models/weather_model.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadWeather();
  }

  Future<void> loadWeather() async {
    await WeatherModel.fetchWeather();
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white, // ✅ 배경색 설정
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context), // ✅ 뒤로가기 버튼
        ),
      ),
      body: Container(
        color: Colors.white,
        child: Center(
          child: isLoading
              ? const SizedBox()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // 🌍 위치
                    const SizedBox(height: 50),
                    Text(
                      WeatherModel.location,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),

                    // 🌤 날씨 아이콘 (조건부 렌더링)
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: Center(
                        child: WeatherModel.w_info.contains("맑음")
                            ? Image.asset('lib/assets/icons/sunny.png',
                                width: 180, height: 180, fit: BoxFit.contain)
                            : const SizedBox(), // 빈 상태 유지
                      ),
                    ),

                    // 🌡 온도
                    Transform.translate(
                      offset: const Offset(10, 0),
                      child: Text(
                        WeatherModel.temp,
                        style: const TextStyle(
                            fontSize: 50, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(height: 5),

                    // ☁️ 날씨 정보
                    Text(
                      WeatherModel.w_info,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
