import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:system_alert_window/system_alert_window.dart';
import 'package:screen_capturer/screen_capturer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemAlertWindow.requestPermissions;
  runApp(const TabletKalemApp());
}

class TabletKalemApp extends StatelessWidget {
  const TabletKalemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: EmptyLauncher(),
    );
  }
}

/// 🚀 SADECE BALONCUĞU BAŞLATIR
class EmptyLauncher extends StatefulWidget {
  const EmptyLauncher({super.key});

  @override
  State<EmptyLauncher> createState() => _EmptyLauncherState();
}

class _EmptyLauncherState extends State<EmptyLauncher> {
  @override
  void initState() {
    super.initState();
    _showBubble();
  }

  void _showBubble() {
    SystemAlertWindow.showSystemWindow(
      height: 60,
      width: 60,
      margin: const SystemWindowMargin(left: 20, top: 200),
      gravity: SystemWindowGravity.TOP_LEFT,
      notificationTitle: "TabletKalem",
      notificationBody: "Çizim Baloncuğu",
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DrawScreen()),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(backgroundColor: Colors.transparent);
  }
}

////////////////////////////////////////////////////////////////
/// 🖍️ ÇİZİM EKRANI (SCREENSHOT + SENİN TOOLBAR)
////////////////////////////////////////////////////////////////

class DrawScreen extends StatefulWidget {
  const DrawScreen({super.key});
  @override
  State<DrawScreen> createState() => _DrawScreenState();
}

class _DrawScreenState extends State<DrawScreen> {
  Uint8List? screenshot;
  List<Stroke> strokes = [];
  Color selectedColor = Colors.black;
  double selectedWidth = 3;
  bool eraser = false;

  @override
  void initState() {
    super.initState();
    _capture();
  }

  Future<void> _capture() async {
    screenshot = await ScreenCapturer.instance.capture();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (screenshot == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          Image.memory(
            screenshot!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),

          GestureDetector(
            onPanStart: (d) {
              if (!eraser) {
                strokes.add(
                  Stroke([d.localPosition], selectedColor, selectedWidth),
                );
              }
            },
            onPanUpdate: (d) {
              if (eraser) {
                strokes.removeWhere((s) =>
                    s.points.any((p) => (p - d.localPosition).distance < 20));
              } else {
                strokes.last.points.add(d.localPosition);
              }
              setState(() {});
            },
            child: CustomPaint(
              painter: CizimRessami(strokes),
              size: Size.infinite,
            ),
          ),

          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () {
                strokes.clear();
                screenshot = null;
                Navigator.pop(context);
              },
            ),
          ),

          _toolbar(),
        ],
      ),
    );
  }

  Widget _toolbar() {
    return Positioned(
      bottom: 40,
      left: 20,
      child: Column(
        children: [
          _colorBtn(Colors.red),
          _colorBtn(Colors.blue),
          _colorBtn(Colors.black),
          const SizedBox(height: 10),
          _widthBtn(2),
          _widthBtn(6),
          _widthBtn(12),
          const SizedBox(height: 10),
          IconButton(
            icon: const Icon(Icons.auto_fix_high, color: Colors.white),
            onPressed: () => setState(() => eraser = !eraser),
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            onPressed: () => setState(() => strokes.clear()),
          ),
        ],
      ),
    );
  }

  Widget _colorBtn(Color c) => IconButton(
        icon: Icon(Icons.circle, color: c),
        onPressed: () => setState(() {
          selectedColor = c;
          eraser = false;
        }),
      );

  Widget _widthBtn(double w) => IconButton(
        icon: Text("${w.toInt()}",
            style: const TextStyle(color: Colors.white)),
        onPressed: () => setState(() => selectedWidth = w),
      );
}

////////////////////////////////////////////////////////////////
/// 🎨 ÇİZİM MOTORU (SENİN KOD)
////////////////////////////////////////////////////////////////

class Stroke {
  List<Offset> points;
  Color color;
  double width;
  Stroke(this.points, this.color, this.width);
}

class CizimRessami extends CustomPainter {
  final List<Stroke> strokes;
  CizimRessami(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    for (var s in strokes) {
      final p = Paint()
        ..color = s.color
        ..strokeWidth = s.width
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < s.points.length - 1; i++) {
        canvas.drawLine(s.points[i], s.points[i + 1], p);
      }
    }
  }

  @override
  bool shouldRepaint(_) => true;
}
