//
//  SelectGroupController.m
//  MyBase
//
//  Created by ciwei luo on 2020/9/5.
//  Copyright © 2020 macdev. All rights reserved.
//

#import "SelectGroupController.h"
#import "SelectGroupData.h"
#import "TextCell.h"
//#include "UICommon.h"

#define kNotificationOnLoadProfile            @"On_ReloadProfileByRecMsg"


@interface SelectGroupController ()

@end

@implementation SelectGroupController
{
    SelectGroupData *root;
    SelectGroupData *testitem;
    SelectGroupData *subtestitem;
    SelectGroupData *subsubtestitem;
    struct regDataMap dataMap;
    NSInteger colLength;
}

@synthesize csvArray;
@synthesize csvFilePath;
@synthesize csvContent;




//@synthesize csvContent;

- (instancetype)init {
    if (self = [super init]) {
        csvArray = nil;
        csvContent = nil;
        csvFilePath = nil;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    //    [self.window center];
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"DefaultCsvPath.plist" ofType:nil];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
    NSString *defaultFile =@"/Users/gdlocal/Suncode_FCT/profile/subScript/FCT__MobileRestore.csv";
    if ([dict objectForKey:@"loadCsvPath"]) {
        defaultFile = [dict objectForKey:@"loadCsvPath"];
    }
    [self setItemWithPath:defaultFile];
    
    [self initSelectGroupView];
    _textTestPlan.stringValue = [csvFilePath lastPathComponent];
    [_textTestPlan sizeToFit];
    _textTestPlan.editable = NO;
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(changeCSVContent:) name:[NSString stringWithUTF8String:"On_NotificationCenterChangeCSVContent"] object:nil];
    //    [[NSNotificationCenter defaultCenter] addObserver:self
    //                                             selector:@selector(windowWillClose:)
    //                                                 name:NSWindowWillCloseNotification
    //                                               object:nil];
    
//
    
    
    [self selectDefault];
}

- (void)initSelectGroupView {
    _selectGroupView.delegate = self;
    _selectGroupView.dataSource = self;
    _selectGroupView.allowsColumnResizing = YES;
    //    _selectGroupView.headerView = nil;
    _selectGroupView.columnAutoresizingStyle = NSTableViewFirstColumnOnlyAutoresizingStyle;
    _selectGroupView.usesAlternatingRowBackgroundColors = YES;//背景颜色的交替，一行白色，一行灰色。
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    [arr addObject:NSPasteboardTypeString];
    [_selectGroupView registerForDraggedTypes:arr];
    [self setViewDisplay];
    //    [self setViewDisplay:[_btnSwitch indexOfSelectedItem]];
    //    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    //    [nc addObserver:self selector:@selector(onLoadData:) name:@"SelectGroup" object:nil];
    
    //    [nc addObserver:self selector:@selector(onLoadData:) name:kNotificationLoadProfile object:nil];
    //    csvContent = [NSArray array];
}

- (void)changeCSVContent:(NSNotification *)nf {
    NSDictionary *dic = [nf userInfo];
    NSString *changeValue = [dic objectForKey:@"value"];
    if (dataMap.col > -1 && dataMap.col <= colLength ) {
        csvContent[dataMap.row][dataMap.col] = changeValue;
    }
    [_selectGroupView.subviews[0] removeFromSuperviewWithoutNeedingDisplay];
    [self setItem];
    [self setViewDisplay];
    [_selectGroupView scrollRowToVisible:dataMap.selectedRow];
}

