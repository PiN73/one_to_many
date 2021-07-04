import 'package:flutter/material.dart';
import 'package:one_to_many/db.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}

final db = MyDatabase();

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await db.populate();
            final factories = await db.query();
            print(factories);
          },
          child: Text('TEST'),
        ),
      ),
    );
  }
}
