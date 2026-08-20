import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tckk_nfc_reader/main.dart';
import 'package:tckk_nfc_reader/features/auth/presentation/views/can_input_view.dart';

void main() {
  testWidgets('CanInputView loads test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: TckkNfcApp(),
      ),
    );

    // Verify that the main view is CanInputView
    expect(find.byType(CanInputView), findsOneWidget);
  });
}
