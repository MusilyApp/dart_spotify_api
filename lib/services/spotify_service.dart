import 'dart:convert';
import 'dart:io';

import 'package:dart_spotify_api/dart_spotify_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:oauth2_client/spotify_oauth2_client.dart';

/// A service class to interact with Spotify's API, providing methods for
/// authentication, data retrieval, and search functionalities.
class SpotifyService {
  /// The client ID of your Spotify application.
  final String clientId;

  /// The client secret of your Spotify application.
  final String clientSecret;

  /// The redirect URI for your Spotify application.
  final String redirectUri;

  /// The custom URI scheme for your application.
  final String customUriScheme;

  /// The localhost port, required for Linux and Windows platforms.
  final int? localhostPort;

  /// The OAuth2 client used for handling authentication with Spotify.
  late final SpotifyOAuth2Client client;

  Dio _dio = Dio();

  SpotifyService({
    required this.clientId,
    required this.clientSecret,
    required this.customUriScheme,
    required this.redirectUri,
    this.localhostPort,
  }) {
    // Determine redirect URI and custom URI scheme based on platform
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

    // Initialize the OAuth2 client
    client = SpotifyOAuth2Client(
      redirectUri: redirectUri,
      customUriScheme: customUriScheme,
    );
  }

  String? accessToken;
  String? refreshToken;

  /// Secure storage for saving and retrieving OAuth credentials.
  final storage = const FlutterSecureStorage();

  bool _loggedIn = false;

  /// Indicates whether the user is currently logged in.
  bool get loggedIn => _loggedIn;

