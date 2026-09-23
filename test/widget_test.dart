import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vernacular_pedagogy/main.dart';
import 'package:vernacular_pedagogy/services/app_state.dart';

void main() {
  testWidgets('VernacularPedagogyApp loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const VernacularPedagogyApp(),
      ),
    );

    // Verify main app title elements load
    expect(find.textContaining('Vernacular Pedagogy'), findsWidgets);
  });
}
