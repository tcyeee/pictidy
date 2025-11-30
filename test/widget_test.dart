import 'package:flutter_test/flutter_test.dart';

import 'package:pictidy/main.dart';

void main() {
  testWidgets('App starts correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PicTidyApp());

    // Verify that the app title is present
    expect(find.text('PicTidy - 相册清理工具'), findsOneWidget);
  });
}
