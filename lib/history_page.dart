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
  CompareBy sortBy = CompareBy.name;
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
        .where((element) =>
            element.name.toLowerCase().contains(filter.toLowerCase()))
        .toList();

    meals.sort((m1, m2) => sortBy.compareMeals(m1, m2));

    List<Widget> mealRows = [];

    for (var (i, m) in meals.indexed) {
      mealRows.add(buildMealRow(context, appState, m, i));
    }

    List<Widget> filterContainer = appState.mealsSortedByDate.isEmpty
        ? []
        : [
            FilterContainer(
                onFilterChange: (newValue) => setState(() {
                      filter = newValue;
                    }),
                onFavoritesOnlyChange: (newValue) => setState(() {
                      favoritesOnly = newValue;
                    }))
          ];

    var textSz = defaultFontSize * 1.3;

    // TODO: implement build
    return Column(
        children: filterContainer +
            [
              Row(
                children: [
                  expandedWithPadding(
                      child: GestureDetector(
                          onTap: () => setState(() {
                                sortBy = CompareBy.name;
                              }),
                          child: textView("Naam",
                              textAlign: TextAlign.center,
                              size: textSz,
                              bold: sortBy == CompareBy.name))),
                  expandedWithPadding(
                      child: GestureDetector(
                          onTap: () => setState(() {
                                sortBy = CompareBy.date;
                              }),
                          child: textView("Datum",
                              textAlign: TextAlign.center,
                              size: textSz,
                              bold: sortBy == CompareBy.date))),
                  expandedWithPadding(
                      child: textView("Favoriet",
                          textAlign: TextAlign.center, size: textSz))
                ],
              ),
              expandedWithPadding(
                  child: ListView(
                children: mealRows,
              ))
            ]);
  }
}
