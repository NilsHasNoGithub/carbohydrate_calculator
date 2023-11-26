import 'dart:math';

import 'package:carbohydrate_calculator/app_state.dart';
import 'package:carbohydrate_calculator/data.dart';
import 'package:carbohydrate_calculator/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class IngredientPickerView extends StatefulWidget {
  final void Function(Ingredient) onPick;
  final void Function() onBack;

  const IngredientPickerView(
      {super.key, required this.onBack, required this.onPick});

  @override
  State<IngredientPickerView> createState() => _IngredientPickerViewState();
}

class _IngredientPickerViewState extends State<IngredientPickerView> {
  String filter = "";

  Widget buildIngredientRow(
      BuildContext context, AppState appState, Ingredient ingredient) {
    return TextButton(
        onPressed: () => widget.onPick(ingredient),
        child: Row(
          children: [
            expandedWithPadding(child: textView(ingredient.name ?? "-", textAlign: TextAlign.center)),
            expandedWithPadding(
                child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                textView(optFormatFloat(ingredient.chPerHGram), bold: true),
                textView("kh. /100g")
              ],
            ))
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    AppState appState = context.watch();

    var ingredients = uniqueBy(
        appState.meals.values
            .expand((element) => element.parts)
            .expand((element) => element.ingredients)
            .where((element) => element.chPerGram != null && element.name != null)
            .where((element) => (element.name!.toLowerCase()).contains(filter.toLowerCase())),
        (elem) => (elem.name, elem.chPerGram));

    ingredients.sort((i1, i2) => (i1.name!.toLowerCase()).compareTo(i2.name!.toLowerCase()));

    List<Widget> ingredientRows = [];

    for (var(idx, ingredient) in ingredients.indexed) {
      ingredientRows.add((
        Container(
          color: idx % 2 == 0 ? Theme.of(context).hoverColor : null,
          child: buildIngredientRow(context, appState, ingredient),
        )
      ));
    }

    Widget filterContainer = padding(child: FilterContainer(onFilterChange: (newValue) => setState(() {
        filter=newValue;
    }), onFavoritesOnlyChange: null));

    Widget backButton = padding(child: TextButton(onPressed: widget.onBack, child: textView("Terug")));

    //TODO add filter, add backButton

    return PopScope(canPop: false, onPopInvoked: (value) {
      widget.onBack();

    },child: Column(children: [
      filterContainer,
      Expanded(child: ListView(children: ingredientRows,)),
      backButton
    ],));
  }
}
