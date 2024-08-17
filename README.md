## Spotify API Dart Client

This repository provides a comprehensive Dart client for the Spotify API, empowering you to seamlessly interact with its various features.

### Installation

#### Using `flutter pub` (for Flutter projects)

```bash
flutter pub add dart_spotify_api
```

#### Using `dart pub` (for general Dart projects)

```bash
dart pub add dart_spotify_api
```

#### Modifying `pubspec.yaml`

Add the following line to your `pubspec.yaml` file under the `dependencies` section:

```yaml
dependencies:
  dart_spotify_api: ^1.1.0
```

Then, run `flutter pub get` (for Flutter projects) or `dart pub get` (for general Dart projects) to install the package.

#### Platform-Specific Configuration

**Android**

- **Minimum SDK Version:** Set the `minSdkVersion` in your `build.gradle` file to at least 18.
- **AndroidManifest.xml:** Add the following code within your `AndroidManifest.xml` file:

```xml
<activity android:name="com.linusu.flutter_web_auth_2.CallbackActivity" android:exported="true">
  <intent-filter android:label="flutter_web_auth_2">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="custom-scheme" /> <!-- This must correspond to the custom scheme used for instantiating the client. See below. -->
  </intent-filter>
</activity>
```

**iOS**

- **Podfile:** Set the `platform` in your `ios/Podfile` file to `platform :ios, '11.0'`.

**Web**

- Web support is available starting from version 2.2.0. It's considered preliminary but functional.
- **HTTPS Redirect URI:** You **must** register your application using an **HTTPS** redirect URI.
- **JavaScript for Code Retrieval:** The authorization code flow involves opening a popup window. After the user grants access, the server redirects the browser to your redirect URI. This page should include JavaScript code to retrieve the `code` parameter from the URL and pass it to the parent window using `postMessage`. Here's an example:

```javascript
window.onload = function() {
  const urlParams = new URLSearchParams(window.location.search);
  const code = urlParams.get('code');
  if (code) {
    window.opener.postMessage(window.location.href, '_url_of_the_opener_window_');
  }
};
```

**Important Note:** The browser cannot securely store confidential information. When using the OAuth2Helper class on the web, tokens are stored in `localStorage`, which means they are not encrypted.

###### Refer to the [oauth2_client](https://github.com/teranetsrl/oauth2_client/) documentation for more detailed information regarding the installation instructions above.
---
#### Linux

- Install the `libsecret-1-dev` dependency:

```bash
sudo apt-get install libsecret-1-dev
```

#### Linux/Windows:

- **Local Port:** Define a local port for the web server when using this library on Linux/Windows:

  ```dart
  final spotifyService = SpotifyService(
    // Other properties
    localhostPort: 8080, // Set the local port for Linux/Windows
  );
  ```

   - Add the URL `http://localhost:{port}` to your app's URLs in the Spotify dashboard.

### Usage

This section provides basic examples to get you started with the Spotify API in Dart.

```dart
import 'package:dart_spotify_api/dart_spotify_api.dart';

void main() async {
  // Create an instance of the Spotify Service
  final spotifyService = SpotifyService(
    clientId: 'YOUR_CLIENT_ID', // Replace with your client ID
    clientSecret: 'YOUR_CLIENT_SECRET', // Replace with your client secret
    customUriScheme: 'custom-scheme', // Choose a custom scheme for your app
    redirectUri: 'your-app-redirect-uri', // App's redirect URI
    localhostPort: 8080, // Set the local port for Linux/Windows, if applicable
  );

  // Initialize the service
  await spotifyService.initialize();

  // Login
  await spotifyService.login();

  // Check if the user is logged in
  if (spotifyService.loggedIn) {
    // Perform actions after successful login
  }
}
```

**Get user information:**

```dart
final user = await spotifyService.getUser();
print('User name: ${user?.displayName}');
```

**Perform a search:**

```dart
final searchResults = await spotifyService.search(
  'The Beatles',
  type: [SearchType.artist, SearchType.album],
);
print('Search results: $searchResults');
```

**Get an album:**

```dart
final album = await spotifyService.getAlbum('album_id');
print('Album name: ${album?.name}');
```

**Get a track:**

```dart
final track = await spotifyService.getTrack('track_id');
print('Track name: ${track?.name}');
```

**Get an artist:**

```dart
final artist = await spotifyService.getArtist('artist_id');
print('Artist name: ${artist?.name}');
```

**Get a playlist:**

```dart
final playlist = await spotifyService.getPlaylist('playlist_id');
print('Playlist name: ${playlist?.name}');
```

**Get similar artists:**

```dart
final similarArtists = await spotifyService.getSimilarArtists('artist_id');
print('Similar artists: ${similarArtists.map((artist) => artist.name).join(', ')}');
```

**Get album tracks:**

```dart
final albumTracks = await spotifyService.getAlbumTracks('album_id');
print('Album tracks: ${albumTracks.map((track) => track.name).join(', ')}');
```

**Get an artist's top tracks:**

```dart
final topTracks = await spotifyService.getTopTracks('artist_id');
print('Top tracks: ${topTracks.map((track) => track.name).join(', ')}');
```

**Get an artist's top albums:**

```dart
final topAlbums = await spotifyService.getTopAlbums('artist_id');
print('Top albums: ${topAlbums.map((album) => album.name).join(', ')}');
```

**Get an artist's top singles:**

```dart
final topSingles = await spotifyService.getTopSingles('artist_id');
print('Top singles: ${topSingles.map((album) => album.name).join(', ')}');
```

**Get user playlists:**

```dart
final userPlaylists = await spotifyService.getUserPlaylists();
print('User playlists: ${userPlaylists.map((playlist) => playlist.name).join(', ')}');
```

### API Documentation

You can find the full Spotify API documentation [here](https://developer.spotify.com/documentation/web-api/).

### Contributions

Contributions are welcome! If you want to contribute to this project, please follow these steps:

1. **Fork this repository.**
2. **Create a new branch for your modification.**
3. **Make your changes and submit a pull request.**

### License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
