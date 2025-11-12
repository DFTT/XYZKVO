//
//  NSObject+XYZKVO.m
//  XYZKVO
//
//  Created by 大大东 on 2021/3/11.
//

#import "NSObject+XYZKVO.h"
#import <objc/runtime.h>
#import "XMHookUtility.h"


NS_ASSUME_NONNULL_BEGIN

// -- helper: ensure run on main thread (sync if caller not main) --
static inline void _xyz_dispatch_sync_main_if_needed(void (^block)(void)) {
    if (!block) return;
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

#pragma mark - Observer item

@interface _XYZObserverItem : NSObject

@property (nonatomic, weak) id hostObj;
@property (nonatomic, copy, nullable) NSString *keypath;
@property (nonatomic, copy, nullable) XYZKVOBlock callback;
@property (nonatomic, copy, nullable) NSString *mapKey;

- (void)removeKVOAndRemoveSelfFrom:(nullable NSMutableDictionary<NSString *, _XYZObserverItem *> *)map;
@end

@implementation _XYZObserverItem

- (void)observeValueForKeyPath:(nullable NSString *)keyPath
                      ofObject:(nullable id)object
                        change:(nullable NSDictionary<NSKeyValueChangeKey, id> *)change
                       context:(nullable void *)context {
    XYZKVOBlock cb = self.callback;
    if (cb == nil) return;
    
    NSKeyValueChange changeKind = [[change objectForKey:NSKeyValueChangeKindKey] integerValue];
    if (changeKind != NSKeyValueChangeSetting) return;
    
    id oldVal = [change objectForKey:NSKeyValueChangeOldKey];
    if (oldVal == [NSNull null]) oldVal = nil;
    
    id newVal = [change objectForKey:NSKeyValueChangeNewKey];
    if (newVal == [NSNull null]) newVal = nil;
    
    cb(object, oldVal, newVal);
}

- (void)removeKVOAndRemoveSelfFrom:(nullable NSMutableDictionary<NSString *, _XYZObserverItem *> *)map {
    id host = self.hostObj;
    NSString *kp = self.keypath;
    if (host && kp.length > 0) {
        @try {
            [host removeObserver:self forKeyPath:kp];
        } @catch (NSException *exception) {
            // ignore
        }
        // clear local references
        self.keypath = nil;
        self.hostObj = nil;
        
        if (map != nil && self.mapKey != nil) {
            [map removeObjectForKey:self.mapKey];
            self.mapKey = nil;
        }
        
        self.callback = nil;
    } else {
        // no host or no keypath: just clear callback
        self.callback = nil;
        self.keypath = nil;
        self.mapKey = nil;
        self.hostObj = nil;
    }
}

- (void)dealloc {
    // defensive: attempt removal; passing nil is fine because map may already be gone
    [self removeKVOAndRemoveSelfFrom:nil];
}

@end


@interface _XYZCellKVOProxy : NSObject
@property (nonatomic, strong, readonly) NSHashTable<_XYZObserverItem *> *observers;
- (void)removeAll;
- (void)addWeakObserver:(_XYZObserverItem *)item;
@end

@interface UITableViewCell (XYZKVO)
- (_XYZCellKVOProxy *)xyz_kvoProxy;
@end

@interface UICollectionViewCell (XYZKVO)
- (_XYZCellKVOProxy *)xyz_kvoProxy;
@end

#pragma mark - Category Implementation

@implementation NSObject (XYZKVO)

- (nullable NSString *)xyz_observerKeyPath:(NSString *)keypath
                               immediately:(BOOL)immediately
                            changeCallback:(XYZKVOBlock)callback {
    _XYZObserverItem *item = [self p_addObserverKeyPath:keypath immediately:immediately callback:callback];
    return item.mapKey;
}

- (nullable NSString *)xyz_observerKeyPath:(NSString *)keypath
                                 reuseCell:(UIView *)cell
                               immediately:(BOOL)immediately
                            changeCallback:(XYZKVOBlock)callback {
    if (!cell) return nil;
    
    _XYZCellKVOProxy *cellProxy = nil;
    if ([cell isKindOfClass:[UITableViewCell class]]) {
        cellProxy = [(UITableViewCell *)cell xyz_kvoProxy];
    }else if ([cell isKindOfClass:[UICollectionViewCell class]]) {
        cellProxy = [(UICollectionViewCell *)cell xyz_kvoProxy];
    }else {
        NSAssert(NO, @"仅支持UITableViewCell or UICollectionViewCell");
        return nil;
    }
    
    _XYZObserverItem *item = [self p_addObserverKeyPath:keypath immediately:immediately callback:callback];
    if (item != nil && cellProxy != nil) {
        [cellProxy addWeakObserver:item];
    }
    return item.mapKey;
}

- (void)xyz_rmAllObserver {
    NSMutableDictionary<NSString *, _XYZObserverItem *> *mMap = [self xyz_observerMap];
    _xyz_dispatch_sync_main_if_needed(^{
        NSArray<_XYZObserverItem *> *items = [mMap allValues];
        [mMap removeAllObjects];
        for (_XYZObserverItem *item in items) {
            // map 参数传 nil，因为已经在锁内清空
            [item removeKVOAndRemoveSelfFrom:nil];
        }
    });
}

- (void)xyz_removeObserverFor:(NSString *)token {
    NSMutableDictionary<NSString *, _XYZObserverItem *> *mMap = [self xyz_observerMap];
    _XYZObserverItem *item = mMap[token];
    _xyz_dispatch_sync_main_if_needed(^{
        [item removeKVOAndRemoveSelfFrom:nil];
        [mMap removeObjectForKey:token];
    });
}
#pragma mark - Private

- (nullable _XYZObserverItem *)p_addObserverKeyPath:(NSString *)keypath
                                        immediately:(BOOL)immediately
                                           callback:(XYZKVOBlock)callback {
    if (keypath == nil || keypath.length == 0 || callback == nil) {
        return nil;
    }
    
    NSMutableDictionary<NSString *, _XYZObserverItem *> *mMap = [self xyz_observerMap];
    
    XYZKVOBlock copiedCallback = [callback copy];
    
    NSString *mapKey = [NSString stringWithFormat:@"xyz_%@_%p", keypath, (void *)copiedCallback];
    
    __block _XYZObserverItem *observer = nil;
    
    _xyz_dispatch_sync_main_if_needed(^{
        if ([mMap objectForKey:mapKey]) {
            return; // already registered with this exact key
        }
        
        observer = [[_XYZObserverItem alloc] init];
        observer.hostObj  = self;
        observer.keypath  = keypath;
        observer.callback = copiedCallback;
        observer.mapKey   = mapKey;
        [self addObserver:observer forKeyPath:keypath options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:NULL];
        [mMap setObject:observer forKey:mapKey];
        
        // 主线程回调
        if (immediately) {
            id immediateValue = nil;
            @try {
                immediateValue = [self valueForKeyPath:keypath];
            } @catch (NSException *exception) {
                immediateValue = nil;
            }
            // use copied callback
            copiedCallback(self, nil, immediateValue);
        }
    });
    
    return observer;
}

- (NSMutableDictionary<NSString *, _XYZObserverItem *> *)xyz_observerMap {
    // thread-safe lazy init
    NSMutableDictionary *mdic = objc_getAssociatedObject(self, @selector(xyz_observerMap));
    if (mdic == nil) {
        mdic = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, @selector(xyz_observerMap), mdic, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return mdic;
}
@end

#pragma mark - UITableViewCell Swizzle

@implementation _XYZCellKVOProxy
- (instancetype)init {
    if (self = [super init]) {
        _observers = [NSHashTable weakObjectsHashTable];
    }
    return self;
}
- (void)addWeakObserver:(_XYZObserverItem *)item {
    @synchronized (self) {
        [_observers addObject:item];
    }
}
- (void)removeAll {
    NSArray<_XYZObserverItem *> *items = nil;
    @synchronized (self) {
        items = [_observers allObjects];
        [_observers removeAllObjects];
    }
    // 在锁外进行 KVO 移除，避免持 proxy 锁期间触发 host 锁或跨线程等待
    for (_XYZObserverItem *item in items) {
        [item removeKVOAndRemoveSelfFrom:[item.hostObj xyz_observerMap]];
    }
}
- (void)dealloc {
    [self removeAll];
}
@end

@implementation UITableViewCell (XYZKVO)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL originalSelector = @selector(prepareForReuse);
        SEL swizzledSelector = @selector(xyz_kvo_prepareForReuse);
        [XMHookUtility swizzleMethodForClass:[self class] originalSelector:originalSelector swizzledSelector:swizzledSelector];
    });
}

