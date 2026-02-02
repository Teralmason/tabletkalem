import 'package:flutter/material.dart';
import 'package:system_alert_window/system_alert_window.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    home: FatihKalem(),
    debugShowCheckedModeBanner: false,
    color: Colors.transparent, // Uygulama seviyesinde şeffaflık
  ));
}

class FatihKalem extends StatefulWidget {
  const FatihKalem({super.key});
  @override
  State<FatihKalem> createState() => _FatihKalemState();
}

// Çizgi Modeli
class Stroke {
  List<Offset> points;
  Color color;
  double width;
  Stroke({required this.points, required this.color, required this.width});
}

class _FatihKalemState extends State<FatihKalem> {
  List<Stroke> strokes = [];
  Color? selectedColor; // Null ise mouse modu, renkli ise çizim modu
  double selectedWidth = 3.0;
  bool isMenuOpen = false;
  bool isEraserMode = false;
  Offset menuPosition = const Offset(20, 100); // Menünün başlangıç konumu

  @override
  void initState() {
    super.initState();
    _initPermissions();
  }

  // İzinleri ve Overlay modunu başlat
  Future<void> _initPermissions() async {
    await SystemAlertWindow.requestPermissions;
  }

  // Çizim veya silgi aktif mi?
  bool get isActive => selectedColor != null || isEraserMode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // EN ÖNEMLİ KISIM: Zemin şeffaf
      body: Stack(
        children: [
          // 1. KATMAN: ÇİZİM ALANI
          // isActive false ise dokunmaları arkaya (masaüstüne) geçirir.
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
                  _silgiIslemi(details.localPosition);
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

          // 2. KATMAN: YÜZEN MENÜ (Sürüklenebilir)
          Positioned(
            left: menuPosition.dx,
            top: menuPosition.dy,
            child: Draggable(
              feedback: _buildMenuContent(isFeedback: true),
              childWhenDragging: Container(), // Sürüklerken yerinde iz bırakma
              onDragEnd: (details) {
                // Ekran dışına taşmayı engellemek için güvenli alan kontrolü
                setState(() {
                  menuPosition = details.offset;
                });
              },
              child: _buildMenuContent(),
            ),
          ),
        ],
      ),
    );
  }

  // Silgi Mantığı: Noktaya yakın olan çizgiyi siler
  void _silgiIslemi(Offset touchPoint) {
    setState(() {
      strokes.removeWhere((stroke) {
        // Çizginin herhangi bir noktası dokunulan yere 20 birimden yakınsa sil
        return stroke.points.any((p) => (p - touchPoint).distance < 20.0);
      });
    });
  }

  // Menü Tasarımı
  Widget _buildMenuContent({bool isFeedback = false}) {
    return Material(
      color: Colors.transparent, // Menü etrafında hare olmasın
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ana Buton (Tıklayınca açılır/kapanır)
          GestureDetector(
            onTap: () {
              if (!isFeedback) {
                setState(() => isMenuOpen = !isMenuOpen);
              }
            },
            child: Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                // Duruma göre renk değişir: Turuncu(Menü Açık), Mor(Silgi), Gri(Mouse), Renk(Seçili Renk)
                color: isMenuOpen 
                    ? Colors.amber[800] 
                    : (isEraserMode ? Colors.purple : (selectedColor ?? const Color(0xFF455A64))),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, spreadRadius: 1)
                ],
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(
                isMenuOpen ? Icons.close : (isEraserMode ? Icons.auto_fix_high : (selectedColor != null ? Icons.create : Icons.mouse)),
                color: Colors.white, 
                size: 24
              ),
            ),
          ),
          
          // Açılır Menü (Animasyonlu)
          if (isMenuOpen && !isFeedback)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              width: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF263238).withOpacity(0.95), // Koyu gri arka plan
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white24),
                boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 8)],
              ),
              child: Column(
                children: [
                  // Renkler
                  _renkButonu(const Color(0xFFD50000)), // Kırmızı
                  _renkButonu(const Color(0xFF2962FF)), // Mavi
                  _renkButonu(Colors.black),            // Siyah
                  _renkButonu(const Color(0xFF00C853)), // Yeşil
                  
                  const Divider(color: Colors.white24, indent: 10, endIndent: 10),
                  
                  // Kalınlıklar
                  _kalinlikButonu(2.0, "S"), // İnce (Small)
                  _kalinlikButonu(6.0, "M"), // Orta (Medium)
                  _kalinlikButonu(12.0, "L"), // Kalın (Large)
                  
                  const Divider(color: Colors.white24, indent: 10, endIndent: 10),
                  
                  // Araçlar
                  _aracButonu(Icons.auto_fix_high, () {
                    setState(() {
                      isEraserMode = !isEraserMode;
                      if (isEraserMode) selectedColor = null;
                      isMenuOpen = false; // Seçince menüyü kapat
                    });
                  }, isEraserMode ? Colors.purple : Colors.grey[700]!),
                  
                  _aracButonu(Icons.delete_forever, () {
                    setState(() {
                      strokes.clear();
                      isMenuOpen = false;
                    });
                  }, Colors.red[900]!),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Menü Yardımcı Widget'ları
  Widget _renkButonu(Color color) {
    bool isSelected = selectedColor == color && !isEraserMode;
    return GestureDetector(
      onTap: () => setState(() { 
        isEraserMode = false; 
        selectedColor = isSelected ? null : color; // Tekrar basınca mouse moduna dön
        isMenuOpen = false;
      }),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: color, 
          shape: BoxShape.circle, 
          border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 2.5)
        ),
      ),
    );
  }

  Widget _kalinlikButonu(double width, String text) {
    bool isSelected = selectedWidth == width;
    return GestureDetector(
      onTap: () => setState(() => selectedWidth = width),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        width: 30, height: 30,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white10,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(text, style: TextStyle(
            color: isSelected ? Colors.black : Colors.white, 
            fontWeight: FontWeight.bold,
            fontSize: 10
          )),
        ),
      ),
    );
  }

  Widget _aracButonu(IconData icon, VoidCallback onTap, Color bg) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        width: 32, height: 32,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

// Çizim Motoru
class CizimRessami extends CustomPainter {
  final List<Stroke> strokes;
  CizimRessami(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    for (var stroke in strokes) {
      Paint paint = Paint()
        ..color = stroke.color
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = stroke.width
        ..style = PaintingStyle.stroke;

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
