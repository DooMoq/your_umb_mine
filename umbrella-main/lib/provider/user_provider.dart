import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class UserProvider extends ChangeNotifier {
  //UserProvider는 ChangeNotifier를 상속받는 클래스 ex.JWT 토큰 등을 저장하고, 이 정보가 변경될 때마다 UI를 업데이트
  static const _tokenKey = 'jwt_token'; // SharedPreferences에 저장할 때 사용할 키
  String? _token; // JWT 토큰을 저장할 변수
  Map<String, dynamic>? _userData; // JWT 토큰을 디코딩하여 얻은 사용자 데이터를 저장할 변수

  String? get token => _token;
  Map<String, dynamic>? get userData => _userData;
  bool get isLoggedIn => _token != null; //// 토큰이 null이 아니면 로그인된 상태

  // 앱을 켤 때마다 자동 로그인. 앱 시작 시(firstscreen.dart에서) 호출하여 SharedPreferences에서 토큰을 불러오기
  Future<void> loadUserFromStorage() async {
    final prefs = await SharedPreferences
        .getInstance(); //SharedPreferences (앱에 key-value 데이터(토큰 저장,자동 로그인 여부,유저 아이디..) 저장하는 곳,Flutter에서 공식으로 제공하는 라이브러리) 를 불러옴.
    final storedToken = prefs.getString(_tokenKey);
    if (storedToken != null && !JwtDecoder.isExpired(storedToken)) {
      //토큰이 존재하고, 유효기간이 안 지났는지
      _token = storedToken;
      _userData = JwtDecoder.decode(storedToken); // JWT 디코딩하여 사용자 데이터 가져오기
      notifyListeners(); //상태가 바뀌었으니까 앱 화면에 알려서 다시 그리게(refresh) 함
    }
  }

  // 로그인 시 토큰을 저장하고 디코딩된 사용자 데이터도 저장
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    _token = token;
    _userData = JwtDecoder.decode(token); // JWT 디코딩하여 사용자 데이터 저장
    await prefs.setString(_tokenKey, token);
    notifyListeners();
  }

  // 로그아웃 시 토큰과 사용자 데이터 제거
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    _token = null;
    _userData = null;
    await prefs.remove(_tokenKey); // SharedPreferences에서 토큰 제거
    notifyListeners();
  }

  // 사용자 ID와 이름을 쉽게 가져올 수 있도록 getter 추가
  String? get userId => _userData?['id']; // 디코딩된 데이터에서 'id' 필드 가져오기
  String? get userName => _userData?['name']; // 디코딩된 데이터에서 'name' 필드 가져오기
}
