//import 'package:flutter/services.dart';
//import 'package:flutter_test/flutter_test.dart';
//import 'package:dio_304_cache/dio_304_cache.dart';
//
//void main() {
//  const MethodChannel channel = MethodChannel('dio_304_cache');
//
//  TestWidgetsFlutterBinding.ensureInitialized();
//
//  setUp(() {
//    channel.setMockMethodCallHandler((MethodCall methodCall) async {
//      return '42';
//    });
//  });
//
//  tearDown(() {
//    channel.setMockMethodCallHandler(null);
//  });
//
//  test('getPlatformVersion', () async {
//    expect(await Dio304Cache.platformVersion, '42');
//  });
//}
