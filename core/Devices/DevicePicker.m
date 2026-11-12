//
//  DevicePicker.m
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

#import "DevicePicker.h"
#import "DiscoveryProvider.h"
#import "DiscoveryManager.h"
#import "DevicePickerTableviewCellProtocol.h"


@interface DevicePicker()
/// 设备选择列表
@property(nonatomic,strong,readwrite)UITableView * _Nullable tableView;
@end

@implementation DevicePicker
{
    NSArray *_generatedDeviceList;
    NSMutableDictionary *_devices;
    
    dispatch_queue_t _sortQueue;
    BOOL _showServiceLabel;
}

- (instancetype) init
{
    self = [super init];

    if (self)
    {
        _sortQueue = dispatch_queue_create("Connect SDK Device Picker Sort", DISPATCH_QUEUE_SERIAL);
        _devices = [[NSMutableDictionary alloc] init];
    }

    return self;
}

- (void)setCurrentDevice:(ConnectableDevice *)currentDevice
{
    _currentDevice = currentDevice;

    [_tableView reloadData];
}

#pragma mark - Picker display methods

- (void)addToParent:(UIView *_Nonnull)view complate:(nonnull void (^)(UITableView * _Nonnull subview))complate
{
    [self sortDevices];

    _showServiceLabel = [DiscoveryManager sharedManager].capabilityFilters.count == 0;
    
    [view addSubview:self.tableView];
    
    complate(_tableView);
    
}

#pragma mark - Helper methods

- (void) sortDevices
{
    dispatch_async(_sortQueue, ^{
        NSArray *devices;
        
        @synchronized (self->_devices) { devices = [self->_devices allValues]; }
        
        @synchronized (self->_generatedDeviceList)
        {
            self->_generatedDeviceList = [devices sortedArrayUsingComparator:^NSComparisonResult(ConnectableDevice *device1, ConnectableDevice *device2) {
                NSString *device1Name = [[self nameForDevice:device1] lowercaseString];
                NSString *device2Name = [[self nameForDevice:device2] lowercaseString];
                
                return [device1Name compare:device2Name];
            }];
        }
    });
}

- (NSString *) nameForDevice:(ConnectableDevice *)device
{
    NSString *name;
    
    if (device.serviceDescription.friendlyName && device.serviceDescription.friendlyName.length > 0)
        name = device.serviceDescription.friendlyName;
    else if (device.serviceDescription.address && device.serviceDescription.address.length > 0)
        name = device.serviceDescription.address;
    else
        name = [[NSBundle mainBundle] localizedStringForKey:@"Connect_SDK_Unnamed_Device" value:@"Unnamed device" table:@"ConnectSDK"];
    
    return name;
}


#pragma mark UITableViewDelegate methods

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    ConnectableDevice *device;

    @synchronized (_generatedDeviceList)
    {
        device = (ConnectableDevice *) [_generatedDeviceList objectAtIndex:indexPath.row];
    }
    
    if (self.currentDevice)
    {
        if ([self.currentDevice.serviceDescription.address isEqualToString:device.serviceDescription.address])
            return;
    }
    
    if (_delegate && [_delegate respondsToSelector:@selector(devicePicker:didSelectDevice:name:)])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self->_delegate devicePicker:self didSelectDevice:device name:[self nameForDevice:device]];
        });
    }
}

#pragma mark UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;

    @synchronized (_generatedDeviceList)
    {
        if (_generatedDeviceList)
            numberOfRows = _generatedDeviceList.count;
    }

    return numberOfRows;
}

