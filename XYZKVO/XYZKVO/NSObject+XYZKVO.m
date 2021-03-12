//
//  NSObject+XYZKVO.m
//  XYZKVO
//
//  Created by 大大东 on 2021/3/11.
//

#import "NSObject+XYZKVO.h"
#import <objc/runtime.h>
#import "XMHookUtility.h"

@interface XYZ_Observer : NSObject
{
@public
    __unsafe_unretained id _hostObj;
    NSString   *_keypath;
    XYZKVOBlock _callback;
    NSString   *_makKey;
}
@end

@implementation XYZ_Observer
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
        
    if (nil == _callback) {
        return;
    }
    
    NSKeyValueChange changeKind = [[change objectForKey:NSKeyValueChangeKindKey] integerValue];
    if (changeKind != NSKeyValueChangeSetting) return;
    
    id oldVal = [change objectForKey:NSKeyValueChangeOldKey];
    if (oldVal == [NSNull null]) oldVal = nil;
    
    id newVal = [change objectForKey:NSKeyValueChangeNewKey];
    if (newVal == [NSNull null]) newVal = nil;

    _callback(object, oldVal, newVal);
}

- (void)dealloc {
    // 此dealloc执行时 宿主dealloc正在执行 此时正好移除
    [_hostObj removeObserver:self forKeyPath:_keypath];
}
@end



@implementation NSObject (XYZKVO)
- (void)xyz_observerKeyPath:(NSString *)keypath changeCallback:(nonnull XYZKVOBlock)callback {
    [self p_addObserverKeyPath:keypath callback:callback];
}

- (void)xyz_observerKeyPath:(NSString *)keypath reuseCell:(UIView *)cell changeCallback:(XYZKVOBlock)callback {
    if (!cell) {
        return;
    }
    if ([cell isKindOfClass:[UITableViewCell class]]) {
        XYZ_Observer *observer = [self p_addObserverKeyPath:keypath callback:callback];
        
        [[(UITableViewCell *)cell xyz_weakObservers] addObject:observer];
        return;
    }
    if ([cell isKindOfClass:[UICollectionViewCell class]]) {
        XYZ_Observer *observer = [self p_addObserverKeyPath:keypath callback:callback];
        
        [[(UICollectionViewCell *)cell xyz_weakObservers] addObject:observer];
        return;
    }
    NSAssert(NO, @"仅支持UITableViewCell or UICollectionViewCell");
}

- (void)xyz_rmAllObserver {
    [[self xyz_observerMap] removeAllObjects];
}

- (void)p_xyz_removeObserverForMapKey:(NSString *)mapkey {
    [[self xyz_observerMap] removeObjectForKey:mapkey];
}
#pragma mark Private
- (nullable XYZ_Observer *)p_addObserverKeyPath:(NSString *)keypath callback:(nonnull XYZKVOBlock)callback {
    if (keypath == nil || keypath.length == 0 || nil == callback) {
        return nil;
    }
    NSMutableDictionary *mMap = [self xyz_observerMap];
    NSString *mapKey = [NSString stringWithFormat:@"xyz_%@_%x", keypath, (unsigned int)[callback hash]];

    XYZ_Observer *observer = [mMap objectForKey:mapKey];
    if (observer) {
        return nil;
    }
    observer = [[XYZ_Observer alloc] init];
    observer->_hostObj  = self;
    observer->_keypath  = keypath;
    observer->_callback = callback;
    observer->_makKey   = mapKey;
    
    [self addObserver:observer forKeyPath:keypath options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:nil];
    
    [mMap setObject:observer forKey:mapKey];
    
    return observer;
}

- (NSMutableDictionary *)xyz_observerMap {
    NSMutableDictionary *mdic = objc_getAssociatedObject(self, @selector(xyz_observerMap));
    if (mdic == nil) {
        mdic = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, @selector(xyz_observerMap), mdic, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return mdic;
}
///
- (NSHashTable *)xyz_weakObservers {
    NSHashTable *table = objc_getAssociatedObject(self, @selector(xyz_weakObservers));
    if (table == nil) {
        table = [NSHashTable weakObjectsHashTable];
        objc_setAssociatedObject(self, @selector(xyz_weakObservers), table, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return table;
}
@end




@interface UITableViewCell (XYZKVO)
@end
@implementation UITableViewCell (XYZKVO)
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // swizzle viewDidLoad
        SEL originalSelector_0 = @selector(prepareForReuse);
        SEL swizzledSelector_0 = @selector(xyz_kvo_prepareForReuse);
        [XMHookUtility swizzleMethodForClass:[self class] originalSelector:originalSelector_0 swizzledSelector:swizzledSelector_0];
    });
}
- (void)xyz_kvo_prepareForReuse {
    /// 这里移除kvo
    NSHashTable *obs = [self xyz_weakObservers];
    if (obs.count > 0) {
        NSEnumerator *enumerator = [obs objectEnumerator];
        XYZ_Observer *observer   = nil;
        while (observer = [enumerator nextObject]) {
            [observer->_hostObj p_xyz_removeObserverForMapKey:observer->_makKey];
        }
    }
    [self xyz_kvo_prepareForReuse];
}
@end



@interface UICollectionViewCell (XYZKVO)
@end
@implementation UICollectionViewCell (XYZKVO)
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // swizzle viewDidLoad
        SEL originalSelector_0 = @selector(prepareForReuse);
        SEL swizzledSelector_0 = @selector(xyz_kvo_prepareForReuse);
        [XMHookUtility swizzleMethodForClass:[self class] originalSelector:originalSelector_0 swizzledSelector:swizzledSelector_0];
    });
}
- (void)xyz_kvo_prepareForReuse {
    /// 这里移除kvo
    NSHashTable *obs = [self xyz_weakObservers];
    if (obs.count > 0) {
        NSEnumerator *enumerator = [obs objectEnumerator];
        XYZ_Observer *observer   = nil;
        while (observer = [enumerator nextObject]) {
            [observer->_hostObj p_xyz_removeObserverForMapKey:observer->_makKey];
        }
    }
    [self xyz_kvo_prepareForReuse];
}
@end
