import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class GeofenceService {
  final LatLng center;
  final double radiusInMeters;
  final Distance _distance = const Distance();

  bool _isInside = true;

  GeofenceService({
    required this.center,
    required this.radiusInMeters,
  });

  void checkPosition({
    required BuildContext context,
    required LatLng currentPosition,
  }) {
    final double dist = _distance.as(LengthUnit.Meter, center, currentPosition);
    final bool nowInside = dist <= radiusInMeters;

    if (_isInside && !nowInside) {
      _isInside = false;
      _showExitMessage(context);
    } else if (!_isInside && nowInside) {
      _isInside = true;
      // 필요 시 재진입 이벤트 처리 가능
    }
  }

  void _showExitMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('지정된 구역을 벗어났습니다!'),
        duration: Duration(seconds: 3),
      ),
    );
  }
}
