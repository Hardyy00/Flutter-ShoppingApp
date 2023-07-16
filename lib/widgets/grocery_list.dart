import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_app/data/categories.dart';
import 'package:shopping_app/models/category.dart';
import 'package:shopping_app/models/grocery_item.dart';
import 'package:shopping_app/widgets/new_item.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryList = [];
  bool _isLoading = true;
  String? _errorMessage = null;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    final url = Uri.https(
        'flutter-prep-11e63-default-rtdb.firebaseio.com', 'shopping-app.json');

    try {
      final response = await http.get(url);

      if (response.body == 'null') {
        setState(() {
          _isLoading = false;
        });

        return;
      }

      if (response.statusCode >= 400) {
        setState(() {
          _errorMessage = "Failed to load the data. Try sometime later.";
        });
      }

      final Map<String, dynamic> responseBody = json.decode(response.body);

      List<GroceryItem> loadedList = [];

      for (final entry in responseBody.entries) {
        // find the category through categories map (finding it through iterating over all the categories name)
        Category category = categories.entries
            .firstWhere(
                (element) => element.value.name == entry.value['category'])
            .value;

        final gItem = GroceryItem(
          id: entry.key, // using the firebase key itself as a key
          name: entry.value['name'],
          quantity: entry.value['quantity'],
          category: category,
        );

        loadedList.add(gItem);
      }

      setState(
        () {
          _groceryList = loadedList;
          _isLoading = false;
        },
      );
    } catch (error) {
      setState(() {
        _errorMessage = "Something Went Wrong!";
      });
    }
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const NewItem(),
      ),
    );

    setState(() {
      _groceryList.add(newItem);
    });
  }

  void _removeItem(GroceryItem item) async {
    int itemIndex = _groceryList.indexOf(item);

    setState(() {
      _groceryList.remove(item);
    });

    final url = Uri.https("flutter-prep-11e63-default-rtdb.firebaseio.com",
        'shopping-app/${item.id}.json');

    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      setState(() {
        _groceryList.insert(itemIndex, item);
      });

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to delete the item...Maybe an error occurred!"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget mainContent = const Center(
      child: Text(
        "Items not added yet!",
        style: TextStyle(fontSize: 19),
      ),
    );

    if (_isLoading) {
      mainContent = const Center(
        child: CircularProgressIndicator(),
      );
    } else if (_groceryList.isNotEmpty) {
      mainContent = ListView.builder(
        itemCount: _groceryList.length,
        itemBuilder: (ctx, index) => Dismissible(
          key: ValueKey(_groceryList[index].id),
          onDismissed: (dir) {
            _removeItem(_groceryList[index]);
          },
          child: ListTile(
            leading: Container(
              width: 24,
              height: 24,
              color: _groceryList[index].category.color,
            ),
            horizontalTitleGap: 25,
            title: Text(
              _groceryList[index].name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            trailing: Text(
              _groceryList[index].quantity.toString(),
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
            ),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      mainContent = Center(
        child: Text(
          _errorMessage!,
          style: const TextStyle(fontSize: 19),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Favorites"),
        actions: [IconButton(onPressed: _addItem, icon: const Icon(Icons.add))],
      ),
      body: mainContent,
    );
  }
}
