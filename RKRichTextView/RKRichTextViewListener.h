//
//  RichTextDelegateListener.h
//
//  Created by ren6 on 2/4/13.
//

#import <Foundation/Foundation.h>
#import "RKRichTextView.h"
@class RKRichTextView;
@interface RKRichTextViewListener : NSObject <UIWebViewDelegate>
@property (nonatomic, assign) RKRichTextView* richTextView;
@end
