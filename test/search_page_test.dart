import 'package:test/test.dart';
import 'package:youtube_explode_dart/src/reverse_engineering/pages/search_page.dart';
import 'package:youtube_explode_dart/src/search/search_result.dart';

void main() {
  test('parses video view count runs as JSON maps', () {
    final page = SearchPage.parse('''
      <script>
        var ytInitialData = {
          "estimatedResults": "1",
          "contents": {
            "twoColumnSearchResultsRenderer": {
              "primaryContents": {
                "sectionListRenderer": {
                  "contents": [
                    {
                      "itemSectionRenderer": {
                        "contents": [
                          {
                            "videoRenderer": {
                              "videoId": "wrM_wdHm6Qs",
                              "title": {"runs": [{"text": "News video"}]},
                              "ownerText": {
                                "runs": [{
                                  "text": "News channel",
                                  "navigationEndpoint": {
                                    "browseEndpoint": {"browseId": "UCnews"}
                                  }
                                }]
                              },
                              "lengthText": {"simpleText": "1:00"},
                              "viewCountText": {
                                "runs": [
                                  {"text": "1,234 views"},
                                  {"text": "watching"}
                                ]
                              },
                              "thumbnail": {
                                "thumbnails": [{
                                  "url": "https://i.ytimg.com/vi/wrM_wdHm6Qs/default.jpg",
                                  "height": 90,
                                  "width": 120
                                }]
                              }
                            }
                          }
                        ]
                      }
                    }
                  ]
                }
              }
            }
          }
        };
      </script>
    ''', 'ニュース 今日');

    final result = page.searchContent.single as SearchVideo;
    expect(result.id.value, 'wrM_wdHm6Qs');
    expect(result.title, 'News video');
    expect(result.viewCount, 1234);
    expect(result.isLive, isTrue);
    expect(result.thumbnails.single.url.toString(),
        'https://i.ytimg.com/vi/wrM_wdHm6Qs/default.jpg');
  });
}
