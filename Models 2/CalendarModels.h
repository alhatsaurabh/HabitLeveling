#import <Foundation/Foundation.h>

// Forward declarations
@class CalendarDay;

// CalendarDay interface
@interface CalendarDay : NSObject

@property (nonatomic, strong) NSDate *date;
@property (nonatomic, assign) BOOL isCurrentMonth;
@property (nonatomic, assign) BOOL isToday;
@property (nonatomic, assign) BOOL isSelected;

- (instancetype)initWithDate:(NSDate *)date
              isCurrentMonth:(BOOL)isCurrentMonth
                    isToday:(BOOL)isToday
                 isSelected:(BOOL)isSelected;

- (NSString *)number;

@end 