import 'package:flutter/material.dart';
import 'package:system_alert_window/system_alert_window.dart';

void main() => runApp(const MaterialApp(
      home: FatihKalem(),
      debugShowCheckedModeBanner: false,
    ));

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
    _checkPermission(); // Uygulama açılınca izni kontrol et
  }

  // Overlay izni isteyen sihirli fonksiyon
  Future<void> _checkPermission() async {
    await SystemAlertWindow.requestPermissions;
  }

  bool get isActive => selectedColor != null || isEraserMode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Arka planı tamamen cam gibi yapıyoruz
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
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.only(top: 6),
            height: isMenuOpen ? 360 : 0, width: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2C).withOpacity(0.98),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white10),
            ),
            child: isMenuOpen ? SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  _colorOption(const Color(0xFFB71C1C)), 
                  _colorOption(const Color(0xFF0D47A1)), 
                  _colorOption(Colors.black),
                  const Divider(color: Colors.white10, height: 16),
                  _widthOption(2.0, "İ"),
                  _widthOption(6.0, "O"),
                  _widthOption(12.0, "K"),
                  const Divider(color: Colors.white10, height: 16),
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
            ) : null,
          ),
        ],
      ),
    );
  }

  Widget _colorOption(Color color) {
    bool isSelected = selectedColor == color;
    return GestureDetector(
      onTap: () => setState(() { isEraserMode = false; selectedColor = isSelected ? null : color; }),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        width: 28, height: 28,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: isSelected ? Colors.white : Colors.white24, width: isSelected ? 2.5 : 1)),
      ),
    );
  }

  Widget _widthOption(double width, String label) {
    bool isSelected = selectedWidth == width;
    return GestureDetector(
      onTap: () => setState(() => selectedWidth = width),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        width: 30, height: 30,
        decoration: BoxDecoration(color: isSelected ? Colors.white : Colors.grey[800], shape: BoxShape.circle),
        child: Center(child: Text(label, style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontSize: 10))),
      ),
    );
  }

  Widget _actionOption(IconData icon, VoidCallback tap, Color bgColor) {
    return GestureDetector(onTap: tap, child: Container(margin: const EdgeInsets.symmetric(vertical: 5), width: 32, height: 32, decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 16)));
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
