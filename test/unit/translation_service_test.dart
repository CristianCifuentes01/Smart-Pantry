import 'package:flutter_test/flutter_test.dart';
import 'package:smart_pantry/data/services/translation_service.dart';

void main() {
  group('TranslationService Tests', () {
    late TranslationService translationService;

    setUp(() {
      translationService = TranslationService();
    });

    test('Short text translation (English to Spanish)', () async {
      final result = await translationService.translate('Hello world', from: 'en', to: 'es');
      expect(result.toLowerCase(), contains('hola'));
    });

    test('Short text translation (Spanish to English)', () async {
      final result = await translationService.translate('pollo', from: 'es', to: 'en');
      expect(result.toLowerCase(), contains('chicken'));
    });

    test('HTML Entities decoding', () async {
      // Test the private method indirectly or verify translation doesn't leak raw HTML entities
      final result = await translationService.translate("It's a beautiful day", from: 'en', to: 'es');
      expect(result, isNot(contains('&#39;')));
      expect(result, isNot(contains('&quot;')));
    });

    test('Empty text handling', () async {
      final result = await translationService.translate('', from: 'en', to: 'es');
      expect(result, equals(''));
    });
  });
}
