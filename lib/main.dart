import 'package:flutter/material.dart';
import 'package:system_alert_window/system_alert_window.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    home: FatihKalem(),
    debugShowCheckedModeBanner: false,
  ));
}

class FatihKalem extends StatefulWidget {
  const FatihKalem({super.key});
  @override
  State<FatihKalem> createState() => _FatihKalemState();
}

class Stroke {
  List<Offset> points;
  Color color;
  double width;
  Stroke({required this.points, required this.color, required this.width});
}

class _FatihKalemState extends State<FatihKalem> {
  List<Stroke> strokes = [];
  Color? selectedColor;
  double selectedWidth = 3.0;
  bool isMenuOpen = false;
  bool isEraserMode = false;
  Offset menuPosition = const Offset(20, 100);

  @override
  void initState() {
    super.initState();
    SystemAlertWindow.requestPermissions; // İzni burada istiyoruz
  }

  bool get isActive => selectedColor != null || isEraserMode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: Stack(
        children: [
          IgnorePointer(
            ignoring: !isActive,
            child: GestureDetector(
              onPanStart: (details) {
                if (!isEraserMode && selectedColor != null) {
                  setState(() {
                    strokes.add(Stroke(
                      points: [details.localPosition],
                      color: selectedColor!,
                      width: selectedWidth,
                    ));
                  });
                }
              },
              onPanUpdate: (details) {
                if (isEraserMode) {
                  _strokeSilme(details.localPosition);
                } else if (selectedColor != null) {
                  setState(() {
                    strokes.last.points.add(details.localPosition);
                  });
                }
              },
              child: CustomPaint(
                painter: CizimRessami(strokes),
                size: Size.infinite,
              ),
            ),
          ),
          Positioned(
            left: menuPosition.dx,
            top: menuPosition.dy,
            child: Draggable(
              feedback: _buildFloatingMenu(isFeedback: true),
              childWhenDragging: Container(),
              onDragEnd: (details) => setState(() => menuPosition = details.offset),
              child: _buildFloatingMenu(),
            ),
          ),
        ],
      ),
    );
  }

  void _strokeSilme(Offset touchPoint) {
    setState(() {
      strokes.removeWhere((stroke) {
        return stroke.points.any((p) => (p - touchPoint).distance < 15.0);
      });
    });
  }

  Widget _buildFloatingMenu({bool isFeedback = false}) {
    return Material(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => setState(() => isMenuOpen = !isMenuOpen),
            child: Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: isMenuOpen ? Colors.amber[800] : (isEraserMode ? Colors.purple : (selectedColor ?? const Color(0xFF455A64))),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 6)],
              ),
              child: Icon(isEraserMode ? Icons.auto_fix_high : (selectedColor != null ? Icons.create : Icons.mouse), color: Colors.white, size: 24),
            ),
          ),
          if (isMenuOpen)
            Container(
              margin: const EdgeInsets.only(top: 6),
              width: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C).withOpacity(0.9),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  _colorOption(const Color(0xFFB71C1C)), 
                  _colorOption(const Color(0xFF0D47A1)), 
                  _colorOption(Colors.black),
                  const Divider(color: Colors.white24),
                  _widthOption(2.0, "İ"),
                  _widthOption(12.0, "K"),
                  const Divider(color: Colors.white24),
                  _actionOption(Icons.auto_fix_high, () {
                    setState(() {
                      isEraserMode = !isEraserMode;
                      if (isEraserMode) selectedColor = null;
                    });
                  }, isEraserMode ? Colors.purple : Colors.grey[700]!),
                  _actionOption(Icons.delete_sweep, () => setState(() => strokes.clear()), Colors.redAccent),
                  const SizedBox(height: 10),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _colorOption(Color color) {
    return GestureDetector(
      onTap: () => setState(() { isEraserMode = false; selectedColor = color; }),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        width: 25, height: 25,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white)),
      ),
    );
  }

  Widget _widthOption(double width, String label) {
    return GestureDetector(
      onTap: () => setState(() => selectedWidth = width),
      child: CircleAvatar(radius: 15, backgroundColor: Colors.white24, child: Text(label, style: const TextStyle(fontSize: 10, color: Colors.white))),
    );
  }

  Widget _actionOption(IconData icon, VoidCallback tap, Color bgColor) {
    return GestureDetector(onTap: tap, child: CircleAvatar(radius: 16, backgroundColor: bgColor, child: Icon(icon, color: Colors.white, size: 16)));
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
        for (int i = 1; i < stroke.points.length; i++) {
          path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
        }
      }
      canvas.drawPath(path, paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
