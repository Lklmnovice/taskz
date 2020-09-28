/// Label data class
///
/// ```sql
/// CREATE TABLE "Tag" (
///	"id"	INTEGER PRIMARY KEY AUTOINCREMENT,
///	"description"	TEXT NOT NULL UNIQUE,
///	"color"	TEXT NOT NULL DEFAULT '0xffbdbdbd'
///)
///```
class Label {
  Label(this.description, {this.id, this.colorValue = kDefaultColor});

  factory Label.fromData(int id, String description, String color) {
    //backward compatibility
    color = color.contains('0x') ? color.substring(2) : color;
    var value = int.parse(color, radix: 16);
    return Label(description, id: id, colorValue: value);
  }

  static const kDefaultColor = 0xffbdbdbd;
  static const TABLE = 'Tag';
  static const cId = 'id';
  static const cDescription = 'description';
  static const cColor = 'color';

  int id;
  String description;
  int colorValue;

  Map<String, dynamic> toMap({bool includeId = true}) {
    Map<String, dynamic> map = {
      if (includeId) 'id': id,
      'description': description,
      'color': colorValue.toRadixString(16),
    };

    map.removeWhere((key, value) => value == null);

    return map;
  }

  String get colorString {
    return this.colorValue.toRadixString(16);
  }
}
