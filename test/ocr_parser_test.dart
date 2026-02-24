import 'package:flutter_test/flutter_test.dart';
import '../lib/engine/ocr_parser.dart';

void main() {
  group('OcrParser dynamic extraction tests', () {
    test('extracts clear numeric values with colons', () {
      final text =
          "Patient results:\nHemoglobin: 14.5 g/dL\nFasting Insulin: 22.1 uIU/mL\nAMH: 1.2";
      final result = OcrParser.analyze(text);

      expect(result['hemoglobin'], 14.5);
      expect(result['fasting_insulin'], 22.1);
      expect(result['amh'], 1.2);
    });

    test('extracts clear numeric values without colons and loose spacing', () {
      final text = "TEST RESULT\nTotal Testosterone 45.3 ng/dL\nDHEAS    312";
      final result = OcrParser.analyze(text);

      expect(result['testosterone'], 45.3);
      expect(result['dheas'], 312.0);
    });

    test('extracts values mixed with garbage text', () {
      final text =
          "ASDQWE FSH level is approx 12.5mIU/mL dsdfg\nESTRADIOL-- 44.1";
      final result = OcrParser.analyze(text);

      expect(result['fsh'], 12.5);
      expect(result['estradiol'], 44.1);
    });

    test('properly handles imaging flags', () {
      final text =
          "Ultrasound shows diffuse echogenic liver consistent with steatosis. No shadowing gallstones seen.";
      final result = OcrParser.analyze(text);

      expect(result['fatty_liver_flag'], 1.0);
      expect(result['gallstone_flag'], 1.0); // "gallstones" should match
      expect(result['kidney_stone_flag'],
          null); // Ensure untouched flags remain null
    });

    test('ignores non-matches completely', () {
      final text = "Random text that has absolutely no medical value 12345.";
      final result = OcrParser.analyze(text);

      expect(result.isEmpty, true);
    });
  });
}
