import 'dart:convert';

import 'package:test/test.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:youtube_explode_dart/src/reverse_engineering/pages/channel_upload_page.dart';

import 'skip_gh.dart';

void main() {
  YoutubeExplode? yt;
  setUpAll(() {
    yt = YoutubeExplode();
  });

  tearDownAll(() {
    yt?.close();
  });

  test('ChannelVideo live status defaults to false', () {
    final video = ChannelVideo(
      VideoId('dQw4w9WgXcQ'),
      'title',
      Duration.zero,
      'https://example.com/thumb.jpg',
      '',
      0,
    );

    expect(video.isLive, isFalse);
  });

  test('parses the Live badge from the lockup bottom overlay', () {
    final raw = '<script>var ytInitialData = ${jsonEncode({
          'contents': {
            'twoColumnBrowseResultsRenderer': {
              'tabs': [
                {
                  'tabRenderer': {
                    'selected': true,
                    'content': {
                      'richGridRenderer': {
                        'contents': [
                          for (final entry in [
                            [
                              'dQw4w9WgXcQ',
                              'THUMBNAIL_OVERLAY_BADGE_STYLE_LIVE'
                            ],
                            [
                              'M7lc1UVf-VE',
                              'THUMBNAIL_OVERLAY_BADGE_STYLE_DEFAULT'
                            ],
                          ])
                            {
                              'richItemRenderer': {
                                'content': {
                                  'lockupViewModel': {
                                    'contentType': 'LOCKUP_CONTENT_TYPE_VIDEO',
                                    'rendererContext': {
                                      'commandContext': {
                                        'onTap': {
                                          'innertubeCommand': {
                                            'watchEndpoint': {
                                              'videoId': entry[0]
                                            },
                                          },
                                        },
                                      },
                                    },
                                    'metadata': {
                                      'lockupMetadataViewModel': {
                                        'title': {'content': entry[0]},
                                      },
                                    },
                                    'contentImage': {
                                      'thumbnailViewModel': {
                                        'overlays': [
                                          {
                                            'thumbnailBottomOverlayViewModel': {
                                              'badges': [
                                                {
                                                  'thumbnailBadgeViewModel': {
                                                    'badgeStyle': entry[1],
                                                  },
                                                },
                                              ],
                                            },
                                          },
                                        ],
                                      },
                                    },
                                  },
                                },
                              },
                            },
                        ],
                      },
                    },
                  },
                },
              ],
            },
          },
        })};</script>';

    final page = ChannelUploadPage.parse(raw, 'channel-id', VideoType.live);

    expect(page.uploads.map((video) => video.isLive), [true, false]);
  });

  test('parses duration, upload date and views from a lockup item', () {
    Map<String, dynamic> lockup(
      String id,
      List<List<String>> metadataRows, {
      Map<String, String> labels = const {},
      List<Map<String, dynamic>> badges = const [],
    }) =>
        {
          'richItemRenderer': {
            'content': {
              'lockupViewModel': {
                'contentType': 'LOCKUP_CONTENT_TYPE_VIDEO',
                'rendererContext': {
                  'commandContext': {
                    'onTap': {
                      'innertubeCommand': {
                        'watchEndpoint': {'videoId': id},
                      },
                    },
                  },
                },
                'metadata': {
                  'lockupMetadataViewModel': {
                    'title': {'content': id},
                    'metadata': {
                      'contentMetadataViewModel': {
                        'metadataRows': [
                          for (final row in metadataRows)
                            {
                              'metadataParts': [
                                for (final text in row)
                                  {
                                    'text': {'content': text},
                                    if (labels[text] case final label?)
                                      'accessibilityLabel': label,
                                    if (labels[text]?.contains('view') ?? false)
                                      'leadingIcon': {
                                        'name': 'PLAY_ARROW_OUTLINED',
                                      },
                                  },
                              ],
                            },
                        ],
                      },
                    },
                  },
                },
                'contentImage': {
                  'thumbnailViewModel': {
                    'overlays': [
                      {
                        'thumbnailBottomOverlayViewModel': {'badges': badges},
                      },
                    ],
                  },
                },
              },
            },
          },
        };

    Map<String, dynamic> badge(String text, [String? style]) => {
          'thumbnailBadgeViewModel': {
            'text': text,
            if (style != null) 'badgeStyle': style,
          },
        };

    final raw = '<script>var ytInitialData = ${jsonEncode({
          'contents': {
            'twoColumnBrowseResultsRenderer': {
              'tabs': [
                {
                  'tabRenderer': {
                    'selected': true,
                    'content': {
                      'richGridRenderer': {
                        'contents': [
                          lockup(
                            'dQw4w9WgXcQ',
                            [
                              ['123 views', '5y ago'],
                            ],
                            badges: [badge('1:04:51')],
                          ),
                          // Collaboration videos prepend a channel list row.
                          lockup(
                            'M7lc1UVf-VE',
                            [
                              ['Channel A and 2 more'],
                              ['456 views', 'Streamed 3w ago'],
                            ],
                            badges: [
                              badge(
                                'LIVE',
                                'THUMBNAIL_OVERLAY_BADGE_STYLE_LIVE',
                              ),
                              badge('2:35'),
                            ],
                          ),
                          lockup('9bZkp7q19f0', [
                            ['No info'],
                          ]),
                          // Real responses abbreviate the visible text and
                          // only the accessibility label says "views".
                          lockup(
                            'abbrev00001',
                            [
                              ['388K', '11h ago'],
                            ],
                            labels: {'388K': '388 thousand views'},
                          ),
                          lockup(
                            'abbrev00002',
                            [
                              ['1.4M', '3d ago'],
                            ],
                            labels: {'1.4M': '1.4 million views'},
                          ),
                          lockup(
                            'abbrev00003',
                            [
                              ['1,234 views', '2d ago'],
                            ],
                          ),
                        ],
                      },
                    },
                  },
                },
              ],
            },
          },
        })};</script>';

    final uploads =
        ChannelUploadPage.parse(raw, 'channel-id', VideoType.normal).uploads;

    expect(uploads.map((video) => video.videoDuration), [
      const Duration(hours: 1, minutes: 4, seconds: 51),
      const Duration(minutes: 2, seconds: 35),
      Duration.zero,
      Duration.zero,
      Duration.zero,
      Duration.zero,
    ]);
    expect(uploads.map((video) => video.videoUploadDate), [
      '5y ago',
      'Streamed 3w ago',
      '',
      '11h ago',
      '3d ago',
      '2d ago',
    ]);
    expect(uploads.map((video) => video.videoViews),
        [123, 456, 0, 388000, 1400000, 1234]);
  });

  test('propagates the current ABC News Live badge through getUploadsFromPage',
      () async {
    final videos = await yt!.channels.getUploadsFromPage(
      'UCBi2mrWuNuyYy4gbM6fU18Q',
      videoType: VideoType.live,
    );
    final live = videos.firstWhere(
      (video) => video.title.contains('ABC News Live - 24/7'),
    );

    expect(live.isLive, isTrue);
  }, skip: skipGH);

  test('Get metadata of a channel', () async {
    const channelUrl =
        'https://www.youtube.com/channel/UCEnBXANsKmyj2r9xVyKoDiQ';
    final channel = await yt!.channels.get(ChannelId(channelUrl));
    expect(channel.url, channelUrl);
    expect(channel.title, 'Tyrrrz');
    expect(channel.logoUrl, isNotEmpty);
    expect(channel.logoUrl, isNot(equalsIgnoringWhitespace('')));

    // TODO: Investigate why sometimes the subscriber count is null
    if (channel.subscribersCount != null) {
      expect(channel.subscribersCount, greaterThanOrEqualTo(190));
    }
  });

  group('Get metadata of any channel', () {
    for (final val in {
      'UCqKbtOLx4NCBh5KKMSmbX0g',
      'UCJ6td3C9QlPO9O_J5dF4ZzA',
      'UCiGm_E4ZwYSHV3bcW1pnSeQ',
    }) {
      test('Channel - $val', () async {
        final channelId = ChannelId(val);
        final channel = await yt!.channels.get(channelId);
        expect(channel.id, channelId);
      });
    }
  });

  test('Get metadata of a channel by username', () async {
    final channel = await yt!.channels.getByUsername(Username('TheTyrrr'));
    expect(channel.id.value, 'UCEnBXANsKmyj2r9xVyKoDiQ');
  });

  test('Get metadata of a channel by handle', () async {
    final channel = await yt!.channels.getByHandle(ChannelHandle('@Hexer10'));
    expect(channel.id.value, 'UCqKbtOLx4NCBh5KKMSmbX0g');
  });

  test('Get metadata of a channel by a video', () async {
    final channel = await yt!.channels.getByVideo(VideoId('TW_yxPcodhk'));
    expect(channel.id.value, 'UCqKbtOLx4NCBh5KKMSmbX0g');
  }, skip: skipGH);

  test('Get the videos of a youtube channel', () async {
    final videos = await yt!.channels
        .getUploads(
          ChannelId(
            'https://www.youtube.com/channel/UCqKbtOLx4NCBh5KKMSmbX0g',
          ),
        )
        .toList();
    expect(videos.length, greaterThanOrEqualTo(6));
  });

  group('Get the videos of any youtube channel', () {
    for (final val in {
      'UCqKbtOLx4NCBh5KKMSmbX0g',
      'UCJ6td3C9QlPO9O_J5dF4ZzA',
      'UCiGm_E4ZwYSHV3bcW1pnSeQ',
    }) {
      test('Channel - $val', () async {
        final videos = await yt!.channels.getUploads(ChannelId(val)).toList();
        expect(videos, isNotEmpty);
      });
    }
  });

  test('Get videos of a youtube channel from the uploads page', () async {
    final videos =
        await yt!.channels.getUploadsFromPage('UC6biysICWOJ-C3P4Tyeggzg');
    expect(videos, isNotEmpty);
    // `lockupViewModel`形式のレスポンスではtitle/uploadDateが
    // metadata/lockupMetadataViewModel配下にネストされているため、
    // 誤ったJSONパスを参照すると空文字のまま返ってしまう回帰を防ぐ。
    expect(videos.first.title, isNotEmpty);
    expect(videos.first.uploadDateRaw, isNotEmpty);
  });

  test('Get next page youtube channel uploads page', () async {
    final videos =
        await yt!.channels.getUploadsFromPage('UC6biysICWOJ-C3P4Tyeggzg');
    final nextPage = await videos.nextPage();
    expect(nextPage!.length, greaterThanOrEqualTo(20));
  });

  test('Get shorts of a youtube channel from the uploads page', () async {
    final shorts = await yt!.channels.getUploadsFromPage(
        'UCMawD8L365TRdcqhQiTDLKA',
        videoType: VideoType.shorts);
    expect(shorts, isNotEmpty);
  });

  test(
    'Get live (Live tab) videos of a youtube channel from the uploads page',
    () async {
      // tv-youtube-player#110: this channel has no "Videos" tab at all
      // (only Home/Live/Posts) and requesting VideoType.normal always fell
      // back to the Home tab's shelfRenderer, which channel_upload_page.dart
      // cannot parse (FatalFailureException). VideoType.live requests
      // `/streams`, which YouTube resolves to the actual "Live" tab.
      final streams = await yt!.channels.getUploadsFromPage(
          'UCuaAmWq07l6Rtz7ZhzHlHSw',
          videoType: VideoType.live);
      expect(streams, isNotEmpty);
      expect(streams.first.title, isNotEmpty);
      expect(streams.first.uploadDateRaw, isNotEmpty);
      final liveVideos = streams.where((video) => video.isLive).toList();
      if (liveVideos.isNotEmpty) {
        expect(liveVideos.every((video) => video.isLive), isTrue);
      }
    },
  );
}
