import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const defaultFontSize = 14.0;

String generateRandomString(int length) {
  const String validCharacters =
      "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
  final random = Random();
  final buffer = StringBuffer();

  for (var i = 0; i < length; i++) {
    final randomIndex = random.nextInt(validCharacters.length);
    buffer.write(validCharacters[randomIndex]);
  }

  return buffer.toString();
}

String generateRandomIdentifier([int randStrLength = 10]) {
  var randString = generateRandomString(randStrLength);
  var currentTimeMs = DateTime.now().millisecondsSinceEpoch;

  return randString + currentTimeMs.toString();
}

enum InputFieldType { text, number }

final _validFloatFieldChars = "0123456789.".characters.toSet();

Widget inputField(
    {required String labelText,
    InputFieldType type = InputFieldType.text,
    String? value,
    void Function(String)? onChanged,
    void Function()? onTapOutside,
    void Function()? onTap,
    void Function()? onFocusLoss,
    double fontSize = defaultFontSize,
    bool readOnly = false}) {
  var controller = TextEditingController(text: value);

  if (value != null) {
    controller.selection =
        TextSelection(baseOffset: 0, extentOffset: value.length);
  }

  List<TextInputFormatter> inputFormatters;
  TextInputType kbdType;

  switch (type) {
    case InputFieldType.number:
      inputFormatters = [
        TextInputFormatter.withFunction((oldValue, newValue) {
          var newText = newValue.text.replaceAll(",", ".");
          bool newTextValid = newText.isEmpty ||
              newText.characters
                  .map((e) => _validFloatFieldChars.contains(e))
                  .reduce((value, element) => value && element);

          if (newTextValid) {
            return TextEditingValue(
                text: newText,
                selection: newValue.selection,
                composing: newValue.composing);
          } else {
            return oldValue;
          }
          // return TextEditingValue(newValue.text.replaceAll(",", "."));
        }),
        // FilteringTextInputFormatter.allow(filterPattern)
      ];
      kbdType = TextInputType.number;
      break;
    default:
      inputFormatters = [];
      kbdType = TextInputType.text;
  }

  TextFormField textFormField = TextFormField(
    controller: controller,
    style: TextStyle(fontSize: fontSize),
    // initialValue: value,
    decoration: InputDecoration(
        border: const UnderlineInputBorder(), labelText: labelText),
    keyboardType: kbdType,
    inputFormatters: inputFormatters,
    onChanged: onChanged,
    readOnly: readOnly,
    onTap: onTap,
  );

  // print(textFormField.controller);

  return onFocusWrap(onFocusLoss: onFocusLoss, child: textFormField);
}

Widget padding({required Widget child, double padding = 5.0}) {
  return Padding(padding: EdgeInsets.all(padding), child: child);
}

Widget expandedWithPadding({required Widget child, double padding = 5.0}) {
  return Expanded(
      child: Padding(padding: EdgeInsets.all(padding), child: child));
}

Widget onFocusWrap(
    {required Widget child,
    void Function()? onFocusLoss,
    void Function()? onFocusGain}) {
  return Focus(
      child: child,
      onFocusChange: (hasFocus) {
        if (!hasFocus && onFocusLoss != null) {
          onFocusLoss();
        } else if (hasFocus && onFocusGain != null) {
          onFocusGain();
        }
      });
}

String emptyStrToDash(String? input) =>
    input == null || input.isEmpty ? "-" : input;

String formatFloat(double float) {
  //This function should not be this complicated :(
  String result = float.toStringAsFixed(2);
  var chars = result.characters.toList();
  var endIndex = chars.length - 1;
  while (chars[endIndex] == "0") {
    endIndex--;
  }
  if (endIndex < 0) {
    return "0";
  }
  if (chars[endIndex] == ".") {
    endIndex--;
  }
  if (endIndex < 0) {
    return "0";
  }

  return result.substring(0, endIndex + 1);
}

String optFormatFloat(double? float, {String defaultVal = ""}) {
  if (float == null) {
    return defaultVal;
  }

  return formatFloat(float);
}

Widget heading(String text,
    {double size = defaultFontSize * 1.3, TextAlign? textAlign}) {
  return Text(
    text,
    textAlign: textAlign,
    style: TextStyle(
      fontSize: size,
      fontWeight: FontWeight.bold,
    ),
  );
}

Widget textView(String text,
    {double size = defaultFontSize,
    TextAlign? textAlign,
    Color? textColor,
    TextOverflow? overflow,
    bool bold = false,
    bool? softWrap}) {
  return Text(
    text,
    textAlign: textAlign,
    style: TextStyle(
      color: textColor,
      fontSize: size,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
    ),
    overflow: overflow,
    softWrap: softWrap,
  );
}

String compressStr(String input) {
  var compressedBytes = gzip.encode(utf8.encode(input));
  var encoded = base64Encode(compressedBytes);
  return encoded;
}

String decompressStr(String compressed) {
  var decodedBytes = base64Decode(compressed);
  var decompressedBytes = gzip.decode(decodedBytes);
  var result = utf8.decode(decompressedBytes);
  return result;
}
