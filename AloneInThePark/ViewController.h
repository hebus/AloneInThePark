//
//  ViewController.h
//  AloneInThePark
//
//  Created by dev webanafi on 16/08/12.
//  Copyright (c) 2012 CraftStudio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIBubbleTableViewDataSource.h"

@class UIBubbleTableView;

@interface ViewController : UIViewController <UIBubbleTableViewDataSource, NSURLConnectionDataDelegate, NSXMLParserDelegate>
{
    IBOutlet UIBubbleTableView *bubbleTable;
    IBOutlet UIView *messageView;
    IBOutlet UITextField *messageText;
    IBOutlet UIButton *sendButton;
    NSMutableArray *bubbleData;
    NSMutableData *receivedData;
    int lastId;
    
    NSTimer *timer;
    
    NSXMLParser *chatParser;
    NSString *msgAdded;
    NSMutableString *msgUser;
    NSMutableString *msgText;
    int msgId;
    
    Boolean inUser;
    Boolean inText;
}
- (IBAction)send:(id)sender;
@end
