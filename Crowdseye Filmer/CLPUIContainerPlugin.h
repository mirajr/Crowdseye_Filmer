#import "CLPUIPlugin.h"

@class CLPContainer;


@interface CLPUIContainerPlugin : CLPUIPlugin

@property (nonatomic, weak) CLPContainer *container;

- (void)wasInstalled;

@end
