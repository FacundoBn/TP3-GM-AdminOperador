// lib/presentation/screens/scan_screen.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// OCR
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

// 👇 usa el scaffold común con hamburguesa / back
import 'package:tp3_v2/presentation/widgets/app_scaffold.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});
  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

/* ===================== Helpers mínimos (sin archivos nuevos) ===================== */

String _normalizePlate(String input) =>
    input.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

bool _isValidPlate(String input) {
  final n = _normalizePlate(input);
  final a = RegExp(r'^[A-Z]{3}\d{3}$');        // ABC123
  final b = RegExp(r'^[A-Z]{2}\d{3}[A-Z]{2}$'); // AB123CD
  return a.hasMatch(n) || b.hasMatch(n);
}

/// Devuelve el ticket activo (id) si existe para la patente.
/// tickets: { vehiclePlate, userId, ingreso, egreso, precioFinal, status, slotId }
Future<String?> _startOrGetActive({
  required String plate,
  required String userId,
}) async {
  final db = FirebaseFirestore.instance;
  final norm = _normalizePlate(plate);

  // Buscar ticket activo existente
  final q = await db
      .collection('tickets')
      .where('vehiclePlate', isEqualTo: norm)
      .where('egreso', isNull: true)
      .limit(1)
      .get();

  if (q.docs.isNotEmpty) {
    return q.docs.first.id; // id del ticket activo
  }

  // No hay ticket activo
  return null;
}

/* =================================== UI =================================== */

class _ScanScreenState extends ConsumerState<ScanScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _manualCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final hasCameraTab = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    _tab = TabController(length: hasCameraTab ? 2 : 1, vsync: this);
  }

  @override
  void dispose() {
    _manualCtrl.dispose();
    _tab.dispose();
    super.dispose();
  }

  Future<void> _startWithPlate(String raw) async {
    if (_saving) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debés iniciar sesión')),
        );
      }
      return;
    }

    final plate = _normalizePlate(raw);
    if (!_isValidPlate(plate)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Patente inválida')),
        );
      }
      return;
    }

    setState(() => _saving = true);
    try {
      final ticketId =
          await _startOrGetActive(plate: plate, userId: user.uid);

      if (!mounted) return;

      if (ticketId != null) {
        // Existe ticket activo → redirigir a pantalla activa
        context.go('/active', extra: ticketId);
      } else {
        // No hay ticket activo → iniciar flujo de nuevo ticket
        // ✅ Variante robusta: path param (evita "no routes for location")
        context.push('/newTicket/$plate');

        // Alternativa equivalente si preferís usar `extra`:
        // context.push('/newTicket', extra: plate);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error verificando ticket: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasCameraTab = !kIsWeb && (Platform.isAndroid || Platform.isIOS);

    return AppScaffold(
      title: 'Escanear patente',
      bottom: TabBar(
        controller: _tab,
        tabs: [
          if (hasCameraTab)
            const Tab(icon: Icon(Icons.photo_camera), text: 'Cámara'),
          const Tab(icon: Icon(Icons.keyboard), text: 'Manual'),
        ],
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          if (hasCameraTab) _CameraTab(onPlateFound: _startWithPlate),
          _ManualTab(
            controller: _manualCtrl,
            onSubmit: _startWithPlate,
            saving: _saving,
          ),
        ],
      ),
    );
  }
}

/* ------------------------------ Tab: Manual ------------------------------ */
class _ManualTab extends StatelessWidget {
  final TextEditingController controller;
  final bool saving;
  final void Function(String plate) onSubmit;
  const _ManualTab({
    required this.controller,
    required this.onSubmit,
    required this.saving,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: controller,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Patente (ABC123 o AB123CD)',
              border: OutlineInputBorder(),
            ),
            onSubmitted: saving ? null : onSubmit,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: saving ? null : () => onSubmit(controller.text),
              icon: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(saving ? 'Procesando...' : 'Iniciar'),
            ),
          ),
        ],
      ),
    );
  }
}

/* ------------------------------ Tab: Cámara ------------------------------ */
class _CameraTab extends StatefulWidget {
  final void Function(String plate) onPlateFound;
  const _CameraTab({required this.onPlateFound});

  @override
  State<_CameraTab> createState() => _CameraTabState();
}

class _CameraTabState extends State<_CameraTab> {
  CameraController? _controller;
  late final TextRecognizer _recognizer;
  bool _busy = false;
  int _skip = 0;

  @override
  void initState() {
    super.initState();
    _recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    _initCam();
  }

  Future<void> _initCam() async {
    try {
      final cams = await availableCameras();
      final cam = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cams.first,
      );
      _controller = CameraController(
        cam,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _controller!.initialize();
      await _controller!.startImageStream(_processFrame);
      if (mounted) setState(() {});
    } catch (_) {
      // Si falla la cámara, mostramos un placeholder
      if (mounted) setState(() => _controller = null);
    }
  }

  Future<void> _processFrame(CameraImage img) async {
    if (_busy) return;
    _skip = (_skip + 1) % 6; // procesa 1 de cada 6 frames
    if (_skip != 0) return;

    _busy = true;
    try {
      // Unimos los planos YUV en un único Uint8List
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane p in img.planes) {
        allBytes.putUint8List(p.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      // API nueva de google_mlkit_commons (metadata en lugar de inputImageData)
      final metadata = InputImageMetadata(
        size: Size(img.width.toDouble(), img.height.toDouble()),
        rotation: InputImageRotation.rotation0deg,
        format: InputImageFormat.nv21,
        bytesPerRow: img.planes.first.bytesPerRow,
      );

      final input = InputImage.fromBytes(
        bytes: bytes,
        metadata: metadata,
      );

      final result = await _recognizer.processImage(input);

      for (final block in result.blocks) {
        final text = _normalizePlate(block.text);
        if (_isValidPlate(text)) {
          widget.onPlateFound(text);
          return;
        }
      }
    } catch (_) {
      // Podés loguear si querés
    } finally {
      _busy = false;
    }
  }

  @override
  void dispose() {
    try {
      _controller?.dispose();
      _recognizer.close();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !(_controller!.value.isInitialized)) {
      return const Center(
        child: Text('Cámara no disponible en este dispositivo.'),
      );
    }
    return AspectRatio(
      aspectRatio: _controller!.value.aspectRatio,
      child: CameraPreview(_controller!),
    );
  }
}
