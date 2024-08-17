## Spotify API Dart Client

This repository provides a Dart client for the Spotify API, allowing you to interact with its features.

### Installation

#### 1. Using `flutter pub` (for Flutter projects)

```bash
flutter pub add dart_spotify_api
```

#### 2. Using `dart pub` (for general Dart projects)

```bash
dart pub add dart_spotify_api
```

#### 3. Modifying `pubspec.yaml`

Add the following line to your `pubspec.yaml` file under the `dependencies` section:

```yaml
dependencies:
  dart_spotify_api: ^1.1.0
```

Then, run `flutter pub get` (for Flutter projects) or `dart pub get` (for general Dart projects) to install the package.

#### Android

On Android you must first set the *minSdkVersion* in the *build.gradle* file:
```
  defaultConfig {
    ...
    minSdkVersion 18
    ...
  }
```

Add the following code to your `AndroidManifest.xml` file:

```xml
    <activity android:name="com.linusu.flutter_web_auth_2.CallbackActivity" android:exported="true">
      <intent-filter android:label="flutter_web_auth_2">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="custom-scheme" /> <!-- This must correspond to the custom scheme used for instantiatng the client... See below -->
      </intent-filter>
    </activity>
```

#### iOS

On iOS you need to set the *platform* in the *ios/Podfile* file:
```
platform :ios, '11.0'
```

#### Web

Web support has been added in the 2.2.0 version, and should be considered preliminary.

On the web platform you **must** register your application using an **HTTPS** redirect uri.

When the authorization code flow is used, the authorization phase will be carried out by opening a popup window to the provider login page.

After the user grants access to your application, the server will redirect the browser to the redirect uri. This page should contain some javascript code to read the _code_ parameter sent by the authorization server and pass it to the parent window through postMessage.

Something like:

```javascript
window.onload = function() {
	const urlParams = new URLSearchParams(window.location.search);
	const code = urlParams.get('code');
	if(code) {
		window.opener.postMessage(window.location.href, _url_of_the_opener_window_);
	}
}
```

**Please note** that the browser can't *securely* store confidential information! The OAuth2Helper class, when used on the web, stores the tokens in the localStorage, and this means they won't be encrypted!

See [oauth2_client](https://github.com/teranetsrl/oauth2_client/) for more information.

#### Linux

- Install the `libsecret-1-dev` dependency:
```bash
sudo apt-get install libsecret-1-dev
```

#### Linux/Windows:

   - Define a local port for the web server:

     ```dart
      final spotifyService = SpotifyService(
        // Other properties
        localhostPort: 8080, // Set the local port for Linux/Windows
      );
     ```

   - Add the URL `http://localhost:{port}` to your app's URLs in the Spotify dashboard.

### Usage

Here's a basic example of how to use the Spotify API in Dart:

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
    // Do something
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
