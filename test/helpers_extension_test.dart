import 'package:test/test.dart';
import 'package:youtube_explode_dart/src/extensions/helpers_extension.dart';

void main() {
  group('String?.toDateTime()', () {
    test('parses the plain "{quantity} {unit} ago" format', () {
      final result = '5 years ago'.toDateTime();
      expect(result, isNotNull);
      expect(
        DateTime.now().difference(result!).inDays,
        greaterThan(365 * 4),
      );
    });

    test(
      'parses ended live broadcasts with the trailing "ago" '
      '("Streamed 3 hours ago")',
      () {
        final result = 'Streamed 3 hours ago'.toDateTime();
        expect(result, isNotNull);
        expect(DateTime.now().difference(result!).inHours, greaterThanOrEqualTo(3));
      },
    );

    test(
      // tv-youtube-player: この形式(末尾のagoが無い)がYouTube側の応答に
      // 実際に現れ、以前はint.parse('Streamed')でFormatExceptionを
      // 投げてフィード取得全体を失敗させていた(2026-09-17実機ログで確認)。
      'does not throw for ended live broadcasts without the trailing "ago" '
      '("Streamed 2 days") and still resolves the date',
      () {
        final result = 'Streamed 2 days'.toDateTime();
        expect(result, isNotNull);
        expect(DateTime.now().difference(result!).inDays, greaterThanOrEqualTo(2));
      },
    );

    test('returns null instead of throwing for unrecognized short labels', () {
      expect('Streamed live'.toDateTime(), isNull);
      expect('Streamed'.toDateTime(), isNull);
    });

    test('returns null for null input', () {
      expect((null as String?).toDateTime(), isNull);
    });
  });
}
