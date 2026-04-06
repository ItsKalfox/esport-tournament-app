import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../config/youtube_config.dart';
import '../../services/youtube_service.dart';

class WatchLiveScreen extends StatefulWidget {
  const WatchLiveScreen({super.key});

  @override
  State<WatchLiveScreen> createState() => _WatchLiveScreenState();
}

class _WatchLiveScreenState extends State<WatchLiveScreen> {
  static const String _apiKey = YouTubeConfig.apiKey;

  late YouTubeService _youtubeService;
  List<YouTubeLiveStream> _liveStreams = [];
  List<YouTubeLiveStream> _upcomingStreams = [];
  bool _isLoading = true;
  String? _errorMessage;
  YoutubePlayerController? _playerController;
  bool _isPlayerVisible = false;

  @override
  void initState() {
    super.initState();
    if (_apiKey.isEmpty) {
      setState(() {
        _errorMessage = 'YouTube API key not configured.';
        _isLoading = false;
      });
      return;
    }
    _youtubeService = YouTubeService(apiKey: _apiKey, channelId: '');
    _fetchStreams();
  }

  Future<void> _fetchStreams() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _youtubeService.getLiveStreams(),
        _youtubeService.getUpcomingStreams(),
      ]);

      setState(() {
        _liveStreams = results[0];
        _upcomingStreams = results[1];
        _isLoading = false;
      });
    } on YouTubeApiException catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  String _getErrorMessage(YouTubeApiException e) {
    switch (e.statusCode) {
      case 401:
        return 'Invalid API key. Please check your YouTube Data API configuration.';
      case 403:
        return 'API quota exceeded. Please try again later.';
      case 404:
        return 'Channel not found. Please check the channel ID.';
      case 0:
        return 'Network error. Please check your internet connection.';
      default:
        return 'Failed to load streams. Please try again.';
    }
  }

  void _playVideo(String videoId) {
    _playerController?.dispose();
    _playerController = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        enableCaption: false,
        hideControls: false,
      ),
    );
    setState(() {
      _isPlayerVisible = true;
    });
  }

  void _closePlayer() {
    _playerController?.pause();
    setState(() {
      _isPlayerVisible = false;
    });
  }

  void _pauseVideo() {
    _playerController?.pause();
  }

  @override
  void dispose() {
    _playerController?.dispose();
    _youtubeService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFE9E9E9)),
          onPressed: () {
            if (_isPlayerVisible) {
              _closePlayer();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: const Text(
          'Watch Live',
          style: TextStyle(
            color: Color(0xFFE9E9E9),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_isPlayerVisible)
            IconButton(
              icon: const Icon(Icons.close, color: Color(0xFFE9E9E9)),
              onPressed: _closePlayer,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF8A00)),
            ),
            SizedBox(height: 16),
            Text(
              'Fetching live streams...',
              style: TextStyle(color: Color(0xFF9A9A9A), fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorView();
    }

    if (_isPlayerVisible && _playerController != null) {
      return _buildPlayerView();
    }

    return _buildStreamsList();
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFFF4444), size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFE9E9E9), fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchStreams,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8A00),
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerView() {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: YoutubePlayer(
            controller: _playerController!,
            showVideoProgressIndicator: true,
            progressIndicatorColor: const Color(0xFFFF8A00),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _pauseVideo,
                icon: const Icon(Icons.pause, size: 20),
                label: const Text('Pause'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A2A2A),
                  foregroundColor: const Color(0xFFE9E9E9),
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: _closePlayer,
                icon: const Icon(Icons.arrow_back, size: 20),
                label: const Text('Back to List'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE9E9E9),
                  side: const BorderSide(color: Color(0xFF2A2A2A)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStreamsList() {
    debugPrint('Building streams list - Live: ${_liveStreams.length}, Upcoming: ${_upcomingStreams.length}');
    final allStreams = [..._liveStreams, ..._upcomingStreams];

    if (allStreams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.live_tv_outlined,
              color: Color(0xFF4B4B4B),
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'No live streams available',
              style: TextStyle(color: Color(0xFF9A9A9A), fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Check back later for live content',
              style: TextStyle(color: Color(0xFF666666), fontSize: 14),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 768;
        final crossAxisCount = isDesktop ? 2 : 1;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_liveStreams.isNotEmpty) ...[
                _buildSectionHeader(
                  'Live Now',
                  Icons.fiber_manual_record,
                  const Color(0xFFFF4444),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: isDesktop ? 2.2 : 1.8,
                  ),
                  itemCount: _liveStreams.length,
                  itemBuilder: (context, index) => _StreamCard(
                    stream: _liveStreams[index],
                    isLive: true,
                    onTap: () => _playVideo(_liveStreams[index].id),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              if (_upcomingStreams.isNotEmpty) ...[
                _buildSectionHeader(
                  'Upcoming',
                  Icons.schedule,
                  const Color(0xFFFF8A00),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: isDesktop ? 2.2 : 1.8,
                  ),
                  itemCount: _upcomingStreams.length,
                  itemBuilder: (context, index) => _StreamCard(
                    stream: _upcomingStreams[index],
                    isLive: false,
                    onTap: () => _showUpcomingMessage(),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color iconColor) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 16),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFFE9E9E9),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showUpcomingMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This stream hasn\'t started yet. Check back later!'),
        backgroundColor: Color(0xFF2A2A2A),
      ),
    );
  }
}

class _StreamCard extends StatelessWidget {
  final YouTubeLiveStream stream;
  final bool isLive;
  final VoidCallback onTap;

  const _StreamCard({
    required this.stream,
    required this.isLive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(12),
              ),
              child: Stack(
                children: [
                  Image.network(
                    stream.thumbnailUrl,
                    width: 140,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 140,
                      color: const Color(0xFF2A2A2A),
                      child: const Icon(
                        Icons.live_tv,
                        color: Color(0xFF4B4B4B),
                        size: 32,
                      ),
                    ),
                  ),
                  if (isLive)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4444),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      stream.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFE9E9E9),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stream.channelTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF9A9A9A),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          isLive ? Icons.fiber_manual_record : Icons.schedule,
                          color: isLive
                              ? const Color(0xFFFF4444)
                              : const Color(0xFFFF8A00),
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isLive
                              ? 'Live Now'
                              : stream.scheduledStartTime != null
                              ? _formatScheduledTime(stream.scheduledStartTime!)
                              : 'Upcoming',
                          style: TextStyle(
                            color: isLive
                                ? const Color(0xFFFF4444)
                                : const Color(0xFF9A9A9A),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                isLive ? Icons.play_circle_filled : Icons.notifications,
                color: const Color(0xFFFF8A00),
                size: 32,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatScheduledTime(DateTime time) {
    final now = DateTime.now();
    final diff = time.difference(now);

    if (diff.inDays > 0) {
      return 'In ${diff.inDays} day${diff.inDays > 1 ? 's' : ''}';
    } else if (diff.inHours > 0) {
      return 'In ${diff.inHours} hour${diff.inHours > 1 ? 's' : ''}';
    } else if (diff.inMinutes > 0) {
      return 'In ${diff.inMinutes} min';
    } else {
      return 'Starting soon';
    }
  }
}