static NSString *cellIdentifier = @"connectPickerCell";

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_customUIDelegate)
    {
        UITableViewCell<DevicePickerTableviewCellProtocol> *cell = [tableView dequeueReusableCellWithIdentifier:[_customUIDelegate classNameForCell] forIndexPath:indexPath];
        ConnectableDevice *device;
        
        @synchronized (_generatedDeviceList)
        {
            if (_generatedDeviceList.count > 0 && indexPath.row < _generatedDeviceList.count)
                device = (ConnectableDevice *) [_generatedDeviceList objectAtIndex:indexPath.row];
        }
        
        if (!device)
            return cell;
        NSString *deviceName = [self nameForDevice:device];
        cell.titleText = deviceName;
        return cell;
    }
    else
    {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        
        if (cell == nil)
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        cell.backgroundColor = UIColor.clearColor;
        ConnectableDevice *device;
        
        @synchronized (_generatedDeviceList)
        {
            if (_generatedDeviceList.count > 0 && indexPath.row < _generatedDeviceList.count)
                device = (ConnectableDevice *) [_generatedDeviceList objectAtIndex:indexPath.row];
        }
        
        if (!device)
            return cell;
        
        NSString *deviceName = [self nameForDevice:device];
        cell.textLabel.textColor = UIColor.whiteColor;
        cell.detailTextLabel.textColor = UIColor.whiteColor;
        [cell.textLabel setText:deviceName];
        
        if (_showServiceLabel)
            [cell.detailTextLabel setText:[device connectedServiceNames]];
        
        if (self.currentDevice)
        {
            if ([self.currentDevice.serviceDescription.address isEqualToString:device.serviceDescription.address])
                [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
            else
                [cell setAccessoryType:UITableViewCellAccessoryNone];
        }
        
        return cell;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;

    @synchronized (_generatedDeviceList)
    {
        if (_generatedDeviceList)
            numberOfRows = _generatedDeviceList.count;
    }
    
    if (numberOfRows > 0)
    {
        tableView.tableFooterView.hidden = true;
    }
    else
    {
        tableView.tableFooterView.hidden = false;
    }
    
    if (section == 0 && _customUIDelegate && numberOfRows > 0)
    {
        UITableViewHeaderFooterView *sectionHeaderView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:_customUIDelegate.classNameForSectionHeader];
        return sectionHeaderView;
    }
    return nil;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;

    @synchronized (_generatedDeviceList)
    {
        if (_generatedDeviceList)
            numberOfRows = _generatedDeviceList.count;
    }
    
    if (numberOfRows > 0)
    {
        tableView.tableFooterView.hidden = true;
    }
    else
    {
        tableView.tableFooterView.hidden = false;
    }
    
    if (section == 0 && _customUIDelegate && numberOfRows > 0)
    {
        
        return 38;
    }
    return CGFLOAT_MIN;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    if ([cell respondsToSelector:@selector(tintColor)]) {
        CGFloat cornerRadius = 7.f;
        cell.backgroundColor = UIColor.clearColor;
        CAShapeLayer *layer = [[CAShapeLayer alloc] init];
        CGMutablePathRef pathRef = CGPathCreateMutable();
        CGRect bounds = CGRectInset(cell.bounds, 15, 0);
        BOOL addLine = NO;
        if (indexPath.row == 0 && indexPath.row == [tableView numberOfRowsInSection:indexPath.section]-1) {
            CGPathAddRoundedRect(pathRef, nil, bounds, cornerRadius, cornerRadius);
        } else if (indexPath.row == 0) {

            CGPathMoveToPoint(pathRef, nil, CGRectGetMinX(bounds), CGRectGetMaxY(bounds));
            CGPathAddArcToPoint(pathRef, nil, CGRectGetMinX(bounds), CGRectGetMinY(bounds), CGRectGetMidX(bounds), CGRectGetMinY(bounds), cornerRadius);
            CGPathAddArcToPoint(pathRef, nil, CGRectGetMaxX(bounds), CGRectGetMinY(bounds), CGRectGetMaxX(bounds), CGRectGetMidY(bounds), cornerRadius);
            CGPathAddLineToPoint(pathRef, nil, CGRectGetMaxX(bounds), CGRectGetMaxY(bounds));
            addLine = YES;
            
        } else if (indexPath.row == [tableView numberOfRowsInSection:indexPath.section]-1) {
            CGPathMoveToPoint(pathRef, nil, CGRectGetMinX(bounds), CGRectGetMinY(bounds));
            CGPathAddArcToPoint(pathRef, nil, CGRectGetMinX(bounds), CGRectGetMaxY(bounds), CGRectGetMidX(bounds), CGRectGetMaxY(bounds), cornerRadius);
            CGPathAddArcToPoint(pathRef, nil, CGRectGetMaxX(bounds), CGRectGetMaxY(bounds), CGRectGetMaxX(bounds), CGRectGetMidY(bounds), cornerRadius);
            CGPathAddLineToPoint(pathRef, nil, CGRectGetMaxX(bounds), CGRectGetMinY(bounds));
        } else {
            CGPathAddRect(pathRef, nil, bounds);
            addLine = YES;
        }
        layer.path = pathRef;
        CFRelease(pathRef);
        //颜色修改
        layer.fillColor = [UIColor colorWithRed:40.0/255.0 green:40.0/255.0 blue:40.0/255.0 alpha:1.0].CGColor;
        layer.strokeColor=[UIColor colorWithRed:40.0/255.0 green:40.0/255.0 blue:40.0/255.0 alpha:1.0].CGColor;
        // 阴影颜色
        layer.shadowColor = UIColor.blackColor.CGColor;
        // 阴影偏移，默认(0, -3)
        layer.shadowOffset = CGSizeMake(0,-3);
        // 阴影透明度，默认0
        layer.shadowOpacity = 0;
        if (addLine == YES) {
            //设置分割线
            CALayer *lineLayer = [[CALayer alloc] init];
            CGFloat lineHeight = (1.f / [UIScreen mainScreen].scale);
            lineLayer.frame = CGRectMake(CGRectGetMinX(bounds)+10, bounds.size.height-lineHeight, bounds.size.width-20, lineHeight);
            lineLayer.backgroundColor = [UIColor colorWithRed:52.0/255.0 green:51.0/255.0 blue:55.0/255.0 alpha:1.0].CGColor;
            [layer addSublayer:lineLayer];
        }
        //设置背景view
        UIView *clickBgView = [[UIView alloc] initWithFrame:bounds];
        [clickBgView.layer insertSublayer:layer atIndex:0];
        clickBgView.backgroundColor = UIColor.clearColor;
        cell.backgroundView = clickBgView;
    }
}


