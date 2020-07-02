
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
  static const kDefaultColorValue = 0xffbdbdbd;

  int id;
  String description;
  int colorValue;

  Label(this.description, {this.id, this.colorValue=kDefaultColorValue});

  factory Label.fromData(int id, String description, String color) {
    //backward compatibility
    color = color.contains('0x') ? color.substring(2) : color;
    var value = int.parse(color, radix: 16);
    return Label(description, id: id, colorValue: value);
  }


  Map<String, dynamic> toMap({bool includeId=true}) {
    Map<String, dynamic> map = {
      if (includeId) 'id' : id,
      'description' : description,
      'color' : colorValue.toRadixString(16),
    };

    map.removeWhere((key, value) => value == null);

    return map;
  }

  String get colorString {
    return this.colorValue.toRadixString(16);
  }
}

