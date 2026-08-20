import 'dart:typed_data';
import '../models/face_verification_result.dart';
import 'face_verification_service.dart';

class MockFaceVerificationService implements FaceVerificationService {
  @override
  Future<FaceVerificationResult> verifyFace({
    required Uint8List cardPhotoBytes,
    required String cameraImagePath,
  }) async {
    // Simulate model loading and network/processing delay (3 seconds)
    await Future.delayed(const Duration(seconds: 3));

    // For testing: if the camera image path contains "fail", simulate match failure.
    // Otherwise, simulate matching success.
    if (cameraImagePath.contains("fail")) {
      return FaceVerificationResult.mockFailure();
    }
    
    return FaceVerificationResult.mockSuccess();
  }
}