- (NSArray *)csvSplit:(NSString *)csvLine {
    NSMutableArray *array = [NSMutableArray array];
    int index = 0;
    int flag = 0;
    NSString *lastTemp = nil;
    for(int i=0; i < csvLine.length; i++) {
        NSString *temp = [csvLine substringWithRange:NSMakeRange(i, 1)];
        if ([temp isEqualToString:@"\""] && [lastTemp isEqualToString:@","]) {
            flag++;
            index = i+1;
        } else if ([temp isEqualToString:@","] && [lastTemp isEqualToString:@"\""]) {
            NSString *item = @"";
            if (i>index) {
                item = [csvLine substringWithRange:NSMakeRange(index, i-index-1)];
            }
            [array addObject:item];
            index = i+1;
            flag++;
        } else if ([temp isEqualToString:@","] && flag%2==0) {
            NSString *item = @"";
            if (i>index) {
                item = [csvLine substringWithRange:NSMakeRange(index, i-index)];
            }
            [array addObject:item];
            index = i+1;
        }
        if (i==csvLine.length-1) {
            NSString *item = @"";
            if (i>=index) {
                item = [csvLine substringWithRange:NSMakeRange(index, i-index+1)];
            }
            [array addObject:item];
        }
        lastTemp = temp;
    }
    return [array copy];
}
- (BOOL)parseCSVWithPath:(NSString *)filepath {
    NSMutableArray *arrayM = [NSMutableArray array];
    csvFilePath = [filepath copy];
    _textTestPlan.stringValue = [csvFilePath lastPathComponent];
    [_textTestPlan sizeToFit];
    _textTestPlan.editable = NO;
    //    NSString *filepath=[[NSBundle mainBundle] pathForResource:@"language" ofType:@"csv"];
    FILE *fp = fopen([filepath UTF8String], "r");
    if (fp) {
        char buf[BUFSIZ];
        fgets(buf, BUFSIZ, fp);
        NSString *a = [[NSString alloc] initWithUTF8String:(const char *)buf];
        NSString *aa = [a stringByReplacingOccurrencesOfString:@"\r" withString:@""];
        aa = [aa stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        //获取的是表头的字段
        //        NSArray *b = [aa componentsSeparatedByString:@","];
        NSArray *b = [self csvSplit:aa];
        [arrayM addObject:[NSMutableArray arrayWithArray:b]];
        char buff[BUFSIZ];
        //        while (!feof(fp)) {
        //            char buff[BUFSIZ];
        //            fgets(buff, BUFSIZ, fp);
        while (fgets(buff, BUFSIZ, fp) != NULL) {
            //获取的是内容
            
            NSString *s = [[NSString alloc] initWithUTF8String:(const char *)buff];
            
            if ([s hasPrefix:@"//"]||[s hasPrefix:@"\\"]) {
                continue;
            }
            
            NSString *ss = [s stringByReplacingOccurrencesOfString:@"\r" withString:@""];
            ss = [ss stringByReplacingOccurrencesOfString:@"\n" withString:@""];
            
            //            NSArray *a = [ss componentsSeparatedByString:@","];
            NSArray *a = [self csvSplit:ss];
            if (a.count == 4) {
                NSString *str = a[3];
                NSString *subStr = [self getSubStringBetween:@"\"" and:@"," fullString:str];
                NSString *str1 = [NSString stringWithFormat:@"\"%@,",subStr];
                NSString *str2 = [NSString stringWithFormat:@"%@\",",subStr];
                
                ss = [ss stringByReplacingOccurrencesOfString:str1 withString:str2];
                a = [self csvSplit:ss];
            }
            
            //            NSMutableDictionary *dic = [NSMutableDictionary dictionary];
            //            for (int i = 0; i < b.count ; i ++) {
            //                //组成字典数组
            //                dic[b[i]] = a[i];
            //            }
            // check csv content
            if ([a isKindOfClass:[NSArray class]] && a.count==b.count) {
                [arrayM addObject:[NSMutableArray arrayWithArray:a]];
            }
        }
        //        csvContent = [array copy];
        csvContent = [arrayM copy];
        colLength = [csvContent[0] count];
        return YES;
    }
    return NO;
}

-(NSString *)getSubStringBetween:(NSString *)from and:(NSString *)to fullString:(NSString *)fullString
{
    NSString *mutString = @"";
    if([fullString containsString:from]&&[fullString containsString:to])
    {
        
        NSRange range1 = [fullString rangeOfString:from];
        NSString *str2 = [fullString substringFromIndex:range1.location];
        NSRange range2 = [str2 rangeOfString:to];
        
        //        NSInteger tempLength =range2.location-range1.location-range1.length;
        //        NSRange range = {range1.location+range1.length,tempLength};
        
        mutString = [str2 substringWithRange:NSMakeRange(1,range2.location-1)];
        
    }
    return mutString;
}


- (void)setItem {
    if (root) {
        root = nil;
        [root release];
    }
    root = [[SelectGroupData alloc] init];
    root.name = @"root";
    NSString *lasttestname = @"";
    NSString *lastsubtestname = @"";
    NSString *tSubtestname = @"NULL";
    NSString *tSubsubtestname = @"NULL";
    int testnameCount = 0;
    int subtestnameCount = 0;
    //    csvPath = path;
    if (csvContent){
        //[itemDic setValue:content[0] forKey:@"header"];
        for (int i=1; i<[csvContent count]; i++) {
            if (!csvContent[i][1] || [csvContent[i][1] isEqualToString:@""]) {
                tSubtestname = @"NULL";
            } else {
                tSubtestname = csvContent[i][1];
            }
            if (!csvContent[i][2] || [csvContent[i][2] isEqualToString:@""]) {
                tSubsubtestname = @"NULL";
            } else {
                tSubsubtestname = csvContent[i][2];
            }
            subsubtestitem = nil;
            [subsubtestitem release];
            subsubtestitem = [[SelectGroupData alloc] init];
            [subsubtestitem setIndex:[NSString stringWithFormat:@"%d", i]];
            [subsubtestitem setName:subsubtestitem.index];
            [subsubtestitem setTestname: csvContent[i][0]];
            [subsubtestitem setSubtestname: tSubtestname];
            [subsubtestitem setSubsubtestname: tSubsubtestname];
            for (int j=0; j<[csvContent[0] count]; j++) {
                [subsubtestitem.dict setObject:csvContent[i][j] forKey:csvContent[0][j]];
            }
            if (![csvContent[i][0] isEqualToString:lasttestname]) {
                if (testitem) {
                    [testitem.array addObject:subtestitem];
                    [root.array addObject:testitem];
                    testitem = nil;
                    [testitem release];
                }
                testitem = [[SelectGroupData alloc] init];
                testnameCount ++;
                [testitem setName:[NSString stringWithFormat:@"%d:%@",testnameCount,csvContent[i][0]]];
                [testitem setIndex: [NSString stringWithFormat:@"group%d", testnameCount]];
                [testitem setSubtestname:@"group"];
                [testitem setSubsubtestname:@"group"];
            }
            if (![tSubtestname isEqualToString:lastsubtestname] || ![csvContent[i][0] isEqualToString:lasttestname]) {
                if (subtestitem && [csvContent[i][0] isEqualToString:lasttestname]) {
                    [testitem.array addObject:subtestitem];
                    subtestitem = nil;
                    [subtestitem release];
                }
                subtestitem = [[SelectGroupData alloc] init];
                subtestnameCount ++;
                [subtestitem setIndex: [NSString stringWithFormat:@"sub%d",subtestnameCount]];
                [subtestitem setName:tSubtestname];
                [subtestitem setSubtestname:@"sub"];
                [subtestitem setSubsubtestname:@"sub"];
            }
            [subtestitem.array addObject:subsubtestitem];
            lasttestname = csvContent[i][0];
            lastsubtestname = tSubtestname;
        }
        [testitem.array addObject:subtestitem];
        [root.array addObject:testitem];
        testitem = nil;
        subtestitem = nil;
        subsubtestitem = nil;
        [testitem release];
        [subtestitem release];
        [subsubtestitem release];
    } else {
        NSLog(@"csv content is nil");
    }
    //    [self setViewDisplay];
    //    [_selectGroupView reloadData];
}


- (void)setItemWithPath:(NSString *)path {
    csvContent = nil;
    if ([self parseCSVWithPath:path]){
        [self setItem];
    } else {
        NSLog(@"open file FAIL");
    }
}

- (NSArray *)getSelectIndex {
    //    if (selectIndex) {
    //        [selectIndex release];
    //    }
    NSMutableArray *selectIndex = [NSMutableArray array];
    for (SelectGroupData *testname in root.array) {
        for (SelectGroupData *subtestname in testname.array) {
            for (SelectGroupData *subsubtestname in subtestname.array) {
                if ([subsubtestname.state isEqualToString:@"on"]||[subsubtestname.state isEqualToString:@"fix"]) {
                    [selectIndex addObject:subsubtestname.index];
                }
            }
        }
    }
    return selectIndex;
}

- (NSArray *)getDebugCSVContentWithIndex:(NSArray *) indexArray {
    NSMutableArray *debugCSVArr = [NSMutableArray array];
    NSMutableString *debugCSV = [NSMutableString string];
    for (NSString *item in csvContent[0]) {
        if ([item containsString:@","] || [item containsString:@"\""]) {
            [debugCSV appendString:[NSString stringWithFormat:@"\"%@\",", item]];
        } else {
            [debugCSV appendString:[NSString stringWithFormat:@"%@,", item]];
        }
    }
    [debugCSV deleteCharactersInRange:NSMakeRange([debugCSV length]-1, 1)];
    [debugCSVArr addObject:[debugCSV copy]];
    [debugCSV setString:@""];
    for (NSString *index in indexArray) {
        NSInteger count = [index integerValue];
        for (NSString *i in csvContent[count]) {
            if ([i containsString:@","] || [i containsString:@"\""]) {
                [debugCSV appendString:[NSString stringWithFormat:@"\"%@\",", i]];
            } else {
                [debugCSV appendString:[NSString stringWithFormat:@"%@,", i]];
            }
        }
        [debugCSV deleteCharactersInRange:NSMakeRange([debugCSV length]-1, 1)];
        //        [debugCSV appendString:@"\r\n"];
        [debugCSVArr addObject:[debugCSV copy]];
        [debugCSV setString:@""];
    }
    //    [debugCSV release];
    return [debugCSVArr copy];
}

- (NSString *)getLocalTime{
    NSDate *date = [NSDate date];
    NSTimeZone *zone = [NSTimeZone systemTimeZone];
    NSTimeInterval interval = [zone secondsFromGMTForDate:date];
    NSDate *current = [date dateByAddingTimeInterval:interval];
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    //    [formatter setDateFormat:@"G yyyy-MM-dd E D F w W a z HH:mm:ss.SSS"];
    [formatter setDateFormat:@"yyyy_MM_dd_HH_mm_ss"];
    NSString* dateStr = [formatter stringFromDate:current];
    return dateStr;
}

- (NSString*)createFileWithFullPath:(NSString *)fullPath{
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isExist = [fm fileExistsAtPath:fullPath];
    if (isExist) {
        [fm removeItemAtPath:fullPath error:nil];
    }
    BOOL ret = [fm createFileAtPath:fullPath contents:nil attributes:nil];//执行了这句话就已经创建
    if (ret) {
        //        NSLog(@"文件创建成功");
        return fullPath;
    }
    return fullPath;
}

- (IBAction)btnSave:(id)sender {
    NSArray *indexArray = [[self getSelectIndex] copy];
    csvArray = [self getDebugCSVContentWithIndex:indexArray];
    NSString *fileName = [csvFilePath.lastPathComponent stringByDeletingPathExtension];
    // NSString *path = [NSString stringWithFormat:@"%@_%@.csv", fileName, [self getLocalTime]];
    NSString *path = [NSString stringWithFormat:@"/Users/gdlocal/Suncode_FCT/profile/subScript/%@_debug.csv",fileName];
    NSString *nTestPlan = [self createFileWithFullPath:path];
    NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:nTestPlan];
    [fh truncateFileAtOffset:0];
    for (NSString *str in csvArray) {
        [fh writeData:[[NSString stringWithFormat:@"%@\r\n", str] dataUsingEncoding:NSUTF8StringEncoding]];
        [fh seekToEndOfFile];
    }
    [fh closeFile];
}

