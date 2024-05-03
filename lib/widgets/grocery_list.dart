import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  var _isLoading = true;
  String? _error;

  @override
  void initState() {
    _loadedItems();
    super.initState();
  }

  void _loadedItems() async {
    final url = Uri.https(
        'flutter-fa09c-default-rtdb.asia-southeast1.firebasedatabase.app',
        'shopping-list.json');
    try {
      final response = await http.get(url);
      if (response.statusCode >= 400) {
        setState(() {
          _error = 'Failed to fetch data. Please try again later.';
        });
        return;
      }
      if (json.decode(response.body) == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      final Map<String, dynamic> listData = json.decode(response.body);
      final List<GroceryItem> groceryList = [];
      for (final item in listData.entries) {
        final category = categories.entries
            .firstWhere(
              (catItem) => catItem.value.title == item.value['category'],
            )
            .value;
        groceryList.add(
          GroceryItem(
            id: item.key,
            name: item.value['name'],
            quantity: item.value['quantity'],
            category: category,
          ),
        );
      }
      setState(() {
        _groceryItems = groceryList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Somethine went wrong! Please try again later.';
      });
    }
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (context) => const NewItem(),
      ),
    );

    if (newItem == null) {
      return;
    }
    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void _removeItem(GroceryItem item) async {
    final itemIndex = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);
    });
    final url = Uri.https(
        'flutter-fa09c-default-rtdb.asia-southeast1.firebasedatabase.app',
        'shopping-list/${item.id}.json');
    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      setState(() {
        _groceryItems.insert(itemIndex, item);
      });

      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 3),
          content: Text('Failed to delete item.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(
      child: Text('No items added yet.'),
    );
    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator());
    }
    if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (ctx, idx) {
          return Dismissible(
            key: ValueKey(_groceryItems[idx].id),
            background: Container(
              color: Theme.of(context)
                  .colorScheme
                  .onPrimaryContainer
                  .withOpacity(0.1),
            ),
            onDismissed: (direction) {
              _removeItem(_groceryItems[idx]);
            },
            child: ListTile(
              title: Text(_groceryItems[idx].name),
              leading: Container(
                width: 24,
                height: 24,
                color: _groceryItems[idx].category.color,
              ),
              trailing: Text(_groceryItems[idx].quantity.toString()),
            ),
          );
        },
      );
    }

    if (_error != null) {
      content = Center(
        child: Text(_error!),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [
          IconButton(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: content,
    );
  }
}
