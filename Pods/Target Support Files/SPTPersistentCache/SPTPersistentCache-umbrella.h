#ifdef __OBJC__
#import <Cocoa/Cocoa.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "SPTPersistentCache.h"
#import "SPTPersistentCacheHeader.h"
#import "SPTPersistentCacheOptions.h"
#import "SPTPersistentCacheRecord.h"
#import "SPTPersistentCacheResponse.h"

FOUNDATION_EXPORT double SPTPersistentCacheVersionNumber;
FOUNDATION_EXPORT const unsigned char SPTPersistentCacheVersionString[];

