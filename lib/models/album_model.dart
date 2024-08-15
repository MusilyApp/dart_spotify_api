import 'dart:convert';

import 'package:dart_spotify_api/enums/market.dart';
import 'package:dart_spotify_api/models/artist_model.dart';
import 'package:dart_spotify_api/models/image_model.dart';

enum AlbumType {
  album,
  single,
  compilation,
}

class SimplifiedAlbum {
  final String id;
  final String name;
  final int totalTracks;
  final List<Market> availableMarkets;
  final List<ImageModel> images;
  final List<SimplifiedArtist> artists;

  SimplifiedAlbum({
    required this.id,
    required this.name,
    required this.totalTracks,
    required this.availableMarkets,
    required this.images,
    required this.artists,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'total_tracks': totalTracks,
      'available_markets': availableMarkets.map((x) => x.name).toList(),
      'images': images.map((x) => x.toMap()).toList(),
      'artists': artists.map((x) => x.toMap()).toList(),
    };
  }

  factory SimplifiedAlbum.fromMap(Map<String, dynamic> map) {
    return SimplifiedAlbum(
      id: map['id'] as String,
      name: map['name'] as String,
      totalTracks: map['total_tracks'] as int,
      availableMarkets: List<Market>.from(
        (map['available_markets'] as List).map<Market>(
          (x) => Market.values.byName(x),
        ),
      ),
      images: List<ImageModel>.from(
        (map['images'] as List).map<ImageModel>(
          (x) => ImageModel.fromMap(x),
        ),
      ),
      artists: List<SimplifiedArtist>.from(
        (map['artists'] as List).map<SimplifiedArtist>(
          (x) => SimplifiedArtist.fromMap(x),
        ),
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory SimplifiedAlbum.fromJson(String source) =>
      SimplifiedAlbum.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'SimplifiedAlbum(id: $id, name: $name, totalTracks: $totalTracks, availableMarkets: $availableMarkets, images: $images, artists: $artists)';
  }
}

class AlbumModel {
  final String id;
  final String name;
  final int totalTracks;
  final List<ImageModel> images;
  final DateTime releaseDate;
  final List<SimplifiedArtist> artists;
  final List<String> genres;
  final int popularity;

  AlbumModel({
    required this.id,
    required this.name,
    required this.totalTracks,
    required this.images,
    required this.releaseDate,
    required this.artists,
    required this.genres,
    required this.popularity,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'total_tracks': totalTracks,
      'images': images.map((x) => x.toMap()).toList(),
      'release_date': releaseDate.millisecondsSinceEpoch,
      'artists': artists.map((x) => x.toMap()).toList(),
      'genres': genres,
      'popularity': popularity,
    };
  }

  factory AlbumModel.fromMap(Map<String, dynamic> map) {
    return AlbumModel(
      id: map['id'] as String,
      name: map['name'] as String,
      totalTracks: map['total_tracks'] as int,
      images: List<ImageModel>.from(
        (map['images'] as List).map<ImageModel>(
          (x) => ImageModel.fromMap(x),
        ),
      ),
      releaseDate:
          DateTime.tryParse(map['release_date'] as String) ?? DateTime.now(),
      artists: List<SimplifiedArtist>.from(
        (map['artists'] as List).map<SimplifiedArtist>(
          (x) => SimplifiedArtist.fromMap(x),
        ),
      ),
      genres: List<String>.from(
        (map['genres'] as List),
      ),
      popularity: map['popularity'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory AlbumModel.fromJson(String source) =>
      AlbumModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'AlbumModel(id: $id, name: $name, totalTracks: $totalTracks, images: $images, releaseDate: $releaseDate, artists: $artists, genres: $genres, popularity: $popularity)';
  }
}
