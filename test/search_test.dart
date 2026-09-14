import 'dart:math';

import 'package:test/test.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

final rnd = Random();
const letters = r'abcdefghilmnopqrstuvzjkwy1234567890!@#$%^&*()_+{}|"?><|~`|';

void main() {
  YoutubeExplode? yt;
  setUp(() {
    yt = YoutubeExplode();
  });

  tearDown(() {
    yt?.close();
  });

  test('Search a youtube video from the search page', () async {
    final videos = await yt!.search.search('undead corporation megalomania');
    expect(videos, isNotEmpty);
  });

  test('Search a query whose results include a runs-based view count',
      () async {
    // Some search results render viewCountText as a `runs` array instead of
    // `simpleText` (and some `channelRenderer`/`videoRenderer` entries rely on
    // it for view/live status). `firstOrNull`/`elementAtSafe`/`first` return a
    // `dynamic` element, so parsing must cast it to a map before calling the
    // `getT` extension - otherwise the call is dispatched dynamically and
    // throws NoSuchMethodError for every result, not just the video that
    // exercises the runs path (tv-youtube-player#68 regressed on this).
    final videos = await yt!.search.search('ニュース 今日');
    expect(videos, isNotEmpty);
  });

  test('Search with no results', () async {
    final videos = await yt!.search.search(
      List.generate(1300, (_) => letters[rnd.nextInt(letters.length)]).join(),
    );
    expect(videos, isEmpty);
    final nextPage = await videos.nextPage();
    expect(nextPage, isNull);
  });

  test('Search only videos', () async {
    final videos =
        await yt!.search.searchContent('Banana', filter: TypeFilters.video);
    expect(videos, everyElement(isA<SearchVideo>()));
  });

  test('Search only channels', () async {
    final channels = await yt!.search
        .searchContent('PewDiePie', filter: TypeFilters.channel);
    expect(channels, everyElement(isA<SearchChannel>()));
  });

  test('Search only playlists', () async {
    final playlists =
        await yt!.search.searchContent('Banana', filter: TypeFilters.playlist);
    expect(playlists, isNotEmpty);
    expect(playlists, everyElement(isA<SearchPlaylist>()));
  });

  test('Search test search filters', () async {
    final featureSearch =
        await yt!.search.searchContent('hello', filter: FeatureFilters.hd);
    expect(featureSearch, isNotEmpty);

    final uploadSearch = await yt!.search
        .searchContent('hello', filter: UploadDateFilter.lastHour);
    expect(uploadSearch, isNotEmpty);

    final durationSearch =
        await yt!.search.searchContent('hello', filter: DurationFilters.long);
    expect(durationSearch, isNotEmpty);

    final sortSearch =
        await yt!.search.searchContent('hello', filter: SortFilters.viewCount);
    expect(sortSearch, isNotEmpty);
  });

  test('Search raw', () async {
    final search = await yt!.search.searchRaw('hello');
    expect(search.content, isNotEmpty);
    expect(search.relatedVideos, isNotEmpty);
    expect(search.estimatedResults, greaterThan(1));
  });

  test('Get youtube search suggestions', () async {
    final suggestions = await yt!.search.getQuerySuggestions('hello');
    expect(suggestions, isNotEmpty);
  });
}
