import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:dio_304_cache/dio_304_cache.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initCache304Interceptor(config: Cache304Config(cacheLength: 3));
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String responseData = '';
  int statusCode;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Plugin Demo',
      home: Scaffold(
        appBar: AppBar(title: const Text('Dio 304 cache example app')),
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                RaisedButton(
                  child: Text('Clear cache'),
                  onPressed: () async {
                    print('========');
                    Cache304Interceptor.clearCache();
                    print('========');
                  },
                ),
                Text('Status code: ${statusCode ?? ''}'),
                Text('responseData:'),
                Text(responseData),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _fetchData,
          tooltip: 'Increment',
          child: Text('fetch'),
        ),
      ),
    );
  }

  void _fetchData() async {
    final dio = Dio();
    dio.interceptors.add(Cache304Interceptor());

    final res = await dio.get<String>(
      '<your_api_endpoint_here>',
      queryParameters: {'1': '1'},
    );

    setState(() {
      responseData = res.data;
      statusCode = res.statusCode;
    });
  }
}
