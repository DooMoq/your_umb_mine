import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

class WeatherModel {
  static String temp = "...";
  static String humid = "...";
  static String w_info = "...";
  static String location = "...";

  static Future<void> fetchWeather() async {
    try {
      // ✅ 네이버 날씨 페이지 요청
      final response = await http.get(
        Uri.parse(
            "https://search.naver.com/search.naver?where=nexearch&sm=top_hty&fbm=0&ie=utf8&query=날씨"),
        headers: {
          "User-Agent":
              "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
        },
      );

      if (response.statusCode == 200) {
        var document = parser.parse(response.body);

        // ✅ 온도(temp) - 공백 문제 해결
        temp = document
                .querySelector(
                    "#main_pack > section.sc_new.cs_weather_new._cs_weather > div > div:nth-child(1) > div.content_wrap > div.open > div:nth-child(1) > div > div.weather_info > div > div._today > div.weather_graphic > div.temperature_text > strong")
                ?.text
                .replaceAll('현재 온도', '') // '도' 문자 제거
                .trim() ??
            "N/A";
        temp = "$temp" "";
        // 🌟 "현재 온"과 값 사이에 공백 추가

        // ✅ 습도(humid) - 중복 % 문제 해결
        String? humidElement;
        var dtElements = document.querySelectorAll(
            "#main_pack > section.sc_new.cs_weather_new._cs_weather > div > div:nth-child(1) > div.content_wrap > div.open > div:nth-child(1) > div > div.weather_info > div > div._today > div.temperature_info > dl > div > dt");

        for (var dt in dtElements) {
          if (dt.text.trim() == "습도") {
            humidElement = dt.nextElementSibling?.text.trim();
            break;
          }
        }

        humid = humidElement ?? "N/A";
        humid = "${humid.replaceAll('%', '')}%"; // 🌟 % 중복 문제 해결

        // ✅ 날씨 정보(w_info)
        w_info = document
                .querySelector(
                    "#main_pack > section.sc_new.cs_weather_new._cs_weather > div > div:nth-child(1) > div.content_wrap > div.open > div:nth-child(1) > div > div.weather_info > div > div._today > div.temperature_info > p > span.weather.before_slash")
                ?.text
                .trim() ??
            "N/A";

        // ✅ 위치(location)
        location = document
                .querySelector(
                    "#main_pack > section.sc_new.cs_weather_new._cs_weather > div > div:nth-child(1) > div.top_wrap > div.title_area._area_panel > h2.title")
                ?.text
                .trim() ??
            "N/A";
      } else {
        print("❌ 데이터 요청 실패 (Status Code: ${response.statusCode})");
      }
    } catch (e) {
      print("❌ 오류 발생: $e");
    }
  }
}
