import 'package:carbohydrate_calculator/app_state.dart';
import 'package:carbohydrate_calculator/data.dart';
import 'package:carbohydrate_calculator/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  String filter = "";
  bool favoritesOnly = false;

  Widget buildMealRow(
      BuildContext context, AppState appState, Meal meal, int idx) {
    onPressed() {
      appState.viewState = ViewState.mealView;
      appState.mealEditState = MealEditState.fromMeal(meal);
    }

    //TODO name and mark favorite
    return Container(
        color: idx % 2 == 0 ? Theme.of(context).hoverColor : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            expandedWithPadding(
                child: TextButton(
                    onPressed: onPressed,
                    child: textView(emptyStrToDash(meal.name)))),
            expandedWithPadding(
                child: TextButton(
                    onPressed: onPressed,
                    child: textView(emptyStrToDash(meal.dateFormatted())))),
            expandedWithPadding(
                child: Checkbox(
                    value: meal.isFavorite,
                    onChanged: (value) {
                      FocusScope.of(context).unfocus();
                      if (value == null) {
                        return;
                      }

                      var newMeal = meal.clone();
                      newMeal.isFavorite = value;

                      appState.saveMeal(newMeal);
                    }))
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    AppState appState = context.watch();

    var meals = appState.mealsSortedByDate
      .where((element) => !favoritesOnly || element.isFavorite)
      .where((element) => element.name.toLowerCase().contains(filter.toLowerCase()));

    List<Widget> mealRows = [];

    for (var (i, m) in meals.indexed) {
      mealRows.add(buildMealRow(context, appState, m, i));
    }

    List<Widget> filter_container = appState.mealsSortedByDate.isEmpty ? [] : [
      FilterContainer(onFilterChange: (newValue) => setState(() {
        filter = newValue;
      }), onFavoritesOnlyChange: (newValue) => setState(() {
        favoritesOnly = newValue;
      }))
    ];

    // TODO: implement build
    return Column(children: filter_container + [
      Row(
        children: [
          expandedWithPadding(
              child: heading("Naam", textAlign: TextAlign.center)),
          expandedWithPadding(
              child: heading("Datum", textAlign: TextAlign.center)),
          expandedWithPadding(
              child: heading("Favoriet", textAlign: TextAlign.center))
        ],
      ),
      expandedWithPadding(
          child: ListView(
        children: mealRows,
      ))
    ]);
  }
}