- (IBAction)btnRefresh:(id)sender {
    csvContent = nil;
    if ([self parseCSVWithPath:csvFilePath]){
        [self setItem];
    } else {
        NSLog(@"open file FAIL");
    }
    [self setViewDisplay];
}

- (void)selectDefault {
    

    [self btnClearAll:nil];
    
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"DefaultCsvPath.plist" ofType:nil];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
    NSArray *arr =nil;
    if ([dict objectForKey:@"unSelectItems"]) {
        NSString *unselectItems = [dict objectForKey:@"unSelectItems"];
        if ([unselectItems containsString:@","]) {
            arr = [unselectItems componentsSeparatedByString:@","];
        }
    }
    
    int i =1;
    for (SelectGroupData *testname in root.array) {
//        if (i>8&&i<=root.array.count-8) {
//            i++;
//            continue;
//
//        }
        if (arr.count) {
            if (![arr containsObject:[NSString stringWithFormat:@"%d",i]]) {
                i++;
                continue;
            }
        }
        [testname setState:@"fix"];
        for (SelectGroupData *subtestname in testname.array) {
            [subtestname setState:@"fix"];
            for (SelectGroupData *subsubtestname in subtestname.array) {
                [subsubtestname setState:@"fix"];
            }
        }
        
        i++;
    }
    [_selectGroupView reloadData];
}


