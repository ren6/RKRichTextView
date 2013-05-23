//
//  RichTextDelegateListener.h
//  ACL Workpapers
//
//  Created by ren6 on 2/4/13.
//  Copyright (c) 2013 ACL Services Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RKRichTextView.h"
@class RKRichTextView;
@interface RKRichTextViewListener : NSObject <UIWebViewDelegate>
@property (nonatomic, assign) RKRichTextView* richTextView;
@end
