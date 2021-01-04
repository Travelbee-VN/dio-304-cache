[dio_304_cache](https://pub.dev/packages/path_provider)

### What does this package do?

- Save `last-modified` header and `data` from http response to app database when making `GET` request the first time (only work if request method is `GET` and reponse header has `last-modified`). <sup>(1)</sup>
- Append `if-modified-since` to request header if making the same `GET` request described in <sup>(1)</sup>.
- If reponse status code is `304`, get the data from previous saved reponse and put it in `data`.

_This package uses [Hive](https://pub.dev/packages/hive) as database resource with __LRU__ cache strategy. If your project uses Hive too, please read below for advoiding conflict configuration._


### Quick start:
1) include the package to your project as dependency:

```
dependencies:
  	dio_304_cache: <latest version>
```

2) In your main function, call `initCache304Interceptor` to initialize the database:

```dart
import 'package:dio_304_cache/dio_304_cache.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initCache304Interceptor();
  runApp(MyApp());
}
```

3) Add `Cache304Interceptor`to dio instance interceptor:
```
    final dio = Dio();
    dio.interceptors.add(Cache304Interceptor());
```

__Go to [example project](https://github.com/Travelbee-VN/dio-304-cache/tree/master/example) for full testing code.__

### Configuration:
+ When calling `initCache304Interceptor `, you can pass a `Cache304Config` object to adjust following properies: 

| Property name      | Type | Default Value |  Description |
| ------------------ | ---- | ------------- | ------------ |
| cacheLength | int | 25 | ___LRU___ is used for cache strategy, if saved data length exceeds this number, the one with least used will be removed. |
| cacheBoxName | String | dio_304_cache_hive_box | the box name used to save data. |
| hiveInitPath | String | use [path_provider](https://pub.dev/packages/path_provider) as Hive path init | path to save your app data. If your app already called `Hive.init(<your_path>)`, set this property to null to prevent re-initialization. Or you can provide your own path. |

_example:_ 
``` 
  await initCache304Interceptor(config: Cache304Config(cacheLength: 50));
```

To clear cache, use:
``` 
  await Cache304Interceptor.clearCache();
```