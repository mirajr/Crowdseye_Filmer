#import "CLPLoader.h"

#import "CLPUICorePlugin.h"
#import "CLPUIContainerPlugin.h"
#import "CLPAVFoundationPlayback.h"
#import "CLPSpinnerThreeBouncePlugin.h"


@interface CLPLoader ()
{
    NSArray *_playbackPlugins;
    NSArray *_containerPlugins;
    NSArray *_corePlugins;
}

@end


@implementation CLPLoader

+ (instancetype)sharedLoader
{
    static CLPLoader *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });

    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _playbackPlugins = @[[CLPAVFoundationPlayback class]];
        _containerPlugins = @[[CLPSpinnerThreeBouncePlugin class]];
        _corePlugins = @[];
    }
    return self;
}

- (BOOL)containsPlugin:(Class)pluginClass
{
    NSArray *plugins;
    if ([pluginClass isSubclassOfClass:[CLPPlayback class]]) {
        plugins = self.playbackPlugins;
    } else if ([pluginClass isSubclassOfClass:[CLPUIContainerPlugin class]]) {
        plugins = self.containerPlugins;
    } else if ([pluginClass isSubclassOfClass:[CLPUICorePlugin class]]) {
        plugins = self.corePlugins;
    }

    __block NSInteger pluginIndex = NSNotFound;
    [plugins enumerateObjectsUsingBlock:^(Class objClass, NSUInteger idx, BOOL *stop) {
        if ([objClass isSubclassOfClass:pluginClass]) {
            pluginIndex = idx;
            *stop = YES;
        }
    }];

    return pluginIndex != NSNotFound;
}

@end
