import 'dart:math';

import 'package:carbohydrate_calculator/app_state.dart';
import 'package:carbohydrate_calculator/data.dart';
import 'package:carbohydrate_calculator/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MealPartPicker extends StatefulWidget {
  final void Function(MealPart) onPick;
  final void Function() onBack;

  MealPartPicker({super.key, required this.onPick, required this.onBack});

  @override
  State<MealPartPicker> createState() => _MealPartPickerState();
}

class _MealPartPickerState extends State<MealPartPicker> {
  MealPart? candidate;
  String? filter;
  bool favoritesOnly = false;

  Widget partsOverview(BuildContext context, AppState appState) {
    var mealsByDate = appState.mealsSortedByDate;
    var mealPartsByDate = mealsByDate
        // .where((element) => filter == null || element.name.contains(filter!))
        .where((element) => !favoritesOnly || element.isFavorite)
        .expand((e) => e.parts.map((e2) => (e, e2)))
        .where((e) => filter==null || (e.$2.name?.toLowerCase() ?? "").contains(filter!.toLowerCase()));
        // .where((e) => e.$2.totalChPer100G() != null);

    List<Widget> mealPartSelectButton = [];

    for (var (idx, (meal, mealPart)) in mealPartsByDate.indexed) {
      mealPartSelectButton.add(Container(
          color: idx % 2 == 0 ? Theme.of(context).hoverColor : null,
          child: TextButton(
            onPressed: () => setState(() {
              candidate = mealPart.clone();
            }),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  expandedWithPadding(child: textView(emptyStrToDash(mealPart.name ?? ""), textAlign: TextAlign.center)),
                  expandedWithPadding(child: textView(meal.dateFormatted(), textAlign: TextAlign.center)),
                  Expanded(child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        textView(optFormatFloat(mealPart.totalChPer100G(), defaultVal: "?"),
                            bold: true),
                        textView("Kh./100g", size: 12.0)
                      ].map((e) => padding(child: e)).toList()))
                ]),
          )));
    }

    double screenWidth = MediaQuery.of(context).size.width;
    double buttonWidth = min(200, 0.27 * screenWidth);

    var backButton = SizedBox(
        width: buttonWidth,
        child: TextButton(onPressed: widget.onBack, child: textView("Terug")));

    var filterField = padding(child: TextFormField(
      initialValue: filter,
      onChanged: (value) => setState(() {
        filter = value;
      }),
      style: const TextStyle(fontSize: defaultFontSize),
      decoration: const InputDecoration(
        border: UnderlineInputBorder(), labelText: "Filter"),
    ));

    var favoritesFilterButton = Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        padding(child: textView("Alleen favorieten: ")),
        padding(child: Checkbox(value: favoritesOnly, onChanged: (newValue) => setState(() {
          favoritesOnly =newValue ?? false;
        })))
      ],
    );

    return Column(
      children: [
        filterField,
        favoritesFilterButton,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          mainAxisSize: MainAxisSize.max,
          children: [
            heading("Deelgerecht"),
            heading("Datum"),
            heading("Koolhydraten")
          ].map((e) => padding(child: e)).toList(),
        ),
        Expanded(
            child: ListView(
          children: mealPartSelectButton,
        )),
        padding(child: backButton)
      ],
    );
  }

  Widget partView(BuildContext context, AppState appState, MealPart part) {
    List<Widget> ingredientRows = [];

    for (var ingredient in part.ingredients) {
      ingredientRows.add(Row(
        children: [
          expandedWithPadding(
              child: inputField(
                  labelText: "Naam ingredient",
                  value: ingredient.name ?? "-",
                  readOnly: true)),
          Expanded(
              child: Row(
            children: [
              inputField(
                  labelText: "Kh. / 100g",
                  value: optFormatFloat(ingredient.chPerHGram),
                  readOnly: true),
              inputField(
                  labelText: "g",
                  value: optFormatFloat(ingredient.weightG),
                  readOnly: true),
              inputField(
                  labelText: "g. Kh. Tot.",
                  value: optFormatFloat(ingredient.totalCarbohydrates),
                  readOnly: true),
            ].map((e) => expandedWithPadding(child: e)).toList(),
          ))
        ],
      ));
    }

    double screenWidth = MediaQuery.of(context).size.width;
    double buttonWidth = min(200, 0.27 * screenWidth);

    var backButton = SizedBox(
        width: buttonWidth,
        child: TextButton(
            onPressed: () => setState(() {
                  candidate = null;
                }),
            child: textView("Terug")));

    var confirmButton = SizedBox(
        child: TextButton(
            onPressed: () => widget.onPick(part), child: textView("Bevestig")));

    return Column(
      children: [
        Expanded(
            child: ListView(
                children: [
                      padding(child: heading("Ingredienten", textAlign: TextAlign.center)),
                      Row(
                        children: [
                          expandedWithPadding(child: textView("Naam")),
                          expandedWithPadding(child: textView("Kh. /100g")),
                          expandedWithPadding(child: textView("Gewicht")),
                          expandedWithPadding(child: textView("Kh. Tot."))
                        ],
                      )
                    ] +
                    ingredientRows +
                    [
                      padding(child: heading("Gegevens deelgerecht", textAlign: TextAlign.center)),
                      Row(
                        children: [
                          textView("Naam van deelgerecht:"),
                          inputField(
                              labelText: "Naam",
                              value: part.name ?? "",
                              readOnly: true)
                        ].map((e) => expandedWithPadding(child: e)).toList(),
                      ),
                      Row(
                        children: [
                          textView("Gewicht van lege pan:"),
                          inputField(
                              labelText: "g",
                              value: optFormatFloat(part.container.weightG),
                              readOnly: true)
                        ].map((e) => expandedWithPadding(child: e)).toList(),
                      ),
                      Row(
                        children: [
                          textView("Gewicht van pan plus inhoud:"),
                          inputField(
                              labelText: "g",
                              value: optFormatFloat(part.weightGTotal),
                              readOnly: true)
                        ].map((e) => expandedWithPadding(child: e)).toList(),
                      )
                    ])),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [backButton, confirmButton],
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    AppState appState = context.watch();

    if (candidate == null) {
      return WillPopScope(
          onWillPop: () async {
            widget.onBack();
            return false;
          },
          child: partsOverview(context, appState));
    } else {
      return WillPopScope(
          onWillPop: () async {
            candidate = null;
            return false;
          },
          child: partView(context, appState, candidate!));
    }
  }
}
