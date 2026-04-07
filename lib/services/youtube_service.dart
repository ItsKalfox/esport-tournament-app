import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class YouTubeLiveStream {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String channelTitle;
  final DateTime? scheduledStartTime;
  final String liveStatus;

  YouTubeLiveStream({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.channelTitle,
    this.scheduledStartTime,
    required this.liveStatus,
  });

  factory YouTubeLiveStream.fromJson(Map<String, dynamic> json) {
    final snippet = json['snippet'] ?? {};
    final thumbnails = snippet['thumbnails'] ?? {};
    String thumbnailUrl = '';
    if (thumbnails['high'] != null) {
      thumbnailUrl = thumbnails['high']['url'] ?? '';
    } else if (thumbnails['medium'] != null) {
      thumbnailUrl = thumbnails['medium']['url'] ?? '';
    } else if (thumbnails['default'] != null) {
      thumbnailUrl = thumbnails['default']['url'] ?? '';
    }

    String videoId = '';
    final id = json['id'];
    if (id is String) {
      videoId = id;
    } else if (id is Map) {
      videoId = id['videoId'] ?? '';
    }

    return YouTubeLiveStream(
      id: videoId,
      title: snippet['title'] ?? '',
      description: snippet['description'] ?? '',
      thumbnailUrl: thumbnailUrl,
      channelTitle: snippet['channelTitle'] ?? '',
      scheduledStartTime: snippet['scheduledStartTime'] != null
          ? DateTime.tryParse(snippet['scheduledStartTime'])
          : null,
      liveStatus: json['status']?['liveBroadcastStatus'] ?? 'unknown',
    );
  }
}

class YouTubeService {
  static const String _baseUrl = 'https://www.googleapis.com/youtube/v3';
  static const Duration _timeout = Duration(seconds: 30);
  
  final String apiKey;
  final http.Client _client;

  YouTubeService({
    required this.apiKey,
    String channelId = '',
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<List<YouTubeLiveStream>> getLiveStreams() async {
    try {
      final keywords = Uri.encodeComponent('gaming esports');
      final searchUrl = Uri.parse(
        '$_baseUrl/search?part=snippet&eventType=live&type=video&q=$keywords&maxResults=50&key=$apiKey',
      );

      final searchResponse = await _client.get(searchUrl).timeout(_timeout);
      
      if (searchResponse.statusCode != 200) {
        throw YouTubeApiException(
          'Failed to search live streams: ${searchResponse.statusCode} - ${searchResponse.body}',
          searchResponse.statusCode,
        );
      }

      final searchData = json.decode(searchResponse.body) as Map<String, dynamic>;
      debugPrint('Live streams: ${searchData['pageInfo']}');
      final rawItems = searchData['items'] as List<dynamic>? ?? [];
      final items = rawItems.whereType<Map<String, dynamic>>().toList();

      if (items.isEmpty) {
        return [];
      }

      final liveStreams = items
          .map((item) => YouTubeLiveStream.fromJson(item))
          .toList();

      debugPrint('Filtered live streams: ${liveStreams.length}');

      return liveStreams;
    } on SocketException catch (e) {
      debugPrint('SocketException getLiveStreams: ${e.message}');
      throw YouTubeApiException('Network error. Please check your internet connection.', 0);
    } on HttpException catch (e) {
      debugPrint('HttpException getLiveStreams: ${e.message}');
      throw YouTubeApiException('Network error. Please check your internet connection.', 0);
    } on TimeoutException {
      debugPrint('TimeoutException getLiveStreams');
      throw YouTubeApiException('Request timed out. Please check your internet connection.', 0);
    } on FormatException catch (e) {
      debugPrint('FormatException getLiveStreams: ${e.message}');
      throw YouTubeApiException('Invalid JSON response: ${e.message}', 0);
    } catch (e) {
      debugPrint('Error getLiveStreams: $e');
      if (e is YouTubeApiException) rethrow;
      throw YouTubeApiException('Network error: $e', 0);
    }
  }

  Future<List<YouTubeLiveStream>> getUpcomingStreams() async {
    try {
      final keywords = Uri.encodeComponent('gaming esports');
      final searchUrl = Uri.parse(
        '$_baseUrl/search?part=snippet&eventType=upcoming&type=video&q=$keywords&maxResults=50&key=$apiKey',
      );

      final response = await _client.get(searchUrl).timeout(_timeout);
      
      if (response.statusCode != 200) {
        throw YouTubeApiException(
          'Failed to search upcoming streams: ${response.statusCode} - ${response.body}',
          response.statusCode,
        );
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      debugPrint('Upcoming streams: ${data['pageInfo']}');
      final rawItems = data['items'] as List<dynamic>? ?? [];
      final items = rawItems.whereType<Map<String, dynamic>>().toList();

      return items
          .map((item) => YouTubeLiveStream.fromJson(item))
          .where((stream) => stream.scheduledStartTime != null)
          .toList();
    } on SocketException catch (e) {
      debugPrint('SocketException getUpcomingStreams: ${e.message}');
      throw YouTubeApiException('Network error. Please check your internet connection.', 0);
    } on HttpException catch (e) {
      debugPrint('HttpException getUpcomingStreams: ${e.message}');
      throw YouTubeApiException('Network error. Please check your internet connection.', 0);
    } on TimeoutException {
      debugPrint('TimeoutException getUpcomingStreams');
      throw YouTubeApiException('Request timed out. Please check your internet connection.', 0);
    } on FormatException catch (e) {
      debugPrint('FormatException getUpcomingStreams: ${e.message}');
      throw YouTubeApiException('Invalid JSON response: ${e.message}', 0);
    } catch (e) {
      debugPrint('Error getUpcomingStreams: $e');
      if (e is YouTubeApiException) rethrow;
      throw YouTubeApiException('Network error: $e', 0);
    }
  }

  void dispose() {
    _client.close();
  }
}

class YouTubeApiException implements Exception {
  final String message;
  final int statusCode;

  YouTubeApiException(this.message, this.statusCode);

  @override
  String toString() => 'YouTubeApiException: $message (status: $statusCode)';
}