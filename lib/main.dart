import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:system_alert_window/system_alert_window.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemAlertWindow.requestPermissions();
  runApp(const MyApp());
}

const platform = MethodChannel('screenshot_channel');

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Launcher(),
    );
  }
}

class Launcher extends StatefulWidget {
  const Launcher({super.key});
  @override
  State<Launcher> createState() => _LauncherState();
}

class _LauncherState extends State<Launcher> {
  @override
  void initState() {
    super.initState();
    _showBubble();
  }

  void _showBubble() {
    SystemAlertWindow.showSystemWindow(
      height: 60,
      width: 60,
      gravity: SystemWindowGravity.TOP_LEFT,
      margin: SystemWindowMargin(left: 20, top: 200),
      notificationTitle: "TabletKalem",
      notificationBody: "Baloncuk aktif",
      onTap: () async {
        final Uint8List? img =
            await platform.invokeMethod('takeScreenshot');

        if (img != null && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DrawScreen(background: img),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(backgroundColor: Colors.transparent);
  }
}

class DrawScreen extends StatelessWidget {
  final Uint8List background;
  const DrawScreen({super.key, required this.background});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Image.memory(
            background,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
