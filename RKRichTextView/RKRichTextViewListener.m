//
//  RichTextDelegateListener.m
//
//  Created by ren6 on 2/4/13.
//

#import "RKRichTextViewListener.h"
@interface RKRichTextView()
-(void) willChangeHeight:(int)newHeight;
-(void) willDidLoad;
-(void) onFocus;
-(void) onFocusOut;
-(void) touchEnded;
-(void) touchMoved;
@end
@implementation RKRichTextViewListener
-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
    
    NSString *string = request.URL.absoluteString;
    if ([string rangeOfString:@"focusout"].location!=NSNotFound){
        [self.richTextView onFocusOut];
        return NO;
    } else if ([string rangeOfString:@"focusin"].location!=NSNotFound){
        [self.richTextView onFocus];
        return NO;
    } else if ([string rangeOfString:@"touchmove"].location!=NSNotFound){
        [self.richTextView touchMoved];
        return NO;
    } else if ([string rangeOfString:@"touchend"].location!=NSNotFound){
        [self.richTextView touchEnded];
        return NO;
    } else if ([string rangeOfString:@"touchstart"].location!=NSNotFound){
        return NO;
    }
    string = [string stringByReplacingOccurrencesOfString:@"http://" withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@".ru/" withString:@""];
    int height = [string intValue];
    if (height>0){
        [self.richTextView willChangeHeight:height];
        return NO;
    }
    return YES;
}
-(void)webViewDidFinishLoad:(RKRichTextView *)webView{
    [self.richTextView willDidLoad];
}
@end
