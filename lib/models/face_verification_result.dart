class FaceVerificationResult {
  final bool success;
  final double confidence;
  final String message;

  FaceVerificationResult({
    required this.success,
    required this.confidence,
    required this.message,
  });

  factory FaceVerificationResult.mockSuccess() {
    return FaceVerificationResult(
      success: true,
      confidence: 98.4,
      message: "Yüz eşleşmesi başarıyla doğrulandı.",
    );
  }

  factory FaceVerificationResult.mockFailure() {
    return FaceVerificationResult(
      success: false,
      confidence: 34.2,
      message: "Yüz eşleşmesi başarısız. Lütfen tekrar deneyin.",
    );
  }
}
