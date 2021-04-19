# XYZKVO


###是什么
主要是为了更方便的使用KVO
1. 更便捷的使用Block方式添加KVO，如果添加多次监听，各block互不影响
2. 不需要关心未移除KVO导致的崩溃（系统在iOS 11及以后已经不会崩溃）
3. 可在UITableViewCell/UICollectionViewCell中使用，且不需要关心cell复用导致多次监听（会自动在自动在- prepareForReuse 时移除kvo），可以更方便的监听数据源变化更新UI

###怎么用
将XYZKVO中代码添加到项目中，具体方法见 NSObject+XYZKVO.h 

###后续
长期更新维护，请提需求
