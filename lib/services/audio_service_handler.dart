import 'package:audio_service/audio_service.dart';

import 'audio_controller.dart';

/// The media notification + lock-screen player for background audio
/// (audio_service), bridged to the app's single audio stream.
///
/// The [AudioController] stays the single source of truth: the handler
/// MIRRORS the controller's state into the media session, and the
/// notification's buttons route back through the controller's own
/// pause/resume/stop — so the in-app controls and the player always agree,
/// whichever side the user acts on.
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
/// Controls are exactly play/pause + stop: no seek bar (the per-sentence
/// Kokoro pipeline has no meaningful whole-item duration) and no skip
/// buttons (the app's pages never auto-advance; Next is always user-pressed).
class FidelisAudioHandler extends BaseAudioHandler {
  FidelisAudioHandler() {
    AudioController.instance.listenable.addListener(_onControllerChanged);
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

  void _broadcast({required bool playing}) {
    final controller = AudioController.instance;
    mediaItem.add(MediaItem(
      id: controller.currentJobId ?? 'fidelis',
      title: controller.currentJobTitle ?? 'Fidelis',
      album: 'Fidelis',
    ));
    playbackState.add(PlaybackState(
      processingState: AudioProcessingState.ready,
      playing: playing,
      controls: [
        playing ? MediaControl.pause : MediaControl.play,
        MediaControl.stop,
      ],
      androidCompactActionIndices: const [0, 1],
      systemActions: const <MediaAction>{},
    ));
  }

  @override
  Future<void> play() => AudioController.instance.resume();

  @override
  Future<void> pause() => AudioController.instance.pause();

  @override
  Future<void> stop() => AudioController.instance.stop();
}