- (IBAction)btnSelectAll:(id)sender {
    for (SelectGroupData *testname in root.array) {
        [testname setState:@"on"];
        for (SelectGroupData *subtestname in testname.array) {
            [subtestname setState:@"on"];
            for (SelectGroupData *subsubtestname in subtestname.array) {
                [subsubtestname setState:@"on"];
            }
        }
    }
    [_selectGroupView reloadData];
}

- (IBAction)btnClearAll:(id)sender {
    for (SelectGroupData *testname in root.array) {
        [testname setState:@"off"];
        for (SelectGroupData *subtestname in testname.array) {
            [subtestname setState:@"off"];
            for (SelectGroupData *subsubtestname in subtestname.array) {
                [subsubtestname setState:@"off"];
            }
        }
    }
    [_selectGroupView reloadData];
}

- (IBAction)btnSelectOK:(id)sender {
    //    NSArray *indexArray = [[self getSelectIndex] copy];
    //    csvArray = [self getDebugCSVContentWithIndex:indexArray];
    ////    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:debugCSVArray forKey:@"csvContent"];
    //    [[NSNotificationCenter defaultCenter] postNotificationName:@"SelectGroup" object:nil userInfo:nil];
    //    [self close];
    //    [self release];
    
    
    [self btnSave:nil];
    [NSThread sleepForTimeInterval:0.5];
    NSString *fileName = [csvFilePath.lastPathComponent stringByDeletingPathExtension];
    NSString *csvName = [NSString stringWithFormat:@"%@_debug.csv",fileName];//@"FCT__MobileRestore_debug.csv";//  [listCsvName valueForKey:@"USB3TEST"];
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:
                         csvName,@"Load_Profile_Debug",nil];
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:kNotificationOnLoadProfile object:nil userInfo:dic deliverImmediately:YES];
    [NSThread sleepForTimeInterval:0.5];
    //[self close];
    [self release];
    [NSApp terminate:nil];
    
    
    
    
}

- (void)setViewDisplay {
    [_selectGroupView reloadData];
    NSInteger state = [_btnSwitch indexOfSelectedItem];
    if (state == 0) {
        [_selectGroupView collapseItem:nil collapseChildren:YES];
        //        [_selectGroupView expandItem:nil expandChildren:NO];
    } else if (state == 1) {
        for (SelectGroupData *testitem in root.array) {
            [_selectGroupView expandItem: testitem];
            for (SelectGroupData *subtestitem in testitem.array) {
                [_selectGroupView collapseItem: subtestitem];
            }
        }
    } else if (state == 2) {
        [_selectGroupView expandItem:nil expandChildren:YES];
    }
}

- (IBAction)btnSwitch:(id)sender {
    //    NSPopUpButton *btnSelect = (NSPopUpButton *)sender;
    [self setViewDisplay];
}

//- (void)setRepresentedObject:(id)representedObject {
//    [super setRepresentedObject:representedObject];
//    // Update the view, if already loaded.
//}


// datasource
- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    if(!item) {
        return [[root array] objectAtIndex:index];
    }else {
        return [[(SelectGroupData *)item array] objectAtIndex:index];
    }
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    NSInteger number = (item == nil) ? [[root array] count] : [[(SelectGroupData *)item array] count];
    return number;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    SelectGroupData *root = (SelectGroupData *)item;
    return [[root array] count];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldExpandItem:(id)item
{
    SelectGroupData *root = (SelectGroupData *)item;
    return [[root array] count];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldShowCellExpansionForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    return YES;
}
//- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
////    id objectValue = nil;
//    if ([[item representedObject] isKindOfClass:[SelectGroupData class]]) {
//        SelectGroupData *nodeData = [item representedObject];
//        return nodeData.name;
//    }
//    return @"";
//}

