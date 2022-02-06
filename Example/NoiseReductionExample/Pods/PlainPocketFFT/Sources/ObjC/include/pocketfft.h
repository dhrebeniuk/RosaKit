//
//  pocketfft.h
//  RosaKit
//
//  Created by Hrebeniuk Dmytro on 21.12.2019.
//  Copyright © 2019 Dmytro Hrebeniuk. All rights reserved.
//

#ifndef pocketfft_h
#define pocketfft_h

#include <stdio.h>
#include <stdlib.h>

#define NFCT 25

typedef struct cmplx {
  double r,i;
} cmplx;

typedef struct cfftp_fctdata
{
size_t fct;
cmplx *tw, *tws;
} cfftp_fctdata;

#define restrict NPY_RESTRICT

#define RALLOC(type,num) \
  ((type *)malloc((num)*sizeof(type)))

#define DEALLOC(ptr) \
  do { free(ptr); (ptr)=NULL; } while(0)

#define SWAP(a,b,type) \
do { type tmp_=(a); (a)=(b); (b)=tmp_; } while(0)

#ifdef __GNUC__
#define NOINLINE __attribute__((noinline))
#define WARN_UNUSED_RESULT __attribute__ ((warn_unused_result))
#else
#define NOINLINE
#define WARN_UNUSED_RESULT
#endif

typedef size_t npy_intp;
typedef size_t npy_uintp;

typedef struct rfftp_fctdata {
    size_t fct;
    double *tw, *tws;
} rfftp_fctdata;

typedef struct rfftp_plan_i
  {
  size_t length, nfct;
  double *mem;
  rfftp_fctdata fct[NFCT];
  } rfftp_plan_i;
typedef struct rfftp_plan_i * rfftp_plan;

rfftp_plan make_rfftp_plan (size_t length);

struct cfft_plan_i;
typedef struct cfft_plan_i * cfft_plan;
struct rfft_plan_i;
typedef struct rfft_plan_i * rfft_plan;

typedef struct cfftp_plan_i
  {
  size_t length, nfct;
  cmplx *mem;
  cfftp_fctdata fct[NFCT];
  } cfftp_plan_i;
typedef struct cfftp_plan_i * cfftp_plan;

typedef struct fftblue_plan_i
  {
  size_t n, n2;
  cfftp_plan plan;
  double *mem;
  double *bk, *bkf;
  } fftblue_plan_i;
typedef struct fftblue_plan_i * fftblue_plan;

typedef struct rfft_plan_i
{
rfftp_plan packplan;
fftblue_plan blueplan;
} rfft_plan_i;

NOINLINE void destroy_rfftp_plan (rfftp_plan plan);

int rfftp_factorize (rfftp_plan plan);

int execute_real_forward(const double *a1, double *resultMatrix, int cols, int rows, double fct);

int execute_real_backward(const double *data,  double *resultArray, int cols, int rows, double fct);

double *execute_real_forward1(const double *a1, int cols, int rows, double fct);

#endif /* pocketfft_h */
