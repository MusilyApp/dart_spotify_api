import 'dart:convert';
import 'dart:io';

import 'package:dart_spotify_api/dart_spotify_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:oauth2_client/spotify_oauth2_client.dart';

class SpotifyService {
  final String clientId;
  final String clientSecret;
  final String redirectUri;
  final String customUriScheme;
  final int? localhostPort;

  late final SpotifyOAuth2Client client;
  Dio _dio = Dio();

  SpotifyService({
    required this.clientId,
    required this.clientSecret,
    required this.customUriScheme,
    required this.redirectUri,
    this.localhostPort,
  }) {
    late final String redirectUri;
    late final String customUriScheme;
    if (Platform.isLinux || Platform.isWindows) {
      if (localhostPort == null) {
        throw Exception('localhostPort is required in Linux and Windows.');
      }
      redirectUri = 'http://localhost:$localhostPort';
      customUriScheme = 'http://localhost:$localhostPort';
    } else {
      redirectUri = this.redirectUri;
      customUriScheme = this.customUriScheme;
    }
    client = SpotifyOAuth2Client(
      redirectUri: redirectUri,
      customUriScheme: customUriScheme,
    );
  }

  String? accessToken;
  String? refreshToken;

  final storage = const FlutterSecureStorage();

  bool _loggedIn = false;
  bool get loggedIn => _loggedIn;

