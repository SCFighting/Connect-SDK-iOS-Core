//
//  DevicePicker.h
//  Connect SDK
//
//  Created by Andrew Longstaff on 9/6/13.
//  Copyright (c) 2014 LG Electronics.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <UIKit/UIKit.h>
#import "DevicePickerDelegate.h"
#import "DiscoveryManagerDelegate.h"
#import "ConnectableDevice.h"
#import "DevicePickerCustomUIProtocol.h"

/*!
 * ###Overview
 * The DevicePicker is provided by the DiscoveryManager as a simple way for you to present a list of available devices to your users.
 * 
 * ###In Depth
 * The DevicePicker takes a sender parameter on the showPicker method. The sender parameter is used to display a popover from a particular UIView on iPads.
 * 
 * You should not attempt to instantiate the DevicePicker on your own. Instead, get the reference from the DeviceManager with [[DeviceManager sharedManager] devicePicker];
 */
@interface DevicePicker : NSObject <DiscoveryManagerDelegate, UITableViewDataSource, UITableViewDelegate>

/*! Delegate that receives selected/cancelled messages. */
@property (nonatomic, weak) id<DevicePickerDelegate> _Nullable delegate;

/// 自定义UI 代理
@property (nonatomic, weak) id<DevicePickerCustomUIProtocol> _Nullable customUIDelegate;

/*!
 * If you wish to show a checkmark next to a device in the picker, you can set that device object to currentDevice. The setter for currentDevice will also reload the tableView in the picker.
 */
@property (nonatomic, weak) ConnectableDevice * _Nullable currentDevice;

/// 添加视图到父视图
/// @param view 将要添加到的父视图
/// @param complate 添加完成回调,用于布局

- (void)addToParent:(UIView *_Nonnull)view complate:(nonnull void (^)(UITableView * _Nonnull subview))complate;

@end
