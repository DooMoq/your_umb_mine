import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleConnector {
  static final BleConnector instance = BleConnector._internal();
  BleConnector._internal() {
    _startAutoReconnectChecker();
  }

  final ValueNotifier<BluetoothDevice?> connectedDeviceNotifier =
      ValueNotifier(null);

  bool isScanning = false;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  Timer? _reconnectTimer;

  void _startAutoReconnectChecker() {
    _reconnectTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (connectedDeviceNotifier.value == null && !isScanning) {
        startConnectingToUmb();
      }
    });
  }

  void startConnectingToUmb() {
    if (isScanning) return;

    isScanning = true;
    FlutterBluePlus.startScan();

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult r in results) {
        final name = r.device.name;
        if (name.startsWith('umb')) {
          try {
            await FlutterBluePlus.stopScan();
            await _scanSubscription?.cancel();
            await r.device.connect(autoConnect: false);
            connectedDeviceNotifier.value = r.device;
            isScanning = false;

            // 연결 끊김 감지
            r.device.connectionState.listen((state) {
              if (state == BluetoothConnectionState.disconnected) {
                connectedDeviceNotifier.value = null;
              }
            });

            return;
          } catch (e) {
            print('❌ 연결 실패: $e');
            await FlutterBluePlus.stopScan();
            await _scanSubscription?.cancel();
            isScanning = false;
          }
        }
      }
    });
  }

  void stopConnecting() {
    _scanSubscription?.cancel();
    FlutterBluePlus.stopScan();
    isScanning = false;
  }

  Future<void> disconnect() async {
    await connectedDeviceNotifier.value?.disconnect();
    connectedDeviceNotifier.value = null;
  }

  bool get isConnected => connectedDeviceNotifier.value != null;
  BluetoothDevice? get connectedDevice => connectedDeviceNotifier.value;
}
