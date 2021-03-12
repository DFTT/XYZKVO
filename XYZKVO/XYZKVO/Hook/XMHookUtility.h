//
//  XMHookUtility.h
//  NativeEastNews
//
//  Created by zhazhenwang on 2017/8/1.
//  Copyright © 2017年 Gaoxin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XMHookUtility : NSObject

+ (void)swizzleMethodForClass:(Class)aClass originalSelector:(SEL)originalSelector swizzledSelector:(SEL)swizzledSelector;

+ (void)swizzleClassMethodForClass:(Class)aClass originalSelector:(SEL)originalSelector swizzledSelector:(SEL)swizzledSelector;
@end
