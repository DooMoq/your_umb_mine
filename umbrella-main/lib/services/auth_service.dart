import 'package:shared_preferences/shared_preferences.dart'; //로컬 저장소. 키-값(key-value) 쌍으로 저장

class AuthService {
  static const _tokenKey = 'authToken';

  // 토큰 저장
  static Future<void> saveToken(String token) async {
    //Future<void> 토큰 저장만하고 돌려주는 값 없음
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // 토큰 가져오기
  static Future<String?> getToken() async {
    //String을 리턴(없으면 null)
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // 토큰 삭제
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}