- (IBAction)checkboxChanged:(id)sender {
    NSButtonCell *aCell = [[sender tableColumnWithIdentifier:@"switch"]
                           dataCellForRow:[sender selectedRow]];
    if ([aCell state] == NSOnState) {
        NSLog(@"ON");
        [aCell setState:NSOffState];
    } else {
        NSLog(@"OFF");
        [aCell setState:NSOnState];
    }
}

- (NSCell *)outlineView:(NSOutlineView *)outlineView dataCellForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    if (tableColumn == nil) {
        return nil;
    }
    //    NSCell *cell = [tableColumn dataCell];
    //    MyEditorCell *cell = [[MyEditorCell alloc] init];
    NSString *identity = [tableColumn identifier];
    SelectGroupData *data = (SelectGroupData *)item;
    NSString *state = data.state;
    if ([identity isEqualToString:@"switch"]){
        NSButtonCell *btnCell = [[NSButtonCell alloc] init];
        [btnCell setSelectable:YES];
        [btnCell setEnabled:YES];
        [btnCell setTransparent:NO];
        //        [btnCell setTarget:self];
        //        [btnCell setAction:@selector(checkboxChanged:)];
        [btnCell setButtonType:NSSwitchButton];
        [btnCell setTitle:@""];
        if ([state isEqualToString:@"on"]) {
            btnCell.state = NSOnState;
        } else if ([state isEqualToString:@"off"]) {
            btnCell.state = NSOffState;
        }else{
            btnCell.state = NSOnState;
            [btnCell setEnabled:NO];
        }
        return btnCell;
    } else {
        TextCell *textCell = [[TextCell alloc] init];
        
        return textCell;
        //        [cell.controlView addSubview:text];
    }
    return nil;
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    SelectGroupData *data = (SelectGroupData *)item;
    NSString *rawIndex = data.index;
    NSString *identifier = [tableColumn identifier];
    if ([identifier isEqualToString:@"testname"]) {
        TextCell *textCell = (TextCell *)cell;
        if ([data.index containsString:@"group"]) {
            rawIndex = [data.index stringByReplacingOccurrencesOfString:@"group" withString:@""];
            [textCell setBackgroundColor:[NSColor lightGrayColor]];
            NSInteger colIndex = [csvContent[0] indexOfObject:@"TESTNAME"];
            [textCell setIdentifier:[NSString stringWithFormat:@"%@_%ld", rawIndex, (long)colIndex]];
        } else if([data.index containsString:@"sub"]) {
            [textCell setBackgroundColor:[NSColor clearColor]];
        } else {
            [textCell setBackgroundColor:[NSColor clearColor]];
        }
        [textCell setDrawsBackground:YES];
        [textCell setStringValue:data.name];
    } else if([identifier isEqualToString:@"subtestname"]) {
        TextCell *textCell = (TextCell *)cell;
        if ([data.subtestname containsString:@"group"]) {
            [textCell setBackgroundColor:[NSColor lightGrayColor]];
        } else if([data.subtestname containsString:@"sub"]) {
            [textCell setBackgroundColor:[NSColor clearColor]];
        } else {
            [textCell setBackgroundColor:[NSColor clearColor]];
            [textCell setStringValue:data.subtestname];
            NSInteger colIndex = [csvContent[0] indexOfObject:@"SUBTESTNAME"];
            [textCell setIdentifier:[NSString stringWithFormat:@"%@_%ld", rawIndex, (long)colIndex]];
        }
        [textCell setDrawsBackground:YES];
    } else if([identifier isEqualToString:@"subsubtestname"] && data.subsubtestname) {
        TextCell *textCell = (TextCell *)cell;
        if ([data.subsubtestname containsString:@"group"]) {
            //            [textCell setBackgroundColor:[NSColor lightGrayColor]];
        } else if([data.subsubtestname containsString:@"sub"]) {
            [textCell setBackgroundColor:[NSColor clearColor]];
        } else {
            [textCell setBackgroundColor:[NSColor clearColor]];
            [textCell setStringValue:data.subsubtestname];
            NSInteger colIndex = [csvContent[0] indexOfObject:@"SUBSUBTESTNAME"];
            [textCell setIdentifier:[NSString stringWithFormat:@"%@_%ld", rawIndex, (long)colIndex]];
        }
        [textCell setDrawsBackground:YES];
    } else if([identifier isEqualToString:@"switch"]) {
        NSButtonCell *btnCell = cell;
        if ([data.state isEqualToString:@"on"]) {
            btnCell.state = NSOnState;
        }else if ([data.state isEqualToString:@"off"]) {
            btnCell.state = NSOffState;
        }else{
            btnCell.state = NSOnState;
            [btnCell setEnabled:NO];
        }
    } else if([identifier isEqualToString:@"unit"] && data.subsubtestname) {
        TextCell *textCell = (TextCell *)cell;
        //        NSLog(@"textCell  = %@", textCell.changeValue);
        if (![data.subsubtestname containsString:@"group"] && ![data.subsubtestname containsString:@"sub"] && [data.dict valueForKey:@"UNIT"]) {
            [textCell setStringValue:[data.dict valueForKey:@"UNIT"]];
            NSInteger colIndex = [csvContent[0] indexOfObject:@"UNIT"];
            [textCell setIdentifier:[NSString stringWithFormat:@"%@_%ld", rawIndex, (long)colIndex]];
        }
    } else if([identifier isEqualToString:@"low"] && data.subsubtestname) {
        TextCell *textCell = (TextCell *)cell;
        if (![data.subsubtestname containsString:@"group"] && ![data.subsubtestname containsString:@"sub"] && [data.dict valueForKey:@"LOW"]) {
            [textCell setStringValue:[data.dict valueForKey:@"LOW"]];
            NSInteger colIndex = [csvContent[0] indexOfObject:@"LOW"];
            [textCell setIdentifier:[NSString stringWithFormat:@"%@_%ld", rawIndex, (long)colIndex]];
        }
    } else if([identifier isEqualToString:@"high"] && data.subsubtestname) {
        TextCell *textCell = (TextCell *)cell;
        if (![data.subsubtestname containsString:@"group"] && ![data.subsubtestname containsString:@"sub"] && [data.dict valueForKey:@"HIGH"]) {
            [textCell setStringValue:[data.dict valueForKey:@"HIGH"]];
            NSInteger colIndex = [csvContent[0] indexOfObject:@"HIGH"];
            [textCell setIdentifier:[NSString stringWithFormat:@"%@_%ld", rawIndex, (long)colIndex]];
        }
    } else if([identifier isEqualToString:@"function"] && data.subsubtestname) {
        TextCell *textCell = (TextCell *)cell;
        if (![data.subsubtestname containsString:@"group"] && ![data.subsubtestname containsString:@"sub"] && [data.dict valueForKey:@"FUNCTION"]) {
            [textCell setStringValue:[data.dict valueForKey:@"FUNCTION"]];
            NSInteger colIndex = [csvContent[0] indexOfObject:@"FUNCTION"];
            [textCell setIdentifier:[NSString stringWithFormat:@"%@_%ld", rawIndex, (long)colIndex]];
        }
    } else if([identifier isEqualToString:@"param1"] && data.subsubtestname) {
        TextCell *textCell = (TextCell *)cell;
        if (![data.subsubtestname containsString:@"group"] && ![data.subsubtestname containsString:@"sub"] && [data.dict valueForKey:@"PARAM1"]) {
            [textCell setStringValue:[data.dict valueForKey:@"PARAM1"]];
            NSInteger colIndex = [csvContent[0] indexOfObject:@"PARAM1"];
            [textCell setIdentifier:[NSString stringWithFormat:@"%@_%ld", rawIndex, (long)colIndex]];
        }
    } else if([identifier isEqualToString:@"param2"] && data.subsubtestname) {
        TextCell *textCell = (TextCell *)cell;
        if (![data.subsubtestname containsString:@"group"] && ![data.subsubtestname containsString:@"sub"] && [data.dict valueForKey:@"PARAM2"]) {
            [textCell setStringValue:[data.dict valueForKey:@"PARAM2"]];
            NSInteger colIndex = [csvContent[0] indexOfObject:@"PARAM2"];
            [textCell setIdentifier:[NSString stringWithFormat:@"%@_%ld", rawIndex, (long)colIndex]];
        }
    } else if([identifier isEqualToString:@"key"] && data.subsubtestname) {
        TextCell *textCell = (TextCell *)cell;
        if (![data.subsubtestname containsString:@"group"] && ![data.subsubtestname containsString:@"sub"] && [data.dict valueForKey:@"KEY"]) {
            [textCell setStringValue:[data.dict valueForKey:@"KEY"]];
            NSInteger colIndex = [csvContent[0] indexOfObject:@"KEY"];
            [textCell setIdentifier:[NSString stringWithFormat:@"%@_%ld", rawIndex, (long)colIndex]];
        }
    } else if([identifier isEqualToString:@"val"] && data.subsubtestname) {
        TextCell *textCell = (TextCell *)cell;
        if (![data.subsubtestname containsString:@"group"] && ![data.subsubtestname containsString:@"sub"] && [data.dict valueForKey:@"VAL"]) {
            [textCell setStringValue:[data.dict valueForKey:@"VAL"]];
            NSInteger colIndex = [csvContent[0] indexOfObject:@"VAL"];
            [textCell setIdentifier:[NSString stringWithFormat:@"%@_%ld", rawIndex, (long)colIndex]];
        }
    } else if([identifier isEqualToString:@"fail_count"] && data.subsubtestname) {
        TextCell *textCell = (TextCell *)cell;
        if (![data.subsubtestname containsString:@"group"] && ![data.subsubtestname containsString:@"sub"] && [data.dict valueForKey:@"FAIL_COUNT"]) {
            [textCell setStringValue:[data.dict valueForKey:@"FAIL_COUNT"]];
            NSInteger colIndex = [csvContent[0] indexOfObject:@"FAIL_COUNT"];
            [textCell setIdentifier:[NSString stringWithFormat:@"%@_%ld", rawIndex, (long)colIndex]];
        }
    } else if([identifier isEqualToString:@"timeout"] && data.subsubtestname) {
        TextCell *textCell = (TextCell *)cell;
        if (![data.subsubtestname containsString:@"group"] && ![data.subsubtestname containsString:@"sub"] && [data.dict valueForKey:@"TIMEOUT"]) {
            [textCell setStringValue:[data.dict valueForKey:@"TIMEOUT"]];
            NSInteger colIndex = [csvContent[0] indexOfObject:@"TIMEOUT"];
            [textCell setIdentifier:[NSString stringWithFormat:@"%@_%ld", rawIndex, (long)colIndex]];
        }
    } else if([identifier isEqualToString:@"retest_policy"] && data.subsubtestname) {
        TextCell *textCell = (TextCell *)cell;
        if (![data.subsubtestname containsString:@"group"] && ![data.subsubtestname containsString:@"sub"] && [data.dict valueForKey:@"RETEST_POLICY"]) {
            [textCell setStringValue:[data.dict valueForKey:@"RETEST_POLICY"]];
            NSInteger colIndex = [csvContent[0] indexOfObject:@"RETEST_POLICY"];
            [textCell setIdentifier:[NSString stringWithFormat:@"%@_%ld", rawIndex, (long)colIndex]];
        }
    } else if([identifier isEqualToString:@"description"] && data.subsubtestname) {
        TextCell *textCell = (TextCell *)cell;
        if (![data.subsubtestname containsString:@"group"] && ![data.subsubtestname containsString:@"sub"] && [data.dict valueForKey:@"DESCRIPTION"]) {
            [textCell setStringValue:[data.dict valueForKey:@"DESCRIPTION"]];
            NSInteger colIndex = [csvContent[0] indexOfObject:@"DESCRIPTION"];
            [textCell setIdentifier:[NSString stringWithFormat:@"%@_%ld", rawIndex, (long)colIndex]];
        }
    } else if([identifier isEqualToString:@"extension1"] && data.subsubtestname) {
        TextCell *textCell = (TextCell *)cell;
        if (![data.subsubtestname containsString:@"group"] && ![data.subsubtestname containsString:@"sub"] && [data.dict valueForKey:@"EXTENSION1"]) {
            [textCell setStringValue:[data.dict valueForKey:@"EXTENSION1"]];
            NSInteger colIndex = [csvContent[0] indexOfObject:@"EXTENSION1"];
            [textCell setIdentifier:[NSString stringWithFormat:@"%@_%ld", rawIndex, (long)colIndex]];
        }
    } else if([identifier isEqualToString:@"extension2"] && data.subsubtestname) {
        TextCell *textCell = (TextCell *)cell;
        if (![data.subsubtestname containsString:@"group"] && ![data.subsubtestname containsString:@"sub"] && [data.dict valueForKey:@"EXTENSION2"]) {
            [textCell setStringValue:[data.dict valueForKey:@"EXTENSION2"]];
            NSInteger colIndex = [csvContent[0] indexOfObject:@"EXTENSION2"];
            [textCell setIdentifier:[NSString stringWithFormat:@"%@_%ld", rawIndex, (long)colIndex]];
        }
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    return YES;
}

