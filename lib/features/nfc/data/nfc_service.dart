import 'package:flutter/foundation.dart';
import 'package:dmrtd/dmrtd.dart';
import '../presentation/controllers/nfc_state.dart';

class NfcService {
  NfcProvider? _nfcProvider;
  Passport? _passport;
  bool _isSessionActive = false;

  /// Polls for NFC tag (IsoDep/MRTD) and connects to it using dmrtd's NfcProvider.
  Future<dynamic> connectToCard() async {
    try {
      _nfcProvider = NfcProvider();
      
      // Connects to the card, triggering iOS or Android native NFC system dialog
      await _nfcProvider!.connect(
        iosAlertMessage: "Lütfen TC Kimlik Kartınızı telefonun arkasına yaklaştırın.",
      );

      _passport = Passport(_nfcProvider!);
      _isSessionActive = true;
      return _nfcProvider;
    } catch (e) {
      debugPrint("NFC Connection Error: $e");
      _isSessionActive = false;
      _nfcProvider = null;
      _passport = null;
      rethrow;
    }
  }

  /// Establishes secure channel via PACE protocol using the 6-digit CAN.
  Future<bool> authenticateWithPACE(String can) async {
    if (!_isSessionActive || _passport == null) {
      throw Exception("Aktif bir NFC bağlantısı bulunamadı.");
    }

    try {
      // 1. Read EF.CardAccess to get PACE configuration parameters
      final cardAccess = await _passport!.readEfCardAccess();

      // 2. Derive PACE access key from the 6-digit CAN
      final accessKey = CanKey(can);

      // 3. Start PACE session with the chip
      await _passport!.startSessionPACE(accessKey, cardAccess);
      return true;
    } catch (e) {
      debugPrint("PACE Authentication Error: $e");
      rethrow;
    }
  }

  /// Reads and parses EF.DG1 containing cardholder personal data.
  Future<NfcCardData> readPersonalData() async {
    if (!_isSessionActive || _passport == null) {
      throw Exception("Aktif bir NFC bağlantısı bulunamadı.");
    }

    try {
      // Read DG1 (biodata)
      final dg1 = await _passport!.readEfDG1();
      
      // Parse MRZ inside DG1
      final mrz = dg1.mrz;

      // Map MRZ details to card data
      return NfcCardData(
        tcNo: mrz.optionalData.replaceAll(RegExp(r'\D'), ''), // Extract digits for TC No (stored in optionalData)
        name: mrz.firstName,
        surname: mrz.lastName,
        dateOfBirth: _formatDate(mrz.dateOfBirth),
        dateOfExpiry: _formatDate(mrz.dateOfExpiry),
        gender: mrz.gender,
        documentNumber: mrz.documentNumber,
        cardSerialNumber: mrz.documentNumber, // Turkish ID doc number serves as unique identifier
      );
    } catch (e) {
      debugPrint("Read Personal Data Error: $e");
      throw Exception("Kimlik bilgileri (DG1) okunamadı. Lütfen kartı hareket ettirmeyin.");
    }
  }

  /// Reads EF.DG2 and extracts biometric photo bytes.
  Future<Uint8List> readBiometricPhoto() async {
    if (!_isSessionActive || _passport == null) {
      throw Exception("Aktif bir NFC bağlantısı bulunamadı.");
    }

    try {
      // Read DG2 (Biometric photo)
      final dg2 = await _passport!.readEfDG2();

      // Extract image bytes from DG2 (often JP2/JPEG2000 format)
      final faceImageBytes = dg2.imageData;
      if (faceImageBytes == null || faceImageBytes.isEmpty) {
        throw Exception("Kartın çipinden biyometrik fotoğraf bulunamadı.");
      }

      return faceImageBytes;
    } catch (e) {
      debugPrint("Read Photo Error: $e");
      throw Exception("Biyometrik fotoğraf (DG2) okunamadı. Lütfen kartı hareket ettirmeyin.");
    }
  }

  /// Closes the NFC connection.
  Future<void> closeSession() async {
    if (_isSessionActive) {
      try {
        await _nfcProvider?.disconnect();
      } catch (e) {
        debugPrint("NFC Close Session Error: $e");
      } finally {
        _isSessionActive = false;
        _nfcProvider = null;
        _passport = null;
      }
    }
  }

  // Formatting date: DateTime -> DD.MM.YYYY
  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}";
  }

  /// Base64 string of a sample professional portrait image to display in mock mode.
  /// This is used on emulators so that the face recognition mock screen has a real photo to verify against.
  static String get mockProfileBase64 => 
      "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";
}
