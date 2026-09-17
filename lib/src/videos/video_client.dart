//ignore_for_file: deprecated_member_use_from_same_package
import '../channels/channel_id.dart';
import '../common/common.dart';
import '../extensions/helpers_extension.dart';
import '../reverse_engineering/challenges/js_challenge.dart';
import '../reverse_engineering/clients/related_videos_client.dart';
import '../reverse_engineering/pages/watch_page.dart';
import '../reverse_engineering/youtube_http_client.dart';
import 'videos.dart';

/// Queries related to YouTube videos.
class VideoClient {
  final YoutubeHttpClient _httpClient;

  /// Queries related to media streams of YouTube videos.
  final StreamClient streamsClient;

  /// Queries related to media streams of YouTube videos.
  /// Alias of [streamsClient].
  StreamClient get streams => streamsClient;

  /// Queries related to closed captions of YouTube videos.
  final ClosedCaptionClient closedCaptions;

  /// Queries related to a YouTube video comments.
  @Deprecated('This interface will not be supported anymore.')
  final CommentsClient commentsClient;

  /// Queries related to a YouTube video comments.
  /// Alias of [commentsClient].
  @Deprecated('This interface will not be supported anymore.')
  CommentsClient get comments => commentsClient;

  /// Initializes an instance of [VideoClient].
  VideoClient(this._httpClient, {BaseJSChallengeSolver? jsSolver})
      : streamsClient = StreamClient(_httpClient, jsSolver: jsSolver),
        closedCaptions = ClosedCaptionClient(_httpClient),
        commentsClient = CommentsClient(_httpClient);

  /// Gets the metadata associated with the specified video.
  Future<Video> _getVideoFromWatchPage(VideoId videoId) async {
    final watchPage = await WatchPage.get(_httpClient, videoId.value);
    final playerResponse = watchPage.playerResponse!;

    return Video(
      videoId,
      playerResponse.videoTitle,
      playerResponse.videoAuthor,
      ChannelId(playerResponse.videoChannelId),
      playerResponse.videoUploadDate ??
          watchPage.root
              .querySelector('meta[itemprop=uploadDate]')
              ?.attributes['content']
              .tryParseDateTime(),
      playerResponse.videoUploadDate.toString(),
      playerResponse.videoPublishDate ??
          watchPage.root
              .querySelector('meta[itemprop=datePublished]')
              ?.attributes['content']
              .tryParseDateTime(),
      playerResponse.videoDescription,
      playerResponse.videoDuration,
      ThumbnailSet(videoId.value),
      playerResponse.videoKeywords,
      Engagement(
        playerResponse.videoViewCount,
        watchPage.videoLikeCount,
        watchPage.videoDislikeCount,
      ),
      playerResponse.isLive,
      watchPage.initialData.getMusicData() ?? [],
      watchPage,
    );
  }

  /// Get a [Video] instance from a [videoId]
  Future<Video> get(dynamic videoId) async =>
      _getVideoFromWatchPage(VideoId.fromString(videoId));

  /// Checks whether the specified video is a currently active live stream.
  ///
  /// Unlike [get], this only parses the watch page's player response and
  /// does not require `ytInitialData` to be extractable from the page.
  /// Some live streams (e.g. long-running 24/7 broadcasts) fail to expose a
  /// parseable `ytInitialData`, which makes [get] throw a
  /// [TransientFailureException] even though the player response itself
  /// (and therefore the live status) was fetched successfully.
  Future<bool> checkIsLive(dynamic videoId) async {
    final watchPage = await WatchPage.get(
      _httpClient,
      VideoId.fromString(videoId).value,
    );
    return watchPage.playerResponse?.isLive ?? false;
  }

  /// Returns a [RelatedVideosList] or null if no related videos were found.
  Future<RelatedVideosList?> getRelatedVideos(Video video) async {
    // Try 3 times before giving up
    for (var i = 0; i < 3; i++) {
      final client = await RelatedVideosClient.get(_httpClient, video);
      if (client != null) {
        final videos = client.relatedVideos().toList();
        if (videos.isNotEmpty) {
          return RelatedVideosList(videos, client, _httpClient);
        }
      }
    }
    return null;
  }
}
