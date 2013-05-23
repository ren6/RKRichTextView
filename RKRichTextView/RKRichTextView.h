//
//  RKRichTextView.h
//  ACL Workpapers
//
//  Created by ren6 on 2/1/13.
//  Copyright (c) 2013 ACL Services Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RKRichTextViewListener.h"

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
@end
