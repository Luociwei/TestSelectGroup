//
//  SelectGroupData.m
//  MainUI
//
//

#import "SelectGroupData.h"

//@implementation SelectGroupData

@implementation SelectGroupData

@synthesize state;
@synthesize index;
@synthesize name;
@synthesize testname;
@synthesize subtestname;
@synthesize subsubtestname;

@synthesize array;
@synthesize dict;

-(id)init
{
    state = @"on";
    index = @"-1";
    name = nil;
    testname = nil;
    subtestname = nil;
    subsubtestname = nil;
    
    array = [NSMutableArray new];
    dict = [NSMutableDictionary new];
    return self;
}

- (id)initWithItem:(NSString *)item {
    if (self = [super init]) {
        name = item;
    }
    return self;
}

-(void)setState:(NSString *)stat{
    if (![state isEqualToString:@"fix"]) {
 
        state = stat;
    }
}

@end
