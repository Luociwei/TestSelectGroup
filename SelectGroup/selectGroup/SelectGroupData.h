//
//  SelectGroupData.h
//  MainUI
//

//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SelectGroupData : NSObject

{
    NSString *name;
    NSMutableArray *array;
    NSMutableDictionary *dict;
    NSString *testname;
    NSString *subtestname;
    NSString *subsubtestname;
}

@property (nonatomic, copy) NSString *state;
@property (readwrite, copy) NSString *index;
@property (readwrite, copy) NSString *name;

@property (readwrite, copy) NSString *testname;
@property (readwrite, copy) NSString *subtestname;
@property (readwrite, copy) NSString *subsubtestname;

@property (readwrite, copy) NSMutableArray *array;
@property (readwrite, copy) NSMutableDictionary *dict;

- (instancetype)initWithItem:(NSString *)item;

@end

NS_ASSUME_NONNULL_END
