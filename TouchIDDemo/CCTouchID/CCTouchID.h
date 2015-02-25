//
//  CCTouchID.h
//  TouchIDDemo
//
//  Created by CHANEL on 15/1/26.
//  Copyright (c) 2015年 cici. All rights reserved.
//
//  这是一个调用苹果TouchID的库.
//  使用时,必须添加LocalAuthentication.framework支持.
//  支持的设备目前有iPhone5s,iPhone6,iPhone6plus,iPadAir2,iPadMini3(截止到2015年2月16日).
//  支持的系统为iOS8.0及以上.
//  带前缀LA(LocalAuthentication)的方法是不涉及到iPhone密码的,只提供一个验证指纹的接口,不能验证iPhone密码,成功或失败都会返相应状态.
//  带前缀KC(KeyChain)的方法可以调用iPhone密码,可以保存一组key-value到iPhone本地,通过指纹或iPhone密码保证其安全性,必须通过验证才可以读取或修改value值.

#import <Foundation/Foundation.h>

typedef enum{
    LAEvaluateStatus_Ready,             //TouchID is ready to use
    LAEvaluateStatus_NotEnrolled,       //fingerprints not enrolled
    LAEvaluateStatus_NotAvailable,      //TouchID is not available in this device
    LAEvaluateStatus_PasscodeNotSet,
    LAEvaluateStatus_SystemCancel,
    LAEvaluateStatus_UserFallback,      //user press fallback button
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

#define DEFAULT_REASON @"Unlock to access locked feature"

typedef void (^LAEvaluateBlock)(LAEvaluateStatus, NSString *);
typedef void (^KeychainBlock)(KeychainStatus, NSString *);

@interface CCTouchID : NSObject

/**
*  验证是否支持指纹验证
*
*  @param resultBlock 响应block
*/
+(void) LACanEvaluatePolicy:(LAEvaluateBlock)resultBlock;

/**
 *  验证指纹
 *
 *  @param resultBlock 响应block
 */
+(void) LAEvaluatePolicy:(LAEvaluateBlock)resultBlock;

/**
 *  验证指纹(自定义提示文字)
 *
 *  @param fallbackTitle fallback按钮文字
 *  @param reason        验证指纹的原因(如验证指纹以登录)
 *  @param resultBlock   响应block
 */
+(void) LAEvaluatePolicy:(NSString *)fallbackTitle Reason:(NSString *)reason Result:(LAEvaluateBlock)resultBlock;

/**
 *  向KeyChain中添加key-value
 *
 *  @param attrService key
 *  @param valueData   value
 *  @param resultBlock 响应block
 */
+(void) KCAddItemAsync:(NSString *)attrService ValueData:(NSString *)valueData Result:(KeychainBlock)resultBlock;

/**
 *  验证KeyChain中的key-value
 *
 *  @param attrService key
 *  @param valueData   value
 *  @param resultBlock 响应block
 */
+(void) KCCopyMatchingAsync:(NSString *)attrService Reason:(NSString *)reason Result:(KeychainBlock)resultBlock;

/**
 *  更新KeyChain中的key-value
 *
 *  @param attrService  key
 *  @param newValueData new value
 *  @param reason       验证指纹的原因(如验证指纹以更改密码)
 *  @param resultBlock  响应block
 */
+(void) KCUpdateItemAsync:(NSString *)attrService NewValueData:(NSString *)newValueData Reason:(NSString *)reason Result:(KeychainBlock)resultBlock;

/**
 *  删除KeyChain中的key-value
 *
 *  @param attrService key
 *  @param resultBlock 响应block
 */
+(void) KCDeleteItemAsync:(NSString *)attrService Result:(KeychainBlock)resultBlock;

@end
