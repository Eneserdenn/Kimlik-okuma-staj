import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/face_verification_service.dart';

class FaceVerificationView extends ConsumerStatefulWidget {
  final Uint8List nfcPhotoBytes;
  final String cardholderName;

  const FaceVerificationView({
    super.key,
    required this.nfcPhotoBytes,
    required this.cardholderName,
  });

  @override
  ConsumerState<FaceVerificationView> createState() => _FaceVerificationViewState();
}

class _FaceVerificationViewState extends ConsumerState<FaceVerificationView> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isVerifying = false;
  bool _verificationComplete = false;
  bool _verificationSuccess = false;
  double _matchPercentage = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        debugPrint("No cameras available");
        return;
      }

      // Find the front-facing camera
      final frontCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint("Camera initialization error: $e");
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  // Runs face recognition algorithms (takes picture and sends it to verification service)
  Future<void> _verifyFace() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kamera henüz hazır değil.")),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    String? tempImagePath;
    try {
      // 1. Take a selfie photo using Flutter Camera plugin
      final XFile photoFile = await _cameraController!.takePicture();
      tempImagePath = photoFile.path;

      // 2. Fetch FaceVerificationService via Riverpod
      final faceVerificationService = ref.read(faceVerificationServiceProvider);

      // 3. Request face verification comparison
      final result = await faceVerificationService.verifyFace(
        cardPhotoBytes: widget.nfcPhotoBytes,
        cameraImagePath: tempImagePath,
      );

      if (mounted) {
        setState(() {
          _isVerifying = false;
          _verificationComplete = true;
          _verificationSuccess = result.success;
          _matchPercentage = result.confidence;
        });
      }
    } catch (e) {
      debugPrint("Verification Error: $e");
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _verificationComplete = true;
          _verificationSuccess = false;
          _matchPercentage = 0.0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Eşleşme doğrulanırken hata oluştu: ${e.toString()}")),
        );
      }
    } finally {
      // 4. Delete the temporary selfie photo from disk to keep cache clean
      if (tempImagePath != null) {
        try {
          final file = File(tempImagePath);
          if (await file.exists()) {
            await file.delete();
            debugPrint("Temporary selfie photo deleted successfully.");
          }
        } catch (e) {
          debugPrint("Failed to delete temporary selfie photo: $e");
        }
      }
    }
  }

  void _resetVerification() {
    setState(() {
      _verificationComplete = false;
      _verificationSuccess = false;
      _matchPercentage = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Yüz Tanıma Eşleşmesi"),
      ),
      body: SafeArea(
        child: _verificationComplete 
            ? _buildResultScreen() 
            : _buildScanningScreen(),
      ),
    );
  }

  // Scanning state view showing live camera and circular guide
  Widget _buildScanningScreen() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera Preview Background
        _isCameraInitialized
            ? CameraPreview(_cameraController!)
            : Container(
                color: Colors.black,
                child: const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryGlow),
                ),
              ),

        // Semi-transparent Overlay to guide face alignment
        _buildCameraOverlay(),

        // Floating thumbnail reference photo of TCKK
        Positioned(
          top: 16,
          right: 16,
          child: _buildReferencePhotoThumbnail(),
        ),

        // Instructions and trigger button
        Positioned(
          bottom: 24,
          left: 24,
          right: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(
                  _isVerifying 
                      ? "Biyometrik veriler analiz ediliyor. Lütfen kıpırdamayın..." 
                      : "Yüzünüzü kılavuz çizgiler içerisine hizalayın ve doğrulamayı başlatın.",
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              
              ElevatedButton(
                onPressed: _isVerifying ? null : _verifyFace,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: AppTheme.primaryColor,
                  disabledBackgroundColor: AppTheme.surfaceColor,
                ),
                child: _isVerifying 
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_front_rounded, size: 24),
                          SizedBox(width: 12),
                          Text(
                            "TARAMAYI BAŞLAT",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Draw face contour guidelines
  Widget _buildCameraOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double height = constraints.maxHeight;
        
        return Stack(
          children: [
            // Darkened borders outside the face frame area
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.65),
                BlendMode.srcOut,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: width * 0.7,
                      height: height * 0.45,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.all(
                          Radius.elliptical(width * 0.35, height * 0.225),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Glowing border of the face oval frame
            Align(
              alignment: Alignment.center,
              child: Container(
                width: width * 0.7,
                height: height * 0.45,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _isVerifying ? AppTheme.warningColor : AppTheme.primaryGlow, 
                    width: 2.5,
                  ),
                  borderRadius: BorderRadius.all(
                    Radius.elliptical(width * 0.35, height * 0.225),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Reference cardholder photo extracted from TCKK
  Widget _buildReferencePhotoThumbnail() {
    return Container(
      width: 76,
      height: 95,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primaryGlow, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 10)
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              widget.nfcPhotoBytes,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black54,
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: const Text(
                "ÇİP RESMİ",
                style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          )
        ],
      ),
    );
  }

  // Face Matching results screen
  Widget _buildResultScreen() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          
          // Result Icon
          Center(
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _verificationSuccess 
                    ? AppTheme.successColor.withOpacity(0.1) 
                    : AppTheme.errorColor.withOpacity(0.1),
                border: Border.all(
                  color: _verificationSuccess ? AppTheme.successColor : AppTheme.errorColor, 
                  width: 3,
                ),
              ),
              child: Icon(
                _verificationSuccess 
                    ? Icons.verified_user_rounded 
                    : Icons.gpp_bad_rounded,
                color: _verificationSuccess ? AppTheme.successColor : AppTheme.errorColor,
                size: 72,
              ),
            ),
          ),
          
          const SizedBox(height: 36),

          Text(
            _verificationSuccess ? "Doğrulama Başarılı!" : "Eşleşme Başarısız",
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 12),

          Text(
            _verificationSuccess
                ? "Selfie kameranızdaki görüntü ile kimlik çipindeki fotoğraf eşleşti.\nEşleşme Skoru: %$_matchPercentage"
                : "Görüntüler arasında yeterli benzerlik oranı bulunamadı. Lütfen daha iyi aydınlatılmış bir alanda tekrar deneyin.",
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          
          const Spacer(flex: 2),

          if (_verificationSuccess) ...[
            ElevatedButton(
              onPressed: () {
                // Clear state and go back to welcome/CAN screen
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text("ANA SAYFAYA DÖN"),
            ),
          ] else ...[
            ElevatedButton(
              onPressed: _resetVerification,
              child: const Text("YENİDEN TARAMA YAP"),
            ),
          ],
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
