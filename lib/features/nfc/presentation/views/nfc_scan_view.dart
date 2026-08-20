import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../controllers/nfc_state.dart';
import 'nfc_result_view.dart';

class NfcScanView extends ConsumerStatefulWidget {
  final String can;
  final bool isMock;

  const NfcScanView({
    super.key,
    required this.can,
    required this.isMock,
  });

  @override
  ConsumerState<NfcScanView> createState() => _NfcScanViewState();
}

class _NfcScanViewState extends ConsumerState<NfcScanView> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // Set up pulsing animation for NFC scan circle
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start NFC read task
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isMock) {
        ref.read(nfcStateProvider.notifier).startMockScan(widget.can);
      } else {
        ref.read(nfcStateProvider.notifier).startCardScan(widget.can);
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // State change listener
  void _listenToStateChanges(NfcState nfcState) {
    if (nfcState.status == NfcScanStatus.success) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Stop animation
        _pulseController.stop();
        
        // Push replacement to Results View
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => NfcResultView(
              cardData: nfcState.cardData!,
              photoBytes: nfcState.photoBytes!,
            ),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final nfcState = ref.watch(nfcStateProvider);
    _listenToStateChanges(nfcState);

    final status = nfcState.status;
    final isError = status == NfcScanStatus.error;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isMock ? "NFC Simülatörü" : "NFC Taraması"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            // Cancel session
            ref.read(nfcServiceProvider).closeSession();
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              
              // Animated Scanner Indicator
              Center(
                child: isError 
                    ? _buildErrorIcon() 
                    : _buildPulsingScanner(status),
              ),
              
              const SizedBox(height: 48),

              // Status Title Text
              Text(
                _getStatusTitle(status),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12),

              // Status Description Text
              Text(
                isError ? nfcState.errorMessage! : _getStatusDescription(status),
                style: TextStyle(
                  fontSize: 14,
                  color: isError ? AppTheme.errorColor : AppTheme.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              
              // Progress indicator for card reading steps
              if (status == NfcScanStatus.readingDG1 || status == NfcScanStatus.readingDG2) ...[
                const SizedBox(height: 24),
                _buildProgressBar(status),
              ],

              const Spacer(flex: 2),

              // Bottom Cancel/Retry Buttons
              if (isError) ...[
                ElevatedButton(
                  onPressed: () {
                    ref.read(nfcStateProvider.notifier).reset();
                    if (widget.isMock) {
                      ref.read(nfcStateProvider.notifier).startMockScan(widget.can);
                    } else {
                      ref.read(nfcStateProvider.notifier).startCardScan(widget.can);
                    }
                  },
                  child: const Text("TEKRAR DENE"),
                ),
                const SizedBox(height: 12),
              ],
              
              TextButton(
                onPressed: () {
                  ref.read(nfcServiceProvider).closeSession();
                  Navigator.pop(context);
                },
                child: Text(
                  isError ? "VAZGEÇ" : "İŞLEMİ İPTAL ET",
                  style: TextStyle(
                    color: isError ? AppTheme.textSecondary : AppTheme.errorColor.withOpacity(0.8),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // Build the pulsing NFC scanner widget
  Widget _buildPulsingScanner(NfcScanStatus status) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primaryColor.withOpacity(0.05),
          ),
          child: Center(
            // Outer glowing ring
            child: Container(
              width: 140 * _pulseAnimation.value,
              height: 140 * _pulseAnimation.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _getThemeColorForStatus(status).withOpacity(0.3),
                  width: 3,
                ),
              ),
              child: Center(
                // Inner solid circle
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        _getThemeColorForStatus(status),
                        _getThemeColorForStatus(status).withOpacity(0.7)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _getThemeColorForStatus(status).withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: Center(
                    child: _getIconForStatus(status),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Build Error Icon representation
  Widget _buildErrorIcon() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.errorColor.withOpacity(0.1),
        border: Border.all(color: AppTheme.errorColor.withOpacity(0.3), width: 3),
      ),
      child: const Center(
        child: Icon(
          Icons.error_outline_rounded,
          color: AppTheme.errorColor,
          size: 72,
        ),
      ),
    );
  }

  // Small step progress bar
  Widget _buildProgressBar(NfcScanStatus status) {
    final progress = status == NfcScanStatus.readingDG1 ? 0.5 : 0.8;
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGlow.withOpacity(0.4),
                blurRadius: 8,
              )
            ],
          ),
        ),
      ),
    );
  }

  // Status mapping functions
  String _getStatusTitle(NfcScanStatus status) {
    switch (status) {
      case NfcScanStatus.searching:
        return "Kart Aranıyor...";
      case NfcScanStatus.connecting:
        return "Kart Algılandı";
      case NfcScanStatus.authenticating:
        return "Çip Kilidi Açılıyor...";
      case NfcScanStatus.readingDG1:
        return "Veriler Okunuyor...";
      case NfcScanStatus.readingDG2:
        return "Biyometrik Resim Çekiliyor...";
      case NfcScanStatus.success:
        return "Okuma Tamamlandı!";
      case NfcScanStatus.error:
        return "Okuma Hatası";
      case NfcScanStatus.idle:
      default:
        return "Hazırlanıyor...";
    }
  }

  String _getStatusDescription(NfcScanStatus status) {
    switch (status) {
      case NfcScanStatus.searching:
        return "Lütfen T.C. Kimlik Kartınızı telefonun arkasında bulunan NFC alanına dokundurun.";
      case NfcScanStatus.connecting:
        return "NFC bağlantısı sağlandı. Lütfen kartı hareket ettirmeyin...";
      case NfcScanStatus.authenticating:
        return "PACE güvenlik protokolü çalıştırılıyor. CAN şifresi doğrulanıyor...";
      case NfcScanStatus.readingDG1:
        return "Kişisel kimlik verileri (DG1) güvenli kanaldan çekiliyor...";
      case NfcScanStatus.readingDG2:
        return "Biyometrik yüksek çözünürlüklü fotoğraf (DG2) çipten aktarılıyor. Lütfen bağlantıyı kesmeyin...";
      case NfcScanStatus.success:
        return "Tüm veriler başarıyla aktarıldı.";
      case NfcScanStatus.idle:
      default:
        return "NFC modülü başlatılıyor...";
    }
  }

  Color _getThemeColorForStatus(NfcScanStatus status) {
    switch (status) {
      case NfcScanStatus.searching:
        return AppTheme.secondaryColor;
      case NfcScanStatus.connecting:
      case NfcScanStatus.authenticating:
        return AppTheme.warningColor;
      case NfcScanStatus.readingDG1:
      case NfcScanStatus.readingDG2:
        return AppTheme.primaryColor;
      case NfcScanStatus.success:
        return AppTheme.successColor;
      case NfcScanStatus.error:
        return AppTheme.errorColor;
      default:
        return AppTheme.textMuted;
    }
  }

  Widget _getIconForStatus(NfcScanStatus status) {
    switch (status) {
      case NfcScanStatus.searching:
        return const Icon(Icons.nfc_rounded, color: Colors.white, size: 48);
      case NfcScanStatus.connecting:
        return const Icon(Icons.contactless_rounded, color: Colors.white, size: 48);
      case NfcScanStatus.authenticating:
        return const Icon(Icons.vpn_key_rounded, color: Colors.white, size: 48);
      case NfcScanStatus.readingDG1:
        return const Icon(Icons.badge_rounded, color: Colors.white, size: 48);
      case NfcScanStatus.readingDG2:
        return const Icon(Icons.portrait_rounded, color: Colors.white, size: 48);
      case NfcScanStatus.success:
        return const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 48);
      default:
        return const Icon(Icons.nfc_rounded, color: Colors.white, size: 48);
    }
  }
}
