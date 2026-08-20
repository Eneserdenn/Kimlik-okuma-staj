import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/nfc_service.dart';
import '../controllers/nfc_state.dart';
import '../../../face_verification/presentation/views/face_verification_view.dart';

class NfcResultView extends StatelessWidget {
  final NfcCardData cardData;
  final Uint8List photoBytes;

  const NfcResultView({
    super.key,
    required this.cardData,
    required this.photoBytes,
  });

  /// Decodes photo bytes.
  /// If it is our mock 100-byte list, it decodes the mock profile JPEG base64 string
  /// to display a realistic photo on the screen.
  Uint8List _getRenderablePhoto() {
    if (photoBytes.length == 100) {
      return base64Decode(NfcService.mockProfileBase64);
    }
    return photoBytes;
  }

  @override
  Widget build(BuildContext context) {
    final imageBytes = _getRenderablePhoto();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Kimlik Bilgileri"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              // Go back to input screen
              Navigator.pop(context);
            },
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Profile Photo Container
                    Center(
                      child: _buildPhotoContainer(imageBytes),
                    ),
                    const SizedBox(height: 24),
                    
                    // Cardholder Name header
                    Text(
                      "${cardData.name} ${cardData.surname}",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "T.C. Kimlik No: ${cardData.tcNo}",
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppTheme.primaryGlow,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
 
                    // Information Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                        child: Column(
                          children: [
                            _buildInfoRow(Icons.cake_rounded, "Doğum Tarihi", cardData.dateOfBirth),
                            const Divider(color: Color(0xFF334155), height: 24),
                            _buildInfoRow(Icons.wc_rounded, "Cinsiyet", cardData.gender == 'E' ? "Erkek" : "Kadın"),
                            const Divider(color: Color(0xFF334155), height: 24),
                            _buildInfoRow(Icons.badge_rounded, "Doküman No", cardData.documentNumber),
                            const Divider(color: Color(0xFF334155), height: 24),
                            _buildInfoRow(Icons.date_range_rounded, "Son Geçerlilik", cardData.dateOfExpiry),
                            const Divider(color: Color(0xFF334155), height: 24),
                            _buildInfoRow(Icons.fingerprint_rounded, "Çip Seri No", cardData.cardSerialNumber),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // CTA Button to navigate to teammate's Face Verification View
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FaceVerificationView(
                        nfcPhotoBytes: imageBytes,
                        cardholderName: "${cardData.name} ${cardData.surname}",
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.face_unlock_rounded, size: 24),
                    SizedBox(width: 12),
                    Text(
                      "YÜZ TANIMA DOĞRULAMASINA GEÇ",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Visual container for biometric cardholder picture
  Widget _buildPhotoContainer(Uint8List imageBytes) {
    return Container(
      width: 140,
      height: 175,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryGlow, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGlow.withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.memory(
          imageBytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback if image bytes are JP2 (JPEG2000) and cannot be parsed natively in Flutter
            return Container(
              color: AppTheme.surfaceColor,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.portrait_rounded,
                    color: AppTheme.primaryGlow,
                    size: 56,
                  ),
                  SizedBox(height: 8),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      "JP2 Formatı\n(Çözümlenecek)",
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Double-column info item
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.textSecondary, size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
