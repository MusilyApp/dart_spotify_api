import 'dart:convert';

import 'package:dart_spotify_api/models/image_model.dart';

class SimplifiedArtist {
  final String id;
  String name;

  SimplifiedArtist({
    required this.id,
    required this.name,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
    };
  }

  factory SimplifiedArtist.fromMap(Map<String, dynamic> map) {
    return SimplifiedArtist(
      id: map['id'] as String,
      name: map['name'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory SimplifiedArtist.fromJson(String source) =>
      SimplifiedArtist.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'SimplifiedArtist(id: $id, name: $name)';
}

class Artist {
  final String id;
  final String name;
  final List<ImageModel> images;
  final int popularity;

  Artist({
    required this.id,
    required this.name,
    required this.images,
    required this.popularity,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'images': images.map((x) => x.toMap()).toList(),
      'popularity': popularity,
    };
  }

  factory Artist.fromMap(Map<String, dynamic> map) {
    return Artist(
      id: map['id'] as String,
      name: map['name'] as String,
      images: List<ImageModel>.from(
        (map['images'] as List).map<ImageModel>(
          (x) => ImageModel.fromMap(x as Map<String, dynamic>),
        ),
      ),
      popularity: map['popularity'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory Artist.fromJson(String source) =>
      Artist.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Artist(id: $id, name: $name, images: $images, popularity: $popularity)';
  }
}
