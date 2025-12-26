import 'package:hive/hive.dart';

part 'frequent_note.g.dart';

@HiveType(typeId: 2)
class FrequentNote extends HiveObject {
  @HiveField(0)
  String note;

  @HiveField(1)
  String category;

  @HiveField(2)
  int count;

  @HiveField(3)
  DateTime lastUsed;

  FrequentNote({
    required this.note,
    required this.category,
    this.count = 1,
    DateTime? lastUsed,
  }) : lastUsed = lastUsed ?? DateTime.now();
}