import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

import 'cache_304_config.dart';

class _Cache304InterceptorStaticFields {
  static int openBoxCount = 0;
  static int cacheLength = 25;
  static String cacheBoxName = 'dio_304_cache_hive_box';

  static Future<Box> getCachedBox() async {
    openBoxCount += 1;
    if (openBoxCount == 1) return await Hive.openBox(cacheBoxName);
    return Hive.box(cacheBoxName);
  }

  static void closeCachedBox() async {
    openBoxCount -= 1;

    if (openBoxCount == 0) {
      final cacheBox = Hive.box(cacheBoxName);
      cacheBox.close();
    }
  }
}

class Cache304Interceptor extends Interceptor {
  static const lastModifiedKey = 'last-modified';
  static const dataKey = 'data';
  static const primaryKeyListKey = '@dio_304_cache_primary_key_list_key@';

  @override
  Future onRequest(RequestOptions options) async {
    await _checkToAddIfModifiedSince(options);
    return options;
  }

  @override
  Future onResponse(Response response) async {
    if (response.request.method.toUpperCase() == 'GET') {
      final lastModified = response.headers.value(lastModifiedKey);

      // check if need to push to cache
      if (response.data != null &&
          lastModified != null &&
          (response.statusCode >= 200 && response.statusCode <= 300)) {
        _pushToCache(response.data, lastModified, response.request);
      }

      // take data from cache if 304
      if (response.statusCode == 304) await _appendDataTo304Response(response);
    }

    return super.onResponse(response);
  }

  Future onError(DioError err) async {
    if (err?.response?.statusCode == 304 &&
        err.request.method.toUpperCase() == 'GET')
      return onResponse(
        Response(
          headers: err?.response?.headers,
          statusCode: 304,
          request: err.request,
        ),
      );

    return super.onError(err);
  }

  Future<void> _checkToAddIfModifiedSince(RequestOptions options) async {
    if (options.method.toUpperCase() != 'GET') return;

    final cacheBox = await _Cache304InterceptorStaticFields.getCachedBox();

    final primaryKey = _getPrimaryKeyFromOptions(options);
    final cacheItem = cacheBox.get(primaryKey);
    _Cache304InterceptorStaticFields.closeCachedBox();

    if (cacheItem == null || cacheItem[lastModifiedKey] == null) return;
    options.headers.addAll({'If-Modified-Since': cacheItem[lastModifiedKey]});
  }

  void _pushToCache(
    dynamic data,
    String lastModified,
    RequestOptions options,
  ) async {
    final primaryKey = _getPrimaryKeyFromOptions(options);
    final cacheBox = await _Cache304InterceptorStaticFields.getCachedBox();

    final List<String> cacheKeyList =
        cacheBox.get(primaryKeyListKey, defaultValue: <String>[]);

    if (!cacheKeyList.contains(primaryKey)) {
      cacheKeyList.insert(0, primaryKey);
      cacheBox.put(primaryKey, {
        lastModifiedKey: lastModified,
        dataKey: data,
      });

      if (cacheKeyList.length < _Cache304InterceptorStaticFields.cacheLength) {
        cacheBox.put(primaryKeyListKey, cacheKeyList);
        _Cache304InterceptorStaticFields.closeCachedBox();
        return;
      }

      final removeKeys =
          cacheKeyList.sublist(_Cache304InterceptorStaticFields.cacheLength);
      cacheBox.deleteAll(removeKeys);
      cacheBox.put(
        primaryKeyListKey,
        cacheKeyList.sublist(0, _Cache304InterceptorStaticFields.cacheLength),
      );
      _Cache304InterceptorStaticFields.closeCachedBox();
      return;
    } else { //To update the cache with the latest modified date and data
      cacheBox.put(primaryKey, {
        lastModifiedKey: lastModified,
        dataKey: data,
      });
    }

    _prioritiseKey(cacheBox, cacheKeyList, primaryKey);
    _Cache304InterceptorStaticFields.closeCachedBox();
  }

  Future<void> _appendDataTo304Response(Response response) async {
    final cacheBox = await _Cache304InterceptorStaticFields.getCachedBox();
    final primaryKey = _getPrimaryKeyFromOptions(response.request);
    final cacheItem = cacheBox.get(primaryKey);
    if (cacheItem == null || cacheItem[dataKey] == null) return;
    response.data = cacheItem[dataKey];

    final List<String> cacheKeyList =
        cacheBox.get(primaryKeyListKey, defaultValue: <String>[]);
    _prioritiseKey(cacheBox, cacheKeyList, primaryKey);
    _Cache304InterceptorStaticFields.closeCachedBox();
  }

  Future<void> _prioritiseKey(
    Box cacheBox,
    List<String> cacheKeyList,
    String primaryKey,
  ) async {
    cacheKeyList.remove(primaryKey);
    cacheKeyList.insert(0, primaryKey);
    cacheBox.put(primaryKeyListKey, cacheKeyList);
  }

  String _getPrimaryKeyFromOptions(RequestOptions options) {
    final uri = options.uri;
    final data = options.data;
    return "${uri?.host}${uri?.path}_${data?.toString()}_${uri?.query}";
  }

  //////////////
  // Static methods

  static Future<void> clearCache() async {
    final cacheBox = await _Cache304InterceptorStaticFields.getCachedBox();
    cacheBox.clear();
    _Cache304InterceptorStaticFields.closeCachedBox();
  }

  Future getCacheData(RequestOptions options) async {
    if (options == null) return null;
    final cacheBox = await _Cache304InterceptorStaticFields.getCachedBox();
    final primaryKey = _getPrimaryKeyFromOptions(options);
    final cacheItem = cacheBox.get(primaryKey);
    _Cache304InterceptorStaticFields.closeCachedBox();

    if (cacheItem == null || cacheItem[dataKey] == null) return null;
    return cacheItem[dataKey];
  }
}

////////////////////////////////////////////////////////////////////////////
// init hive database and set interceptor config
Future<void> initCache304Interceptor({Cache304Config config}) async {
  if (config != null && config.cacheLength != null) {
    _Cache304InterceptorStaticFields.cacheLength = config.cacheLength;
  }

  if (config != null && config.cacheBoxName != null) {
    _Cache304InterceptorStaticFields.cacheBoxName = config.cacheBoxName;
  }

  if (config != null && config.hiveInitPath == null) return;

  String appDocumentDirectoryPath = config?.hiveInitPath ?? '';

  if (appDocumentDirectoryPath.isEmpty) {
    final appDocumentDirectory =
        await path_provider.getApplicationDocumentsDirectory();
    appDocumentDirectoryPath = appDocumentDirectory.path;
  }

  Hive.init(appDocumentDirectoryPath);
}
