//
//  AppDelegate.m
//  XYZKVO
//
//  Created by 大大东 on 2021/3/11.
//

#import "AppDelegate.h"
#import "ViewController.h"
@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    
    _window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    _window.rootViewController = [ViewController new];
    [_window makeKeyWindow];
    return YES;
}



@end
