import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:field_survey_pwa/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Field Survey dashboard renders', (tester) async {
    await tester.pumpWidget(const FieldSurveyApp());
    await tester.pumpAndSettle();
    expect(find.text('Field Survey'), findsWidgets);
    expect(find.text('Survey dashboard'), findsOneWidget);
  });
}
