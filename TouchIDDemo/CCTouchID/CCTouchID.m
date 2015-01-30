//
//  CCTouchID.m
//  TouchIDDemo
//
//  Created by CHANEL on 15/1/26.
//  Copyright (c) 2015年 cici. All rights reserved.
//

#import "CCTouchID.h"
#import <LocalAuthentication/LAContext.h>
#import <LocalAuthentication/LAError.h>

LAEvaluateStatus laEvaluateStatus;
KeychainStatus keychainStatus;

@implementation CCTouchID

+(void) LACanEvaluatePolicy:(LAEvaluateBlock)resultBlock {
    if (!resultBlock) {
        return;
    }
    LAContext *context = [[LAContext alloc] init];
    __block  NSString *msg;
    NSError *error;
    BOOL success = [context canEvaluatePolicy: LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error];
    if (success) {
        resultBlock(LAEvaluateStatus_Ready, @"LACanEvaluatePolicy: ready");
    }
    else {
        msg = [ NSString stringWithFormat:@"LACanEvaluatePolicy: %@", [self getAuthErrorDescription:error.code]];
        resultBlock(laEvaluateStatus, msg);
    }
}

+(void) LAEvaluatePolicy:(LAEvaluateBlock)resultBlock {
    [self LAEvaluatePolicy:nil Reason:nil Result:resultBlock];
}

+(void) LAEvaluatePolicy:(NSString *)fallbackTitle Reason:(NSString *)reason Result:(LAEvaluateBlock)resultBlock {
    if (!resultBlock) {
        return;
    }
    if (!reason) {
        reason = DEFAULT_REASON;
    }
    LAContext *context = [[LAContext alloc] init];
    context.localizedFallbackTitle = fallbackTitle;
    __block  NSString *msg;
    NSError *error;
    BOOL success = [context canEvaluatePolicy: LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error];
    if (success) {
        [context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics localizedReason:reason reply:
         ^(BOOL passed, NSError *authenticationError) {
             if (passed) {
                 resultBlock(LAEvaluateStatus_AuthenticationSuccess, @"LAEvaluatePolicy: success");
             }
             else {
                 msg = [ NSString stringWithFormat:@"LAEvaluatePolicy: %@", [self getAuthErrorDescription:authenticationError.code]];
                 resultBlock(laEvaluateStatus, msg);

             }
         }];
    }
    else {
        msg = [ NSString stringWithFormat:@"%@", [self getAuthErrorDescription:error.code]];
        resultBlock(laEvaluateStatus, msg);
    }
}

+(void) KCAddItemAsync:(NSString *)attrService ValueData:(NSString *)valueData Result:(KeychainBlock)resultBlock {
    if (!resultBlock) {
        return;
    }
    else if (!attrService || !valueData) {
        resultBlock(KeychainStatus_ParameterError, @"parameters missing");
        return;
    }
    CFErrorRef error = NULL;
    SecAccessControlRef sacObject;
    
    sacObject = SecAccessControlCreateWithFlags(kCFAllocatorDefault,
                                                kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                                                kSecAccessControlUserPresence, &error);
    if(sacObject == NULL || error != NULL)
    {
        NSLog(@"can't create sacObject: %@", error);
        resultBlock(KeychainStatus_UnknowError, [NSString stringWithFormat:@"can't create sacObject:%@", error]);
        return;
    }
    
    NSDictionary *attributes = @{
                                 (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                                 (__bridge id)kSecAttrService:attrService,
                                 (__bridge id)kSecValueData: [valueData dataUsingEncoding:NSUTF8StringEncoding],
                                 (__bridge id)kSecUseNoAuthenticationUI: @YES,
                                 (__bridge id)kSecAttrAccessControl: (__bridge_transfer id)sacObject
                                 };
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        OSStatus osstatus =  SecItemAdd((__bridge CFDictionaryRef)attributes, nil);
        NSString *msg = [NSString stringWithFormat:@"add item status: %@", [self keychainErrorToString:osstatus]];
        resultBlock(keychainStatus, msg);
    });
}

+(void) KCCopyMatchingAsync:(NSString *)attrService Reason:(NSString *)reason Result:(KeychainBlock)resultBlock {
    if (!resultBlock) {
        return;
    }
    else if (!attrService) {
        resultBlock(KeychainStatus_ParameterError, @"parameter missing");
        return;
    }
    else if (!reason) {
        reason = DEFAULT_REASON;
    }
    NSDictionary *query = @{
                            (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecAttrService:attrService,
                            (__bridge id)kSecReturnData: @YES,
                            (__bridge id)kSecUseOperationPrompt:reason
                            };
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CFTypeRef dataTypeRef = NULL;
        NSString *msg;
        
        OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)(query), &dataTypeRef);
        if (status == errSecSuccess) {
            NSData *resultData = ( __bridge_transfer NSData *)dataTypeRef;
            NSString * result = [[NSString alloc] initWithData:resultData encoding:NSUTF8StringEncoding];
            resultBlock(KeychainStatus_Success, result);
        }
        else {
            msg = [NSString stringWithFormat:@"copy matching status: %@", [self keychainErrorToString:status]];
            resultBlock(keychainStatus, msg);
        }
    });
}

