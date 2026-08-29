import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:utanglista_mobileapp/core/routes/routes.dart';
import 'package:utanglista_mobileapp/core/shared/scanner/manual_barcode_entry_dialog.dart';
import 'package:utanglista_mobileapp/core/styles/app_palette.dart';
import 'package:utanglista_mobileapp/core/styles/app_text_styles.dart';

/*
  ------------------------------------------------------------------
  BarcodeScannerScreen: the app's only camera surface.
  ------------------------------------------------------------------

  Pops a barcode String, or null if the user backed out. Callers never
  touch mobile_scanner directly, so the package's frequent breaking
  changes stay contained in this one file.

  USAGE — the static helper keeps call sites to one line:

    final barcode = await BarcodeScannerScreen.open(context);
    if (barcode == null) return;          // cancelled
    // ...look the barcode up, or drop it into the form field

  It routes through go_router (AppRoutes.scan) like everything else in
  the app; the helper only exists so callers do not have to remember to
  build a ScanRequest and type the return generic.

  ------------------------------------------------------------------
  SCANNING IS ALWAYS OPTIONAL.
  ------------------------------------------------------------------

  A street-vendor store sells fishball and kwek-kwek; there is no
  barcode to scan, and the products table allows a null barcode for
  exactly that reason. On top of that the camera can be refused,
  missing, or simply unable to read a barcode worn smooth by a year in
  a sari-sari store.

  So every failure path here ends at manual entry rather than at a dead
  end. A permission the user denied is not an error state — it is just
  a different way to type thirteen digits.
*/
class BarcodeScannerScreen extends StatefulWidget {
  /// Shown under the viewfinder to say what the scan is for.
  final String title;
  final String? subtitle;

  const BarcodeScannerScreen({
    super.key,
    this.title = 'Scan barcode',
    this.subtitle,
  });

  /// Opens the scanner and resolves to the scanned barcode, or null if
  /// the user cancelled.
  static Future<String?> open(
    BuildContext context, {
    String title = 'Scan barcode',
    String? subtitle,
  }) {
    return context.push<String>(
      AppRoutes.scan,
      extra: ScanRequest(title: title, subtitle: subtitle),
    );
  }

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  /*
    Retail formats only.

    Two reasons. It speeds detection up, because the decoder is not
    trying twenty formats on every frame. More importantly it stops a
    QR code taped to the wall being read as a product — the scanner is
    for goods, and every format here is one that appears on packaging.
  */
  late final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.code93,
      BarcodeFormat.itf14,
    ],
  );

  /*
    onDetect keeps firing while the barcode stays in frame. Without this
    guard the first scan pops the route and every later frame pops
    whatever screen happened to take its place.
  */
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;

    // A capture can arrive with no readable value; wait for a real one
    // rather than popping null and looking like a cancel.
    final value = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .firstWhere(
          (raw) => raw != null && raw.trim().isNotEmpty,
          orElse: () => null,
        );

    if (value == null) return;

    _handled = true;
    HapticFeedback.mediumImpact();

    if (!mounted) return;
    context.pop(value.trim());
  }

  Future<void> _enterManually() async {
    final barcode = await ManualBarcodeEntryDialog.show(context);
    if (barcode == null || !mounted) return;

    _handled = true;
    context.pop(barcode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.title,
          style: AppTextStyles.body1.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [_TorchButton(controller: _controller)],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final scanWindow = _scanWindowFor(constraints.biggest);

          return Stack(
            fit: StackFit.expand,
            children: [
              MobileScanner(
                controller: _controller,
                onDetect: _onDetect,

                // Decode only inside the frame. Cheaper per frame, and
                // it stops a barcode on a neighbouring packet being
                // picked up while the user aims at the one they want.
                scanWindow: scanWindow,

                errorBuilder: (context, error) => _ScannerErrorView(
                  error: error,
                  onEnterManually: _enterManually,
                ),

                placeholderBuilder: (context) => const ColoredBox(
                  color: Colors.black,
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              ),

              // Dim everything outside the frame.
              IgnorePointer(
                child: CustomPaint(
                  painter: _ScanWindowOverlayPainter(scanWindow: scanWindow),
                ),
              ),

              _ScannerFooter(
                subtitle: widget.subtitle,
                onEnterManually: _enterManually,
              ),
            ],
          );
        },
      ),
    );
  }

  /// A wide, short window — retail barcodes are far wider than they are
  /// tall, and a square frame invites the user to hold the phone wrong.
  Rect _scanWindowFor(Size layout) {
    final width = layout.width * 0.8;
    final height = width * 0.45;

    return Rect.fromCenter(
      center: Offset(layout.width / 2, layout.height / 2.4),
      width: width,
      height: height,
    );
  }
}

// ============================================================
// TORCH
// ============================================================
/*
  Hidden entirely when the device reports no torch, rather than shown
  disabled — a sari-sari store at dusk is exactly when this matters, and
  a greyed-out button reads as "broken" rather than "unavailable".
*/
class _TorchButton extends StatelessWidget {
  final MobileScannerController controller;