  /// Initializes the service, setting up the Dio instance and loading credentials.
  Future<void> initialize() async {
    // Configure Dio with authorization header
    _dio = Dio(
      BaseOptions(
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      ),
    )..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            // Refresh access token if needed before each request
            await _refreshAccessTokenIfNeeded();
            options.headers['Authorization'] = 'Bearer $accessToken';
            return handler.next(options);
          },
        ),
      );

    // Load OAuth credentials from secure storage
    await _loadCredentialsFromStorage();
  }

  /// Initiates the login process using Spotify's OAuth2 authentication.
  Future<void> login() async {
    // Request authorization code from Spotify
    final authResponse = await client.requestAuthorization(
      clientId: clientId,
    );

    // Extract authorization code from response
    final authCode = authResponse.code;

    // Request access token and refresh token using the authorization code
    final tokenResponse = await client.requestAccessToken(
      code: authCode.toString(),
      clientId: clientId,
      clientSecret: clientSecret,
    );

    // Store refresh token
    refreshToken = tokenResponse.refreshToken;

    // Store OAuth credentials in secure storage
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

    // Update login status and access token
    _loggedIn = true;
    accessToken = tokenResponse.accessToken;

    // Reconfigure Dio with the new access token
    _dio = Dio(
      BaseOptions(
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      ),
    );
  }

  /// Retrieves the current user's profile information.
  ///
  /// Returns a [UserModel] representing the user's data.
  Future<UserModel?> getUser() async {
    if (!loggedIn || accessToken == null) {
      throw Exception('User is not logged in or access token is missing.');
    }

    try {
      // Make an API request to get user data
      final response = await _dio.get('https://api.spotify.com/v1/me');

      // Parse the response into a UserModel
      return UserModel.fromMap(
        response.data,
      );
    } catch (e) {
      throw Exception('Error fetching user data: $e');
    }
  }

  /// Performs a search query on Spotify.
  ///
  /// - [query]: The search query string.
  /// - [type]: The types of items to search for (albums, artists, playlists, tracks).
  /// - [market]: An optional market (country code) to filter results.
  /// - [offset]: The index of the first result to return.
  /// - [limit]: The maximum number of results to return.
  ///
  /// Returns a list of search results matching the query.
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
      // Construct query parameters for the search API
      final queryParams = {
        'q': query,
        'type': type.map((e) => e.name).join(','),
        if (market != null) 'market': market,
        'offset': offset,
        'limit': limit,
      };

      // Make an API request to search Spotify
      final response = await _dio.get(
        'https://api.spotify.com/v1/search',
        queryParameters: queryParams,
      );

      // Parse the search results based on their type
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

      // Return all search results as a single list
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

  /// Searches for albums matching the given query.
  ///
  /// - [query]: The search query string.
  /// - [market]: An optional market (country code) to filter results.
  /// - [offset]: The index of the first result to return.
  /// - [limit]: The maximum number of results to return.
  ///
  /// Returns a list of [SimplifiedAlbum] objects.
  Future<List<SimplifiedAlbum>> searchAlbums(
    String query, {
    String? market,
    int offset = 0,
    int limit = 20,
  }) async {
    // Perform a search with the specified type (album)
    final results = await search(
      query,
      type: [SearchType.album],
      market: market,
      offset: offset,
      limit: limit,
    );

    // Filter the results to only include albums
    return results.whereType<SimplifiedAlbum>().toList();
  }

  /// Searches for artists matching the given query.
  ///
  /// - [query]: The search query string.
  /// - [market]: An optional market (country code) to filter results.
  /// - [offset]: The index of the first result to return.
  /// - [limit]: The maximum number of results to return.
  ///
  /// Returns a list of [Artist] objects.
  Future<List<Artist>> searchArtists(
    String query, {
    String? market,
    int offset = 0,
    int limit = 20,
  }) async {
    // Perform a search with the specified type (artist)
    final results = await search(
      query,
      type: [SearchType.artist],
      market: market,
      offset: offset,
      limit: limit,
    );

    // Filter the results to only include artists
    return results.whereType<Artist>().toList();
  }

  /// Searches for playlists matching the given query.
  ///
  /// - [query]: The search query string.
  /// - [market]: An optional market (country code) to filter results.
  /// - [offset]: The index of the first result to return.
  /// - [limit]: The maximum number of results to return.
  ///
  /// Returns a list of [SimplifiedPlaylist] objects.
  Future<List<SimplifiedPlaylist>> searchPlaylists(
    String query, {
    String? market,
    int offset = 0,
    int limit = 20,
  }) async {
    // Perform a search with the specified type (playlist)
    final results = await search(
      query,
      type: [SearchType.playlist],
      market: market,
      offset: offset,
      limit: limit,
    );

    // Filter the results to only include playlists
    return results.whereType<SimplifiedPlaylist>().toList();
  }

  /// Searches for tracks matching the given query.
  ///
  /// - [query]: The search query string.
  /// - [market]: An optional market (country code) to filter results.
  /// - [offset]: The index of the first result to return.
  /// - [limit]: The maximum number of results to return.
  ///
  /// Returns a list of [TrackModel] objects.
  Future<List<TrackModel>> searchTracks(
    String query, {
    String? market,
    int offset = 0,
    int limit = 20,
  }) async {
    // Perform a search with the specified type (track)
    final results = await search(
      query,
      type: [SearchType.track],
      market: market,
      offset: offset,
      limit: limit,
    );

    // Filter the results to only include tracks
    return results.whereType<TrackModel>().toList();
  }

  /// Retrieves detailed information about a specific album.
  ///
  /// - [albumId]: The Spotify ID of the album.
  ///
  /// Returns an [AlbumModel] object representing the album's data.
  Future<AlbumModel?> getAlbum(String albumId) async {
    try {
      // Make an API request to get album details
      final response =
          await _dio.get('https://api.spotify.com/v1/albums/$albumId');
      return AlbumModel.fromMap(response.data);
    } catch (e) {
      print('Error fetching album: $e');
      return null;
    }
  }

  /// Retrieves detailed information about a specific track.
  ///
  /// - [trackId]: The Spotify ID of the track.
  ///
  /// Returns a [TrackModel] object representing the track's data.
  Future<TrackModel?> getTrack(String trackId) async {
    try {
      // Make an API request to get track details
      final response =
          await _dio.get('https://api.spotify.com/v1/tracks/$trackId');
      return TrackModel.fromMap(response.data);
    } catch (e) {
      return null;
    }
  }

  /// Retrieves detailed information about a specific artist.
  ///
  /// - [artistId]: The Spotify ID of the artist.
  ///
  /// Returns an [Artist] object representing the artist's data.
  Future<Artist?> getArtist(String artistId) async {
    try {
      // Make an API request to get artist details
      final response =
          await _dio.get('https://api.spotify.com/v1/artists/$artistId');
      return Artist.fromMap(response.data);
    } catch (e) {
      return null;
    }
  }

  /// Retrieves detailed information about a specific playlist.
  ///
  /// - [playlistId]: The Spotify ID of the playlist.
  ///
  /// Returns a [PlaylistModel] object representing the playlist's data.
  Future<PlaylistModel?> getPlaylist(String playlistId) async {
    try {
      // Make an API request to get playlist details
      final response = await _dio.get(
        'https://api.spotify.com/v1/playlists/$playlistId',
      );
      return PlaylistModel.fromMap(response.data);
    } catch (e, t) {
      throw Exception('Error fetching playlist: $e, $t');
    }
  }

  // Private methods for handling OAuth credential management

  /// Loads OAuth credentials from secure storage.
  Future<void> _loadCredentialsFromStorage() async {
    // Read credentials from storage
    final credentialsJson = await storage.read(key: 'credentials');
    if (credentialsJson == null) {
      _loggedIn = false;
      return;
    }

    // Parse credentials from JSON
    final Map<String, dynamic> credentials = jsonDecode(credentialsJson);

    // Extract credential values
    final accessTokenStr = credentials['token'] as String?;
    final refreshTokenStr = credentials['refresh_token'] as String?;
    final expiresIn = credentials['expires_in'] as int?;
    final createdAt = credentials['created_at'] as int?;

    // Check if all required credentials are present
    if (accessTokenStr == null ||
        refreshTokenStr == null ||
        expiresIn == null ||
        createdAt == null) {
      _loggedIn = false;
      return;
    }

    // Calculate expiration date
    final expirationDateTime =
        DateTime.fromMillisecondsSinceEpoch(createdAt).add(
      Duration(
        seconds: expiresIn,
      ),
    );

    // Check if access token is expired
    final isExpired = DateTime.now().isAfter(expirationDateTime);

    // Refresh access token if expired
    if (isExpired) {
      refreshToken = refreshTokenStr;
      await _refreshAccessToken();
    } else {
      // Update login status and store credentials
      _loggedIn = true;
      accessToken = accessTokenStr;
      refreshToken = refreshTokenStr;
    }
  }

  /// Refreshes the access token using the refresh token.
  Future<void> _refreshAccessToken() async {
    // Only attempt refresh if refresh token is available
    if (refreshToken != null) {
      // Request a new access token using refresh token
      final tokenResponse = await client.refreshToken(
        refreshToken!,
        clientId: clientId,
        clientSecret: clientSecret,
      );

      // Update refresh token and credentials if successful
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

  /// Refreshes the access token if it's expired.
  Future<void> _refreshAccessTokenIfNeeded() async {
    // Read credentials from storage
    final credentialsJson = await storage.read(key: 'credentials');
    if (credentialsJson == null) {
      return;
    }

    // Parse credentials from JSON
    final Map<String, dynamic> credentials = jsonDecode(credentialsJson);

    // Extract credential values
    final accessTokenStr = credentials['token'] as String?;
    final refreshTokenStr = credentials['refresh_token'] as String?;
    final expiresIn = credentials['expires_in'] as int?;
    final createdAt = credentials['created_at'] as int?;

    // Check if all required credentials are present
    if (accessTokenStr == null ||
        refreshTokenStr == null ||
        expiresIn == null ||
        createdAt == null) {
      return;
    }

    // Calculate expiration date
    final expirationDateTime = DateTime.fromMillisecondsSinceEpoch(createdAt)
        .add(Duration(seconds: expiresIn));

    // Check if access token is expired
    final isExpired = DateTime.now().isAfter(expirationDateTime);

    // Refresh access token if expired
    if (isExpired) {
      await _refreshAccessToken();
    }
  }

  /// Retrieves a list of similar artists for a given artist.
  ///
  /// - [artistId]: The Spotify ID of the artist.
  ///
  /// Returns a list of [Artist] objects representing similar artists.
  Future<List<Artist>> getSimilarArtists(String artistId) async {
    try {
      // Make an API request to get similar artists
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

  /// Retrieves a list of tracks from a specific album.
  ///
  /// - [albumId]: The Spotify ID of the album.
  ///
  /// Returns a list of [SimplifiedTrack] objects representing the album's tracks.
  Future<List<SimplifiedTrack>> getAlbumTracks(String albumId) async {
    try {
      // Make an API request to get album tracks
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

  /// Retrieves a list of an artist's top tracks in a specific market.
  ///
  /// - [artistId]: The Spotify ID of the artist.
  ///
  /// Returns a list of [TrackModel] objects representing the artist's top tracks.
  Future<List<TrackModel>> getTopTracks(String artistId) async {
    try {
      // Make an API request to get artist's top tracks
      final response = await _dio.get(
        'https://api.spotify.com/v1/artists/$artistId/top-tracks',
        queryParameters: {
          'market': Market.AM.name, // Replace with the desired market
        },
      );

      // Parse the response into a list of TrackModel objects
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

  /// Retrieves a list of an artist's top albums in a specific market.
  ///
  /// - [artistId]: The Spotify ID of the artist.
  ///
  /// Returns a list of [SimplifiedAlbum] objects representing the artist's top albums.
  Future<List<SimplifiedAlbum>> getTopAlbums(String artistId) async {
    try {
      // Make an API request to get artist's albums
      final response = await _dio.get(
        'https://api.spotify.com/v1/artists/$artistId/albums',
        queryParameters: {
          'include_groups': 'album',
          'market': Market.AM.name, // Replace with the desired market
        },
      );

      // Parse the response into a list of SimplifiedAlbum objects
      final albums = (response.data['items'] as List)
          .map((album) => SimplifiedAlbum.fromMap(album))
          .toList();
      return albums;
    } catch (e) {
      throw Exception('Error fetching top albums: $e');
    }
  }

  /// Retrieves a list of an artist's top singles in a specific market.
  ///
  /// - [artistId]: The Spotify ID of the artist.
  ///
  /// Returns a list of [SimplifiedAlbum] objects representing the artist's top singles.
  Future<List<SimplifiedAlbum>> getTopSingles(String artistId) async {
    try {
      // Make an API request to get artist's albums
      final response = await _dio.get(
        'https://api.spotify.com/v1/artists/$artistId/albums',
        queryParameters: {
          'include_groups': 'single',
          'market': Market.AM.name, // Replace with the desired market
        },
      );

      // Parse the response into a list of SimplifiedAlbum objects
      final albums = (response.data['items'] as List)
          .map((album) => SimplifiedAlbum.fromMap(album))
          .toList();
      return albums;
    } catch (e) {
      throw Exception('Error fetching top singles: $e');
    }
  }

  /// Retrieves a list of the current user's playlists.
  ///
  /// Returns a list of [SimplifiedPlaylist] objects representing the user's playlists.
  Future<List<SimplifiedPlaylist>> getUserPlaylists() async {
    try {
      // Make an API request to get user playlists
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
