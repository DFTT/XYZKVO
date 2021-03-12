//
//  ViewController.m
//  XYZKVO
//
//  Created by 大大东 on 2021/3/11.
//

#import "ViewController.h"
#import "NSObject+XYZKVO.h"

@interface Test : NSObject
@property (nonatomic, copy) NSString *txt;
@end
@implementation Test
@end

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource>
{
    NSMutableArray<Test *> *_dataArr;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    Test *vc = [[Test alloc] init];
//    [vc xyz_observerKeyPath:@"txt" changeCallback:^(id  _Nonnull obj, id  _Nullable oldValue, id  _Nullable newValue) {
//
//        NSLog(@"%@- %@- %@", obj, oldValue, newValue);
//    }];
//
//    vc.txt = @"1";
//    vc.txt = @"2";
//    vc.txt = nil;
//    vc.txt = @"3";
//    [vc change];
//    vc = nil;
//
    UITableView *tabView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    tabView.delegate = self;
    tabView.dataSource = self;
    [self.view addSubview:tabView];
    
    NSMutableArray *marr = [[NSMutableArray alloc] init];
    for (int i = 0; i < 50; i++) {
        Test *t = [[Test alloc] init];
        t.txt = [NSString stringWithFormat:@"%d 点击改变", i];
        [marr addObject:t];
    }
    _dataArr = marr;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _dataArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    Test *t = _dataArr[indexPath.row];
    cell.textLabel.text = t.txt;
    [t xyz_observerKeyPath:@"txt" reuseCell:cell changeCallback:^(id  _Nonnull obj, id  _Nullable oldValue, id  _Nullable newValue) {
        cell.textLabel.text = newValue;
        NSLog(@"%d, 改变了......", (int)indexPath.row);
    }];
    return cell;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Test *t = _dataArr[indexPath.row];
    t.txt = [NSString stringWithFormat:@"%d ============ %d", (int)indexPath.row, arc4random() % 200];
    
}

@end
