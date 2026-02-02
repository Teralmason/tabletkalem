import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:system_alert_window/system_alert_window.dart';
import 'package:screenshot/screenshot.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    home: GirisEkrani(),
    debugShowCheckedModeBanner: false,
  ));
}

class GirisEkrani extends StatefulWidget {
  const GirisEkrani({super.key});
  @override
  State<GirisEkrani> createState() => _GirisEkraniState();
}

class _GirisEkraniState extends State<GirisEkrani> {
  final ScreenshotController screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _izinleriAl();
  }

  Future<void> _izinleriAl() async {
    await [Permission.storage, Permission.photos, Permission.manageExternalStorage].request();
    await SystemAlertWindow.requestPermissions();
  }

  void _baloncuguGoster() {
    // Paket bu alt nesnelerin tanımlanmasını zorunlu kılıyor.
    // Hata almamak için her birini en sade haliyle oluşturuyoruz.
    SystemWindowHeader header = SystemWindowHeader(
      title: SystemWindowText(text: "Kalem", fontSize: 14, textColor: Colors.black),
      decoration: SystemWindowDecoration(startColor: Colors.white),
    );

    SystemWindowBody body = SystemWindowBody(
      rows: [
        EachRow(columns: [
          EachColumn(text: SystemWindowText(text: "Çizmek için tıklayın", fontSize: 12, textColor: Colors.black45))
        ])
      ],
    );

    SystemAlertWindow.showSystemWindow(
      height: 100,
      width: 100,
      header: header,
      body: body,
      gravity: SystemWindowGravity.CENTER,
      prefMode: SystemWindowPrefMode.OVERLAY,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Screenshot(
      controller: screenshotController,
      child: Scaffold(
        appBar: AppBar(title: const Text("Tablet Kalem V2")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.gesture, size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: const Text("Baloncuğu Başlat"),
                onPressed: _baloncuguGoster,
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text("Ekranı Yakala ve Çiz"),
                onPressed: () async {
                  final image = await screenshotController.capture();
                  if (image != null && mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CizimEkrani(imageBytes: image)),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CizimEkrani extends StatefulWidget {
  final Uint8List imageBytes;
  const CizimEkrani({super.key, required this.imageBytes});
  @override
  State<CizimEkrani> createState() => _CizimEkraniState();
}

class Stroke {
  List<Offset> points;
  Color color;
  double width;
  Stroke({required this.points, required this.color, required this.width});
}

class _CizimEkraniState extends State<CizimEkrani> {
  List<Stroke> strokes = [];
  Color selectedColor = Colors.red;
  bool isEraser = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Image.memory(widget.imageBytes, width: double.infinity, height: double.infinity, fit: BoxFit.fill),
          GestureDetector(
            onPanStart: (d) => setState(() => strokes.add(Stroke(points: [d.localPosition], color: isEraser ? Colors.white : selectedColor, width: 4.0))),
            onPanUpdate: (d) => setState(() => strokes.last.points.add(d.localPosition)),
            child: CustomPaint(painter: CizimRessami(strokes), size: Size.infinite),
          ),
          Positioned(
            top: 40, left: 20, right: 20,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(30)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => setState(() => isEraser = false)),
                  IconButton(icon: const Icon(Icons.auto_fix_high, color: Colors.purple), onPressed: () => setState(() => isEraser = true)),
                  IconButton(icon: const Icon(Icons.circle, color: Colors.red), onPressed: () => setState(() => selectedColor = Colors.red)),
                  IconButton(icon: const Icon(Icons.delete, color: Colors.white), onPressed: () => setState(() => strokes.clear())),
                  IconButton(icon: const Icon(Icons.close, color: Colors.redAccent), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CizimRessami extends CustomPainter {
  final List<Stroke> strokes;
  CizimRessami(this.strokes);
  @override
  void paint(Canvas canvas, Size size) {
    for (var stroke in strokes) {
      Paint paint = Paint()..color = stroke.color..strokeCap = StrokeCap.round..strokeWidth = stroke.width..style = PaintingStyle.stroke;
      Path path = Path();
      if (stroke.points.isNotEmpty) {
        path.moveTo(stroke.points[0].dx, stroke.points[0].dy);
        for (var p in stroke.points) path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
