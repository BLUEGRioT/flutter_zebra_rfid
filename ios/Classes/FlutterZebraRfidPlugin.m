#import "FlutterZebraRfidPlugin.h"
#if __has_include(<flutter_zebra_rfid/flutter_zebra_rfid-Swift.h>)
#import <flutter_zebra_rfid/flutter_zebra_rfid-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_zebra_rfid-Swift.h"
#endif

#import "RfidSdkFactory.h"

@implementation FlutterZebraRfidPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  id<srfidISdkApi> api = [srfidSdkFactory createRfidSdkApiInstance];
    
  [SwiftFlutterZebraRfidPlugin registerWithRegistrar:registrar];
}
@end
