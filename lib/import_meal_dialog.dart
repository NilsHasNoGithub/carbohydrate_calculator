import 'dart:math';

import 'package:carbohydrate_calculator/data.dart';
import 'package:carbohydrate_calculator/utils.dart';
import 'package:flutter/material.dart';

class ImportMealDialog extends StatefulWidget {
  final void Function(Meal meal) importFn;
  final void Function(Object e) onFail;

  const ImportMealDialog(
      {super.key, required this.importFn, required this.onFail});

  @override
  State<ImportMealDialog> createState() => _ImportMealDialogState();
}

class _ImportMealDialogState extends State<ImportMealDialog> {
  String? importStr;

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    var screenWidth = MediaQuery.of(context).size.width;

    return AlertDialog(
      title: Column(children: [
        padding(child: textView("Plak de gerechtgegevens hieronder:")),
        padding(
            child: SizedBox(
                width: min(400.0, 0.8 * screenWidth),
                child: TextFormField(
                  style: const TextStyle(fontSize: defaultFontSize),
                  decoration: const InputDecoration(
                      border: UnderlineInputBorder(), labelText: ""),
                  onChanged: (value) => setState(() => importStr = value),
                )))
      ]),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: textView("Terug")),
        TextButton(
            onPressed: importStr != null
                ? () {
                    assert(importStr != null);
                    if (importStr == null) return;
                    Navigator.of(context).pop();
                    try {
                      Meal importResult = Meal.fromBase64(importStr!);
                      widget.importFn(importResult);
                    } catch (e) {
                      widget.onFail(e);
                    }
                  }
                : () {},
            child: textView("Importeer gerecht",
                textColor: importStr == null ? theme.disabledColor : null)),
      ],
    );
  }
}
