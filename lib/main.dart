import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:typed_data';

// Ana uygulama entry point
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String _debugLog = '';
  bool _isOverlayActive = false;

  void _addLog(String message) {
    setState(() {
      _debugLog = '${DateTime.now().toString().substring(11, 19)} - $message\n$_debugLog';
    });
    debugPrint('🔵 $message');
  }

  Future<void> _checkPermissions() async {
    _addLog('İzinler kontrol ediliyor...');
    
    // Bildirim izni kontrol
    final notificationStatus = await Permission.notification.status;
    _addLog('Bildirim izni: ${notificationStatus.isGranted ? "✅ Var" : "❌ Yok"}');
    
    // Overlay izni kontrol
    final overlayGranted = await FlutterOverlayWindow.isPermissionGranted();
    _addLog('Overlay izni: ${overlayGranted ? "✅ Var" : "❌ Yok"}');
    
    // Overlay aktif mi kontrol
    final overlayActive = await FlutterOverlayWindow.isActive();
    _addLog('Overlay aktif mi: ${overlayActive ? "✅ Evet" : "❌ Hayır"}');
    
    setState(() {
      _isOverlayActive = overlayActive;
    });
  }

  Future<void> _requestAllPermissions() async {
    _addLog('Tüm izinler isteniyor...');
    
    // 1. Bildirim izni
    if (!await Permission.notification.isGranted) {
      _addLog('Bildirim izni isteniyor...');
      final result = await Permission.notification.request();
      _addLog('Bildirim izni sonucu: ${result.isGranted ? "✅ Verildi" : "❌ Reddedildi"}');
    }
    
    // 2. Overlay izni
    if (!await FlutterOverlayWindow.isPermissionGranted()) {
      _addLog('Overlay izni isteniyor...');
      final result = await FlutterOverlayWindow.requestPermission();
      _addLog('Overlay izni sonucu: ${result ? "✅ Verildi" : "❌ Reddedildi"}');
    }
    
    await _checkPermissions();
  }

  Future<void> _startOverlay() async {
    _addLog('=== BALONCUK BAŞLATMA BAŞLADI ===');
    
    try {
      // İzinleri kontrol et
      final hasOverlayPermission = await FlutterOverlayWindow.isPermissionGranted();
      _addLog('Overlay izni var mı: ${hasOverlayPermission ? "✅" : "❌"}');
      
      if (!hasOverlayPermission) {
        _addLog('⚠️ Overlay izni yok! İsteniyor...');
        final granted = await FlutterOverlayWindow.requestPermission();
        
        if (!granted) {
          _addLog('❌ Overlay izni reddedildi!');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Overlay izni gerekli! Lütfen ayarlardan verin.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        _addLog('✅ Overlay izni verildi!');
      }
      
      // Overlay zaten aktif mi kontrol et
      final isActive = await FlutterOverlayWindow.isActive();
      _addLog('Overlay şu an aktif mi: ${isActive ? "Evet" : "Hayır"}');
      
      if (isActive) {
        _addLog('⚠️ Overlay zaten aktif!');
        setState(() {
          _isOverlayActive = true;
        });
        return;
      }
      
      // Overlay'i başlat
      _addLog('🚀 FlutterOverlayWindow.showOverlay() çağrılıyor...');
      
      final result = await FlutterOverlayWindow.showOverlay(
        enableDrag: true,
        overlayTitle: "TabletKalem",
        overlayContent: "Baloncuk",
        flag: OverlayFlag.defaultFlag,
        visibility: NotificationVisibility.visibilityPublic,
        positionGravity: PositionGravity.none,
        width: 200,
        height: 200,
      );
      
      _addLog('showOverlay() sonucu: ${result ? "✅ Başarılı" : "❌ Başarısız"}');
      
      // Kontrol et
      await Future.delayed(const Duration(seconds: 1));
      final nowActive = await FlutterOverlayWindow.isActive();
      _addLog('1 saniye sonra overlay aktif mi: ${nowActive ? "✅ Evet" : "❌ Hayır"}');
      
      setState(() {
        _isOverlayActive = nowActive;
      });
      
      if (nowActive) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Baloncuk başlatıldı! Ekranın köşesine bakın!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Baloncuk başlatılamadı! Log\'a bakın.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      
    } catch (e, stackTrace) {
      _addLog('❌ HATA: $e');
      _addLog('Stack trace: $stackTrace');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
    
    _addLog('=== BALONCUK BAŞLATMA BİTTİ ===');
  }

  Future<void> _closeOverlay() async {
    _addLog('=== BALONCUK KAPATMA BAŞLADI ===');
    
    try {
      final isActive = await FlutterOverlayWindow.isActive();
      _addLog('Overlay aktif mi: ${isActive ? "Evet" : "Hayır"}');
      
      if (!isActive) {
        _addLog('⚠️ Overlay zaten kapalı!');
        setState(() {
          _isOverlayActive = false;
        });
        return;
      }
      
      _addLog('🔴 FlutterOverlayWindow.closeOverlay() çağrılıyor...');
      await FlutterOverlayWindow.closeOverlay();
      
      await Future.delayed(const Duration(milliseconds: 500));
      final nowActive = await FlutterOverlayWindow.isActive();
      _addLog('Kapatıldıktan sonra overlay aktif mi: ${nowActive ? "Evet" : "Hayır"}');
      
      setState(() {
        _isOverlayActive = nowActive;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Baloncuk kapatıldı')),
      );
      
    } catch (e) {
      _addLog('❌ Kapatma hatası: $e');
    }
    
    _addLog('=== BALONCUK KAPATMA BİTTİ ===');
  }

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tablet Kalem - DEBUG'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          // Durum paneli
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: _isOverlayActive ? Colors.green.shade100 : Colors.red.shade100,
            child: Column(
              children: [
                Icon(
                  _isOverlayActive ? Icons.check_circle : Icons.cancel,
                  color: _isOverlayActive ? Colors.green : Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 8),
                Text(
                  _isOverlayActive ? 'BALONCUK AKTİF ✅' : 'BALONCUK KAPALI ❌',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _isOverlayActive ? Colors.green.shade900 : Colors.red.shade900,
                  ),
                ),
              ],
            ),
          ),
          
          // Butonlar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _requestAllPermissions,
                    icon: const Icon(Icons.security),
                    label: const Text('İzinleri İste'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _checkPermissions,
                    icon: const Icon(Icons.refresh),
                    label: const Text('İzinleri Kontrol Et'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _startOverlay,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Baloncuğu Başlat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _closeOverlay,
                    icon: const Icon(Icons.stop),
                    label: const Text('Baloncuğu Kapat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Debug log
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'DEBUG LOG:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                reverse: true,
                child: Text(
                  _debugLog.isEmpty ? 'Log boş...' : _debugLog,
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
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
      home: Material(
        color: Colors.transparent,
        child: OverlayBubble(),
      ),
    ),
  );
}

class OverlayBubble extends StatelessWidget {
  const OverlayBubble({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () {
          debugPrint('🔵 Baloncuğa tıklandı!');
          FlutterOverlayWindow.closeOverlay();
        },
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 3,
              ),
            ],
          ),
          child: const Icon(
            Icons.create,
            color: Colors.white,
            size: 50,
          ),
        ),
      ),
    );
  }
}
