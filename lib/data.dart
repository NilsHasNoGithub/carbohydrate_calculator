import 'dart:convert';
import 'dart:io';

import 'package:carbohydrate_calculator/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:quiver/core.dart';

part 'data.g.dart';

bool? _baseEqual(o1, o2) {
  if (identical(o1, o2)) return true;
  if (o1.runtimeType != o2.runtimeType) return false;
  return null;
}

@JsonSerializable()
class Ingredient {
  String? name;
  double? weightG;
  double? chPerHGram;
  double? totalCarbohydrates;

  double? get chPerGram {
    if (chPerHGram == null) {
      return null;
    }

    return chPerHGram! / 100.0;
  }

  set chPerGram(double? value) {
    if (value == null) {
      chPerHGram = null;
      return;
    }

    chPerHGram = value * 100.0;
  }

  Ingredient(this.name, this.weightG, this.chPerHGram, this.totalCarbohydrates);

  Ingredient.empty()
      : name = null,
        weightG = null,
        chPerHGram = null,
        totalCarbohydrates = null;

  Ingredient clone() =>
      Ingredient(name, weightG, chPerHGram, totalCarbohydrates);

  @override
  bool operator ==(Object other) {
    bool? baseEq = _baseEqual(this, other);
    if (baseEq != null) return baseEq;
    var o = other as Ingredient;
    return name == o.name &&
        weightG == o.weightG &&
        chPerGram == o.chPerGram &&
        totalCarbohydrates == o.totalCarbohydrates;
  }

  @override
  int get hashCode => hash4(name, weightG, chPerGram, totalCarbohydrates);

  bool hasData() {
    return [name == "" ? null : name, weightG, chPerGram, totalCarbohydrates]
        .map((e) => e != null)
        .reduce((value, element) => value || element);
  }

  bool tryInferTotalCh() {
    if (weightG != null && chPerHGram != null) {
      totalCarbohydrates = chPerGram! * weightG!;
      return true;
    }
    return false;
  }

  bool tryInferWeight() {
    if (chPerHGram != null && totalCarbohydrates != null && chPerGram! != 0.0) {
      weightG = totalCarbohydrates! / chPerGram!;
      return true;
    }

    return false;
  }

  bool tryInferChPerGram() {
    if (weightG != null && totalCarbohydrates != null && weightG! != 0) {
      chPerGram = totalCarbohydrates! / weightG!;
      return true;
    }
    return false;
  }

  factory Ingredient.fromJson(Map<String, dynamic> json) =>
      _$IngredientFromJson(json);
  Map<String, dynamic> toJson() => _$IngredientToJson(this);
}

@JsonSerializable()
class FoodContainerWeight {
  double? weightG;
  String? containerId;

  FoodContainerWeight(this.weightG, this.containerId);

  FoodContainerWeight clone() => FoodContainerWeight(weightG, containerId);

  factory FoodContainerWeight.fromJson(Map<String, dynamic> json) =>
      _$FoodContainerWeightFromJson(json);
  Map<String, dynamic> toJson() => _$FoodContainerWeightToJson(this);

  @override
  bool operator ==(Object other) {
    bool? baseEq = _baseEqual(this, other);
    if (baseEq != null) return baseEq;
    var o = other as FoodContainerWeight;
    return o.weightG == weightG && o.containerId == containerId;
  }

  @override
  int get hashCode => hash2(weightG, containerId);
}

@JsonSerializable()
class MealPart {
  String? name;
  FoodContainerWeight container;
  double? weightGTotal; // Weight of meal part + container it is in
  List<Ingredient> ingredients;

  MealPart(this.name, this.container, this.weightGTotal, this.ingredients);

  MealPart clone() => MealPart(name, container.clone(), weightGTotal,
      ingredients.map((e) => e.clone()).toList());

  bool hasData() {
    return [name, container, weightGTotal]
            .map((e) => e != null)
            .reduce((value, element) => value || element) ||
        ingredients
            .map((e) => e.hasData())
            .reduce((value, element) => value || element);
  }

  @override
  int get hashCode =>
      hash4(name, container, weightGTotal, Object.hashAll(ingredients));

  @override
  bool operator ==(Object other) {
    bool? baseEq = _baseEqual(this, other);
    if (baseEq != null) return baseEq;
    var o = other as MealPart;
    return name == o.name &&
        container == o.container &&
        weightGTotal == o.weightGTotal &&
        listEquals(ingredients, o.ingredients);
  }

  void removeEmptyParts() {
    ingredients = ingredients.where((element) => element.hasData()).toList();
  }

  double? totalIngredientWeight() {
    if (weightGTotal == null || container.weightG == null) {
      return null;
    }

    return weightGTotal! - container.weightG!;
  }

  double? totalChPerG() {
    var contentWeight = totalIngredientWeight();

    if (contentWeight == null || contentWeight == 0.0) {
      return null;
    }

    var totalIngChs = [];

    for (var ing in ingredients) {
      ing.tryInferTotalCh();
      if (ing.totalCarbohydrates == null) {
        return null;
      }
      totalIngChs.add(ing.totalCarbohydrates);
    }

    double totalCh = totalIngChs.reduce((value, element) => value + element);
    return (totalCh / contentWeight);
  }

