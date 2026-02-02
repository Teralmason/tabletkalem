import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:system_alert_window/system_alert_window.dart';
import 'package:screenshot/screenshot.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(home: GirisEkrani(), debugShowCheckedModeBanner: false));
}

class GirisEkrani extends StatefulWidget {
  const GirisEkrani({super.key});
  @override
  State<GirisEkrani> createState() => _GirisEkraniState();
}

class _GirisEkraniState extends State<GirisEkrani> {
  @override
  void initState() {
    super.initState();
    _baslat();
  }

  Future<void> _baslat() async {
    await [Permission.storage, Permission.manageExternalStorage].request();
    await SystemAlertWindow.requestPermissions;
    _baloncuguGoster();
  }

  void _baloncuguGoster() {
    SystemWindowHeader header = SystemWindowHeader(
      title: SystemWindowText(text: "KALEM", fontSize: 14, textColor: Colors.white),
      decoration: SystemWindowDecoration(startColor: Colors.blueAccent),
    );

    SystemAlertWindow.showSystemWindow(
      height: 70,
      width: 70,
      header: header,
      gravity: SystemWindowGravity.CENTER,
      prefMode: SystemWindowPrefMode.OVERLAY,
    );
    
    // Uygulamayı simge durumuna küçült (User PDF'e dönsün)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: Main Strategy.center,
          children: [
            const Text("Kalem Baloncuğu Aktif!"),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () => _baloncuguGoster(), child: const Text("Baloncuğu Tekrar Aç")),
          ],
        ),
      ),
    );
  }
}

// ASIL ÇİZİM EKRANI (Ekran görüntüsü alındığında burası açılır)
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
  double selectedWidth = 4.0;
  bool isEraser = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Alttaki Ekran Görüntüsü
          Image.memory(widget.imageBytes, width: double.infinity, height: double.infinity, fit: BoxFit.fill),
          
          // Çizim Katmanı
          GestureDetector(
            onPanStart: (d) => setState(() => strokes.add(Stroke(points: [d.localPosition], color: isEraser ? Colors.transparent : selectedColor, width: selectedWidth))),
            onPanUpdate: (d) => setState(() => strokes.last.points.add(d.localPosition)),
            child: CustomPaint(painter: CizimRessami(strokes), size: Size.infinite),
          ),

          // Toolbar
          Positioned(
            top: 40, left: 20,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(30)),
              child: Row(
                children: [
                  _btn(Icons.edit, Colors.blue, () => setState(() => isEraser = false)),
                  _btn(Icons.auto_fix_high, Colors.purple, () => setState(() => isEraser = true)),
                  _btn(Icons.palette, Colors.red, () => setState(() => selectedColor = Colors.red)),
                  _btn(Icons.palette, Colors.green, () => setState(() => selectedColor = Colors.green)),
                  _btn(Icons.delete, Colors.grey, () => setState(() => strokes.clear())),
                  _btn(Icons.close, Colors.redAccent, () => Navigator.pop(context)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, Color color, VoidCallback tap) => IconButton(icon: Icon(icon, color: color), onPressed: tap);
}

class CizimRessami extends CustomPainter {
  final List<Stroke> strokes;
  CizimRessami(this.strokes);
  @override
  void paint(Canvas canvas, Size size) {
    for (var stroke in strokes) {
      Paint paint = Paint()..color = stroke.color..strokeCap = StrokeCap.round..strokeWidth = stroke.width..style = PaintingStyle.stroke;
      if (stroke.color == Colors.transparent) paint.blendMode = BlendMode.clear;
      
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
