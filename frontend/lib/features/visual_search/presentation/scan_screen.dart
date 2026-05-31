import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_animations.dart';
import '../domain/visual_search_provider.dart';
import 'visual_search_results_sheet.dart';
import 'scan_overlay_painter.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> with TickerProviderStateMixin {
  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;
  bool _isFlashOn = false;

  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;

  late AnimationController _scanLineController;
  late Animation<double> _scanLineAnimation;

  @override
  void initState() {
    super.initState();
    _initCamera();

    _breathingController = AnimationController(
      vsync: this,
      duration: cameraPulseDuration,
    )..repeat(reverse: true);
    _breathingAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _breathingController, curve: easeOutCubic),
    );

    _scanLineController = AnimationController(
      vsync: this,
      duration: scanFadeDuration,
    )..repeat();
    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_scanLineController);
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
    );
    _initializeControllerFuture = _cameraController!.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _breathingController.dispose();
    _scanLineController.dispose();
    super.dispose();
  }

  void _toggleFlash() async {
    if (_cameraController == null) return;
    _isFlashOn = !_isFlashOn;
    await _cameraController!.setFlashMode(_isFlashOn ? FlashMode.torch : FlashMode.off);
    setState(() {});
  }

  Future<void> _captureImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    
    try {
      final image = await _cameraController!.takePicture();
      ref.read(visualSearchNotifierProvider.notifier).processImage(image.path);
      _showResultsSheet();
    } catch (e) {
      // Ignore
    }
  }

  void _showResultsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      isDismissible: false,
      builder: (context) => const VisualSearchResultsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(visualSearchNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera Preview
          if (_initializeControllerFuture != null)
            FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return CameraPreview(_cameraController!);
                } else {
                  return const Center(child: CircularProgressIndicator(color: AppColors.signal));
                }
              },
            ),

          // Vignette
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Colors.transparent,
                  AppColors.warmWhite.withValues(alpha: 0.15),
                ],
                radius: 0.8,
                stops: const [0.5, 1.0],
              ),
            ),
          ),

          // Top Controls
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _toggleFlash,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.ink.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isFlashOn ? Icons.flash_on : Icons.flash_off,
                      color: AppColors.warmWhite,
                      size: 20,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.ink.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: AppColors.warmWhite, size: 20),
                  ),
                ),
              ],
            ),
          ),

          // Viewfinder
          Center(
            child: ScaleTransition(
              scale: _breathingAnimation,
              child: AnimatedBuilder(
                animation: _scanLineAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    size: const Size(220, 220),
                    painter: ScanOverlayPainter(scanLineProgress: _scanLineAnimation.value),
                  );
                },
              ),
            ),
          ),

          // Hint Text
          const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 260),
              child: Text(
                'POINT AT ANY OBJECT',
                style: TextStyle(
                  color: Color.fromRGBO(255, 248, 243, 0.5), // warmWhite 50%
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),

          // Bottom Controls
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () async {
                    await ref.read(visualSearchNotifierProvider.notifier).pickFromGallery();
                    _showResultsSheet();
                  },
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.photo_library_outlined, color: AppColors.warmWhite),
                  ),
                ),
                GestureDetector(
                  onTap: _captureImage,
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.signal, width: 2),
                    ),
                    child: Center(
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 52), // Balance
              ],
            ),
          ),

          // Processing Overlay
          if (state.status == VisualSearchStatus.processing)
            Container(
              color: AppColors.ink.withValues(alpha: 0.7),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: AppColors.signal),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Identifying product...',
                      style: AppTypography.titleMD.copyWith(color: AppColors.warmWhite),
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