//- (BOOL)outlineView:(NSOutlineView *)outlineView shouldShowOutlineCellForItem:(id)item {
//    //    NSLog(@"shouldShowOutlineCellForItem");
//    return YES;
//}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldTrackCell:(NSCell *)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    NSRange aRange = [_selectGroupView rowsInRect:_selectGroupView.enclosingScrollView.contentView.visibleRect];
    dataMap.selectedRow = (int)aRange.location + (int)aRange.length - 1;
    if ([cell isKindOfClass:[TextCell class]]) {
        TextCell *textCell = (TextCell *)cell;
        NSString *tmpStr = [NSString stringWithFormat:@"%@", textCell.identifier];
        NSArray *tmpArr = [tmpStr componentsSeparatedByString:@"_"];
        dataMap.row = [tmpArr[0] intValue];
        dataMap.col = [tmpArr[1] intValue];
    } else if ([cell isKindOfClass:[NSButtonCell class]]) {
        dataMap.row = -1;
        dataMap.col = -1;
    } else {
        return NO;
    }
    return YES;
}

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    SelectGroupData *data = (SelectGroupData *)item;
    NSString *identifier = [tableColumn identifier];
    if([identifier isEqualToString:@"switch"]) {
        if ([data.state isEqualToString:@"on"]) {
            [data setState:@"off"];
            if ([data.index containsString:@"group"]) {
                for (SelectGroupData *subgroup in data.array) {
                    [subgroup setState:@"off"];
                    for (SelectGroupData *item in subgroup.array) {
                        [item setState:@"off"];
                    }
                }
            } else if ([data.index containsString:@"sub"]){
                for (SelectGroupData *item in data.array) {
                    [item setState:@"off"];
                }
            }
        } else {
            [data setState:@"on"];
            if ([data.index containsString:@"group"]) {
                
                //                NSInteger int_index = [self getIndexWithSelectGroupDataIndex:data.index];
                //                int i =1;
                //                for (SelectGroupData *testitem in root.array){
                //
                //                    for (SelectGroupData *subgroup in testitem.array) {
                //                        [subgroup setState:@"on"];
                //                        for (SelectGroupData *item in subgroup.array) {
                //                            [item setState:@"on"];
                //                        }
                //                    }
                //                    [testitem setState:@"on"];
                //                    if (i==int_index) {
                //                        break;
                //                    }
                //                    i++;
                //
                //                }
                
                for (SelectGroupData *subgroup in data.array) {
                    [subgroup setState:@"on"];
                    for (SelectGroupData *item in subgroup.array) {
                        [item setState:@"on"];
                    }
                }
                
            } else if ([data.index containsString:@"sub"]){
                for (SelectGroupData *item in data.array) {
                    [item setState:@"on"];
                }
            }
        }
        [_selectGroupView reloadData];
    }
}


