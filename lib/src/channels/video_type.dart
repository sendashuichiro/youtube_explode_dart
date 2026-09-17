import 'package:meta/meta.dart';

/// Video types provided by Youtube
enum VideoType {
  /// Default horizontal video
  normal('videos', 'videoRenderer'),

  /// Youtube shorts video
  shorts('shorts', 'shortsLockupViewModel'),

  /// Channel's "Live" tab: live/upcoming broadcasts and past (ended) live
  /// broadcasts. Items are rendered the same way as [normal] uploads
  /// (`videoRenderer` or `lockupViewModel` with
  /// `contentType: LOCKUP_CONTENT_TYPE_VIDEO`); only the tab/URL differs.
  live('streams', 'videoRenderer');

  final String name;

  @internal
  final String youtubeRenderText;

  const VideoType(this.name, this.youtubeRenderText);
}
