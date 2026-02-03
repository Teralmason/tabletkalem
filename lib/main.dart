import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!await FlutterOverlayWindow.isPermissionGranted()) {
    await FlutterOverlayWindow.requestPermission();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Home(),
    );
  }
}

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          child: const Text("Baloncuğu Aç"),
          onPressed: () async {
            await FlutterOverlayWindow.showOverlay(
              height: 80,
              width: 80,
              enableDrag: true,
              overlayTitle: "TabletKalem",
              overlayContent: "Baloncuk",
              flag: OverlayFlag.defaultFlag,
              visibility: NotificationVisibility.visibilityPublic,
            );
          },
        ),
      ),
    );
  }
}

/// 🔴 OVERLAY BALONCUĞU
@pragma("vm:entry-point")
void overlayMain() {
  runApp(const OverlayBubble());
}

class OverlayBubble extends StatelessWidget {
  const OverlayBubble({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () {
          FlutterOverlayWindow.closeOverlay();
        },
        child: Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue,
          ),
          child: const Icon(Icons.create, color: Colors.white, size: 30),
        ),
      ),
    );
  }
}
