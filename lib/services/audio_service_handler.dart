import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

import 'audio_controller.dart';

/// The media notification + lock-screen player for background audio
/// (audio_service), bridged to the app's single audio stream.
///
/// The [AudioController] stays the single source of truth: the handler
/// MIRRORS the controller's state into the media session, and the
/// notification's buttons route back through the controller's own
/// pause/resume/restart — so the in-app controls and the player always
/// agree, whichever side the user acts on.
///
/// Notification lifecycle (audio_service):
///  - playing: the foreground service starts — the media notification and
///    the lock-screen controls appear, and playback continues off-screen.
///  - paused: the service leaves the foreground (androidStopForegroundOnPause)
///    — the notification stays, swipeable, until the user resumes or
///    dismisses it. This includes a playback that ended naturally while the
///    app was backgrounded: the controller parks the finished job as paused.
///  - stopped: the session idles — the service stops and the notification
///    is dismissed. No audio, no player.
///
/// Controls are exactly play/pause + stop: no skip buttons (the app's pages
/// never auto-advance; Next is always user-pressed). The play control
/// covers every state: paused → resume (including the parked-after-end
/// resume); stopped → RESTART the last-played content (a media-button play
/// after a stop must not be a dead button); playing → no-op. The progress
/// bar is driven by the LIVE position/duration the controller publishes
/// (updatePosition + updateTime so the system projects the position between
/// broadcasts).
class FidelisAudioHandler extends BaseAudioHandler {
  FidelisAudioHandler() {
    AudioController.instance.listenable.addListener(_onControllerChanged);
    AudioController.instance.progressListenable.addListener(_onProgressChanged);
    _prepareArtwork();
  }

  /// The notification artwork: the bundled app icon copied to a real file —
  /// MediaItem.artUri supports file/http/content URIs, not Flutter asset
  /// bundles. Null until the copy lands; the notification then shows the
  /// app's icon so the player reads as part of Fidelis.
  Uri? _artUri;

  /// The MediaItem last published — re-added only when its content changes
  /// (the position broadcasts are separate and cheap).
  MediaItem? _lastMediaItem;

  Future<void> _prepareArtwork() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final file = File('${dir.path}/notification_app_icon.png');
      final data = await rootBundle.load('assets/app_icon.png');
      if (!file.existsSync() || file.lengthSync() != data.lengthInBytes) {
        await file.writeAsBytes(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          flush: true,
        );
      }
      _artUri = Uri.file(file.path);
      // Republish so a visible notification picks the artwork up.
      final info = AudioController.instance.listenable.value;
      if (info.state != AudioState.stopped) {
        _broadcast(playing: info.state == AudioState.playing);
      }
    } catch (_) {}
  }

  /// Mirrors the controller's state into the media session.
  void _onControllerChanged() {
    final info = AudioController.instance.listenable.value;
    if (info.state == AudioState.stopped) {
      // Idle the session: audio_service stops the service and the media
      // notification is dismissed.
      playbackState.add(PlaybackState(
        processingState: AudioProcessingState.idle,
        playing: false,
        controls: const [],
      ));
      return;
    }
    _broadcast(playing: info.state == AudioState.playing);
  }

  /// Live position/duration updates: re-broadcast so the system's progress
  /// bar tracks the audio. Skipped while stopped (the session is idle — a
  /// ready-state broadcast would resurrect it).
  void _onProgressChanged() {
    final info = AudioController.instance.listenable.value;
    if (info.state == AudioState.stopped) return;
    _broadcast(playing: info.state == AudioState.playing);
  }

  void _broadcast({required bool playing}) {
    final controller = AudioController.instance;
    final progress = controller.progressListenable.value;
    final item = MediaItem(
      id: controller.currentJobId ?? 'fidelis',
      // The player IS Fidelis; the recited content is the subtitle.
      title: 'Fidelis',
      artist: controller.currentJobTitle ?? 'Fidelis',
      album: 'Fidelis',
      artUri: _artUri,
      duration: progress?.duration,
    );
    final last = _lastMediaItem;
    if (last == null ||
        last.id != item.id ||
        last.artist != item.artist ||
        last.duration != item.duration ||
        last.artUri != item.artUri) {
      mediaItem.add(item);
      _lastMediaItem = item;
    }
    playbackState.add(PlaybackState(
      processingState: AudioProcessingState.ready,
      playing: playing,
      controls: [
        playing ? MediaControl.pause : MediaControl.play,
        MediaControl.stop,
      ],
      androidCompactActionIndices: const [0, 1],
      systemActions: const <MediaAction>{},
      // The live position: the system projects it forward from
      // (updatePosition, updateTime, playing) between broadcasts, so the
      // progress bar displays and moves without per-frame updates.
      updatePosition: progress?.position ?? Duration.zero,
      updateTime: DateTime.now(),
      speed: 1.0,
    ));
  }

  @override
  Future<void> play() async {
    final controller = AudioController.instance;
    if (controller.state == AudioState.paused) {
      // The parked-after-end resume and the ordinary pause resume. The
      // parked resume runs the job loop (pending for the whole playback) —
      // fire-and-forget so the play() response returns promptly.
      unawaited(controller.resume());
    } else if (controller.state == AudioState.stopped) {
      // Nothing is loaded (e.g. a media-button play after a stop): restart
      // the last-played content instead of doing nothing. The restart runs
      // the job loop — fire-and-forget for the same reason.
      unawaited(controller.restartLast());
    }
    // playing: already playing — a duplicate play is a no-op.
  }

  @override
  Future<void> pause() => AudioController.instance.pause();

  @override
  Future<void> stop() => AudioController.instance.stop();
}
