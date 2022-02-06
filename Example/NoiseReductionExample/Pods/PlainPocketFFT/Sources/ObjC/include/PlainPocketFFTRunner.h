#import <Foundation/Foundation.h>

@interface PlainPocketFFTRunner: NSObject

+ (int)execute_real_forward:(double *)a1 result:(double *)resultMatrix cols:(int)cols rows:(int)rows fct:(double)fct;

+ (int)execute_real_backward:(double *)a1 result:(double *)resultArray cols:(int)cols rows:(int)rows fct:(double)fct;

@end
