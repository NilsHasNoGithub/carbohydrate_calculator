// Contains meal views

import 'dart:math';

import 'package:carbohydrate_calculator/app_state.dart';
import 'package:carbohydrate_calculator/data.dart';
import 'package:carbohydrate_calculator/meal_part_picker.dart';
import 'package:carbohydrate_calculator/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

typedef MealPartCallback = void Function(MealPart part);

const inputFieldPadding = 5.0;

enum MealViewState {
  meal,
  mealPart,
  importMealPart,
  calculator,
}

class MealPage extends StatefulWidget {
  const MealPage({super.key});

  @override
  State<MealPage> createState() => _MealPageState();
}

class _MealPageState extends State<MealPage> {
  MealViewState currentView = MealViewState.meal;
  MealEditState? mesBeforeEdit;
  MealEditState? currentMes;
  int? mealPartViewIdx;

  void exitMealPage(AppState appState) {
    appState.mealEditState = null;
    currentView = MealViewState.meal;
    currentMes = null;
    mealPartViewIdx = null;
  }

  Widget buildMealPartRow(AppState appState, MealPart part, int partIndex) {
    //Row with part name and ch per 100g, and click function

    return Container(
        color: partIndex % 2 == 0 ? Theme.of(context).hoverColor : null,
        child: TextButton(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                  child: textView(emptyStrToDash(part.name ?? ""),
                      textAlign: TextAlign.center)),
              Expanded(
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        textView(
                            part.totalChPerG() != null
                                ? optFormatFloat(part.totalChPer100G())
                                : "?",
                            bold: true),
                        textView("Kh./100g", size: 12.0)
                      ].map((e) => padding(child: e)).toList()))
            ],
          ),
          onPressed: () => setState(() {
            mealPartViewIdx = partIndex;
            currentView = MealViewState.mealPart;
          }),
        ));
  }

  void saveOverwriteFunction(BuildContext context, AppState appState) {
    assert(currentMes != null);

    var toSave = currentMes!.clone();
    toSave.id = appState.generateNewMealId();
    toSave.removeEmptyParts();
    appState.saveMeal(currentMes!.toMeal());
    appState.viewState = defaultViewState;
    exitMealPage(appState);
  }

  void saveAsNewFunction(
      BuildContext context, AppState appState, bool allowEmpty) {
    assert(currentMes != null);
    var toSave = currentMes!.clone();
    toSave.removeEmptyParts();
    if (toSave.hasData() || allowEmpty) appState.addMealEditState(toSave);
    appState.viewState = defaultViewState;
    exitMealPage(appState);
  }

  void deleteMealFunction(BuildContext context, AppState appState) {
    var idToDelete = currentMes?.id;

    if (idToDelete != null) {
      appState.removeMeal(idToDelete);
    }

    appState.viewState = defaultViewState;
    exitMealPage(appState);
  }

  void backFunction(BuildContext context, AppState appState) {
    appState.viewState = defaultViewState;
    exitMealPage(appState);
  }

  Widget saveMealButton(BuildContext context, AppState appState) {
    assert(currentMes != null);
    var saveAsCopyOption = appState.meals.containsKey(currentMes!.id);

    void Function() onPressed;

    if (saveAsCopyOption) {
      onPressed = () => showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: textView(
                    "Wil je dit gerecht opslaan als kopie, of wil je dit gerecht updaten?"),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: textView("Annuleren")),
                  TextButton(
                      onPressed: () {
                        saveAsNewFunction(context, appState, true);
                        Navigator.of(context).pop();
                      },
                      child: textView("Als kopie")),
                  TextButton(
                      onPressed: () {
                        saveOverwriteFunction(context, appState);
                        Navigator.of(context).pop();
                      },
                      child: textView("Update gerecht")),
                ],
              ));
    } else {
      onPressed = () => saveAsNewFunction(context, appState, true);
    }

    return TextButton(
        onPressed: onPressed,
        child: textView("Sla gerecht op", textAlign: TextAlign.center));
  }

  Widget deleteMealButton(BuildContext context, AppState appState) {
    return TextButton(
        onPressed: () => showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: textView("Wil je dit gerecht echt verwijderen?"),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: textView("Nee")),
                    TextButton(
                        onPressed: () {
                          deleteMealFunction(context, appState);
                          Navigator.of(context).pop();
                        },
                        child: textView("Ja")),
                  ],
                )),
        child: textView("Verwijder gerecht", textAlign: TextAlign.center));
  }

  Widget backButton(BuildContext context, AppState appState) {
    assert(currentMes != null);
    var askUpdateInfo = appState.meals.containsKey(currentMes!.id);

    void Function() onPressed;

    //todo check later

    if (askUpdateInfo) {
      onPressed = () {
        var mesNotUpdated = mesBeforeEdit == currentMes;

        if (mesNotUpdated) {
          backFunction(context, appState);
        } else {
          onBackUpdateDialog(context, appState);
        }
      };
    } else {
      onPressed = () => saveAsNewFunction(context, appState, false);
    }

    return TextButton(
      onPressed: onPressed,
      child: textView("Terug", textAlign: TextAlign.center),
    );
  }

  void onBackUpdateDialog(BuildContext context, AppState appState) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: textView(
                  "Gegevens van dit gerecht zijn gewijzigd. Wil je de gegevens updaten?"),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: textView("Annuleren")),
                TextButton(
                    onPressed: () {
                      backFunction(context, appState);
                      Navigator.of(context).pop();
                    },
                    child: textView("Nee")),
                TextButton(
                    onPressed: () {
                      saveOverwriteFunction(context, appState);
                      Navigator.of(context).pop();
                    },
                    child: textView("Ja")),
              ],
            ));
  }

  Widget exportButton(BuildContext context, AppState appState) {
    onPressed() {
      assert(currentMes != null);
      if (currentMes == null) return; // For release

      var exportStr = currentMes!.toMeal().toBase64();

      var controller = TextEditingController(text: exportStr);
      controller.selection =
          TextSelection(baseOffset: 0, extentOffset: exportStr.length);

      // var controller = TextInputControl()

      var screenWidth = MediaQuery.of(context).size.width;

      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: Column(children: [
                  padding(child: textView("Kopieer de volgende text:")),
                  padding(
                      child: SizedBox(
                          width: min(400.0, 0.8 * screenWidth),
                          child: TextFormField(
                            controller: controller,
                            readOnly: true,
                            style: const TextStyle(fontSize: defaultFontSize),
                            decoration: const InputDecoration(
                                border: UnderlineInputBorder(), labelText: ""),
                            onTap: () {
                              controller.selection = TextSelection(
                                  baseOffset: 0,
                                  extentOffset: controller.text.length);
                            },
                          )))
                ]),
                actions: [
                  TextButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: exportStr))
                            .then((_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Gerecht is gekopieerd")));
                        });
                        Navigator.of(context).pop();
                      },
                      child: textView("Kopieer text")),
                  TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: textView("Terug")),
                ],
              ));
    }

    return TextButton(
        onPressed: onPressed,
        child: textView("Exporteer gerecht", textAlign: TextAlign.center));
  }

  Widget calculatorButton(BuildContext context, AppState appState) {
    return TextButton(
        onPressed: () {
          setState(() {
            currentView = MealViewState.calculator;
          });
        },
        child: textView("Open calculator", textAlign: TextAlign.center));
  }

  Widget mealView(BuildContext context, AppState appState) {
    assert(currentMes != null);

    //////////// Meal view
    List<Widget> mealPartRows = [];

    var screenWidth = MediaQuery.of(context).size.width;

    for (var (index, part) in currentMes!.parts.indexed) {
      mealPartRows.add(buildMealPartRow(appState, part, index));
    }

    mealPartRows
        .add(Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      TextButton(
          onPressed: () => setState(() {
                currentView = MealViewState.importMealPart;
              }),
          child: const Text("Importeer deelgerecht")),
      TextButton(
          onPressed: () => setState(() {
                mealPartViewIdx = currentMes!.parts.length;
                currentView = MealViewState.mealPart;
              }),
          child: const Text("Nieuw deelgerecht"))
    ]));

    //TODO add name and isFavorite

    var boxWidth = min(800.0, screenWidth);

    Widget mealNameContainer = SizedBox(
        width: boxWidth,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            expandedWithPadding(child: textView("Naam van gerecht: ")),
            expandedWithPadding(
                child: inputField(
                    labelText: "Naam",
                    type: InputFieldType.text,
                    value: currentMes!.name,
                    onChanged: (txt) {
                      currentMes!.name = txt;
                    },
                    onFocusLoss: () => setState(() {
                          _storeMes(appState, currentMes!);
                        })))
          ],
        ));

    Widget mealFavoriteContainer = SizedBox(
        width: boxWidth,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            expandedWithPadding(child: textView("Favoriet: ")),
            expandedWithPadding(
                child: onFocusWrap(
                    onFocusLoss: () => setState(() {
                          _storeMes(appState, currentMes!);
                        }),
                    child: Checkbox(
                        value: currentMes!.isFavorite,
                        onChanged: (newVal) => setState(() {
                              FocusScope.of(context).unfocus();
                              if (newVal != null) {
                                currentMes!.isFavorite = newVal;
                              }
                            }))))
          ],
        ));

    double buttonWidth = min(200, 0.27 * screenWidth);

    return ListView(children: [
      Column(
        children: [
          heading("Deelgerechten"),
          Column(
            children: mealPartRows,
          )
        ],
      ),
      Column(
        children: [
          heading("Gegevens gerecht"),
          mealNameContainer,
          mealFavoriteContainer,
        ],
      ),
      Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            padding(
                child: SizedBox(
                    width: buttonWidth, child: backButton(context, appState))),
            padding(
                child: SizedBox(
                    width: buttonWidth,
                    child: deleteMealButton(context, appState))),
            padding(
                child: SizedBox(
                    width: buttonWidth,
                    child: saveMealButton(context, appState))),
          ],
        ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          padding(
              child: SizedBox(
                  width: buttonWidth,
                  child: calculatorButton(context, appState))),
          padding(
              child: SizedBox(
                  width: buttonWidth, child: exportButton(context, appState))),
        ])
      ])
    ]);
  }

  Future<void> _storeMes(AppState appState, MealEditState mes) async {
    var toStore = mes.clone();
    toStore.removeEmptyParts();
    await appState.setMealEditStateNoUpdate(toStore);
  }

  @override
  Widget build(BuildContext context) {
    AppState appState = context.watch();

    if (currentMes == null) {
      currentMes = appState.mealEditState?.clone() ??
          MealEditState.empty(appState.generateNewMealId());
      mesBeforeEdit = currentMes!.clone();
    }

    /////////

    // TODO: implement build
    if (currentView == MealViewState.meal) {
      // return WillPopScope(
      //     onWillPop: () async {
      //       setState(() {
      //         currentView = MealViewState.meal;
      //         mealPartViewIdx = null;
      //       });
      //       return true;
      //     },
      //     child: mealView(context, appState));
      return WillPopScope(
          onWillPop: () async {
            if (currentMes == mesBeforeEdit) {
              appState.viewState = defaultViewState;
              exitMealPage(appState);
              return false;
            }

            onBackUpdateDialog(context, appState);

            return false;
          },
          child: mealView(context, appState));
    } else if (currentView == MealViewState.calculator) {
      return WillPopScope(
          onWillPop: () async {
            setState(() {
              currentView = MealViewState.meal;
            });

            return false;
          },
          child: CalculatorPage(
            meal: currentMes!.toMeal(),
            backFunction: () => setState(() {
              currentView = MealViewState.meal;
            }),
          ));
    } else if (currentView == MealViewState.mealPart) {
      while (mealPartViewIdx! >= currentMes!.parts.length) {
        currentMes!.parts
            .add(MealPart("", FoodContainerWeight(null, null), null, []));
      }

      return WillPopScope(
          onWillPop: () async {
            setState(() {
              currentView = MealViewState.meal;
              mealPartViewIdx = null;
            });
            return false;
          },
          child: MealPartPage(
            currentlyEditing: currentMes!.parts[mealPartViewIdx!],
            onChange: (p) {
              setState(() {
                // p.removeEmptyParts();
                currentMes!.parts[mealPartViewIdx!] = p;
                _storeMes(appState, currentMes!);
              });
            },
            backFunction: (p) {
              currentMes!.parts[mealPartViewIdx!] = p;
              currentMes!.removeEmptyParts();
              appState.mealEditState = currentMes!.clone();
              mealPartViewIdx = null;
              currentView = MealViewState.meal;

              // mealPartViewIdx
            },
            deletePart: (part) {
              currentMes!.parts.removeAt(mealPartViewIdx!);
              var removedIdxs = currentMes!.removeEmptyParts();
              removedIdxs.add(mealPartViewIdx!);
              appState.calculationStates[currentMes!.id]
                  ?.removePartsByIdx(removedIdxs);
              appState.mealEditState = currentMes!.clone();
              mealPartViewIdx = null;
              currentView = MealViewState.meal;
            },
          ));
    } else if (currentView == MealViewState.importMealPart) {
      return MealPartPicker(
          onPick: (part) {
            setState(() {
              currentMes!.parts.add(part);
              var removedIdxs = currentMes!.removeEmptyParts();
              appState.calculationStates[currentMes!.id]
                  ?.removePartsByIdx(removedIdxs);
              appState.mealEditState = currentMes!.clone();
              currentView = MealViewState.meal;
            });
          },
          onBack: () => currentView = MealViewState.meal);
    } else {
      throw UnimplementedError();
    }
  }
}

