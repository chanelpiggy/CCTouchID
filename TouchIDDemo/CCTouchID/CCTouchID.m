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

LocalAuth localAuth;
Keychain keychain;

@implementation CCTouchID

+(void) LACanEvaluatePolicy:(LocalAuthBlock)resultBlock {
    if (!resultBlock) {
        return;
    }
    LAContext *context = [[LAContext alloc] init];
    __block  NSString *msg;
    NSError *error;
    BOOL success = [context canEvaluatePolicy: LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error];
    if (success) {
        resultBlock(LocalAuthReady, @"LocalAuthReady: ready");
    }
    else {
        msg = [ NSString stringWithFormat:@"LocalAuthReady: %@", [self getAuthErrorDescription:error.code]];
        resultBlock(localAuth, msg);
    }
}

+(void) LocalAuthPolicy:(LocalAuthBlock)resultBlock {
    [self LocalAuthPolicy:nil Reason:nil Result:resultBlock];
}

+(void) LocalAuthPolicy:(NSString *)fallbackTitle Reason:(NSString *)reason Result:(LocalAuthBlock)resultBlock {
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
                 resultBlock(LocalAuthSuccess, @"LocalAuthPolicy: success");
             }
             else {
                 msg = [ NSString stringWithFormat:@"LocalAuthPolicy: %@", [self getAuthErrorDescription:authenticationError.code]];
                 resultBlock(localAuth, msg);

             }
         }];
    }
    else {
        msg = [ NSString stringWithFormat:@"%@", [self getAuthErrorDescription:error.code]];
        resultBlock(localAuth, msg);
    }
}

+(void) KCAddItemAsync:(NSString *)attrService Value:(NSString *)value Result:(KeychainBlock)resultBlock {
    if (!resultBlock) {
        return;
    }
    else if (!attrService || !value) {
        resultBlock(KeychainParameterError, @"parameters missing");
        return;
    }
    CFErrorRef error = NULL;
    SecAccessControlRef sacObject;
    
    sacObject = SecAccessControlCreateWithFlags(kCFAllocatorDefault,
                                                kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                                                kSecAccessControlUserPresence,
                                                &error);
    if(sacObject == NULL || error != NULL)
    {
        NSLog(@"can't create sacObject: %@", error);
        resultBlock(KeychainUnknowError, [NSString stringWithFormat:@"can't create sacObject:%@", error]);
        return;
    }
    
    NSDictionary *attributes = @{
                                 (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                                 (__bridge id)kSecAttrService:attrService,
                                 (__bridge id)kSecValueData: [value dataUsingEncoding:NSUTF8StringEncoding],
                                 (__bridge id)kSecUseNoAuthenticationUI: @YES,
                                 (__bridge id)kSecAttrAccessControl: (__bridge_transfer id)sacObject
                                 };
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        OSStatus osstatus =  SecItemAdd((__bridge CFDictionaryRef)attributes, nil);
        NSString *msg = [NSString stringWithFormat:@"add item result: %@", [self keychainErrorToString:osstatus]];
        resultBlock(keychain, msg);
    });
}

+(void) KCCopyMatchingAsync:(NSString *)attrService Reason:(NSString *)reason Result:(KeychainBlock)resultBlock {
    if (!resultBlock) {
        return;
    }
    else if (!attrService) {
        resultBlock(KeychainParameterError, @"parameter missing");
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
            resultBlock(KeychainSuccess, result);
        }
        else {
            msg = [NSString stringWithFormat:@"copy matching result: %@", [self keychainErrorToString:status]];
            resultBlock(keychain, msg);
        }
    });
}

+(void) KCUpdateItemAsync:(NSString *)attrService NewValue:(NSString *)newValue Reason:(NSString *)reason Result:(KeychainBlock)resultBlock {
    if (!resultBlock) {
        return;
    }
    else if (!attrService || !newValue) {
        resultBlock(KeychainParameterError, @"parameter missing");
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
                              (__bridge id)kSecValueData: [newValue dataUsingEncoding:NSUTF8StringEncoding]
                              };
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        OSStatus status = SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)changes);
        NSString *msg = [NSString stringWithFormat:@"update item status: %@", [self keychainErrorToString:status]];
        resultBlock(keychain, msg);
    });
}

+(void) KCDeleteItemAsync:(NSString *)attrService Result:(KeychainBlock)resultBlock {
    if (!resultBlock) {
        return;
    }
    else if (!attrService) {
        resultBlock(KeychainParameterError, @"parameter missing");
        return;
    }
    NSDictionary *query = @{
                            (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecAttrService:attrService,
                            };
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        OSStatus status = SecItemDelete((__bridge CFDictionaryRef)(query));
        NSString *msg = [NSString stringWithFormat:@"delete item result: %@", [self keychainErrorToString:status]];
        resultBlock(keychain, msg);
    });
}

+(NSString *) getAuthErrorDescription:(NSInteger)code
{
    NSString *msg = @"";
    switch (code) {
        case LAErrorTouchIDNotEnrolled: //认证不能开始,因为touch id没有录入指纹.
            localAuth = LocalAuthNotEnrolled;
            msg = @"fingerprints not enrolled";
            break;
            
        case LAErrorTouchIDNotAvailable:    //认证不能开始,因为touch id在此台设备尚是无效的.
            localAuth = LocalAuthNotAvailable;
            msg = @"TouchID not available";
            break;
            
        case LAErrorPasscodeNotSet: //认证不能开始,因为此台设备没有设置密码.
            localAuth = LocalAuthPasscodeNotSet;
            msg = @"passcode not set";
            break;
            
        case LAErrorSystemCancel:   //认证被系统取消了,例如其他的应用程序到前台了
            localAuth = LocalAuthSystemCancel;
            msg = @"system cancel";
            break;
            
        case LAErrorUserFallback:   //认证被取消,因为用户点击了fallback按钮(输入密码).
            localAuth = LocalAuthUserFallback;
            msg = @"user fallback";
            break;
            
        case LAErrorUserCancel: //认证被用户取消,例如点击了cancel按钮.
            localAuth = LocalAuthUserCancel;
            msg = @"user cancel";
            break;
            
        case LAErrorAuthenticationFailed:   //认证没有成功,因为用户没有成功的提供一个有效的认证资格
            localAuth = LocalAuthFailed;
            msg = @"authentication failed";
            break;

        default:
            msg = @"unkown error";
            localAuth = LocalAuthUnknowError;
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
            keychain = KeychainSuccess;
            break;
            
        case errSecDuplicateItem:
            msg = @"item already exists";
            keychain = KeychainDuplicateItem;
            break;
            
        case errSecItemNotFound :
            msg = @"item not found";
            keychain = KeychainItemNotFound;
            break;
            
        case errSecAuthFailed:
            msg = @"authentication failed";
            keychain = KeychainAuthFailed;
            break;
            
        case errSecInteractionNotAllowed:
            msg = @"interaction not allowed";
            keychain = KeychainInteractionNotAllowed;  //待定,这个状态发生在已经add过相同item情况下
            break;
            
        default:
            msg = @"unkown error";
            keychain = KeychainUnknowError;
            break;
    }
    return msg;
}

@end
