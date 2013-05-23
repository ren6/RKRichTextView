//
//  RKRichTextView.m
//  ACL Workpapers
//
//  Created by ren6 on 2/1/13.
//  Copyright (c) 2013 ACL Services Ltd. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>
#import "RKRichTextView.h"
#define RK_IS_IPAD ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
#define RK_IS_IPHONE ([UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPad)

@interface RKRichTextView()<UIGestureRecognizerDelegate>
-(void) willChangeHeight:(int)newHeight;
-(void) willDidLoad;
-(void) onFocus;
-(void) onFocusOut;
-(void) touchMoved;
-(void) touchEnded;
@end
@implementation RKRichTextView{
    CGRect keyboardFrame;
    RKRichTextViewListener *listener;
    CGAffineTransform rotate;
    BOOL isHiding; BOOL isShowing;
    float screenHeight;
}
@synthesize isActiveResponder;
-(void) dealloc{
    [listener release];
    [self.toolbarView removeFromSuperview];
    self.toolbarView = nil;
    self.toolbar = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}
-(void) richTextViewTapped{
    [self becomeFirstResponder];
}
-(void) awakeFromNib{
    [super awakeFromNib];
    [self setup];
}
-(id)init{
    self = [super init];
    if (self){
        [self setup];
    }
    return self;
}
-(id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self){
        [self setup];
    }
    return self;
}

-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView{
    return nil; // if disable zooming then content offset will remain still
}
-(void) setup{
    self.opaque = NO;
    self.backgroundColor = [UIColor whiteColor];
    self.scrollView.delegate = self;
    listener = [[RKRichTextViewListener alloc] init];
    listener.richTextView = self;
    
    screenHeight = [[UIScreen mainScreen] bounds].size.height;
    
    self.delegate = listener;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    int index = (RK_IS_IPAD? 0:1);
    self.toolbarView = [[[NSBundle mainBundle] loadNibNamed:@"RKRichTextViewToolbar" owner:nil options:nil] objectAtIndex:index];
    CGRect aFrame = self.toolbarView.frame;
    aFrame.origin = CGPointMake(0, screenHeight);
    
    self.toolbarView.frame = aFrame;
    self.toolbarView.hidden = YES;
    
#warning I do this because toolbarView should be added to window after rootViewController was added. We need toolbarView to be above controller's view.
    
    double delayInSeconds = 0.0f;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [[UIApplication sharedApplication].delegate.window addSubview:self.toolbarView];
    });
    

    self.toolbar = (UIToolbar*)[self.toolbarView viewWithTag:10];
    for (UIBarButtonItem *item in self.toolbar.items){
        if (item.tag==1){
            [item setAction:@selector(boldAction:)];
            [item setTarget:self];
        } else if (item.tag==2){
            [item setAction:@selector(italicAction:)];
            [item setTarget:self];
        } else if (item.tag==3){
            [item setAction:@selector(underlineAction:)];
            [item setTarget:self];
        } else if (item.tag==4){
            [item setAction:@selector(strikeAction:)];
            [item setTarget:self];
        } else if (item.tag==5){
            [item setAction:@selector(orderedAction:)];
            [item setTarget:self];
        } else if (item.tag==6){
            [item setAction:@selector(unorderedAction:)];
            [item setTarget:self];
        } else if (item.tag==7){
            [item setAction:@selector(colorAction:)];
            [item setTarget:self];
        } else if (item.tag==10){
            [item setAction:@selector(resignFirstResponder)];
            [item setTarget:self];
        } else if (item.tag==100){
            [((UISegmentedControl*)[item customView]) addTarget:self action:@selector(didChangeSegmentControl:) forControlEvents:UIControlEventValueChanged];
        }
    }
    [self checkSelections];
    [self setText:@""];
}

