import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:umbrella/services/bleconnector.dart';

class Ble extends StatefulWidget {
  const Ble({super.key});

  @override
  State<Ble> createState() => _BleState();
}

class _BleState extends State<Ble> {
  final Guid ledServiceUuid = Guid("12345678-1234-5678-1234-56789abcdef0");
  final Guid ledCharUuid = Guid("12345678-1234-5678-1234-56789abcdef1");

  bool isScanning = false;
  bool isFound = false;

  Future<void> sendLedSignal(BluetoothDevice device) async {
    try {
      final services = await device.discoverServices();
      for (var service in services) {
        if (service.uuid == ledServiceUuid) {
          for (var char in service.characteristics) {
            if (char.uuid == ledCharUuid && char.properties.write) {
              await char.write([0x01]);
              debugPrint('✅ LED 신호 전송 완료');
              return;
            }
          }
        }
      }
      debugPrint('⚠️ characteristic을 찾을 수 없습니다');
    } catch (e) {
      debugPrint('❌ 전송 실패: $e');
    }
  }

  void startScan() {
    setState(() {
      isScanning = true;
      isFound = BleConnector.instance.connectedDevice != null;
    });

    // 근처에 장치가 있다면 신호 전송
    final device = BleConnector.instance.connectedDevice;
    if (device != null) sendLedSignal(device);

    // 10초 후 자동 중지
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          isScanning = false;
        });
      }
    });
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ValueListenableBuilder<BluetoothDevice?>(
          valueListenable: BleConnector.instance.connectedDeviceNotifier,
          builder: (context, device, _) {
            final hasDevice = device != null;

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '우산을 잃어버리셨나요?',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Text(
                  '탐색 버튼을 누르고 우산과 연결이\n끊긴 지점 주변에서 우산을 찾아보세요.\n우산이 근처에 있으면 우산의 LED가 깜빡입니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),
                const SizedBox(height: 40),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: isScanning
                          ? CircularProgressIndicator(
                              strokeWidth: 14,
                              color: Colors.grey,
                              backgroundColor: const Color(0xFFF5F6FA),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFF5F6FA),
                                border: Border.all(
                                  color: hasDevice
                                      ? const Color(0xFF3ECAC2)
                                      : const Color(0xFFCCCCCC),
                                  width: 14,
                                ),
                              ),
                            ),
                    ),
                    Icon(
                      isScanning
                          ? Icons.search
                          : (hasDevice
                              ? Icons.check_circle_outline
                              : Icons.search),
                      size: 40,
                      color: isScanning
                          ? Colors.black87
                          : (hasDevice
                              ? const Color(0xFF3ECAC2)
                              : Colors.black54),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  isScanning
                      ? '탐색 중...'
                      : (hasDevice ? '근처에 우산이 있습니다.\n우산의 LED가 깜빡입니다.' : ''),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                    ),
                    onPressed: isScanning ? null : startScan,
                    child: Text(
                      isScanning ? '탐색 중...' : '찾기',
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                )
              ],
            );
          },
        ),
      ),
    );
  }
}