  double? totalChPer100G() {
    var result = totalChPerG();
    if (result == null) {
      return null;
    }
    return result * 100;
  }

  factory MealPart.fromJson(Map<String, dynamic> json) =>
      _$MealPartFromJson(json);
  Map<String, dynamic> toJson() => _$MealPartToJson(this);
}

@JsonSerializable()
class Meal {
  String id;
  String name;
  DateTime timestamp;
  bool isFavorite;
  List<MealPart> parts;

  Meal(this.id, this.name, this.timestamp, this.isFavorite, this.parts);

  @override
  bool operator ==(Object other) {
    bool? baseEq = _baseEqual(this, other);
    if (baseEq != null) return baseEq;
    var o = other as Meal;

    return o.id == id &&
        name == o.name &&
        timestamp == o.timestamp &&
        isFavorite == o.isFavorite &&
        listEquals(parts, o.parts);
  }

  @override
  int get hashCode =>
      hashObjects([id, name, timestamp, isFavorite, Object.hashAll(parts)]);

  Meal clone() => Meal(
      id, name, timestamp, isFavorite, parts.map((e) => e.clone()).toList());

  void resetTimestamp() {
    timestamp = DateTime.now();
  }

  String dateFormatted() {
    return DateFormat("dd/MM/yy").format(timestamp);
  }

  String toBase64() {
    var jsonString = jsonEncode(toJson());
    var encoded = compressStr(jsonString);
    return encoded;
  }

  factory Meal.fromBase64(String base64String) {
    var jsonString = decompressStr(base64String);
    var jsonMap = jsonDecode(jsonString);
    return Meal.fromJson(jsonMap);
  }

  factory Meal.fromJson(Map<String, dynamic> json) => _$MealFromJson(json);
  Map<String, dynamic> toJson() => _$MealToJson(this);
}

@JsonSerializable()
class MealEditState {
  String id;
  String? name;
  bool isFavorite = false;
  List<MealPart> parts;

  MealEditState({
    required this.id,
    this.name,
    this.isFavorite = false,
    required this.parts,
  });

  factory MealEditState.empty(String id) => MealEditState(id: id, parts: []);

  factory MealEditState.fromMeal(Meal meal) {
    var mealClone = meal.clone();

    return MealEditState(
        id: mealClone.id,
        name: mealClone.name,
        isFavorite: mealClone.isFavorite,
        parts: mealClone.parts);
  }

  @override
  bool operator ==(Object other) {
    bool? baseEq = _baseEqual(this, other);
    if (baseEq != null) return baseEq;
    var o = other as MealEditState;

    return o.id == id &&
        name == o.name &&
        isFavorite == o.isFavorite &&
        listEquals(parts, o.parts);
  }

  @override
  int get hashCode => hash4(id, name, isFavorite, Object.hashAll(parts));

  MealEditState clone() => MealEditState(
      id: id,
      name: name,
      isFavorite: isFavorite,
      parts: parts.map((e) => e.clone()).toList());

  // MealEditState.fromMeal(Meal meal) {
  //   return MealEditState(id: meal.id, name: meal.name, parts: meal.parts);
  // }

  Meal toMeal() {
    return Meal(id, name ?? "", DateTime.now(), isFavorite, parts);
  }

  bool hasData() {
    return name != null ||
        (parts.isNotEmpty &&
            !parts
                .map((e) => e.hasData())
                .reduce((value, element) => value || element));
  }

  void removeEmptyParts({bool alsoRemoveEmptyIngredients = true}) {
    parts = parts.where((element) => element.hasData()).toList();
    if (alsoRemoveEmptyIngredients) {
      for (var element in parts) {
        element.removeEmptyParts();
      }
    }
  }

  factory MealEditState.fromJson(Map<String, dynamic> json) =>
      _$MealEditStateFromJson(json);
  Map<String, dynamic> toJson() => _$MealEditStateToJson(this);
}




@JsonSerializable()
class ChCalculationState {
  List<int> mealPartIdxs = [];
  List<double> weights = [];

  ChCalculationState();

  double totalCarbohydratesG(Meal meal, {bool skipIncompleteParts = false}) {
    assert (mealPartIdxs.length == weights.length);

    var result = 0.0;

    for (var i=0;i<mealPartIdxs.length;i++) {
      var partIdx = mealPartIdxs[i];
      var weight = weights[i];

      var part = meal.parts[partIdx];
      var partChPerGram = part.totalChPerG();

      if (partChPerGram == null) {
        if (skipIncompleteParts) continue;
        throw Exception("Part of meal was not complete: $partIdx");
      }

      result += partChPerGram * weight;
    }

    return result;
  }

  void addPartAndWeight(int partIdx, double weight) {
    mealPartIdxs.add(partIdx);
    weights.add(weight);
  }

  void removePartAndWeightAt(int idx) {
    mealPartIdxs.removeAt(idx);
    weights.removeAt(idx);
  }

  factory ChCalculationState.fromJson(Map<String, dynamic> json) =>
      _$ChCalculationStateFromJson(json);
  Map<String, dynamic> toJson() => _$ChCalculationStateToJson(this);
}
