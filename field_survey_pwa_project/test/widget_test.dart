import 'package:flutter_test/flutter_test.dart';
import 'package:field_survey_pwa/main.dart';

void main() {
  test('Survey model serializes API payload', () {
    const survey = Survey(
      location: 'District 1',
      surveyor: 'Student',
      date: '2026-10-14',
      status: 'Planned',
      notes: 'Test',
    );
    expect(survey.toJson()['location'], 'District 1');
    expect(survey.toJson()['date'], '2026-10-14');
  });
}