-(NSInteger)getIndexWithSelectGroupDataIndex:(NSString *)dataIndex{
    
    NSString *str_index = [dataIndex stringByReplacingOccurrencesOfString:@"group" withString:@""];
    return str_index.integerValue;
}

//
- (id<NSPasteboardWriting>)outlineView:(NSOutlineView *)outlineView pasteboardWriterForItem:(id)item {
    SelectGroupData *data = (SelectGroupData *)item;
    if ([data isKindOfClass:[SelectGroupData class]]){
        NSPasteboardItem* pbItem = [[NSPasteboardItem alloc] init];
        [pbItem setString:data.index forType:NSPasteboardTypeString];
        return pbItem;
    }
    return nil;
}

- (NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id<NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)index{
    bool canDrag = index>=0 && item!=nil;
    if (!canDrag){
        return NSDragOperationNone;
    }
    return NSDragOperationMove;
}

- (void)moveObject:(SelectGroupData *)data fromIndex:(int)fromIndex toIndex:(int)toIndex
{
    if (toIndex != fromIndex && fromIndex < [data.array count] && toIndex<= [data.array count]) {
        id obj = [data.array objectAtIndex:fromIndex];
        if (fromIndex < toIndex) {
            toIndex --;
            toIndex = toIndex==-1?0:toIndex;
        }
        [obj retain];
        [data.array removeObjectAtIndex:fromIndex];
        if (toIndex >= [data.array count]) {
            [data.array addObject:obj];
        } else {
            [data.array insertObject:obj atIndex:toIndex];
        }
        [obj release];
    }
}