class MealPartPage extends StatefulWidget {
  final MealPart currentlyEditing;
  final MealPartCallback backFunction;
  final MealPartCallback deletePart;
  final MealPartCallback onChange;

  // Map<int, TextFormField> ingredientNames;
  // Map<int, TextFormField> ingredientKhPer100;
  // Map<int, TextFormField> ingredientTotal;

  const MealPartPage({
    super.key,
    required this.currentlyEditing,
    required this.backFunction,
    required this.onChange,
    required this.deletePart,
  });

  @override
  State<MealPartPage> createState() => _MealPartPageState();
}

class _MealPartPageState extends State<MealPartPage> {
  Ingredient getOrAddIngredient(int index) {
    while (index >= widget.currentlyEditing.ingredients.length) {
      widget.currentlyEditing.ingredients.add(Ingredient.empty());
    }

    return widget.currentlyEditing.ingredients[index];
  }

  void updateIngredientWeight(String value, int ingredientIdx) {
    var ing = getOrAddIngredient(ingredientIdx);
    var weight = double.tryParse(value);

    ing.weightG = weight;
    // ing.tryInferTotalCh() || ing.tryInferChPerGram();
    ing.tryInferTotalCh();
  }

  void updateChPer100(String value, int ingredientIdx) {
    var ing = getOrAddIngredient(ingredientIdx);
    var ch100 = double.tryParse(value);

    ing.chPerHGram = ch100;

    // ing.tryInferTotalCh() || ing.tryInferWeight();
    ing.tryInferTotalCh();
  }

