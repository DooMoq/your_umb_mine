import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  String temperature = '-';
  String humidity = '-';
  String rainfall = '-';
  String rainProb = '-';
  String weatherIcon = '❓';
  String weatherMessage = '';
  bool isLoading = true;

  final String apiKey =
      '5SxB%2B0zbSvxv1Q1zsqJkqhDD4SEPGIi1RMJ2mXfvgphGdvsIQnl303E45yfutf53n%2B120l3Gm3T94AB5SP20sA%3D%3D';

  final Map<String, dynamic> iconAssets = {
    "☀️": "lib/assets/weather/sun.png",
    "⛅": "lib/assets/weather/cloud.png",
    "☁️": "lib/assets/weather/dull.png",
    "🌧️": "lib/assets/weather/rain.png",
    "❄️": "lib/assets/weather/snow.png",
    "❄️🌧️": ["lib/assets/weather/snow.png", "lib/assets/weather/rain.png"]
  };

  @override
  void initState() {
    super.initState();
    fetchWeatherData();
  }

  Future<void> fetchWeatherData() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final coords = convertToGrid(position.latitude, position.longitude);
      final now = DateTime.now();

      final baseDate =
          '${now.year}${_twoDigits(now.month)}${_twoDigits(now.day)}';
      final baseTimeNcst = _getBaseTime(now, forNcst: true);
      final baseTimeFcst = _getBaseTime(now, forNcst: false);

      final ncstUrl = Uri.parse(
          'https://apis.data.go.kr/1360000/VilageFcstInfoService_2.0/getUltraSrtNcst'
          '?serviceKey=$apiKey'
          '&pageNo=1&numOfRows=100&dataType=JSON'
          '&base_date=$baseDate&base_time=$baseTimeNcst'
          '&nx=${coords['nx']}&ny=${coords['ny']}');

      final fcstUrl = Uri.parse(
          'https://apis.data.go.kr/1360000/VilageFcstInfoService_2.0/getVilageFcst'
          '?serviceKey=$apiKey'
          '&pageNo=1&numOfRows=100&dataType=JSON'
          '&base_date=$baseDate&base_time=$baseTimeFcst'
          '&nx=${coords['nx']}&ny=${coords['ny']}');

      final ncstRes = await http.get(ncstUrl);
      final fcstRes = await http.get(fcstUrl);

      if (ncstRes.statusCode == 200 && fcstRes.statusCode == 200) {
        final ncstData = jsonDecode(ncstRes.body);
        final fcstData = jsonDecode(fcstRes.body);

        final ncstItems = ncstData['response']['body']['items']['item'];
        final fcstItems = fcstData['response']['body']['items']['item'];

        final temp = _findValue(ncstItems, 'T1H');
        final hum = _findValue(ncstItems, 'REH');
        final rn1 = _findValue(ncstItems, 'RN1');

        final sky = _findFirstFcstValue(fcstItems, 'SKY');
        final pty = _findFirstFcstValue(fcstItems, 'PTY');
        final pop = _findFirstFcstValue(fcstItems, 'POP');

        final icon = _getWeatherEmoji(sky, pty);
        final msg = _getWeatherMessage(icon);

        if (mounted) {
          setState(() {
            temperature = '$temp°C';
            humidity = '$hum%';
            rainfall = rn1 == '강수없음' ? '0mm' : '$rn1 mm';
            rainProb = '$pop%';
            weatherIcon = icon;
            weatherMessage = msg;
            isLoading = false;
          });
        }
      } else {
        throw Exception('API 응답 오류');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          temperature = '에러';
          humidity = '에러';
          rainfall = '에러';
          rainProb = '에러';
          weatherIcon = '❓';
          weatherMessage = '날씨 정보를 불러올 수 없어요';
          isLoading = false;
        });
      }
    }
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  String _getBaseTime(DateTime now, {required bool forNcst}) {
    final hour = now.hour;
    final minute = now.minute;
    if (forNcst) {
      final h = (minute < 40) ? hour - 1 : hour;
      return '${_twoDigits(h)}00';
    } else {
      const times = [2, 5, 8, 11, 14, 17, 20, 23];
      int base = times.lastWhere((t) => hour >= t, orElse: () => 23);
      return '${_twoDigits(base)}00';
    }
  }

  Map<String, int> convertToGrid(double lat, double lon) {
    const RE = 6371.00877;
    const GRID = 5.0;
    const SLAT1 = 30.0;
    const SLAT2 = 60.0;
    const OLON = 126.0;
    const OLAT = 38.0;
    const XO = 43;
    const YO = 136;

    double DEGRAD = pi / 180.0;
    double re = RE / GRID;
    double slat1 = SLAT1 * DEGRAD;
    double slat2 = SLAT2 * DEGRAD;
    double olon = OLON * DEGRAD;
    double olat = OLAT * DEGRAD;

    double sn = tan(pi * 0.25 + slat2 * 0.5) / tan(pi * 0.25 + slat1 * 0.5);
    sn = log(cos(slat1) / cos(slat2)) / log(sn);
    double sf = tan(pi * 0.25 + slat1 * 0.5);
    sf = pow(sf, sn) * cos(slat1) / sn;
    double ro = tan(pi * 0.25 + olat * 0.5);
    ro = re * sf / pow(ro, sn);

    double ra = tan(pi * 0.25 + lat * DEGRAD * 0.5);
    ra = re * sf / pow(ra, sn);
    double theta = lon * DEGRAD - olon;
    if (theta > pi) theta -= 2.0 * pi;
    if (theta < -pi) theta += 2.0 * pi;
    theta *= sn;

    int nx = (ra * sin(theta) + XO + 0.5).floor();
    int ny = (ro - ra * cos(theta) + YO + 0.5).floor();
    return {'nx': nx, 'ny': ny};
  }

  String _findValue(List items, String category) {
    final match = items.firstWhere(
      (e) => e['category'] == category,
      orElse: () => null,
    );
    return match != null ? match['obsrValue'].toString() : '-';
  }

  String _findFirstFcstValue(List items, String category) {
    final match = items.firstWhere(
      (e) => e['category'] == category,
      orElse: () => null,
    );
    return match != null ? match['fcstValue'].toString() : '-';
  }

  String _getWeatherEmoji(String sky, String pty) {
    if (pty == "1" || pty == "4") return "🌧️";
    if (pty == "2") return "❄️🌧️";
    if (pty == "3") return "❄️";
    if (pty == "0") {
      if (sky == "1") return "☀️";
      if (sky == "3") return "⛅";
      if (sky == "4") return "☁️";
    }
    return "❓";
  }

  String _getWeatherMessage(String icon) {
    switch (icon) {
      case "☀️":
        return "맑음";
      case "⛅":
        return "구름";
      case "☁️":
        return "흐림";
      case "🌧️":
        return "비";
      case "❄️🌧️":
        return "눈비";
      case "❄️":
        return "눈";
      default:
        return "날씨 정보를 불러올 수 없어요 😥";
    }
  }

  Widget _buildWeatherIcon() {
    final asset = iconAssets[weatherIcon];
    if (asset is String) {
      return Image.asset(asset, width: 200, height: 200);
    } else if (asset is List) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: asset
            .map<Widget>((a) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Image.asset(a, width: 60, height: 60),
                ))
            .toList(),
      );
    } else {
      return const Text('❓', style: TextStyle(fontSize: 80));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator(color: Color(0xFF5075AF))
            : Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildWeatherIcon(),
                    const SizedBox(height: 16),
                    Text(
                      temperature,
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      weatherMessage,
                      style: TextStyle(fontSize: 30, color: Colors.grey[700]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(children: [
                            Image.asset('lib/assets/weather/humid.png',
                                width: 24, height: 24),
                            const SizedBox(height: 4),
                            Text(humidity,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            const Text('현재습도'),
                          ]),
                          Column(children: [
                            Image.asset('lib/assets/weather/umbrella.png',
                                width: 24, height: 24),
                            const SizedBox(height: 4),
                            Text(rainfall,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            const Text('강수량'),
                          ]),
                          Column(children: [
                            Image.asset('lib/assets/weather/drop.png',
                                width: 24, height: 24),
                            const SizedBox(height: 4),
                            Text(rainProb,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            const Text('강수확률'),
                          ]),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '* 날씨 예보 및 공공데이터 반영주기에 따라 실제 날씨와 상이할 수 있습니다.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    const Text('발표: 기상청, 한국환경공단\n제공: 공공데이터 포털',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
      ),
    );
  }
}
