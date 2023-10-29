// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Ingredient _$IngredientFromJson(Map<String, dynamic> json) => Ingredient(
      json['name'] as String?,
      (json['weightG'] as num?)?.toDouble(),
      (json['chPerHGram'] as num?)?.toDouble(),
      (json['totalCarbohydrates'] as num?)?.toDouble(),
    )..chPerGram = (json['chPerGram'] as num?)?.toDouble();

Map<String, dynamic> _$IngredientToJson(Ingredient instance) =>
    <String, dynamic>{
      'name': instance.name,
      'weightG': instance.weightG,
      'chPerHGram': instance.chPerHGram,
      'totalCarbohydrates': instance.totalCarbohydrates,
      'chPerGram': instance.chPerGram,
    };

FoodContainerWeight _$FoodContainerWeightFromJson(Map<String, dynamic> json) =>
    FoodContainerWeight(
      (json['weightG'] as num?)?.toDouble(),
      json['containerId'] as String?,
    );

Map<String, dynamic> _$FoodContainerWeightToJson(
        FoodContainerWeight instance) =>
    <String, dynamic>{
      'weightG': instance.weightG,
      'containerId': instance.containerId,
    };

MealPart _$MealPartFromJson(Map<String, dynamic> json) => MealPart(
      json['name'] as String?,
      FoodContainerWeight.fromJson(json['container'] as Map<String, dynamic>),
      (json['weightGTotal'] as num?)?.toDouble(),
      (json['ingredients'] as List<dynamic>)
          .map((e) => Ingredient.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$MealPartToJson(MealPart instance) => <String, dynamic>{
      'name': instance.name,
      'container': instance.container,
      'weightGTotal': instance.weightGTotal,
      'ingredients': instance.ingredients,
    };

Meal _$MealFromJson(Map<String, dynamic> json) => Meal(
      json['id'] as String,
      json['name'] as String,
      DateTime.parse(json['timestamp'] as String),
      json['isFavorite'] as bool,
      (json['parts'] as List<dynamic>)
          .map((e) => MealPart.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$MealToJson(Meal instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'timestamp': instance.timestamp.toIso8601String(),
      'isFavorite': instance.isFavorite,
      'parts': instance.parts,
    };

MealEditState _$MealEditStateFromJson(Map<String, dynamic> json) =>
    MealEditState(
      id: json['id'] as String,
      name: json['name'] as String?,
      isFavorite: json['isFavorite'] as bool? ?? false,
      parts: (json['parts'] as List<dynamic>)
          .map((e) => MealPart.fromJson(e as Map<String, dynamic>))
          .toList(),
      inCalculator: json['inCalculator'] as bool? ?? false,
    );

Map<String, dynamic> _$MealEditStateToJson(MealEditState instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'isFavorite': instance.isFavorite,
      'parts': instance.parts,
      'inCalculator': instance.inCalculator,
    };

ChCalculationState _$ChCalculationStateFromJson(Map<String, dynamic> json) =>
    ChCalculationState()
      ..mealPartIdxs =
          (json['mealPartIdxs'] as List<dynamic>).map((e) => e as int).toList()
      ..weights = (json['weights'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList();

Map<String, dynamic> _$ChCalculationStateToJson(ChCalculationState instance) =>
    <String, dynamic>{
      'mealPartIdxs': instance.mealPartIdxs,
      'weights': instance.weights,
    };
