import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../nfc/presentation/controllers/nfc_state.dart';
import '../../../nfc/presentation/views/nfc_scan_view.dart';

class CanInputView extends ConsumerStatefulWidget {
  const CanInputView({super.key});

  @override
  ConsumerState<CanInputView> createState() => _CanInputViewState();
}

class _CanInputViewState extends ConsumerState<CanInputView> {
  final TextEditingController _canController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _canController.dispose();
    super.dispose();
  }

  void _startScan(bool isMock) {
    if (_formKey.currentState!.validate()) {
      // Reset state first
      ref.read(nfcStateProvider.notifier).reset();
      
      // Navigate to scan screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NfcScanView(
            can: _canController.text,
            isMock: isMock,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("T.C. Kimlik Kartı NFC"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "NFC Doğrulaması",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  "Çip kilidini açmak için kartınızın ön yüzünün sağ alt kısmında bulunan 6 haneli CAN kodunu girmeniz gerekmektedir.",
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),

                // Visual Representation of TCKK ID Card showing CAN location
                _buildCardGuide(),

                const SizedBox(height: 32),

                // CAN Input field
                TextFormField(
                  controller: _canController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8.0,
                    color: AppTheme.primaryGlow,
                  ),
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: "CAN Kodu (6 Hane)",
                    labelStyle: TextStyle(
                      letterSpacing: 0,
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                    floatingLabelAlignment: FloatingLabelAlignment.center,
                    hintText: "000000",
                    counterText: "",
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Lütfen CAN kodunu girin";
                    }
                    if (value.length < 6) {
                      return "CAN kodu 6 haneli olmalıdır";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),

                // Action Buttons
                ElevatedButton(
                  onPressed: () => _startScan(false),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                  ).copyWith(
                    backgroundColor: WidgetStateProperty.resolveWith((states) => null), // allows decoration
                  ),
                  child: Container(
                    width: double.infinity,
                    alignment: Alignment.center,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.nfc_rounded, size: 24, color: Colors.white),
                        SizedBox(width: 12),
                        Text(
                          "KARTI NFC İLE OKU",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Test Mock Simulation Button
                OutlinedButton(
                  onPressed: () => _startScan(true),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.secondaryColor,
                    side: const BorderSide(color: AppTheme.secondaryColor, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.developer_mode_rounded, size: 20),
                      SizedBox(width: 8),
                      Text(
                        "Test Modu (Simülasyon)",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // TCKK Graphic Card Guide
  Widget _buildCardGuide() {
    return Center(
      child: Container(
        width: 320,
        height: 190,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF334155), width: 1.5),
          gradient: const LinearGradient(
            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Stack(
          children: [
            // Top Header: Türkiye Cumhuriyeti Kimlik Kartı
            Positioned(
              top: 14,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "TÜRKİYE CUMHURİYETİ",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Container(
                    width: 20,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: const Center(
                      child: Text(
                        "C*",
                        style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Mock Chip Graphics
            Positioned(
              top: 45,
              left: 20,
              child: Container(
                width: 36,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.amber.withOpacity(0.4), width: 1),
                ),
                child: Center(
                  child: Icon(Icons.memory_rounded, color: Colors.amber.withOpacity(0.6), size: 18),
                ),
              ),
            ),

            // Cardholder Photo Mock Outline
            Positioned(
              bottom: 30,
              left: 20,
              child: Container(
                width: 60,
                height: 75,
                decoration: BoxDecoration(
                  color: const Color(0xFF334155).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF475569), width: 1),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppTheme.textMuted,
                  size: 36,
                ),
              ),
            ),

            // Card Text Details Mocks
            Positioned(
              top: 50,
              left: 95,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMockTextLine(60),
                  const SizedBox(height: 6),
                  _buildMockTextLine(80),
                  const SizedBox(height: 6),
                  _buildMockTextLine(50),
                ],
              ),
            ),

            // CAN Location Indicator & Callout
            Positioned(
              bottom: 22,
              right: 18,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.primaryGlow, width: 1.5),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "CAN Kodu: ",
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      "123456",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryGlow,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Glowing arrow pointing to CAN location
            const Positioned(
              bottom: 38,
              right: 85,
              child: Icon(
                Icons.arrow_right_alt_rounded,
                color: AppTheme.primaryGlow,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMockTextLine(double width) {
    return Container(
      width: width,
      height: 6,
      decoration: BoxDecoration(
        color: const Color(0xFF475569).withOpacity(0.5),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
