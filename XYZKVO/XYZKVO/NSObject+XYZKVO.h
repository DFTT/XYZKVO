//
//  NSObject+XYZKVO.h
//  XYZKVO
//
//  Created by 大大东 on 2021/3/11.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^XYZKVOBlock)(_Nonnull id obj, _Nullable id oldValue, _Nullable id newValue);

@interface NSObject (XYZKVO)

/// 便捷的添加kvo (一般可以不用关心 观察者的移除问题)
/// @param keypath  要监听的属性
/// @param callback 属性变化的回调
- (void)xyz_observerKeyPath:(NSString *)keypath
              changeCallback:(XYZKVOBlock)callback;



/// 便捷的添加kvo (可以不用关心 观察者的移除问题 & cell复用重复时移除问题)
/// @param keypath 要监听的属性
/// @param cell    UITableViewCell or UICollectionViewCell
/// @param callback 属性变化的回调
- (void)xyz_observerKeyPath:(NSString *)keypath
                  reuseCell:(UIView *)cell
             changeCallback:(XYZKVOBlock)callback;


/// 移除观察者 (仅对使用方法xyz_observerKeyPath:changeCallback:添加的有效)
- (void)xyz_rmAllObserver;
@end


NS_ASSUME_NONNULL_END
