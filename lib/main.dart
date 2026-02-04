import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'dart:typed_data';

// Ana uygulama entry point
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
      appBar: AppBar(
        title: const Text('Tablet Kalem'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.create, size: 100, color: Colors.blue),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.bubble_chart),
              label: const Text("Baloncuğu Başlat"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              onPressed: () async {
                if (await FlutterOverlayWindow.isActive()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Baloncuk zaten aktif!')),
                  );
                  return;
                }
                
                await FlutterOverlayWindow.showOverlay(
                  height: 80,
                  width: 80,
                  enableDrag: true,
                  overlayTitle: "TabletKalem",
                  overlayContent: "Baloncuk",
                  flag: OverlayFlag.defaultFlag,
                  visibility: NotificationVisibility.visibilityPublic,
                );
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Baloncuk başlatıldı!')),
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.close),
              label: const Text("Baloncuğu Kapat"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              onPressed: () async {
                if (await FlutterOverlayWindow.isActive()) {
                  await FlutterOverlayWindow.closeOverlay();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Baloncuk kapatıldı!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Baloncuk zaten kapalı!')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ========================================
// OVERLAY BALONCUK ENTRY POINT
// ========================================
@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OverlayBubble(),
    ),
  );
}

class OverlayBubble extends StatefulWidget {
  const OverlayBubble({super.key});

  @override
  State<OverlayBubble> createState() => _OverlayBubbleState();
}

class _OverlayBubbleState extends State<OverlayBubble> {
  bool _isDrawingMode = false;
  Uint8List? _screenshot;
  static const platform = MethodChannel('screenshot_channel');

  Future<void> _takeScreenshot() async {
    try {
      // Önce overlay'i gizle
      await FlutterOverlayWindow.closeOverlay();
      
      // Biraz bekle ki ekran temiz olsun
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Screenshot al
      final Uint8List result = await platform.invokeMethod('takeScreenshot');
      
      setState(() {
        _screenshot = result;
        _isDrawingMode = true;
      });
    } catch (e) {
      debugPrint('Screenshot hatası: $e');
      // Hata olursa overlay'i geri aç
      await FlutterOverlayWindow.showOverlay(
        height: 80,
        width: 80,
        enableDrag: true,
      );
    }
  }

  void _closeDrawing() {
    setState(() {
      _isDrawingMode = false;
      _screenshot = null;
    });
    
    // Baloncuğu tekrar aç
    FlutterOverlayWindow.showOverlay(
      height: 80,
      width: 80,
      enableDrag: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isDrawingMode && _screenshot != null) {
      return DrawingScreen(
        screenshot: _screenshot!,
        onClose: _closeDrawing,
      );
    }

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: _takeScreenshot,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.create,
            color: Colors.white,
            size: 35,
          ),
        ),
      ),
    );
  }
}

// ========================================
// ÇİZİM EKRANI
// ========================================
class DrawingScreen extends StatefulWidget {
  final Uint8List screenshot;
  final VoidCallback onClose;

  const DrawingScreen({
    super.key,
    required this.screenshot,
    required this.onClose,
  });

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  final List<DrawingPoint> _points = [];
  Color _selectedColor = Colors.red;
  double _strokeWidth = 3.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Arka plan screenshot
          Positioned.fill(
            child: Image.memory(
              widget.screenshot,
              fit: BoxFit.contain,
            ),
          ),
          
          // Çizim alanı
          Positioned.fill(
            child: GestureDetector(
              onPanStart: (details) {
                setState(() {
                  _points.add(
                    DrawingPoint(
                      details.localPosition,
                      _selectedColor,
                      _strokeWidth,
                    ),
                  );
                });
              },
              onPanUpdate: (details) {
                setState(() {
                  _points.add(
                    DrawingPoint(
                      details.localPosition,
                      _selectedColor,
                      _strokeWidth,
                    ),
                  );
                });
              },
              onPanEnd: (details) {
                setState(() {
                  _points.add(DrawingPoint.separator());
                });
              },
              child: CustomPaint(
                painter: DrawingPainter(_points),
              ),
            ),
          ),
          
          // Üst toolbar
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: Colors.black54,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Kapat butonu
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 30),
                    onPressed: widget.onClose,
                  ),
                  
                  // Renk seçimi
                  ...[ Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.white ]
                      .map((color) => GestureDetector(
                        onTap: () => setState(() => _selectedColor = color),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _selectedColor == color ? Colors.white : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                      )),
                  
                  // Temizle
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.white, size: 30),
                    onPressed: () => setState(() => _points.clear()),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ========================================
// ÇİZİM NOKTALARI VE PAINTER
// ========================================
class DrawingPoint {
  final Offset? offset;
  final Color color;
  final double strokeWidth;

  DrawingPoint(this.offset, this.color, this.strokeWidth);
  
  DrawingPoint.separator()
      : offset = null,
        color = Colors.transparent,
        strokeWidth = 0;
}

class DrawingPainter extends CustomPainter {
  final List<DrawingPoint> points;

  DrawingPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i].offset != null && points[i + 1].offset != null) {
        canvas.drawLine(
          points[i].offset!,
          points[i + 1].offset!,
          Paint()
            ..color = points[i].color
            ..strokeWidth = points[i].strokeWidth
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
}
