#import "CLPUICorePlugin.h"
#import "CLPCore.h"


@implementation CLPUICorePlugin

- (instancetype)initWithCore:(CLPCore *)core
{
    self = [super init];
    if (self) {
        _core = core;
        [_core addSubview:self];
    }
    return self;
}

- (instancetype)init
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"Use initWithCore: instead"
                                 userInfo:nil];
}

@end
