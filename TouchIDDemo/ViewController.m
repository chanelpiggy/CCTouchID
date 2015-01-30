//
//  ViewController.m
//  TouchIDDemo
//
//  Created by CHANEL on 15/1/23.
//  Copyright (c) 2015年 cici. All rights reserved.
//

#import "ViewController.h"
#import <LocalAuthentication/LAContext.h>
#import <LocalAuthentication/LAError.h>
#import "CCTouchID/CCTouchID.h"

#define DEFAULT_ATTRSERVICE @"key123"
#define DEFAULT_VALUEDATA @"value456"

@interface ViewController () {
    BOOL success;
}

@end

@implementation ViewController

@synthesize canEvaluatePolicyButton, evaluatePolicyButton, logView;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
//    evaluatePolicyButton.hidden = YES;
    
    [logView scrollRangeToVisible:NSMakeRange([logView.text length], 0)];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)canEvaluatePolicy:(id)sender {
    [CCTouchID LACanEvaluatePolicy:^(LAEvaluateStatus status, NSString *msg){
        if (status == LAEvaluateStatus_Ready) {
            //do something...
        }
        else {
            //do something...
        }
        NSLog(@"%@", msg);
        [self printResult:logView message:msg];
    }];
    
}

- (IBAction)evaluatePolicy:(id)sender {
    [CCTouchID LAEvaluatePolicy:nil Reason:nil Result:^(LAEvaluateStatus status, NSString *msg){
        switch (status) {
            case LAEvaluateStatus_AuthenticationSuccess: {
                
            }
                break;
            case LAEvaluateStatus_UserFallback: {
                
            }
                break;
            case LAEvaluateStatus_AuthenticationFailed: {
                
            }
                break;
                
            default:
                break;
        }
        [self printResult:logView message:msg];
    }];
}

- (IBAction)addItemAsync:(id)sender {
    [CCTouchID KCAddItemAsync:DEFAULT_ATTRSERVICE ValueData:DEFAULT_VALUEDATA Result:^(KeychainStatus status, NSString *msg){
        switch (status) {
            case KeychainStatus_Success: {
                
            }
                break;
            case KeychainStatus_InteractionNotAllowed: {
                
            }
                break;
            case KeychainStatus_UnknowError: {
                
            }
                break;
                
            default:
                break;
        }
        [self printResult:logView message:msg];
    }];
}

- (IBAction)copyMatchingAsync:(id)sender {
    [CCTouchID KCCopyMatchingAsync:DEFAULT_ATTRSERVICE Reason:@"输入密码" Result:^(KeychainStatus status, NSString *msg){
        switch (status) {
            case KeychainStatus_Success: {
                
            }
                break;
            case KeychainStatus_AuthFailed: {
                
            }
                break;

                
            default:
                break;
        }
        [self printResult:logView message:msg];
    }];
}

- (IBAction)updateItemAsync:(id)sender {
    
}

- (IBAction)deleteItemAsync:(id)sender {
    
}

- (NSString *)getAuthErrorDescription:(NSInteger)code
{
    NSString *msg = @"";
    switch (code) {
        case LAErrorTouchIDNotEnrolled:
            //认证不能开始,因为touch id没有录入指纹.
            msg = @"此设备未录入指纹信息\n";
            break;
        case LAErrorTouchIDNotAvailable:
            //认证不能开始,因为touch id在此台设备尚是无效的.
            msg = @"此设备不支持Touch ID\n";
            break;
        case LAErrorPasscodeNotSet:
            //认证不能开始,因为此台设备没有设置密码.
            msg = @"未设置密码,无法开启认证\n";
            break;
        case LAErrorSystemCancel:
            //认证被系统取消了,例如其他的应用程序到前台了
            msg = @"系统取消认证\n";
            break;
        case LAErrorUserFallback:
            //认证被取消,因为用户点击了fallback按钮(输入密码).
            msg = @"选择输入密码\n";
            break;
        case LAErrorUserCancel:
            //认证被用户取消,例如点击了cancel按钮.
            msg = @"用户取消认证\n";
            break;
        case LAErrorAuthenticationFailed:
            //认证没有成功,因为用户没有成功的提供一个有效的认证资格
            msg = @"认证失败\n";
            break;
        default:
            break;
    }
    return msg;
}

- (void)printResult:(UITextView*)textView message:(NSString*)msg
{
    dispatch_async(dispatch_get_main_queue(), ^{
        textView.text = [textView.text stringByAppendingString:[NSString stringWithFormat:@"%@\n",msg]];
        [textView scrollRangeToVisible:NSMakeRange([textView.text length], 0)];
    });
}

@end
