import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerScreen extends StatefulWidget {
  final File file;
  const VideoPlayerScreen({super.key, required this.file});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with SingleTickerProviderStateMixin {
  late final VideoPlayerController _controller;
  late final Future<void> _initFuture;
  late final AnimationController _controlsAnimCtrl;
  late final Animation<double> _controlsOpacity;

  bool _showControls = true;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _controller = VideoPlayerController.file(widget.file);
    _initFuture = _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
      _controller
        ..setLooping(true)
        ..play();
    });

    _controlsAnimCtrl = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _controlsOpacity = CurvedAnimation(
      parent: _controlsAnimCtrl,
      curve: Curves.easeInOut,
    );
    _controlsAnimCtrl.value = 1;
    _hideControlsAfterDelay();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _controller.dispose();
    _controlsAnimCtrl.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
    _showControlsTemporarily();
  }

  void _seekRelative(Duration offset) {
    final pos = _controller.value.position;
    final dur = _controller.value.duration;
    final target = pos + offset;
    final clamped = target < Duration.zero
        ? Duration.zero
        : (dur != Duration.zero && target > dur ? dur : target);
    _controller.seekTo(clamped);
    HapticFeedback.selectionClick();
    _showControlsTemporarily();
  }

  void _showControlsTemporarily() {
    if (!_showControls) {
      setState(() => _showControls = true);
      _controlsAnimCtrl.forward();
    }
    _hideControlsAfterDelay();
  }

  void _hideControlsAfterDelay() {
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted || _isDragging) return;
      if (_controller.value.isInitialized && _controller.value.isPlaying) {
        setState(() => _showControls = false);
        _controlsAnimCtrl.reverse();
      }
    });
  }

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return h > 0 ? '${two(h)}:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.white));
          }
          if (!_controller.value.isInitialized) {
            return Center(
              child: Text(
                'Failed to load video',
                style:
                    theme.textTheme.titleMedium?.copyWith(color: Colors.white),
              ),
            );
          }

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _showControlsTemporarily,
            child: Stack(
              children: [
                // Video content
                Center(
                  child: AspectRatio(
                    aspectRatio: _controller.value.aspectRatio == 0
                        ? 16 / 9
                        : _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
                ),

                // Top gradient + minimal bar
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: AnimatedBuilder(
                    animation: _controlsOpacity,
                    builder: (context, _) {
                      return IgnorePointer(
                        ignoring: !_showControls,
                        child: Opacity(
                          opacity: _controlsOpacity.value,
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.black54, Colors.transparent],
                              ),
                            ),
                            child: SafeArea(
                              bottom: false,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 6),
                                child: Row(
                                  children: [
                                    IconButton(
                                      onPressed: () => Navigator.pop(context),
                                      icon: const Icon(CupertinoIcons.back,
                                          color: Colors.white),
                                      tooltip: 'Back',
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      onPressed: () async => Share.shareXFiles(
                                          [XFile(widget.file.path)]),
                                      icon: const Icon(CupertinoIcons.share,
                                          color: Colors.white),
                                      tooltip: 'Share',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Center play button (only when paused) - Fixed with ValueListenableBuilder
                ValueListenableBuilder<VideoPlayerValue>(
                  valueListenable: _controller,
                  builder: (context, value, child) {
                    if (value.isPlaying) return const SizedBox.shrink();

                    return Center(
                      child: AnimatedBuilder(
                        animation: _controlsOpacity,
                        builder: (context, _) {
                          return IgnorePointer(
                            ignoring: !_showControls,
                            child: Opacity(
                              opacity: _controlsOpacity.value,
                              child: GestureDetector(
                                onTap: _togglePlayPause,
                                child: Container(
                                  width: 84,
                                  height: 84,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(CupertinoIcons.play_fill,
                                      color: Colors.white, size: 44),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),

                // iOS-styled bottom controls - Fixed with ValueListenableBuilder
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: AnimatedBuilder(
                    animation: _controlsOpacity,
                    builder: (context, _) {
                      return IgnorePointer(
                        ignoring: !_showControls,
                        child: Opacity(
                          opacity: _controlsOpacity.value,
                          child: SafeArea(
                            top: false,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: BackdropFilter(
                                  filter:
                                      ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                                  child: Container(
                                    padding: const EdgeInsets.fromLTRB(
                                        12, 10, 12, 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.08),
                                      border: Border.all(
                                          color:
                                              Colors.white.withOpacity(0.12)),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: ValueListenableBuilder<
                                        VideoPlayerValue>(
                                      valueListenable: _controller,
                                      builder: (context, value, child) {
                                        final position = value.position;
                                        final duration = value.duration ==
                                                Duration.zero
                                            ? const Duration(milliseconds: 1)
                                            : value.duration;
                                        final sliderValue = position
                                            .inMilliseconds
                                            .clamp(0, duration.inMilliseconds)
                                            .toDouble();
                                        final sliderMax =
                                            duration.inMilliseconds.toDouble();

                                        return Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Transport controls (iOS style)
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                IconButton(
                                                  onPressed: () =>
                                                      _seekRelative(
                                                          const Duration(
                                                              seconds: -15)),
                                                  icon: const Icon(
                                                      CupertinoIcons
                                                          .gobackward_15,
                                                      color: Colors.white),
                                                  tooltip: 'Back 15s',
                                                ),
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  onPressed: _togglePlayPause,
                                                  icon: Icon(
                                                    value.isPlaying
                                                        ? CupertinoIcons
                                                            .pause_fill
                                                        : CupertinoIcons
                                                            .play_fill,
                                                    color: Colors.white,
                                                    size: 28,
                                                  ),
                                                  tooltip: value.isPlaying
                                                      ? 'Pause'
                                                      : 'Play',
                                                ),
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  onPressed: () =>
                                                      _seekRelative(
                                                          const Duration(
                                                              seconds: 15)),
                                                  icon: const Icon(
                                                      CupertinoIcons
                                                          .goforward_15,
                                                      color: Colors.white),
                                                  tooltip: 'Forward 15s',
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            // Time + Fixed CupertinoSlider
                                            Row(
                                              children: [
                                                Text(
                                                  _fmt(position),
                                                  style: const TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 12),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: CupertinoSlider(
                                                    value: sliderValue,
                                                    min: 0,
                                                    max: sliderMax,
                                                    onChanged: (newValue) {
                                                      final newPosition =
                                                          Duration(
                                                              milliseconds:
                                                                  newValue
                                                                      .round());
                                                      _controller
                                                          .seekTo(newPosition);
                                                    },
                                                    onChangeStart: (_) {
                                                      _isDragging = true;
                                                      _showControlsTemporarily();
                                                    },
                                                    onChangeEnd: (_) {
                                                      _isDragging = false;
                                                      _hideControlsAfterDelay();
                                                    },
                                                    activeColor: Colors.white,
                                                    thumbColor: Colors.white,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  _fmt(duration),
                                                  style: const TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
