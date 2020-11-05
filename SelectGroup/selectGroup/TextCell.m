//
//  TextCell.m
//  MainUI

//

#import "TextCell.h"
#import "SelectGroupData.h"

extern  SelectGroupData *root;

@implementation TextCell

//@synthesize changeValue;

- (id)init {
    self = [super init];
    if (self) {
        [self setEnabled:YES];
        [self setEditable:YES];
        [self setSelectable:YES];
    }
    return self;
}

- (void)dealloc {
    [super dealloc];
}

//- (NSText *)setUpFieldEditorAttributes:(NSText *)textObj {
////    NSText *text = [super setUpFieldEditorAttributes:textObj];
//    NSLog(@"zhimin debug 1101, text = %@", textObj.string);
//    return nil;
//}

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor {
    return YES;
}

- (void)endEditing:(NSText *)textObj {
//    NSText *text = [super setUpFieldEditorAttributes:textObj];
//    changeValue = textObj.string;
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:textObj.string, @"value", nil];
    self.state = NO;
    self.enabled = NO;
    self.editable = NO;
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"On_NotificationCenterChangeCSVContent" object:nil userInfo:userInfo deliverImmediately:YES];
}

@end
