import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

const FirebaseOptions firebaseOptions = FirebaseOptions(
  apiKey: 'api-key',
  appId: 'the-app-id',
  messagingSenderId: '',
  projectId: 'the-project-id',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: firebaseOptions);
  runApp(const MyApp());

  // One-time Large collection initialisation
  var itemsRef = FirebaseFirestore.instance.collection('items');
  var maxItem = await itemsRef.doc('item1999').get();
  if (!maxItem.exists) {
    for (int i = 0; i < 2000; i++) {
      var docRef = itemsRef.doc('item${i}');
      docRef.set({ 'field1': '${0}' });
    }
  }

  DateTime lastFieldChange = DateTime.now();
  itemsRef.snapshots().listen((event) async {
    for (var fieldChange in event.docChanges) {
      if (fieldChange.type == DocumentChangeType.modified) {
        var now = DateTime.now();
        debugPrint('CHANGE: ${fieldChange.type} ${fieldChange.doc.id} ${fieldChange.doc['field1']} TimeSinceLastChange: ${now.difference(lastFieldChange).inMilliseconds} ms');
        lastFieldChange = now;
      }
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Core Firestore Performance Repro',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  Future<void> _incrementCounter() async {
    setState(() {
      _counter++;
    });

    var itemsRef = FirebaseFirestore.instance.collection('items');

    for (int i = 0; i < 100; i++) {
      var docRef = itemsRef.doc('item${i}');
      // .set and .update don't seem to have different performance here
      docRef.set({ 'field1': '${_counter}' }, SetOptions(merge: true));
      // docRef.update({ 'field1': '${_counter}' });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