- (BOOL)rootMoveObjAiRootIdx:(NSString *)idx0 withObjAtIdx1:(int)idx1 withObjAtIdx2:(int)idx2{
    for (SelectGroupData *testitem in root.array) {
        if ([testitem.index isEqualToString:idx0]) {
            [self moveObject:root fromIndex:idx1 toIndex:idx2];
            return YES;
        }
        for (SelectGroupData *subtestitem in testitem.array) {
            if ([subtestitem.index isEqualToString:idx0]) {
                [self moveObject:testitem fromIndex:idx1 toIndex:idx2];
                return YES;
            }
            for (SelectGroupData *subsubtestitem in subtestitem.array) {
                if ([subsubtestitem.index isEqualToString:idx0]) {
                    [self moveObject:subtestitem fromIndex:idx1 toIndex:idx2];
                    return YES;
                }
            }
        }
    }
    return YES;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id<NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)index{
    NSPasteboard* pb = [info draggingPasteboard];
    NSString *name = [pb stringForType:NSPasteboardTypeString];
    //    NSTreeNode *sourceNode = nil;
    SelectGroupData *data = (SelectGroupData *)item;
    NSString *sourceIndex = nil;
    if(data.array != nil){
        int i = 0;
        for(SelectGroupData *subitem in data.array){
            if([subitem isKindOfClass:[SelectGroupData class]]){
                if([subitem.index isEqualToString:name]){
                    sourceIndex = subitem.index;
                    //                    [data.array exchangeObjectAtIndex:i withObjectAtIndex:index];
                    [self rootMoveObjAiRootIdx:sourceIndex withObjAtIdx1:i withObjAtIdx2:(int)index];
                    [_selectGroupView reloadData];
                    return YES;
                }
            }
            i++;
        }
    }
    if(sourceIndex == nil){
        return NO;
    }
    //    NSUInteger indexs[] ={0,index};
    //    NSIndexPath* toIndexPath = [[NSIndexPath alloc] initWithIndexes:indexs length:2];
    //    [_treeController moveNode:sourceNode toIndexPath:toIndexPath];
    return NO;
}

- (void)dealloc {
    _selectGroupView.delegate = nil;
    _selectGroupView.dataSource = nil;
    root = nil;
    csvContent = nil;
    [super dealloc];
}

//- (void)windowWillClose:(NSNotification *)notification
//{
//
//    NSWindow *window = notification.object;
//    if(window == self.window) {
//        [NSApp terminate:self];
//        // [[NSApplication sharedApplication] terminate:nil];  //或这句也行
//    }
//}
//- (void)windowWillClose:(NSNotification *)notification {
//
//    [[NSApplication sharedApplication] stopModal];
//
//    if (sessionCode != 0) {
//        [[NSApplication sharedApplication]endModalSession:sessionCode];
//    }
//}
@end
