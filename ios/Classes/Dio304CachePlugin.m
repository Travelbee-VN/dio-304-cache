#import "Dio304CachePlugin.h"
#if __has_include(<dio_304_cache/dio_304_cache-Swift.h>)
#import <dio_304_cache/dio_304_cache-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "dio_304_cache-Swift.h"
#endif

@implementation Dio304CachePlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftDio304CachePlugin registerWithRegistrar:registrar];
}
@end
