import 'dart:typed_data';
import 'package:flutter/material.dart';
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
  final ScreenshotController screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _izinIste();
  }

  Future<void> _izinIste() async {
    await [Permission.storage, Permission.photos, Permission.camera].request();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Fatih Kalem V2"), backgroundColor: Colors.blue),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.edit_note, size: 100, color: Colors.blue),
            const SizedBox(height: 20),
            const Text("1. PDF Uygulamasını Açın\n2. Buraya Dönüp Butona Basın", textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                // 5 saniye süre veriyoruz, kullanıcı bu sırada PDF'e geçsin
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("5 saniye içinde PDF'e geçin!"), duration: Duration(seconds: 2))
                );
                
                await Future.delayed(const Duration(seconds: 5));
                
                final image = await screenshotController.capture();
                if (image != null && mounted) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => CizimEkrani(imageBytes: image)));
                }
              },
              child: const Text("5 SN SONRA YAKALA VE ÇİZ"),
            ),
          ],
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
  Stroke({required this.points, required this.color});
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
            onPanStart: (d) => setState(() => strokes.add(Stroke(points: [d.localPosition], color: isEraser ? Colors.white : selectedColor))),
            onPanUpdate: (d) => setState(() => strokes.last.points.add(d.localPosition)),
            child: CustomPaint(painter: CizimPainter(strokes), size: Size.infinite),
          ),
          Positioned(
            top: 40, left: 10, right: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _btn(Icons.edit, Colors.blue, () => isEraser = false),
                _btn(Icons.auto_fix_high, Colors.purple, () => isEraser = true),
                _btn(Icons.delete, Colors.white, () => strokes.clear()),
                _btn(Icons.close, Colors.red, () => Navigator.pop(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, Color col, VoidCallback fn) => IconButton(
    icon: Icon(icon, color: col), 
    onPressed: () => setState(fn),
    style: IconButton.styleFrom(backgroundColor: Colors.black87),
  );
}

class CizimPainter extends CustomPainter {
  final List<Stroke> strokes;
  CizimPainter(this.strokes);
  @override
  void paint(Canvas canvas, Size size) {
    for (var stroke in strokes) {
      final paint = Paint()..color = stroke.color..strokeCap = StrokeCap.round..strokeWidth = 5.0..style = PaintingStyle.stroke;
      final path = Path();
      if (stroke.points.isNotEmpty) {
        path.moveTo(stroke.points[0].dx, stroke.points[0].dy);
        for (var p in stroke.points) path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
    }
  }
  @override
  bool shouldRepaint(CustomPainter old) => true;
}
