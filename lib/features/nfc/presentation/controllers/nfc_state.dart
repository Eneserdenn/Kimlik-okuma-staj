import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/nfc_service.dart';

enum NfcScanStatus {
  idle,
  searching,
  connecting,
  authenticating,
  readingDG1,
  readingDG2,
  success,
  error
}

class NfcCardData {
  final String tcNo;
  final String name;
  final String surname;
  final String dateOfBirth;
  final String dateOfExpiry;
  final String gender;
  final String documentNumber;
  final String cardSerialNumber;

  NfcCardData({
    required this.tcNo,
    required this.name,
    required this.surname,
    required this.dateOfBirth,
    required this.dateOfExpiry,
    required this.gender,
    required this.documentNumber,
    required this.cardSerialNumber,
  });

  factory NfcCardData.mock() {
    return NfcCardData(
      tcNo: "12345678901",
      name: "ENES",
      surname: "ERDEN",
      dateOfBirth: "15.08.2002",
      dateOfExpiry: "14.08.2032",
      gender: "E",
      documentNumber: "A12B34567",
      cardSerialNumber: "TR-EID-98765432",
    );
  }
}

class NfcState {
  final NfcScanStatus status;
  final NfcCardData? cardData;
  final Uint8List? photoBytes;
  final String? errorMessage;

  NfcState({
    required this.status,
    this.cardData,
    this.photoBytes,
    this.errorMessage,
  });

  factory NfcState.initial() {
    return NfcState(status: NfcScanStatus.idle);
  }

  NfcState copyWith({
    NfcScanStatus? status,
    NfcCardData? cardData,
    Uint8List? photoBytes,
    String? errorMessage,
  }) {
    return NfcState(
      status: status ?? this.status,
      cardData: cardData ?? this.cardData,
      photoBytes: photoBytes ?? this.photoBytes,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class NfcNotifier extends StateNotifier<NfcState> {
  final NfcService _nfcService;

  NfcNotifier(this._nfcService) : super(NfcState.initial());

  void reset() {
    state = NfcState.initial();
  }

  /// Run physical NFC card read.
  Future<void> startCardScan(String can) async {
    if (can.length != 6) {
      state = NfcState(
        status: NfcScanStatus.error,
        errorMessage: "Geçersiz CAN numarası. Lütfen 6 haneli CAN numarasını kontrol edin.",
      );
      return;
    }

    state = NfcState(status: NfcScanStatus.searching);

    try {
      // Step 1: Wait for card detection and connect
      state = state.copyWith(status: NfcScanStatus.connecting);
      final tag = await _nfcService.connectToCard();
      if (tag == null) {
        throw Exception("Kart algılanamadı. Lütfen NFC alanında tutun.");
      }

      // Step 2: Perform PACE Authentication with CAN
      state = state.copyWith(status: NfcScanStatus.authenticating);
      final sessionEstablished = await _nfcService.authenticateWithPACE(can);
      if (!sessionEstablished) {
        throw Exception("NFC Çip şifre doğrulaması (PACE) başarısız oldu. CAN kodunu kontrol edin.");
      }

      // Step 3: Read DG1 (Personal Data)
      state = state.copyWith(status: NfcScanStatus.readingDG1);
      final cardData = await _nfcService.readPersonalData();

      // Step 4: Read DG2 (Photo)
      state = state.copyWith(status: NfcScanStatus.readingDG2);
      final photo = await _nfcService.readBiometricPhoto();

      // Finish with success
      state = NfcState(
        status: NfcScanStatus.success,
        cardData: cardData,
        photoBytes: photo,
      );
    } catch (e) {
      state = NfcState(
        status: NfcScanStatus.error,
        errorMessage: e.toString().replaceAll("Exception: ", ""),
      );
    } finally {
      await _nfcService.closeSession();
    }
  }

  /// Runs a step-by-step simulated scan. Perfect for emulator testing!
  Future<void> startMockScan(String can) async {
    if (can.length != 6) {
      state = NfcState(
        status: NfcScanStatus.error,
        errorMessage: "Geçersiz CAN numarası. Lütfen 6 haneli CAN numarasını kontrol edin.",
      );
      return;
    }

    state = NfcState(status: NfcScanStatus.searching);
    await Future.delayed(const Duration(milliseconds: 1500));

    state = state.copyWith(status: NfcScanStatus.connecting);
    await Future.delayed(const Duration(milliseconds: 1200));

    state = state.copyWith(status: NfcScanStatus.authenticating);
    await Future.delayed(const Duration(milliseconds: 1500));

    state = state.copyWith(status: NfcScanStatus.readingDG1);
    await Future.delayed(const Duration(milliseconds: 1200));

    state = state.copyWith(status: NfcScanStatus.readingDG2);
    await Future.delayed(const Duration(milliseconds: 1800));

    // Create a mock photo of colored face icon or standard placeholder byte data
    // We will generate fake 100 bytes just to simulate having image bytes.
    final mockBytes = Uint8List.fromList(List.generate(100, (index) => index));

    state = NfcState(
      status: NfcScanStatus.success,
      cardData: NfcCardData.mock(),
      photoBytes: mockBytes,
    );
  }
}

// Service provider
final nfcServiceProvider = Provider<NfcService>((ref) => NfcService());

// State provider
final nfcStateProvider = StateNotifierProvider<NfcNotifier, NfcState>((ref) {
  final service = ref.read(nfcServiceProvider);
  return NfcNotifier(service);
});
