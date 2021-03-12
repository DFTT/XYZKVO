//
//  XMHookUtility.m
//  NativeEastNews
//
//  Created by zhazhenwang on 2017/8/1.
//  Copyright © 2017年 Gaoxin. All rights reserved.
//

#import "XMHookUtility.h"
#import <objc/runtime.h>

@implementation XMHookUtility

+ (void)swizzleMethodForClass:(Class)aClass originalSelector:(SEL)originalSelector swizzledSelector:(SEL)swizzledSelector
{
    Method originalMethod = class_getInstanceMethod(aClass, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(aClass, swizzledSelector);
    
    BOOL didAddMethod = class_addMethod(aClass,
                                        originalSelector,
                                        method_getImplementation(swizzledMethod),
                                        method_getTypeEncoding(swizzledMethod));
    if (didAddMethod) {
        class_replaceMethod(aClass,
                            swizzledSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

+ (void)swizzleClassMethodForClass:(Class)aClass originalSelector:(SEL)originalSelector swizzledSelector:(SEL)swizzledSelector{
   
    Method originalMethod = class_getClassMethod(aClass, originalSelector);
    Method swizzledMethod = class_getClassMethod(aClass, swizzledSelector);
    method_exchangeImplementations(originalMethod, swizzledMethod);
}

@end
