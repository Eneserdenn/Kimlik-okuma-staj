import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/face_verification_result.dart';
import 'mock_face_verification_service.dart';

abstract class FaceVerificationService {
  /// Compares the camera selfie against the biometric card photo bytes.
  Future<FaceVerificationResult> verifyFace({
    required Uint8List cardPhotoBytes,
    required String cameraImagePath,
  });
}

// Provider that registers the active face verification service.
// By default, it returns the Mock service, which can be swapped with
// a native MethodChannel or REST API service tomorrow.
final faceVerificationServiceProvider = Provider<FaceVerificationService>((ref) {
  return MockFaceVerificationService();
});
