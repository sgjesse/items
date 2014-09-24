library model;

import 'package:cloud_datastore/cloud_datastore.dart';

@ModelMetadata(const ItemsRootDescription())
class ItemsRoot extends Model { }

class ItemsRootDescription extends ModelDescription {
  final id = const IntProperty();

  const ItemsRootDescription() : super('ItemsRoot');
}

@ModelMetadata(const ItemDescription())
class Item extends Model {
  String name;
  
  validate() {
    if (name.length == 0) return "Name cannot be empty";
    if (name.length < 3) return "Name cannot be short";
  }
  
  Map serialize() => {'name': name};
  static Item deserialize(json) => new Item()..name = json['name'];
}

class ItemDescription extends ModelDescription {
  final id = const IntProperty();
  final name = const StringProperty();

  const ItemDescription() : super('Item');
}
