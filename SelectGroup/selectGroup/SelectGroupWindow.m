//
//  SelectGroupWindow.m
//  MainUI
//
//

#import "SelectGroupWindow.h"
#import "SelectGroupController.h"

@implementation SelectGroupWindow



- (void)windowDidLoad {
    [super windowDidLoad];
    self.window.contentViewController = [SelectGroupController new];
    

}


@end
