// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Note.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NoteAdapter extends TypeAdapter<Note> {
  @override
  final int typeId = 1;

  @override
  Note read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Note(
      id: fields[0] as String,
      title: fields[2] as String,
      content: fields[3] as String,
      createdAt: fields[1] as String,
      isShareable: fields[7] == null ? false : fields[7] as bool,
      source: fields[4] as String,
      isDeleted: fields[6] as bool,
      sourceTitle: fields[9] as String?,
      sourceDescription: fields[10] as String?,
      sourceImageUrl: fields[12] as String?,
    )..modifiedAt = fields[8] == null ? '2000-01-01' : fields[8] as String;
  }

  @override
  void write(BinaryWriter writer, Note obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.createdAt)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.content)
      ..writeByte(4)
      ..write(obj.source)
      ..writeByte(6)
      ..write(obj.isDeleted)
      ..writeByte(7)
      ..write(obj.isShareable)
      ..writeByte(8)
      ..write(obj.modifiedAt)
      ..writeByte(9)
      ..write(obj.sourceTitle)
      ..writeByte(10)
      ..write(obj.sourceDescription)
      ..writeByte(12)
      ..write(obj.sourceImageUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
