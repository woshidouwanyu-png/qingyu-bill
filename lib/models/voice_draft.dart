import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'voice_draft.g.dart';

@HiveType(typeId: 3)
class VoiceDraft extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String rawText;

  @HiveField(2)
  final DateTime timestamp;

  VoiceDraft({
    String? id,
    required this.rawText,
    DateTime? timestamp,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();
}