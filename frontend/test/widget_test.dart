import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app/app.dart';

void main() {
  testWidgets('Stream downloader app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const StreamDownloaderApp());

    expect(find.text('Descobrir'), findsOneWidget);
    expect(find.text('Biblioteca'), findsOneWidget);
  });
}
