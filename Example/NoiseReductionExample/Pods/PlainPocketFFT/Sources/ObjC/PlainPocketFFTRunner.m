#import "PlainPocketFFTRunner.h"
#import "pocketfft.h"

@implementation PlainPocketFFTRunner

+ (int)execute_real_forward:(double *)a1 result:(double *)resultMatrix cols:(int)cols rows:(int)rows fct:(double)fct {
  return execute_real_forward(a1, resultMatrix, cols, rows, fct);
}

+ (int)execute_real_backward:(double *)a1 result:(double *)resultArray cols:(int)cols rows:(int)rows fct:(double)fct {
  return execute_real_backward(a1, resultArray, cols, rows, fct);
}

@end