- (UIView *)inputAccessoryView{
    return nil;
}
- (void) keyboardWillHide:(NSNotification *)notif {
    [self hideToolbar];
}
- (void) keyboardWillShow:(NSNotification *)notif {
    [self performSelector:@selector(removeBar) withObject:nil afterDelay:0.0f];
    if (RK_IS_IPHONE) {
        if (isActiveResponder)
            [self showToolbar];
        else
            [self hideToolbar];
        return;
    }
    
    NSDictionary *dict = [notif userInfo];
    CGFloat duration =[[dict objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    CGPoint beginPoint = [[dict objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].origin;
    keyboardFrame = [[dict objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    [self showToolbar];
    
    if (isActiveResponder==NO)
        self.toolbarView.hidden = YES;
    
    CGRect aFrame = self.toolbarView.frame;
    aFrame.origin = beginPoint;
    self.toolbarView.frame = aFrame;
    
    UIInterfaceOrientation newOrientation = [UIApplication sharedApplication].statusBarOrientation;
    CGRect finalFrame = self.toolbarView.frame;
    switch (newOrientation) {
            // hardcoded - I know it is not good, but there are some artifacts on iOS 5, when hiding/showing keyboard multilpe times on richtextview
        case UIInterfaceOrientationLandscapeLeft:
            finalFrame= CGRectMake(372 +10, 0, 34, 1024);
            break;
        case UIInterfaceOrientationLandscapeRight:
            finalFrame= CGRectMake(396-44, 0, 34, 1024);
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            finalFrame= CGRectMake(0, 308-44, 768, 34);
            break;
        default:
            finalFrame= CGRectMake(0, 716+10, 768, 34);
            break;
    }
    
    [UIView animateWithDuration:duration animations:^{
        [self.toolbarView setFrame:finalFrame];
    }];
    
}

-(void) hideToolbar{
    if (RK_IS_IPHONE){
        if (isHiding) return;
        isHiding =YES;
        [UIView animateWithDuration:0.25 animations:^{
            [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
            CGRect aFrame = self.toolbarView.frame;
            aFrame.origin = CGPointMake(0, screenHeight-34);
            self.toolbarView.frame = aFrame;
        } completion:^(BOOL finished) {
            NSLog(@"hide finished %i",finished);
            isHiding = NO;
            if (finished)
                self.toolbarView.hidden = YES;
        }];
        return;
    }
    self.toolbarView.hidden = YES;
    [self.toolbarView removeFromSuperview];
}
-(void) showToolbar{
    if (RK_IS_IPHONE){
        if (isShowing) return;
        isShowing = YES;
        CGRect aFrame = self.toolbarView.frame;
        aFrame.origin = CGPointMake(0, screenHeight-34);
        if (isHiding==NO)
            self.toolbarView.frame = aFrame;
        else
            [self.toolbarView.layer removeAllAnimations];
        self.toolbarView.hidden = NO;
        [UIView animateWithDuration:0.25 animations:^{
            [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
            CGRect aFrame = self.toolbarView.frame;
            aFrame.origin = CGPointMake(0, screenHeight-260 + 10);
            self.toolbarView.frame = aFrame;

        }completion:^(BOOL finished) {
            isShowing = NO;
            self.toolbarView.hidden = NO;
        }];
        return;
    }
    [self.toolbarView removeFromSuperview];
    self.toolbarView.hidden = NO;
    [[UIApplication sharedApplication].delegate.window addSubview:self.toolbarView];
    
    UIInterfaceOrientation newOrientation = [UIApplication sharedApplication].statusBarOrientation;
    switch (newOrientation) {
        case UIInterfaceOrientationLandscapeLeft:
            rotate = CGAffineTransformMakeRotation(M_PI+M_PI_2); // 90 degress
            break;
        case UIInterfaceOrientationLandscapeRight:
            rotate = CGAffineTransformMakeRotation(M_PI_2); // 270 degrees
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            rotate = CGAffineTransformMakeRotation(M_PI); // 180 degrees
            break;
        default:
            rotate = CGAffineTransformMakeRotation(0.0);
            break;
    }
    [self.toolbarView setTransform:rotate];
}
-(void) onFocusOut{
    if ([((NSObject*)[self aDelegate]) respondsToSelector:@selector(richTextViewWillLooseFocus:)])
        [[self aDelegate] richTextViewWillLooseFocus:self];
    [self hideToolbar];
    [self firstResponder:NO];
}
-(void) onFocus{
    if ([((NSObject*)[self aDelegate]) respondsToSelector:@selector(richTextViewWillReceiveFocus:)])
        [[self aDelegate] richTextViewWillReceiveFocus:self];
    [self firstResponder:YES];
    self.toolbarView.hidden = NO;
    
    if (RK_IS_IPHONE){
        if (isShowing==NO && self.toolbarView.frame.origin.y!=(screenHeight-260+10)){
            [self showToolbar];
        }
    }
}
-(void) touchEnded{
    isActiveResponder = YES;
}
-(void) touchMoved{
    if (isActiveResponder)
        [self checkSelections];
}
-(void) firstResponder:(BOOL) f{
    isActiveResponder = f;
    if (isActiveResponder){
        [[NSNotificationCenter defaultCenter] postNotificationName:@"richTextViewWillBecomeFirstResponder" object:nil];
    }
}
-(BOOL) becomeFirstResponder{
    if ([self respondsToSelector:@selector(setKeyboardDisplayRequiresUserAction:)])
        self.keyboardDisplayRequiresUserAction = NO;
    [self firstResponder:YES];
    [self stringByEvaluatingJavaScriptFromString:@"document.getElementById('entryContents').focus();"];
    [self showToolbar];
    return [super becomeFirstResponder];
}
-(BOOL)resignFirstResponder{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"richTextViewWillResignFirstResponder" object:nil];
    UITextField *t = [[UITextField alloc] initWithFrame:self.toolbarView.frame];
    [self.toolbarView.superview addSubview:t];
    [t becomeFirstResponder];
    [t resignFirstResponder];
    [t removeFromSuperview];
    [t release];

    [self stringByEvaluatingJavaScriptFromString:@"document.activeElement.blur()"];
    [self hideToolbar];
    [self firstResponder:NO];
    
    return [super resignFirstResponder];
}
-(void) setInputAccessoryView:(UIView *)inputAccessoryView{
   
}


-(void)didChangeSegmentControl:(UISegmentedControl*)sender{
    if ([((NSObject*)[self aDelegate]) respondsToSelector:@selector(prevNextControlTouched:)]){
        [[NSNotificationCenter defaultCenter] postNotificationName:@"richTextViewWillBecomeFirstResponder" object:nil];
        [[self aDelegate] prevNextControlTouched:sender];
    }
}
-(void) willDidLoad{
    if ([((NSObject*)[self aDelegate]) respondsToSelector:@selector(richTextViewDidLoad:)])
        [[self aDelegate] richTextViewDidLoad:self];
    [self checkSelections];
}
-(void) willChangeHeight:(int)newHeight{
    self.scalesPageToFit = YES;
    self.scrollView.scrollEnabled = NO;
    if ([((NSObject*)[self aDelegate]) respondsToSelector:@selector(richTextViewDidChange:)])
        [[self aDelegate] richTextViewDidChange:self];
    [self checkSelections];
}
-(int)contentSizeHeight{
    return [[self stringByEvaluatingJavaScriptFromString:@"getHeight()"] intValue];
}
-(NSString*) text{
    NSString* t = [self stringByEvaluatingJavaScriptFromString:@"document.getElementById('entryContents').innerHTML"];
    
    NSArray *stringsToRemove = [NSArray arrayWithObjects:
                                @"&nbsp;",
                                @" ",
                                @"<div>",
                                @"</div>",
                                @"<br>",
                                nil];
    NSString *t2 = t;
    for (NSString *s in stringsToRemove)
        t2 = [t2 stringByReplacingOccurrencesOfString:s withString:@""];
    if ([t2 length] == 0 ){
        return @"";
    }
    return t;
}
-(void)setText:(NSString *)richText{
    NSBundle *bundle = [NSBundle mainBundle];
    NSURL *indexFileURL = [bundle URLForResource:@"RKRichTextView" withExtension:@"html"];
	NSString *text = [NSString stringWithContentsOfURL:indexFileURL encoding:NSUTF8StringEncoding error:nil];
	text = [text stringByReplacingOccurrencesOfString:@"{%content}" withString:richText];
	[self loadHTMLString:text baseURL:nil];
    self.scalesPageToFit = YES;
    self.scrollView.scrollEnabled = NO;
    for(UIView *wview in [[[self subviews] objectAtIndex:0] subviews]) {
        if([wview isKindOfClass:[UIImageView class]]) { wview.hidden = YES; }
    }
}
- (IBAction)boldAction:(id)sender {
    [self stringByEvaluatingJavaScriptFromString:@"document.execCommand(\"Bold\")"];
        [self checkSelections];
}

- (IBAction)italicAction:(id)sender {
    [self stringByEvaluatingJavaScriptFromString:@"document.execCommand(\"Italic\")"];
        [self checkSelections];
}

- (IBAction)underlineAction:(id)sender {
    [self stringByEvaluatingJavaScriptFromString:@"document.execCommand(\"underline\")"];
        [self checkSelections];
}
- (IBAction)strikeAction:(id)sender {
    [self stringByEvaluatingJavaScriptFromString:@"document.execCommand(\"strikeThrough\")"];
        [self checkSelections];
}

- (IBAction)orderedAction:(id)sender {
    [self stringByEvaluatingJavaScriptFromString:@"document.execCommand(\"insertOrderedList\")"];
        [self checkSelections];
    if ([((NSObject*)[self aDelegate]) respondsToSelector:@selector(richTextViewDidChange:)])
        [[self aDelegate] richTextViewDidChange:self];
}
- (IBAction)unorderedAction:(id)sender {
    [self stringByEvaluatingJavaScriptFromString:@"document.execCommand(\"insertUnorderedList\")"];
    [self checkSelections];
    if ([((NSObject*)[self aDelegate]) respondsToSelector:@selector(richTextViewDidChange:)])
        [[self aDelegate] richTextViewDidChange:self];
}
-(void) checkSelections{
    
    BOOL boldEnabled = [[self stringByEvaluatingJavaScriptFromString:@"document.queryCommandState('Bold')"] boolValue];
    BOOL italicEnabled = [[self stringByEvaluatingJavaScriptFromString:@"document.queryCommandState('Italic')"] boolValue];
    BOOL underlineEnabled = [[self stringByEvaluatingJavaScriptFromString:@"document.queryCommandState('Underline')"] boolValue];
    BOOL strikeEnabled = [[self stringByEvaluatingJavaScriptFromString:@"document.queryCommandState('strikeThrough')"] boolValue];
    BOOL isOrdered = [[self stringByEvaluatingJavaScriptFromString:@"document.queryCommandState('insertOrderedList')"] boolValue];
    BOOL isUnordered = [[self stringByEvaluatingJavaScriptFromString:@"document.queryCommandState('insertUnorderedList')"] boolValue];
    
    UIColor *blue = [UIColor colorWithRed:0.2 green:0.5 blue:0.75 alpha:1.0];
    UIColor *clear = [UIColor colorWithRed:95.0f/255.0f green:97.0f/255.0f blue:106.0f/255.0f alpha:1.0f];
    for (UIBarButtonItem *item in self.toolbar.items){
        if (item.tag==1)
            [item setTintColor:boldEnabled?blue:clear];
        else if (item.tag==2)
            [item setTintColor:italicEnabled?blue:clear];
        else if (item.tag==3)
            [item setTintColor:underlineEnabled?blue:clear];
        else if (item.tag==4)
            [item setTintColor:strikeEnabled?blue:clear];
        else if (item.tag==5)
            [item setTintColor:isOrdered?blue:clear];
        else if (item.tag==6)
            [item setTintColor:isUnordered?blue:clear];
        
    }
}

-(UIWindow*) keyWindow{
    for (UIWindow *testWindow in [[UIApplication sharedApplication] windows]) {
        if (![[testWindow class] isEqual:[UIWindow class]]) {
            return testWindow;
        }
    }
    return nil;
}
- (void)removeBar {
    // Locate non-UIWindow.
    UIWindow *keyboardWindow = nil;
    for (UIWindow *testWindow in [[UIApplication sharedApplication] windows]) {
        if (![[testWindow class] isEqual:[UIWindow class]]) {
            keyboardWindow = testWindow;
            break;
        }
    }
    // Locate UIWebFormView.
    for (UIView *formView in [keyboardWindow subviews]) {
        // iOS 5 sticks the UIWebFormView inside a UIPeripheralHostView.
        if ([[formView description] rangeOfString:@"UIPeripheralHostView"].location != NSNotFound) {
            for (UIView *subView in [formView subviews]) {
                if ([[subView description] rangeOfString:@"UIWebFormAccessory"].location != NSNotFound) {
                    // remove the input accessory view
                    [subView setHidden:YES];
                    [subView removeFromSuperview];
                }
                else if([[subView description] rangeOfString:@"UIImageView"].location != NSNotFound){
                    // remove the line above the input accessory view (changing the frame)
                    [subView setHidden:YES];
                    [subView setFrame:CGRectZero];
                }
            }
        }
    }
}

@end
