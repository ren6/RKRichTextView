//
//  RKRichTextView.h
//
//  Created by ren6 on 2/1/13.
//

#import <UIKit/UIKit.h>
#import "RKRichTextViewListener.h"

/**
 Add observers for following notifications if needed
 **/
extern NSString * const WRKRichTextViewWillBecomeFirstResponder;
extern NSString * const WRKRichTextViewWillResignFirstResponder;


@class RKRichTextView;
@protocol RKRichTextViewDelegate
@optional
-(void) prevNextControlTouched:(UISegmentedControl*)control;
-(void) richTextViewDidChange:(RKRichTextView *)richTextView;
-(void) richTextViewDidLoad:(RKRichTextView*)richTextView;
-(void) richTextViewWillReceiveFocus:(RKRichTextView*)richTextView;
-(void) richTextViewWillLooseFocus:(RKRichTextView*)richTextView;
@end

@interface RKRichTextView : UIWebView

@property (nonatomic, assign) BOOL isTheOnlyRichTextView; // Recommended to use. If set to YES, then rich text view will not create a temporary text field and then will not make first responder and resign. See ResignFirstResponder method. Default is NO.

@property (nonatomic, assign) BOOL isActiveResponder; // don't want to override isFirstResponder property
@property (nonatomic, assign) id <RKRichTextViewDelegate> aDelegate;
@property (nonatomic, retain) UIView *toolbarView;
@property (nonatomic, retain) UIToolbar *toolbar;
@property (nonatomic, retain) UIToolbar *toolbariPhone;
@property (nonatomic, assign) UIView *modalView;
@property (nonatomic, retain) NSString *text; // HTML Text
-(int) contentSizeHeight;
-(BOOL) becomeFirstResponder;
-(BOOL)resignFirstResponder;
-(void) setMinimumHeight:(int)newHeight;
@end