+(void) KCUpdateItemAsync:(NSString *)attrService NewValueData:(NSString *)newValueData Reason:(NSString *)reason Result:(KeychainBlock)resultBlock {
    if (!resultBlock) {
        return;
    }
    else if (!attrService || !newValueData) {
        resultBlock(KeychainStatus_ParameterError, @"parameter missing");
        return;
    }
    else if (!reason) {
        reason = DEFAULT_REASON;
    }
    NSDictionary *query = @{
                            (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecAttrService:attrService,
                            (__bridge id)kSecUseOperationPrompt:reason
                            };
    
    NSDictionary *changes = @{
                              (__bridge id)kSecValueData: [newValueData dataUsingEncoding:NSUTF8StringEncoding]
                              };
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        OSStatus status = SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)changes);
        NSString *msg = [NSString stringWithFormat:@"update item status: %@", [self keychainErrorToString:status]];
        resultBlock(keychainStatus, msg);
    });
}

+(void) KCDeleteItemAsync:(NSString *)attrService Result:(KeychainBlock)resultBlock {
    if (!resultBlock) {
        return;
    }
    else if (!attrService) {
        resultBlock(KeychainStatus_ParameterError, @"parameter missing");
        return;
    }
    NSDictionary *query = @{
                            (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecAttrService:attrService,
                            };
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        OSStatus status = SecItemDelete((__bridge CFDictionaryRef)(query));
        NSString *msg = [NSString stringWithFormat:@"delete item status: %@", [self keychainErrorToString:status]];
        resultBlock(keychainStatus, msg);
    });
}

+(NSString *) getAuthErrorDescription:(NSInteger)code
{
    NSString *msg = @"";
    switch (code) {
        case LAErrorTouchIDNotEnrolled:
            //认证不能开始,因为touch id没有录入指纹.
            laEvaluateStatus = LAEvaluateStatus_NotEnrolled;
            msg = @"fingerprints not enrolled";
            break;
        case LAErrorTouchIDNotAvailable:
            //认证不能开始,因为touch id在此台设备尚是无效的.
            laEvaluateStatus = LAEvaluateStatus_NotAvailable;
            msg = @"TouchID not available";
            break;
        case LAErrorPasscodeNotSet:
            //认证不能开始,因为此台设备没有设置密码.
            laEvaluateStatus = LAEvaluateStatus_PasscodeNotSet;
            msg = @"passcode not set";
            break;
        case LAErrorSystemCancel:
            //认证被系统取消了,例如其他的应用程序到前台了
            laEvaluateStatus = LAEvaluateStatus_SystemCancel;
            msg = @"system cancel";
            break;
        case LAErrorUserFallback:
            //认证被取消,因为用户点击了fallback按钮(输入密码).
            laEvaluateStatus = LAEvaluateStatus_UserFallback;
            msg = @"user fallback";
            break;
        case LAErrorUserCancel:
            //认证被用户取消,例如点击了cancel按钮.
            laEvaluateStatus = LAEvaluateStatus_UserCancel;
            msg = @"user cancel";
            break;
        case LAErrorAuthenticationFailed:
            //认证没有成功,因为用户没有成功的提供一个有效的认证资格
            laEvaluateStatus = LAEvaluateStatus_AuthenticationFailed;
            msg = @"authentication failed";
            break;

        default:
            msg = @"unkown error";
            laEvaluateStatus = LAEvaluateStatus_UnknowError;
            break;
    }
    return msg;
}

+ (NSString *)keychainErrorToString:(OSStatus)error
{
    
    NSString *msg = [NSString stringWithFormat:@"%ld",(long)error];
    
    switch (error) {
        case errSecSuccess:
            msg = @"success";
            keychainStatus = KeychainStatus_Success;
            break;
        case errSecDuplicateItem:
            msg = @"item already exists";
            keychainStatus = KeychainStatus_DuplicateItem;
            break;
        case errSecItemNotFound :
            msg = @"item not found";
            keychainStatus = KeychainStatus_ItemNotFound;
            break;
        case errSecAuthFailed:
            msg = @"authentication failed";
            keychainStatus = KeychainStatus_AuthFailed;
            break;
        case errSecInteractionNotAllowed:
            msg = @"interaction not allowed";
            keychainStatus = KeychainStatus_InteractionNotAllowed;  //待定,这个状态发生在已经add过相同item情况下
            break;
            
        default:
            msg = @"unkown error";
            keychainStatus = KeychainStatus_UnknowError;
            break;
    }
    return msg;
}

@end
