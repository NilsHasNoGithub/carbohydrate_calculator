import 'dart:convert';

import 'package:carbohydrate_calculator/data.dart';
import 'package:carbohydrate_calculator/utils.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const mealSettingPrefix = "meal-";
const mealCalcStateSettingPrefix = "mealCalcState-";
const mealEditStateKey = "mealEditState";

const mealIdLength = 25;

enum ViewState {
  favoritesView,
  historyView,
  mealView,
}

const defaultViewState = ViewState.historyView;

class AppState extends ChangeNotifier {
  bool initialized = false;
  ViewState _viewState = ViewState.historyView;
  MealEditState? _mealEditState;

  Map<String, Meal> meals = {};
  List<String> _mealsIdsSortedByDate = [];
  List<String> _favoriteIds = [];

  Map<String, ChCalculationState> calculationStates = {};

  List<Meal> get mealsSortedByDate {
    return _mealsIdsSortedByDate.map((k) => meals[k]!).toList();
  }

  List<Meal> get favoriteMeals {
    return _favoriteIds.map((k) => meals[k]!).toList();
  }

  set mealEditState(MealEditState? mealEditState) {
    _mealEditState = mealEditState;
    saveMealEditState();
    notifyListeners();
  }

  MealEditState? get mealEditState {
    return _mealEditState;
  }

  Future<void> setMealEditStateNoUpdate(MealEditState? mealEditState) async {
    _mealEditState = mealEditState;
    await saveMealEditState();
  }

  set viewState(ViewState viewState) {
    _viewState = viewState;
    notifyListeners();
  }

  ViewState get viewState {
    return _viewState;
  }

  Future<void> saveMealEditState() async {
    final prefs = await SharedPreferences.getInstance();

    var mesCopy = mealEditState;

    if (mesCopy == null) {
      await prefs.remove(mealEditStateKey);
    } else {
      var jsonString = jsonEncode(mesCopy.toJson());
      await prefs.setString(mealEditStateKey, jsonString);
    }
  }

  String generateNewMealId() {
    assert(initialized);

    var candidate = generateRandomIdentifier(mealIdLength);
    while (meals.containsKey(candidate)) {
      candidate = generateRandomIdentifier(mealIdLength);
    }

    return candidate;
  }

  void _updateMealMetaInfo() {
    var mealVals = meals.values.toList();
    mealVals.sort((m1, m2) => m2.timestamp.compareTo(m1.timestamp));

    _mealsIdsSortedByDate = mealVals.map((m) => m.id).toList();

    _favoriteIds =
        mealVals.where((m) => m.isFavorite).map((m) => m.id).toList();
  }

  void _finalizeUpdate(bool notify) {
    _updateMealMetaInfo();
    if (notify) notifyListeners();
  }

  String _mkMealCalcStateSettingStr(String mealId) {
    return "$mealCalcStateSettingPrefix$mealId";
  }

  Future<void> saveCalcStateOf(String mealId, ChCalculationState calcState,
      {bool notify = true}) async {
    calcState.removeEmpties();
    calculationStates[mealId] = calcState;

    if (notify) notifyListeners();

    var prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _mkMealCalcStateSettingStr(mealId), jsonEncode(calcState.toJson()));
  }

  Future<void> removeCalcStateOf(String mealId, {bool notify = true}) async {
    calculationStates.remove(mealId);

    if (notify) notifyListeners();

    var prefs = await SharedPreferences.getInstance();
    await prefs.remove(_mkMealCalcStateSettingStr(mealId));
  }

  String _mkMealSettingStr(String mealId) {
    return "$mealSettingPrefix$mealId";
  }

  Future<void> addMealEditState(MealEditState mes, {bool notify = true}) async {
    await saveMeal(mes.toMeal(), notify: notify);
  }

  Future<void> saveMeal(Meal meal, {bool notify = true}) async {
    var jsonString = jsonEncode(meal.toJson());
    meals[meal.id] = meal;
    _finalizeUpdate(notify);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_mkMealSettingStr(meal.id), jsonString);
  }

  Future<void> removeMeal(String mealId, {bool notify = true}) async {
    meals.remove(mealId);
    _finalizeUpdate(notify);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_mkMealSettingStr(mealId));
  }

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    // Load meals
    for (final k in prefs.getKeys()) {
      id() => k.split("-")[1];

      if (k.startsWith(mealSettingPrefix)) {
        meals[id()] = Meal.fromJson(jsonDecode(prefs.getString(k)!));
      } else if (k.startsWith(mealCalcStateSettingPrefix)) {
        calculationStates[id()] =
            ChCalculationState.fromJson(jsonDecode(prefs.getString(k)!));
      }
    }

    // Load view edit state
    var mesJsonString = prefs.getString(mealEditStateKey);

    if (mesJsonString != null) {
      var json = jsonDecode(mesJsonString);
      mealEditState = MealEditState.fromJson(json);
      viewState = ViewState.mealView;
    }

    // Finalize
    initialized = true;
    _finalizeUpdate(true);
  }

  Future<void> clearData({bool notify = true}) async {
    _viewState = defaultViewState;
    _mealEditState = null;
    meals.clear();

    _finalizeUpdate(notify);

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
