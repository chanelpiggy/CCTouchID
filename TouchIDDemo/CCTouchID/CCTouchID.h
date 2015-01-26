//
//  CCTouchID.h
//  TouchIDDemo
//
//  Created by CHANEL on 15/1/26.
//  Copyright (c) 2015年 cici. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum{
    CheckStatus_OK,             //Touch ID is OK
    CheckStatus_NotEnrolled,    //fingerprints not enrolled
    CheckStatus_NotAvailable,   //Touch ID is not available in this device
    CheckStatus_PasscodeNotSet, //Passcode not set
}CheckStatus;

@interface CCTouchID : NSObject

+(void) checkTouchID;

@end
