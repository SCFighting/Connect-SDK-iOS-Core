//
//  DevicePickerCustomUIProtocol.h
//  ConnectSDK
//
//  Created by SC on 2024/1/18.
//

#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN

@protocol DevicePickerCustomUIProtocol <NSObject>

/// 获取sectionHeader class name
- (NSString *)classNameForSectionHeader;

/// 获取tableview的 tableviewheader
- (UIView *)headerForTableview;

/// 获取tableview的 tableviewfooter
- (UIView *)footerForTableview;

/// 获取自定义Cell className
- (NSString *)classNameForCell;

@end

NS_ASSUME_NONNULL_END
