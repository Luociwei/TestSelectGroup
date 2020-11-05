//
//  SelectGroupController.h
//  MyBase
//
//  Created by ciwei luo on 2020/9/5.
//  Copyright © 2020 macdev. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "SelectGroupData.h"

NS_ASSUME_NONNULL_BEGIN

typedef struct regDataMap {
    int row;
    int col;
    int selectedRow;
} DataMap;

@interface SelectGroupController : NSViewController<NSOutlineViewDelegate, NSOutlineViewDataSource, NSTextFieldDelegate>
{
    NSArray *csvArray;
    NSString *csvFilePath;
    NSMutableArray *csvContent;
}

@property (assign) IBOutlet NSOutlineView *selectGroupView;
@property (assign) IBOutlet NSPopUpButton *btnSwitch;
@property (assign) IBOutlet NSTextField *textTestPlan;

@property (readwrite, copy) NSArray *csvArray;
@property (readwrite, copy) NSString *csvFilePath;
@property (readwrite, copy) NSMutableArray *csvContent;

- (void)setItemWithPath:(NSString *)path;
- (void)setViewDisplay;
@end

NS_ASSUME_NONNULL_END
