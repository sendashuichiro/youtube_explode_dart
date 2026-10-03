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
        expect(DateTime.now().difference(result!).inHours,
            greaterThanOrEqualTo(3));
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
        expect(
            DateTime.now().difference(result!).inDays, greaterThanOrEqualTo(2));
      },
    );

    test('parses the compact format without a space ("5y ago", "3mo ago")', () {
      final cases = {
        '30s ago': const Duration(seconds: 30),
        '10m ago': const Duration(minutes: 10),
        '20h ago': const Duration(hours: 20),
        '2d ago': const Duration(days: 2),
        '3w ago': const Duration(days: 21),
        '11mo ago': const Duration(days: 330),
        '5y ago': const Duration(days: 365 * 5),
        'Streamed 1y ago': const Duration(days: 365),
      };
      cases.forEach((label, expected) {
        final result = label.toDateTime();
        expect(result, isNotNull, reason: label);
        final diff = DateTime.now().difference(result!);
        expect(diff - expected, lessThan(const Duration(seconds: 5)),
            reason: label);
        expect(diff, greaterThanOrEqualTo(expected), reason: label);
      });
    });

    test('returns null instead of throwing for unrecognized short labels', () {
      expect('Streamed live'.toDateTime(), isNull);
      expect('Streamed'.toDateTime(), isNull);
      expect('5x ago'.toDateTime(), isNull);
    });

    test('returns null instead of throwing for an unknown unit', () {
      expect('5 fortnights ago'.toDateTime(), isNull);
      expect('Streamed 2 eons ago'.toDateTime(), isNull);
    });

    test('returns null for null input', () {
      expect((null as String?).toDateTime(), isNull);
    });
  });
}
