import '../../domain/entities/category.dart';
import '../models/category_model.dart';

class CategoryMapper {
  static Category toEntity(CategoryModel model) {
    return Category(
      id: model.id,
      name: model.name,
      parentId: model.parentId,
      parentName: model.parentName,
    );
  }
}

