//
//  CCTouchID.h
//  TouchIDDemo
//
//  Created by CHANEL on 15/1/26.
//  Copyright (c) 2015年 cici. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum{
    LAEvaluateStatus_Ready,             //TouchID is ready to use
    LAEvaluateStatus_NotEnrolled,    //fingerprints not enrolled
    LAEvaluateStatus_NotAvailable,   //TouchID is not available in this device
    LAEvaluateStatus_PasscodeNotSet,
    LAEvaluateStatus_SystemCancel,
    LAEvaluateStatus_UserFallback,
    LAEvaluateStatus_UserCancel,
    LAEvaluateStatus_AuthenticationFailed,
    LAEvaluateStatus_AuthenticationSuccess,
    LAEvaluateStatus_ParameterError,
    LAEvaluateStatus_UnknowError,
}LAEvaluateStatus;

typedef enum{
    KeychainStatus_Success,
    KeychainStatus_DuplicateItem,
    KeychainStatus_ItemNotFound,
    KeychainStatus_AuthFailed,
    KeychainStatus_InteractionNotAllowed,
    KeychainStatus_ParameterError,
    KeychainStatus_UnknowError,
}KeychainStatus;

#define DEFAULT_REASON @"Unlock access to locked feature"

typedef void (^LAEvaluateBlock)(LAEvaluateStatus, NSString *);
typedef void (^KeychainBlock)(KeychainStatus, NSString *);

@interface CCTouchID : NSObject

+(void) LACanEvaluatePolicy:(LAEvaluateBlock)resultBlock;
+(void) LAEvaluatePolicy:(LAEvaluateBlock)resultBlock;
+(void) LAEvaluatePolicy:(NSString *)fallbackTitle Reason:(NSString *)reason Result:(LAEvaluateBlock)resultBlock;

+(void) KCAddItemAsync:(NSString *)attrService ValueData:(NSString *)valueData Result:(KeychainBlock)resultBlock;
+(void) KCCopyMatchingAsync:(NSString *)attrService Reason:(NSString *)reason Result:(KeychainBlock)resultBlock;

@end