# pragma mark - DiscoveryManagerDelegate methods

- (void)discoveryManager:(DiscoveryManager *)manager didFindDevice:(ConnectableDevice *)device
{
    if (_devices)
    {
        @synchronized (_devices) { [_devices setObject:device forKey:device.address]; }

        [self sortDevices];

        dispatch_async(dispatch_get_main_queue(), ^{
            if (self->_tableView)
                [self->_tableView reloadData];
        });
    }
}

- (void)discoveryManager:(DiscoveryManager *)manager didLoseDevice:(ConnectableDevice *)device
{
    if (_devices)
    {
        @synchronized (_devices) { [_devices removeObjectForKey:device.address]; }

        [self sortDevices];

        dispatch_async(dispatch_get_main_queue(), ^{
            if (self->_tableView)
                [self->_tableView reloadData];
        });
    }
}

- (void)discoveryManager:(DiscoveryManager *)manager didUpdateDevice:(ConnectableDevice *)device
{
    if (_devices)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self->_tableView)
                [self->_tableView reloadData];
        });
    }
}

#pragma mark -- Getter

- (UITableView *)tableView
{
    if (_tableView == nil)
    {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        _tableView.backgroundColor = [UIColor colorWithRed:26/225.0 green:26/225.0 blue:26/225.0 alpha:1.0];
        if (_customUIDelegate)
        {
            UIView *headerView = [_customUIDelegate headerForTableview];
            headerView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [headerView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height);
            _tableView.tableHeaderView = headerView;
            
            UIView *footerView = [_customUIDelegate footerForTableview];
            footerView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [footerView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height);
            _tableView.tableFooterView = footerView;
        }
        _tableView.showsVerticalScrollIndicator = false;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.estimatedRowHeight = 44;
        _tableView.rowHeight = UITableViewAutomaticDimension;
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.bounces = false;
    }
    return _tableView;
}

@end