  void updateTotalKh(String value, int ingredientIdx) {
    var ing = getOrAddIngredient(ingredientIdx);
    var totalCh = double.tryParse(value);

    ing.totalCarbohydrates = totalCh;
  }

  void updateIngredientName(String value, int ingredientIdx) {
    getOrAddIngredient(ingredientIdx).name = value;
  }

  Widget buildIngredientRow(AppState appState, int ingredientIdx) {
    var curIng = ingredientIdx >= widget.currentlyEditing.ingredients.length
        ? null
        : widget.currentlyEditing.ingredients[ingredientIdx];

    // TODO format float

    var onTap = curIng == null
        ? () {
            setState(() {
              widget.currentlyEditing.ingredients.add(Ingredient.empty());
            });
          }
        : null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Ingredient name
        expandedWithPadding(
            padding: inputFieldPadding,
            child: onFocusWrap(
              child: inputField(
                  labelText: "Naam ingredient",
                  value: curIng?.name,
                  onChanged: (txt) => updateIngredientName(txt, ingredientIdx),
                  onTap: onTap),
              onFocusLoss: () => widget.onChange(widget.currentlyEditing),
            )),
        // Number fields
        expandedWithPadding(
            padding: inputFieldPadding,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                inputField(
                  labelText: "Kh. /100g",
                  type: InputFieldType.number,
                  value: optFormatFloat(curIng?.chPerHGram),
                  onChanged: (value) => updateChPer100(value, ingredientIdx),
                  onTap: onTap,
                ),
                inputField(
                  labelText: "g",
                  type: InputFieldType.number,
                  value: optFormatFloat(curIng?.weightG),
                  onChanged: (value) =>
                      updateIngredientWeight(value, ingredientIdx),
                  onTap: onTap,
                ),
                inputField(
                  labelText: "g. Kh. Tot.",
                  type: InputFieldType.number,
                  value: optFormatFloat(curIng?.totalCarbohydrates),
                  onChanged: (value) => updateTotalKh(value, ingredientIdx),
                  onTap: onTap,
                )
              ]
                  .map((e) => expandedWithPadding(
                      child: onFocusWrap(
                        child: e,
                        onFocusLoss: () =>
                            widget.onChange(widget.currentlyEditing),
                      ),
                      padding: inputFieldPadding))
                  .toList(),
            ))
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    AppState appState = context.watch();

    var screenHeight = MediaQuery.of(context).size.height;
    var screenWidth = MediaQuery.of(context).size.width;

    ///////////////////// Ingredient rows
    List<Widget> ingredientRows = [
      Row(
        children: [
          expandedWithPadding(child: textView("Naam")),
          Expanded(
              child: Row(
            children: [
              expandedWithPadding(child: textView("Kh. /100g")),
              expandedWithPadding(child: textView("Gewicht")),
              expandedWithPadding(child: textView("Kh. Tot."))
            ],
          ))
        ],
      )
    ];

    for (int i = 0; i < widget.currentlyEditing.ingredients.length; i++) {
      ingredientRows.add(buildIngredientRow(appState, i));
    }

    ingredientRows.add(buildIngredientRow(
        appState, widget.currentlyEditing.ingredients.length));

    ///// Container weight full, container weight total, part name
    ///
    var buttonSize = min(200.0, .4 * screenWidth);
    var boxWidth = min(800.0, screenWidth);

    Widget panNameContainer = SizedBox(
        width: boxWidth,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            expandedWithPadding(child: textView("Naam van deelgerecht: ")),
            expandedWithPadding(
                child: inputField(
                    labelText: "Naam",
                    value: widget.currentlyEditing.name,
                    onChanged: (txt) {
                      widget.currentlyEditing.name = txt;
                    },
                    onFocusLoss: () =>
                        widget.onChange(widget.currentlyEditing)))
          ],
        ));

    Widget panWeightEmptyContainer = SizedBox(
        width: boxWidth,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            expandedWithPadding(child: textView("Gewicht van lege pan: ")),
            expandedWithPadding(
                child: inputField(
                    labelText: "g",
                    type: InputFieldType.number,
                    value: optFormatFloat(
                        widget.currentlyEditing.container.weightG),
                    onChanged: (txt) {
                      widget.currentlyEditing.container.weightG =
                          double.tryParse(txt);
                    },
                    onFocusLoss: () =>
                        widget.onChange(widget.currentlyEditing)))
          ],
        ));

    Widget panWeightFullContainer = SizedBox(
        width: boxWidth,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            expandedWithPadding(
                child: textView("Gewicht van pan plus inhoud: ")),
            expandedWithPadding(
                child: inputField(
                    labelText: "g",
                    type: InputFieldType.number,
                    value: optFormatFloat(widget.currentlyEditing.weightGTotal),
                    onChanged: (txt) {
                      widget.currentlyEditing.weightGTotal =
                          double.tryParse(txt);
                    },
                    onFocusLoss: () =>
                        widget.onChange(widget.currentlyEditing)))
          ],
        ));

    return ListView(
        // mainAxisSize: MainAxisSize.max,
        // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              heading("Ingredienten"),
              Padding(
                  padding: const EdgeInsets.all(inputFieldPadding),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: ingredientRows,
                  )),
            ],
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              heading("Gegevens deelgerecht"),
              panNameContainer,
              panWeightEmptyContainer,
              panWeightFullContainer,
            ],
          ),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            padding(
                child: SizedBox(
                    width: buttonSize,
                    child: TextButton(
                      child: textView("Bevestig", textAlign: TextAlign.center),
                      onPressed: () =>
                          widget.backFunction(widget.currentlyEditing),
                    ))),
            padding(
                child: SizedBox(
                    width: buttonSize,
                    child: TextButton(
                        onPressed: () => showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                                  title: textView(
                                      "Wil je dit deelgerecht echt verwijderen?"),
                                  actions: [
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        child: textView("Nee")),
                                    TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          widget.deletePart(
                                              widget.currentlyEditing);
                                        },
                                        child: textView("Ja")),
                                  ],
                                )),
                        child: textView("Verwijder deelgerecht",
                            textAlign: TextAlign.center)))),
          ])
        ]);
  }
}