  Future<void> initialize() async {
    _dio = Dio(
      BaseOptions(
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      ),
    )..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            await _refreshAccessTokenIfNeeded();
            options.headers['Authorization'] = 'Bearer $accessToken';
            return handler.next(options);
          },
        ),
      );

    await _loadCredentialsFromStorage();
  }

  Future<void> login() async {
    final authResponse = await client.requestAuthorization(
      clientId: clientId,
    );

    final authCode = authResponse.code;

    final tokenResponse = await client.requestAccessToken(
      code: authCode.toString(),
      clientId: clientId,
      clientSecret: clientSecret,
    );

    refreshToken = tokenResponse.refreshToken;

    final credentails = {
      'token': tokenResponse.accessToken,
      'refresh_token': tokenResponse.refreshToken,
      'expires_in': tokenResponse.expiresIn,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    };

    await storage.write(
      key: 'credentials',
      value: jsonEncode(credentails),
    );

    _loggedIn = true;
    accessToken = tokenResponse.accessToken;

    _dio = Dio(
      BaseOptions(
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      ),
    );
  }

  Future<UserModel?> getUser() async {
    if (!loggedIn || accessToken == null) {
      throw Exception('User is not logged in or access token is missing.');
    }

    try {
      final response = await _dio.get('https://api.spotify.com/v1/me');

      return UserModel.fromMap(
        response.data,
      );
    } catch (e) {
      throw Exception('Error fetching user data: $e');
    }
  }

  Future<dynamic> search(
    String query, {
    List<SearchType> type = SearchType.values,
    String? market,
    int offset = 0,
    int limit = 20,
  }) async {
    if (!loggedIn || accessToken == null) {
      throw Exception('User is not logged in or access token is missing.');
    }

    try {
      final queryParams = {
        'q': query,
        'type': type.map((e) => e.name).join(','),
        if (market != null) 'market': market,
        'offset': offset,
        'limit': limit,
      };

      final response = await _dio.get(
        'https://api.spotify.com/v1/search',
        queryParameters: queryParams,
      );

      final albums = ((response.data['albums']?['items'] as List?) ?? []).map(
        (e) => SimplifiedAlbum.fromMap(e),
      );
      final artists = ((response.data['artists']?['items'] as List?) ?? []).map(
        (e) => Artist.fromMap(e),
      );
      final playlists =
          ((response.data['playlists']?['items'] as List?) ?? []).map(
        (e) => SimplifiedPlaylist.fromMap(e),
      );
      final tracks = ((response.data['tracks']?['items'] as List?) ?? []).map(
        (e) => TrackModel.fromMap(e),
      );

      return [
        ...albums,
        ...artists,
        ...playlists,
        ...tracks,
      ];
    } catch (e) {
      throw Exception('Error searching Spotify: $e');
    }
  }

  Future<List<SimplifiedAlbum>> searchAlbums(
    String query, {
    String? market,
    int offset = 0,
    int limit = 20,
  }) async {
    final results = await search(
      query,
      type: [SearchType.album],
      market: market,
      offset: offset,
      limit: limit,
    );

    return results.whereType<SimplifiedAlbum>().toList();
  }

  Future<List<Artist>> searchArtists(
    String query, {
    String? market,
    int offset = 0,
    int limit = 20,
  }) async {
    final results = await search(
      query,
      type: [SearchType.artist],
      market: market,
      offset: offset,
      limit: limit,
    );

    return results.whereType<Artist>().toList();
  }

  Future<List<SimplifiedPlaylist>> searchPlaylists(
    String query, {
    String? market,
    int offset = 0,
    int limit = 20,
  }) async {
    final results = await search(
      query,
      type: [SearchType.playlist],
      market: market,
      offset: offset,
      limit: limit,
    );

    return results.whereType<SimplifiedPlaylist>().toList();
  }

  Future<List<TrackModel>> searchTracks(
    String query, {
    String? market,
    int offset = 0,
    int limit = 20,
  }) async {
    final results = await search(
      query,
      type: [SearchType.track],
      market: market,
      offset: offset,
      limit: limit,
    );

    return results.whereType<TrackModel>().toList();
  }

  Future<AlbumModel?> getAlbum(String albumId) async {
    try {
      final response =
          await _dio.get('https://api.spotify.com/v1/albums/$albumId');
      return AlbumModel.fromMap(response.data);
    } catch (e) {
      print('Error fetching album: $e');
      return null;
    }
  }

  Future<TrackModel?> getTrack(String trackId) async {
    try {
      final response =
          await _dio.get('https://api.spotify.com/v1/tracks/$trackId');
      return TrackModel.fromMap(response.data);
    } catch (e) {
      return null;
    }
  }

  Future<Artist?> getArtist(String artistId) async {
    try {
      final response =
          await _dio.get('https://api.spotify.com/v1/artists/$artistId');
      return Artist.fromMap(response.data);
    } catch (e) {
      return null;
    }
  }

  Future<PlaylistModel?> getPlaylist(String playlistId) async {
    try {
      final response = await _dio.get(
        'https://api.spotify.com/v1/playlists/$playlistId',
      );
      return PlaylistModel.fromMap(response.data);
    } catch (e, t) {
      throw Exception('Error fetching playlist: $e, $t');
    }
  }

  // OAuth flow
  Future<void> _loadCredentialsFromStorage() async {
    final credentialsJson = await storage.read(key: 'credentials');
    if (credentialsJson == null) {
      _loggedIn = false;
      return;
    }

    final Map<String, dynamic> credentials = jsonDecode(credentialsJson);

    final accessTokenStr = credentials['token'] as String?;
    final refreshTokenStr = credentials['refresh_token'] as String?;
    final expiresIn = credentials['expires_in'] as int?;
    final createdAt = credentials['created_at'] as int?;

    if (accessTokenStr == null ||
        refreshTokenStr == null ||
        expiresIn == null ||
        createdAt == null) {
      _loggedIn = false;
      return;
    }

    final expirationDateTime =
        DateTime.fromMillisecondsSinceEpoch(createdAt).add(
      Duration(
        seconds: expiresIn,
      ),
    );
    final isExpired = DateTime.now().isAfter(expirationDateTime);

    if (isExpired) {
      refreshToken = refreshTokenStr;
      await _refreshAccessToken();
    } else {
      _loggedIn = true;
      accessToken = accessTokenStr;
      refreshToken = refreshTokenStr;
    }
  }

  Future<void> _refreshAccessToken() async {
    if (refreshToken != null) {
      final tokenResponse = await client.refreshToken(
        refreshToken!,
        clientId: clientId,
        clientSecret: clientSecret,
      );

      if (tokenResponse.accessToken != null) {
        refreshToken = tokenResponse.refreshToken ?? refreshToken;

        final updatedCredentials = {
          'token': tokenResponse.accessToken,
          'refresh_token': refreshToken,
          'expires_in': tokenResponse.expiresIn,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        };

        await storage.write(
          key: 'credentials',
          value: jsonEncode(updatedCredentials),
        );
        accessToken = tokenResponse.accessToken;
        _loggedIn = true;
      } else {
        _loggedIn = false;
      }
    }
  }

  Future<void> _refreshAccessTokenIfNeeded() async {
    final credentialsJson = await storage.read(key: 'credentials');
    if (credentialsJson == null) {
      return;
    }

    final Map<String, dynamic> credentials = jsonDecode(credentialsJson);

    final accessTokenStr = credentials['token'] as String?;
    final refreshTokenStr = credentials['refresh_token'] as String?;
    final expiresIn = credentials['expires_in'] as int?;
    final createdAt = credentials['created_at'] as int?;

    if (accessTokenStr == null ||
        refreshTokenStr == null ||
        expiresIn == null ||
        createdAt == null) {
      return;
    }

    final expirationDateTime = DateTime.fromMillisecondsSinceEpoch(createdAt)
        .add(Duration(seconds: expiresIn));
    final isExpired = DateTime.now().isAfter(expirationDateTime);

    if (isExpired) {
      await _refreshAccessToken();
    }
  }

  Future<List<Artist>> getSimilarArtists(String artistId) async {
    try {
      final response = await _dio.get(
        'https://api.spotify.com/v1/artists/$artistId/related-artists',
      );
      final artists = (response.data['artists'] as List)
          .map((artist) => Artist.fromMap(artist))
          .toList();
      return artists;
    } catch (e) {
      throw Exception('Error fetching similar artists: $e');
    }
  }

  Future<List<SimplifiedTrack>> getAlbumTracks(String albumId) async {
    try {
      final response = await _dio.get(
        'https://api.spotify.com/v1/albums/$albumId/tracks',
      );
      final tracks = (response.data['items'] as List)
          .map((track) => SimplifiedTrack.fromMap(track))
          .toList();
      return tracks;
    } catch (e) {
      throw Exception('Error fetching album tracks: $e');
    }
  }

  Future<List<TrackModel>> getTopTracks(String artistId) async {
    try {
      final response = await _dio.get(
        'https://api.spotify.com/v1/artists/$artistId/top-tracks',
        queryParameters: {
          'market': Market.AM.name,
        },
      );
      print(response.data['tracks']);
      final tracks = (response.data['tracks'] as List)
          .map(
            (track) => TrackModel.fromMap(track),
          )
          .toList();
      return tracks;
    } catch (e) {
      throw Exception('Error fetching top tracks: $e');
    }
  }

  Future<List<SimplifiedAlbum>> getTopAlbums(String artistId) async {
    try {
      final response = await _dio.get(
        'https://api.spotify.com/v1/artists/$artistId/albums',
        queryParameters: {
          'include_groups': 'album',
          'market': Market.AM.name,
        },
      );
      final albums = (response.data['items'] as List)
          .map((album) => SimplifiedAlbum.fromMap(album))
          .toList();
      return albums;
    } catch (e) {
      throw Exception('Error fetching top albums: $e');
    }
  }

  Future<List<SimplifiedAlbum>> getTopSingles(String artistId) async {
    try {
      final response = await _dio.get(
        'https://api.spotify.com/v1/artists/$artistId/albums',
        queryParameters: {
          'include_groups': 'single',
          'market': Market.AM.name,
        },
      );
      final albums = (response.data['items'] as List)
          .map((album) => SimplifiedAlbum.fromMap(album))
          .toList();
      return albums;
    } catch (e) {
      throw Exception('Error fetching top singles: $e');
    }
  }

  Future<List<SimplifiedPlaylist>> getUserPlaylists() async {
    try {
      final response = await _dio.get(
        'https://api.spotify.com/v1/me/playlists',
      );
      final playlists = (response.data['items'] as List)
          .map((playlist) => SimplifiedPlaylist.fromMap(playlist))
          .toList();
      return playlists;
    } catch (e) {
      throw Exception('Error fetching user playlists: $e');
    }
  }
}
