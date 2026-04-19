import 'dart:typed_data';

class PickedFilePayload {
  PickedFilePayload({
    required this.name,
    required this.bytes,
    required this.contentType,
  });

  final String name;
  final Uint8List bytes;
  final String contentType;

  factory PickedFilePayload.fromPicked({
    required String name,
    required Uint8List bytes,
  }) {
    return PickedFilePayload(
      name: name,
      bytes: bytes,
      contentType: _resolveContentType(name),
    );
  }

  static String _resolveContentType(String fileName) {
    final ext = fileName.toLowerCase().split('.').last;
    return switch (ext) {
      'pdf'             => 'application/pdf',
      'png'             => 'image/png',
      'webp'            => 'image/webp',
      'jpg' || 'jpeg'   => 'image/jpeg',
      _                 => 'application/octet-stream',
    };
  }
}