class CalculatorPage extends StatefulWidget {
  final Meal meal;
  final void Function() backFunction;
  const CalculatorPage(
      {super.key, required this.meal, required this.backFunction});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  ChCalculationState calcState = ChCalculationState();

  Widget buildMealPartCalcRow(BuildContext context, AppState appState,
      List<int> allowedPartIdxs, int calcStateIdx) {
    List<String> dropDownLabels = [];

    for (var partIdx in allowedPartIdxs) {
      var part = widget.meal.parts[partIdx];
      dropDownLabels.add(
          "${part.name} (${optFormatFloat(part.totalChPer100G())} Kh. /100g)");
    }

    Widget dropDownMenu = expandedWithPadding(
        child: DropdownButton<int>(
            value: calcState.mealPartIdxs[calcStateIdx],
            isExpanded: true,
            itemHeight: null,
            items: allowedPartIdxs
                .map((item) => DropdownMenuItem<int>(
                      value: item,
                      child: padding(
                          child: textView(
                        dropDownLabels[item],
                        // overflow: TextOverflow.ellipsis,
                        softWrap: true,
                      )),
                    ))
                .toList(),
            onChanged: (value) {
              calcState.mealPartIdxs[calcStateIdx] = value;
              appState.saveCalcStateOf(widget.meal.id, calcState);
            }));

    // Widget partNameWidget = expandedWithPadding(child: textView(emptyStrToDash(meal.parts[partIdx].name), textAlign: TextAlign.center));

    Widget weightInputField = expandedWithPadding(
        child: inputField(
      value: optFormatFloat(calcState.weights[calcStateIdx]),
      labelText: "g",
      type: InputFieldType.number,
      onChanged: (value) {
        var weight = double.tryParse(value);
        calcState.weights[calcStateIdx] = weight;
      },
      onFocusLoss: () => appState.saveCalcStateOf(widget.meal.id, calcState),
    ));

    calcState.carbohydratesGAt(widget.meal, calcStateIdx);

    Widget totalKhField = expandedWithPadding(
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      expandedWithPadding(
          child: textView(
              optFormatFloat(
                  calcState.carbohydratesGAt(widget.meal, calcStateIdx),
                  defaultVal: "?"),
              bold: true,
              textAlign: TextAlign.right)),
      expandedWithPadding(child: textView("g. Kh.", textAlign: TextAlign.left))
    ]));

    return Container(
        color: calcStateIdx % 2 == 0 ? Theme.of(context).hoverColor : null,
        child: Row(
          children: [dropDownMenu, weightInputField, totalKhField],
        ));
  }

  @override
  Widget build(BuildContext context) {
    AppState appState = context.watch();

    calcState =
        appState.calculationStates[widget.meal.id] ?? ChCalculationState();

    if (calcState.isEmpty || !calcState.lastIsEmpty()) {
      calcState.addEmpty();
    }

    List<int> partIdxCandidates = [];

    for (var (i, part) in widget.meal.parts.indexed) {
      if (part.totalChPerG() != null) partIdxCandidates.add(i);
    }

    // var partIdxCandidates = widget.meal.parts.indexed
    //     .where((i,element) => element.totalChPerG() != null)
    //     .toList();

    List<Widget> calcRows = [];

    for (var i = 0; i < calcState.length; i++) {
      calcRows
          .add(buildMealPartCalcRow(context, appState, partIdxCandidates, i));
    }

    var screenWidth = MediaQuery.of(context).size.width;

    double buttonWidth = min(0.27 * screenWidth, 200);

    Widget backButton =
        TextButton(onPressed: widget.backFunction, child: textView("Terug"));

    Widget resetButton = TextButton(
        onPressed: () => showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: textView(
                      "Weet je zeker dat je de calculator wil resetten?"),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: textView("Nee")),
                    TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // appState.saveCalcStateOf(widget.meal.id, ChCalculationState());
                          appState.removeCalcStateOf(widget.meal.id);
                        },
                        child: textView("Ja")),
                  ],
                )),
        child: textView("Reset"));

    var totalCh = calcState.totalCarbohydratesG(widget.meal);

    // TODO: implement build
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            heading("Deelgerecht"),
            heading("Gewicht"),
            heading("Kh. Tot.")
          ].map((e) => padding(child: e)).toList(),
        ),
        Expanded(
            child: ListView(
          children: calcRows,
        )),
        padding(
            child: heading(
                "Totaal g. Koolhydraten: ${optFormatFloat(totalCh, defaultVal: "?")}")),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [backButton, resetButton]
              .map(
                  (e) => padding(child: SizedBox(width: buttonWidth, child: e)))
              .toList(),
        )
        //TODO reset and backbuttons
      ],
    );
  }
}