  const _TorchButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MobileScannerState>(
      valueListenable: controller,
      builder: (context, state, child) {
        if (!state.isInitialized ||
            state.torchState == TorchState.unavailable) {
          return const SizedBox.shrink();
        }

        final isOn = state.torchState == TorchState.on;

        return IconButton(
          tooltip: isOn ? 'Turn off flash' : 'Turn on flash',
          onPressed: () => controller.toggleTorch(),
          icon: Icon(
            isOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
            color: isOn ? AppPalette.warning : Colors.white,
          ),
        );
      },
    );
  }
}

// ============================================================
// FOOTER
// ============================================================
class _ScannerFooter extends StatelessWidget {
  final String? subtitle;
  final VoidCallback onEnterManually;

  const _ScannerFooter({required this.subtitle, required this.onEnterManually});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.85)],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              subtitle ?? 'Point the camera at the product barcode',
              textAlign: TextAlign.center,
              style: AppTextStyles.body1.copyWith(color: Colors.white),
            ),

            const SizedBox(height: 16),

            // Always available, not just after a failure: some barcodes
            // are unreadable and the user knows it before the camera does.
            TextButton.icon(
              onPressed: onEnterManually,
              icon: const Icon(Icons.keyboard_rounded, size: 20),
              label: const Text('Enter barcode manually'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ERROR
// ============================================================
/*
  Every branch ends with manual entry. A denied permission or a device
  with no camera must not block adding a product — it only changes how
  the barcode gets typed.
*/
class _ScannerErrorView extends StatelessWidget {
  final MobileScannerException error;
  final VoidCallback onEnterManually;

  const _ScannerErrorView({required this.error, required this.onEnterManually});

  @override
  Widget build(BuildContext context) {
    final (icon, title, message) = switch (error.errorCode) {
      MobileScannerErrorCode.permissionDenied => (
        Icons.no_photography_outlined,
        'Camera permission needed',
        'Allow camera access in your device settings to scan barcodes, '
            'or enter the barcode by hand.',
      ),
      MobileScannerErrorCode.unsupported => (
        Icons.videocam_off_outlined,
        'Scanning not supported',
        'This device cannot scan barcodes. You can still enter them by hand.',
      ),
      _ => (
        Icons.error_outline_rounded,
        'Camera unavailable',
        'The camera could not be started. You can enter the barcode by hand.',
      ),
    };

    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: Colors.white70),

              const SizedBox(height: 20),

              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.subtitle1.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.body1.copyWith(
                  color: Colors.white70,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 28),

              FilledButton.icon(
                onPressed: onEnterManually,
                icon: const Icon(Icons.keyboard_rounded, size: 20),
                label: const Text('Enter barcode manually'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppPalette.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// OVERLAY
// ============================================================
/*
  Dims the preview everywhere except the scan window, and outlines the
  window with corner brackets.

  Drawn with an even-odd fill rather than four rectangles around the
  hole: the single path keeps the cutout exactly aligned with the Rect
  passed to MobileScanner, so what the user aims at is what actually
  gets decoded.
*/
class _ScanWindowOverlayPainter extends CustomPainter {
  final Rect scanWindow;

  const _ScanWindowOverlayPainter({required this.scanWindow});

  @override
  void paint(Canvas canvas, Size size) {
    final windowRect = RRect.fromRectAndRadius(
      scanWindow,
      const Radius.circular(16),
    );

    final dim = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(windowRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(dim, Paint()..color = Colors.black.withValues(alpha: 0.6));

    canvas.drawRRect(
      windowRect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    _paintCorners(canvas, windowRect);
  }

  void _paintCorners(Canvas canvas, RRect window) {
    const armLength = 26.0;
    final paint = Paint()
      ..color = AppPalette.primarySoft
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final rect = window.outerRect;

    // Top-left
    canvas.drawLine(
      rect.topLeft.translate(0, armLength),
      rect.topLeft.translate(0, 14),
      paint,
    );
    canvas.drawLine(
      rect.topLeft.translate(14, 0),
      rect.topLeft.translate(armLength, 0),
      paint,
    );

    // Top-right
    canvas.drawLine(
      rect.topRight.translate(0, armLength),
      rect.topRight.translate(0, 14),
      paint,
    );
    canvas.drawLine(
      rect.topRight.translate(-14, 0),
      rect.topRight.translate(-armLength, 0),
      paint,
    );

    // Bottom-left
    canvas.drawLine(
      rect.bottomLeft.translate(0, -armLength),
      rect.bottomLeft.translate(0, -14),
      paint,
    );
    canvas.drawLine(
      rect.bottomLeft.translate(14, 0),
      rect.bottomLeft.translate(armLength, 0),
      paint,
    );

    // Bottom-right
    canvas.drawLine(
      rect.bottomRight.translate(0, -armLength),
      rect.bottomRight.translate(0, -14),
      paint,
    );
    canvas.drawLine(
      rect.bottomRight.translate(-14, 0),
      rect.bottomRight.translate(-armLength, 0),
      paint,
    );
  }

  @override
  bool shouldRepaint(_ScanWindowOverlayPainter oldDelegate) =>
      oldDelegate.scanWindow != scanWindow;
}
