import 'dart:convert';

import 'package:dart_spotify_api/models/image_model.dart';
import 'package:dart_spotify_api/models/track_model.dart';
import 'package:dart_spotify_api/models/user_model.dart';

class SimplifiedPlaylist {
  final String id;
  final List<ImageModel> images;
  final UserModel owner;
  final bool public;
  final String snapshotId;
  final int totalTracks;
  final bool collaborative;
  final String? description;

  SimplifiedPlaylist({
    required this.id,
    required this.images,
    required this.owner,
    required this.public,
    required this.snapshotId,
    required this.totalTracks,
    required this.collaborative,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'images': images.map((x) => x.toMap()).toList(),
      'owner': owner.toMap(),
      'public': public,
      'snapshot_id': snapshotId,
      'total_tracks': totalTracks,
      'collaborative': collaborative,
      'description': description,
    };
  }

  factory SimplifiedPlaylist.fromMap(Map<String, dynamic> map) {
    return SimplifiedPlaylist(
      id: map['id'] as String,
      images: List<ImageModel>.from(
        (map['images']).map<ImageModel>(
          (x) => ImageModel.fromMap(x as Map<String, dynamic>),
        ),
      ),
      owner: UserModel.fromMap(map['owner'] as Map<String, dynamic>),
      public: map['public'] as bool? ?? true,
      snapshotId: map['snapshot_id'] as String,
      totalTracks: map['tracks']['total'] as int,
      collaborative: map['collaborative'] as bool,
      description: map['description'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory SimplifiedPlaylist.fromJson(String source) =>
      SimplifiedPlaylist.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'SimplifiedPlaylist(id: $id, images: $images, owner: $owner, public: $public, snapshotId: $snapshotId, totalTracks: $totalTracks, collaborative: $collaborative, description: $description)';
  }
}

class PlaylistModel {
  final String id;
  final String name;
  final bool collaborative;
  final List<ImageModel> images;
  final UserModel owner;
  final bool public;
  final String snapshotId;
  final List<TrackModel> tracks;

  PlaylistModel({
    required this.id,
    required this.name,
    required this.collaborative,
    required this.images,
    required this.owner,
    required this.public,
    required this.snapshotId,
    required this.tracks,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'collaborative': collaborative,
      'images': images.map((x) => x.toMap()).toList(),
      'owner': owner.toMap(),
      'public': public,
      'snapshot_id': snapshotId,
      'tracks': tracks.map((x) => x.toMap()).toList(),
    };
  }

  factory PlaylistModel.fromMap(Map<String, dynamic> map) {
    return PlaylistModel(
      id: map['id'] as String,
      name: map['name'] as String,
      collaborative: map['collaborative'] as bool,
      images: List<ImageModel>.from(
        (map['images']).map(
          (x) => ImageModel.fromMap(x as Map<String, dynamic>),
        ),
      ),
      owner: UserModel.fromMap(map['owner'] as Map<String, dynamic>),
      public: map['public'] as bool? ?? true,
      snapshotId: map['snapshot_id'] as String,
      tracks: List<TrackModel>.from(
        (map['tracks']['items'] as List).map(
          (x) {
            try {
              return TrackModel.fromMap(x['track'] as Map<String, dynamic>);
            } catch (e) {
              return null;
            }
          },
        ).whereType<TrackModel>(),
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory PlaylistModel.fromJson(String source) =>
      PlaylistModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'PlaylistModel(id: $id, name: $name, collaborative: $collaborative, images: $images, owner: $owner, public: $public, snapshotId: $snapshotId, tracks: $tracks)';
  }
}
