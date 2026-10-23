import 'package:flutter_test/flutter_test.dart';
import 'package:movie/app.dart';

void main() {
  testWidgets('Movie Diary app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MovieDiaryApp());
    expect(find.text('Movie Diary'), findsOneWidget);
  });
}
