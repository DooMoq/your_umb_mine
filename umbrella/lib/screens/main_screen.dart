import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final MapController _mapController = MapController();
  bool _locationPermissionGranted = false;

  final LatLng _centerPoint = const LatLng(36.77203, 126.9316);
  final double _radiusInMeters = 800;
  bool _isOutside = false;

  @override
  void initState() {
    super.initState();
    _requestPermission();
    _startMonitoringPosition();
  }

  Future<void> _requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      _updateLocation();
      setState(() {
        _locationPermissionGranted = true;
      });
    }
  }

  Future<void> _updateLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    _mapController.move(LatLng(position.latitude, position.longitude), 17);
  }

  void _startMonitoringPosition() {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      final double distance = const Distance().as(
        LengthUnit.Meter,
        _centerPoint,
        LatLng(position.latitude, position.longitude),
      );

      if (distance > _radiusInMeters && !_isOutside) {
        _isOutside = true;
        _showOutOfRangeAlert();
      } else if (distance <= _radiusInMeters && _isOutside) {
        _isOutside = false;
      }
    });
  }

  void _showOutOfRangeAlert() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("서비스 구역을 벗어났습니다."),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        drawerEnableOpenDragGesture: false,
        drawer: _buildDrawer(),
        body: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: const MapOptions(
                initialZoom: 17,
                minZoom: 13,
                maxZoom: 18,
                initialCenter: LatLng(36.77203, 126.9316),
                interactionOptions: InteractionOptions(
                  flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                ),
                if (_locationPermissionGranted)
                  CurrentLocationLayer(
                    style: LocationMarkerStyle(
                      showAccuracyCircle: false,
                      showHeadingSector: true,
                      accuracyCircleColor: Colors.blue.withOpacity(0.2),
                      marker: const DefaultLocationMarker(
                        color: Colors.red,
                      ),
                    ),
                  ),
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _centerPoint,
                      radius: _radiusInMeters,
                      color: Colors.blue.withOpacity(0.2),
                      borderColor: Colors.red,
                      borderStrokeWidth: 0.5,
                      useRadiusInMeter: true,
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(30)),
                      ),
                      builder: (context) => Container(
                        padding: const EdgeInsets.all(20),
                        height: 230,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(30)),
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
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "미디어랩스",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Color.fromARGB(255, 78, 78, 78),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 50,
                                  child: Column(
                                    children: [
                                      Text(
                                        "4",
                                        style: TextStyle(
                                            fontSize: 40,
                                            color: Color(0xFF0061FF),
                                            fontWeight: FontWeight.w100),
                                      ),
                                      Text(
                                        "우산",
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  height: 50,
                                  width: 1,
                                  color: Colors.grey[300],
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 30),
                                ),
                                const SizedBox(
                                  width: 50,
                                  child: Column(
                                    children: [
                                      Text(
                                        "6",
                                        style: TextStyle(
                                            fontSize: 40,
                                            color: Color(0xFFFF0000),
                                            fontWeight: FontWeight.w100),
                                      ),
                                      Text(
                                        "빈 슬롯",
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 40,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00B2FF),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(40),
                                  ),
                                ),
                                onPressed: () {
                                  print("이용하기 버튼 클릭됨");
                                  showModalBottomSheet(
                                    context: context,
                                    backgroundColor: Colors.transparent,
                                    isScrollControlled: true,
                                    builder: (context) {
                                      return Container(
                                        margin: const EdgeInsets.all(15),
                                        height: 450,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(30),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const SizedBox(height: 45),
                                            const Text(
                                              "NFC 태그",
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 20),
                                            Container(
                                              padding: const EdgeInsets.all(20),
                                              decoration: BoxDecoration(
                                                color: Colors.transparent,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  const SizedBox(width: 40),
                                                  Image.asset(
                                                    'lib/assets/tag.png',
                                                    width: 160,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 20),
                                            const Text(
                                              "휴대전화의 뒷면을 카드 리더기에 대세요.",
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.black),
                                            ),
                                            const SizedBox(height: 20),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                      20, 0, 20, 0),
                                              child: SizedBox(
                                                width: double.infinity,
                                                height: 40,
                                                child: TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  style: TextButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.grey[300],
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              7),
                                                    ),
                                                  ),
                                                  child: const Text("취소",
                                                      style: TextStyle(
                                                          color: Colors.black)),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                                child: const Text(
                                  "이용하기",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: MarkerLayer(
                    markers: [
                      Marker(
                        width: 60,
                        height: 60,
                        point: const LatLng(36.77200, 126.9317),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFF26539C),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    'lib/assets/umbrella.png',
                                    width: 12,
                                  ),
                                  const SizedBox(width: 3),
                                  const Text(
                                    "4",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(width: 2)
                                ],
                              ),
                            ),
                            Transform.translate(
                              offset: const Offset(0, -6),
                              child: Transform.rotate(
                                angle: 3.14 / 4,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  color: const Color(0xFF26539C),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(top: 40, left: 16, child: _buildMenuButton()),
            Positioned(
              top: 40,
              left: MediaQuery.of(context).size.width / 2 - 120,
              child: _buildTopContainer(),
            ),
            Positioned(top: 40, right: 16, child: _buildSearchButton()),
            Positioned(bottom: 30, right: 16, child: _buildFloatingButtons()),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton() {
    return Builder(
      builder: (context) {
        return IconButton(
          icon: const Icon(Icons.menu, size: 30, color: Colors.white),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(const Color(0xFF26539C)),
            shape: WidgetStateProperty.all(const CircleBorder()),
            padding: WidgetStateProperty.all(const EdgeInsets.all(10)),
          ),
        );
      },
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          _buildDrawerHeader(),
          _buildDrawerMenuItem(Icons.history, "이용 내역"),
          Container(color: Colors.grey, height: 0.7),
          _buildDrawerMenuItem(Icons.info_outline, "이용 안내"),
          Container(color: Colors.grey, height: 0.7),
          _buildDrawerMenuItem(Icons.headset_mic, "고객센터"),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey[300],
            child: const Icon(Icons.person, size: 40, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text("김사물",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text("iotkim1004",
                      style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                ],
              ),
              const SizedBox(width: 10)
            ],
          ),
          const Icon(Icons.chevron_right,
              size: 30, color: Color.fromARGB(255, 67, 67, 67)),
        ],
      ),
    );
  }

  Widget _buildDrawerMenuItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      onTap: () {
        Navigator.pop(context);
        if (title == "이용 안내") {
          showOnboardingDialog(context);
        }
      },
    );
  }

  Widget _buildTopContainer() {
    return Container(
      width: 240,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF26539C),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Image.asset('lib/assets/nii_nae.jpg'),
    );
  }

  Widget _buildSearchButton() {
    return IconButton(
      icon: const Icon(Icons.search, size: 30, color: Colors.white),
      onPressed: () {
        print("검색 버튼 클릭됨");
      },
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(const Color(0xFF26539C)),
        shape: WidgetStateProperty.all(const CircleBorder()),
        padding: WidgetStateProperty.all(const EdgeInsets.all(10)),
      ),
    );
  }

  Widget _buildFloatingButtons() {
    return Column(
      children: [
        _buildRoundIconButton(Icons.cloud, "날씨"),
        const SizedBox(height: 10),
        _buildRoundIconButton(Icons.wifi_tethering_error_rounded, "클립"),
        const SizedBox(height: 10),
        _buildRoundIconButton(Icons.my_location, "좌표"),
      ],
    );
  }

  Widget _buildRoundIconButton(IconData icon, String label) {
    return Container(
      width: 50,
      height: 50,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(50)),
      child: FloatingActionButton(
        heroTag: label,
        onPressed: () {
          if (label == "좌표") {
            _updateLocation();
          }
        },
        backgroundColor: const Color(0xFF5075AF),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _OnboardingPopup extends StatefulWidget {
  @override
  _OnboardingPopupState createState() => _OnboardingPopupState();
}

class _OnboardingPopupState extends State<_OnboardingPopup> {
  int currentIndex = 0;
  final int totalPages = 9;

  final List<Map<String, String>> onboardingData = [
    {"title": "어떻게 대여/반납하나요?", "description": "지도에서 반납할 보관함 위치를\n확인하세요."},
    {"title": "어떻게 대여/반납하나요?", "description": "또는, 반납할 보관함을 검색하세요."},
    {
      "title": "어떻게 대여/반납하나요?",
      "description": "이용하기 버튼을 누르고 휴대폰을 보관함\nNFC 리더기에 가져다 대세요."
    },
    {"title": "어떻게 대여/반납하나요?", "description": "우산함 화면에 표시된 안내를 따라\n진행해 주세요."},
    {"title": "우산을 분실하셨나요?", "description": "우산과 연결이 끊긴 지점을\n확인해 주세요."},
    {
      "title": "우산을 분실하셨나요?",
      "description": "우산이 끊긴 위치에 도착하여, 해당 핀을\n터치해 내 우산 찾기를 시작해 주세요."
    },
    {"title": "서비스 구역 준수", "description": "대여한 우산은 지정된 서비스 구역\n내에서만 사용 가능합니다."},
    {
      "title": "반납 기간",
      "description": "대여 후 3일 이내 반납해 주세요. 3일 초과 시\n초과 일수의 2배 요금이 부과됩니다."
    },
    {
      "title": "우산 분실 및 미반납",
      "description": "우산 분실 시 보증금 10,000원이 부과되며,\n반납하지 않으면 다음 대여가 제한됩니다."
    },
  ];

  void nextPage() {
    if (currentIndex < totalPages - 1) {
      setState(() => currentIndex++);
    }
  }

  void prevPage() {
    if (currentIndex > 0) {
      setState(() => currentIndex--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: 450,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 30),
          Text(onboardingData[currentIndex]["title"]!,
              style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 20),
          Image.asset(
            'lib/assets/icons/${currentIndex + 1}.jpg',
            width: 170,
            height: 170,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 15),
          Text(
            onboardingData[currentIndex]["description"]!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              totalPages,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == currentIndex
                      ? const Color(0xFF26539C)
                      : const Color(0xFF26539C).withOpacity(0.4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: prevPage,
                color: currentIndex > 0 ? Colors.black : Colors.transparent,
              ),
              if (currentIndex < totalPages - 1)
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios),
                  onPressed: nextPage,
                )
              else
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

void showOnboardingDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: _OnboardingPopup(),
      );
    },
  );
}
