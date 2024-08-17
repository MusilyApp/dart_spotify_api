import 'package:dart_spotify_api/dart_spotify_api.dart';

void main() async {
  // Replace with your actual Spotify credentials
  final spotifyService = SpotifyService(
    clientId: 'YOUR_CLIENT_ID',
    clientSecret: 'YOUR_CLIENT_SECRET',
    customUriScheme:
        'your-app-scheme', // Choose a custom URI scheme for your app
    redirectUri: 'your-app-redirect-uri', // App's redirect URI
    localhostPort: 8080, // Set the local port for Linux/Windows, if applicable
  );

  // Initialize the service
  await spotifyService.initialize();

  // Login
  await spotifyService.login();

  // Check if the user is logged in
  if (spotifyService.loggedIn) {
    // Get user information
    final user = await spotifyService.getUser();
    print('User name: ${user?.name}');

    // Search for albums by The Beatles
    final searchResults = await spotifyService.searchAlbums(
      'The Beatles',
      market: 'US', // Specify a market (optional)
    );
    print(
        'Search results: ${searchResults.map((album) => album.name).join(', ')}');

    // Get the album "Abbey Road"
    final album = await spotifyService.getAlbum('3IHW9P9o9jOYXS574q19oL');
    print('Album name: ${album?.name}');

    // Get the track "Come Together"
    final track = await spotifyService.getTrack('4c61x5w0f8e99Yf741Qh0C');
    print('Track name: ${track?.name}');

    // Get the artist "The Beatles"
    final artist = await spotifyService.getArtist('3WrFJ7ztbogyGnThbHJFl2');
    print('Artist name: ${artist?.name}');

    // Get similar artists to The Beatles
    final similarArtists =
        await spotifyService.getSimilarArtists('3WrFJ7ztbogyGnThbHJFl2');
    print(
        'Similar artists: ${similarArtists.map((artist) => artist.name).join(', ')}');

    // Get the tracks from the album "Abbey Road"
    final albumTracks =
        await spotifyService.getAlbumTracks('3IHW9P9o9jOYXS574q19oL');
    print('Album tracks: ${albumTracks.map((track) => track.name).join(', ')}');

    // Get The Beatles' top tracks in the US market
    final topTracks =
        await spotifyService.getTopTracks('3WrFJ7ztbogyGnThbHJFl2');
    print('Top tracks: ${topTracks.map((track) => track.name).join(', ')}');

    // Get The Beatles' top albums in the US market
    final topAlbums =
        await spotifyService.getTopAlbums('3WrFJ7ztbogyGnThbHJFl2');
    print('Top albums: ${topAlbums.map((album) => album.name).join(', ')}');

    // Get The Beatles' top singles in the US market
    final topSingles =
        await spotifyService.getTopSingles('3WrFJ7ztbogyGnThbHJFl2');
    print('Top singles: ${topSingles.map((album) => album.name).join(', ')}');

    // Get the user's playlists
    final userPlaylists = await spotifyService.getUserPlaylists();
    print(
        'User playlists: ${userPlaylists.map((playlist) => playlist.name).join(', ')}');
  }
}