- (void)xyz_kvo_prepareForReuse {
    [[self xyz_kvoProxy] removeAll];
    // call original implementation (swizzled)
    [self xyz_kvo_prepareForReuse];
}

- (_XYZCellKVOProxy *)xyz_kvoProxy {
    _XYZCellKVOProxy *proxy = objc_getAssociatedObject(self, @selector(xyz_kvoProxy));
    if (!proxy) {
        proxy = [[_XYZCellKVOProxy alloc] init];
        objc_setAssociatedObject(self, @selector(xyz_kvoProxy), proxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return proxy;
}

@end

#pragma mark - UICollectionViewCell Swizzle

@implementation UICollectionViewCell (XYZKVO)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL originalSelector = @selector(prepareForReuse);
        SEL swizzledSelector = @selector(xyz_kvo_prepareForReuse);
        [XMHookUtility swizzleMethodForClass:[self class] originalSelector:originalSelector swizzledSelector:swizzledSelector];
    });
}

- (void)xyz_kvo_prepareForReuse {
    [[self xyz_kvoProxy] removeAll];
    //
    [self xyz_kvo_prepareForReuse];
}

- (_XYZCellKVOProxy *)xyz_kvoProxy {
    _XYZCellKVOProxy *proxy = objc_getAssociatedObject(self, @selector(xyz_kvoProxy));
    if (!proxy) {
        proxy = [[_XYZCellKVOProxy alloc] init];
        objc_setAssociatedObject(self, @selector(xyz_kvoProxy), proxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return proxy;
}

@end

NS_ASSUME_NONNULL_END
