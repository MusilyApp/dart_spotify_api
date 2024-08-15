import 'dart:convert';

import 'package:dart_spotify_api/enums/market.dart';
import 'package:dart_spotify_api/models/album_model.dart';
import 'package:dart_spotify_api/models/artist_model.dart';

class SimplifiedTrack {
  final String id;
  final String name;
  final List<SimplifiedArtist> artists;
  final Duration duration;
  final bool explicit;
  final List<Market> availableMarkets;
  final bool isPlayable;
  final String? previewUrl;
  final int trackNumber;

  SimplifiedTrack({
    required this.id,
    required this.name,
    required this.artists,
    required this.duration,
    required this.explicit,
    required this.availableMarkets,
    required this.isPlayable,
    required this.previewUrl,
    required this.trackNumber,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'artists': artists.map((x) => x.toMap()).toList(),
      'duration': duration.inMilliseconds,
      'explicit': explicit,
      'availableMarkets': availableMarkets.map((x) => x.name).toList(),
      'isPlayable': isPlayable,
      'previewUrl': previewUrl,
      'trackNumber': trackNumber,
    };
  }

  factory SimplifiedTrack.fromMap(Map<String, dynamic> map) {
    return SimplifiedTrack(
      id: map['id'] as String,
      name: map['name'] as String,
      artists: List<SimplifiedArtist>.from(
        (map['artists'] as List<int>).map<SimplifiedArtist>(
          (x) => SimplifiedArtist.fromMap(x as Map<String, dynamic>),
        ),
      ),
      duration: Duration(
        milliseconds: map['duration_ms'],
      ),
      explicit: map['explicit'] as bool,
      availableMarkets: List<Market>.from(
        (map['available_markets'] as List<String>).map<Market>(
          (x) => Market.values.byName(x),
        ),
      ),
      isPlayable: map['is_playable'] as bool,
      previewUrl:
          map['preview_url'] != null ? map['preview_url'] as String : null,
      trackNumber: map['track_number'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory SimplifiedTrack.fromJson(String source) =>
      SimplifiedTrack.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'SimplifiedTrack(id: $id, name: $name, artists: $artists, duration: $duration, explicit: $explicit, availableMarkets: $availableMarkets, isPlayable: $isPlayable, previewUrl: $previewUrl, trackNumber: $trackNumber)';
  }
}

class TrackModel {
  final String id;
  final String name;
  final SimplifiedAlbum album;
  final List<SimplifiedArtist> artists;
  final List<Market> availableMarkets;
  final int discNumber;
  final Duration duration;
  final bool explicit;
  final bool isPlayable;
  final int popularity;
  final String? previewUrl;
  final int trackNumber;

  TrackModel(
      {required this.id,
      required this.name,
      required this.album,
      required this.artists,
      required this.availableMarkets,
      required this.discNumber,
      required this.duration,
      required this.explicit,
      required this.isPlayable,
      required this.popularity,
      required this.previewUrl,
      required this.trackNumber});

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'album': album.toMap(),
      'artists': artists.map((x) => x.toMap()).toList(),
      'available_markets': availableMarkets.map((x) => x.name).toList(),
      'disc_number': discNumber,
      'duration': duration.inMilliseconds,
      'explicit': explicit,
      'is_playable': isPlayable,
      'popularity': popularity,
      'preview_url': previewUrl,
      'track_number': trackNumber,
    };
  }

  factory TrackModel.fromMap(Map<String, dynamic> map) {
    return TrackModel(
      id: map['id'] as String,
      name: map['name'] as String,
      album: SimplifiedAlbum.fromMap(map['album'] as Map<String, dynamic>),
      artists: List<SimplifiedArtist>.from(
        (map['artists']).map<SimplifiedArtist>(
          (x) => SimplifiedArtist.fromMap(x as Map<String, dynamic>),
        ),
      ),
      availableMarkets: List<Market>.from(
        (map['available_markets']).map<Market>(
          (x) => Market.values.byName(x),
        ),
      ),
      discNumber: map['disc_number'] as int,
      duration: Duration(milliseconds: map['duration_ms']),
      explicit: map['explicit'] as bool,
      isPlayable: map['is_playable'] as bool? ?? true,
      popularity: map['popularity'] as int,
      previewUrl:
          map['preview_url'] != null ? map['preview_url'] as String : null,
      trackNumber: map['track_number'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory TrackModel.fromJson(String source) =>
      TrackModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'TrackModel(id: $id, name: $name, album: $album, artists: $artists, availableMarkets: $availableMarkets, discNumber: $discNumber, duration: $duration, explicit: $explicit, isPlayable: $isPlayable, popularity: $popularity, previewUrl: $previewUrl, trackNumber: $trackNumber)';
  }
}
