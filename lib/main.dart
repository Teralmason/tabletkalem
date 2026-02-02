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
    // Depolama ve Overlay izinlerini iste
    await [Permission.storage, Permission.photos].request();
    await SystemAlertWindow.requestPermissions;
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
              const Icon(Icons.draw, size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons. Ondemand_video),
                label: const Text("Yüzen Baloncuğu Aç"),
                onPressed: _baloncuguGoster,
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text("Ekranı Yakala ve Çiz"),
                onPressed: () async {
                  // Bu buton normalde baloncuktan tetiklenecek ama test için burada
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
  double selectedWidth = 4.0;
  bool isEraser = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Arka plan: Yakalanan ekran görüntüsü
          Image.memory(
            widget.imageBytes,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.fill,
          ),
          
          // Çizim katmanı
          GestureDetector(
            onPanStart: (details) {
              setState(() {
                strokes.add(Stroke(
                  points: [details.localPosition],
                  color: isEraser ? Colors.white : selectedColor,
                  width: selectedWidth,
                ));
              });
            },
            onPanUpdate: (details) {
              setState(() {
                strokes.last.points.add(details.localPosition);
              });
            },
            child: CustomPaint(
              painter: CizimRessami(strokes),
              size: Size.infinite,
            ),
          ),

          // Araç Çubuğu
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _actionBtn(Icons.edit, Colors.blue, () => setState(() => isEraser = false)),
                  _actionBtn(Icons.auto_fix_high, Colors.purple, () => setState(() => isEraser = true)),
                  _actionBtn(Icons.circle, Colors.red, () => setState(() => selectedColor = Colors.red)),
                  _actionBtn(Icons.circle, Colors.green, () => setState(() => selectedColor = Colors.green)),
                  _actionBtn(Icons.delete, Colors.white, () => setState(() => strokes.clear())),
                  _actionBtn(Icons.close, Colors.redAccent, () => Navigator.pop(context)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, Color color, VoidCallback tap) {
    return IconButton(icon: Icon(icon, color: color), onPressed: tap);
  }
}

class CizimRessami extends CustomPainter {
  final List<Stroke> strokes;
  CizimRessami(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    for (var stroke in strokes) {
      Paint paint = Paint()
        ..color = stroke.color
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke.width
        ..style = PaintingStyle.stroke;

      Path path = Path();
      if (stroke.points.isNotEmpty) {
        path.moveTo(stroke.points[0].dx, stroke.points[0].dy);
        for (var p in stroke.points) {
          path.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
