import 'package:carbohydrate_calculator/app_state.dart';
import 'package:carbohydrate_calculator/history_page.dart';
import 'package:carbohydrate_calculator/import_meal_dialog.dart';
import 'package:carbohydrate_calculator/meal_view_pages.dart';
import 'package:carbohydrate_calculator/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // var appState = context.watch<AppState>();

    // var initState = initAppState(appState);

    return ChangeNotifierProvider(
        create: (context) {
          var appState = AppState();

          return appState;
        },
        child: MaterialApp(
          title: 'Flutter Demo',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          home: const MainView(),
        ));
  }
}

class MainView extends StatelessWidget {
  const MainView({super.key});

  // This widget is the home page of your application. It is stateful, meaning
  Future<int> initAppState(AppState appState) async {
    if (!appState.initialized) {
      await appState.initialize();
    }

    return 0;
  }

  void onSuccessFullMealImport(
      BuildContext context, AppState appState, Meal meal) {
    var mealExists = appState.meals.containsKey(meal.id);

    setMealView(Meal meal) {
      appState.setMealEditStateNoUpdate(MealEditState.fromMeal(meal));
      appState.viewState = ViewState.mealView;
    }

    if (mealExists) {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: textView(
                    "Een gerecht met hetzelfde ID bestaat al. Wil je de oude vervangen, of het nieuwe gerecht toevoegen als kopie."),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: textView("Annuleren")),
                  TextButton(
                      onPressed: () {
                        appState.saveMeal(meal);
                        setMealView(meal);
                        Navigator.of(context).pop();
                      },
                      child: textView("Vervangen")),
                  TextButton(
                      onPressed: () {
                        meal.id = appState.generateNewMealId();
                        meal.resetTimestamp();
                        setMealView(meal);
                        appState.saveMeal(meal);
                        Navigator.of(context).pop();
                      },
                      child: textView("Als kopie")),
                ],
              ));
    } else {
      meal.resetTimestamp();
      setMealView(meal);
      appState.saveMeal(meal);
    }
  }

  void importFailedDialog(
      BuildContext context, AppState appState, Object exception) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: textView(
                  "Importeren niet gelukt, er is iets mis met de gegevens."),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: textView("Terug"))
              ],
            ));
  }

  Widget mkFloatingActionButton(BuildContext context, AppState appState) {
    return FloatingActionButton(
        onPressed: () {
          showDialog(
              context: context,
              builder: (context) => AlertDialog(
                    title: textView("Nieuw gerecht, of gerecht importeren?"),
                    actions: [
                      TextButton(
                          onPressed: () {
                            appState.viewState = ViewState.mealView;
                            Navigator.of(context).pop();
                          },
                          child: textView("Nieuw gerecht")),
                      TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            showDialog(
                                context: context,
                                builder: (context) => ImportMealDialog(
                                    importFn: (meal) => onSuccessFullMealImport(
                                        context, appState, meal),
                                    onFail: (e) => importFailedDialog(
                                        context, appState, e)));
                          },
                          child: textView("Gerecht importeren")),
                    ],
                  ));
        },
        child: const Icon(Icons.add));
  }

  Widget mainPage(BuildContext context) {
    //TODO select view and user interaction state

    var appState = context.watch<AppState>();

    Widget body;
    var floatingActionButton = mkFloatingActionButton(context, appState);
    bool doFloatingActionButton;

    switch (appState.viewState) {
      case ViewState.historyView:
        body = const HistoryView();
        doFloatingActionButton = true;
        break;
      case ViewState.mealView:
        body = const MealPage();
        doFloatingActionButton = false;
        break;
      case ViewState.favoritesView:
        // body = Favorite
        doFloatingActionButton = true;
        throw UnimplementedError();
        break;
      default:
        throw UnimplementedError();
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Hello world"),
      ),
      body: body,
      floatingActionButton:
          doFloatingActionButton ? floatingActionButton : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();

    var initState = initAppState(appState);

    // var initState = () async {
    //   await appState.clearData(notifyListeners: false);
    //   return 0;
    // }();

    return FutureBuilder<int>(
      future: initState,
      builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
        List<Widget> children;
        if (snapshot.hasData) {
          return mainPage(context);
        }

        if (snapshot.hasError) {
          children = <Widget>[
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text('Error: ${snapshot.error}'),
            ),
          ];
        } else {
          children = const <Widget>[
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(),
            ),
            Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text('Awaiting result...'),
            ),
          ];
        }

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: children,
          ),
        );
      },
    );
  }
}
