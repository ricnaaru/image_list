#import "ImageListPlugin.h"
#import <image_list/image_list-Swift.h>

@implementation ImageListPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftImageListPlugin registerWithRegistrar:registrar];
}
@end
