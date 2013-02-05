//
//  ViewController.m
//  AloneInThePark
//
//  Created by dev webanafi on 16/08/12.
//  Copyright (c) 2012 CraftStudio. All rights reserved.
//

#import "ViewController.h"
#import "UIBubbleTableView.h"
#import "UIBubbleTableViewDataSource.h"
#import "NSBubbleData.h"
#import "Reachability.h"

@interface ViewController ()

@end

@implementation ViewController{
    UITapGestureRecognizer *tapRecongnizer;
    NSString *username;
}

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    if(self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]){
        lastId = 0;
        chatParser = NULL;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *user = [defaults stringForKey:@"username_preference"];
    if([user length] > 0)
        username = user;
    else
        username = @"default";
    
    
	// Do any additional setup after loading the view, typically from a nib.
    bubbleTable.bubbleDataSource = self;
    [self getNewMessages];

    /*
    bubbleData = [[NSMutableArray alloc] initWithObjects:
                  [NSBubbleData dataWithText:@"Marge, there's something that I want to ask you, but I'm afraid, because if you say no, it will destroy me and make me a criminal." andDate:[NSDate dateWithTimeIntervalSinceNow:-300] andType:BubbleTypeMine],
                  [NSBubbleData dataWithText:@"Well, I haven't said no to you yet, have I?" andDate:[NSDate dateWithTimeIntervalSinceNow:-280] andType:BubbleTypeSomeoneElse],
                  [NSBubbleData dataWithText:@"Marge... Oh, damn it." andDate:[NSDate dateWithTimeIntervalSinceNow:0] andType:BubbleTypeMine],
                  [NSBubbleData dataWithText:@"What's wrong?" andDate:[NSDate dateWithTimeIntervalSinceNow:300]  andType:BubbleTypeSomeoneElse],
                  [NSBubbleData dataWithText:@"Ohn I wrote down what I wanted to say on a card.." andDate:[NSDate dateWithTimeIntervalSinceNow:395]  andType:BubbleTypeMine],
                  [NSBubbleData dataWithText:@"The stupid thing must have fallen out of my pocket." andDate:[NSDate dateWithTimeIntervalSinceNow:400]  andType:BubbleTypeMine],
                  nil];
*/
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardShown:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardHidden:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    tapRecongnizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                             action:@selector(didTapAnywhere:)];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityChanged:)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    
    Reachability * reach = [Reachability reachabilityWithHostname:@"fmpevolution.free.fr"];
    
    reach.reachableBlock = ^(Reachability * reachability)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Block Says Reachable");
            [bubbleData addObject:[NSBubbleData dataWithText:@"Block Says Reachable" andDate:[NSDate dateWithTimeIntervalSinceNow:0] andType:BubbleTypeSomeoneElse]];
            [self getNewMessages];
            sendButton.enabled = true;
        });
    };
    
    reach.unreachableBlock = ^(Reachability * reachability)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Block Says Unreachable");
            [bubbleData addObject:[NSBubbleData dataWithText:@"Block Says Unreachable" andDate:[NSDate dateWithTimeIntervalSinceNow:0] andType:BubbleTypeSomeoneElse]];
            [bubbleTable reloadData];

            sendButton.enabled = false;
        });
    };
    
    [reach startNotifier];
}

-(void)reachabilityChanged:(NSNotification*)note
{
    Reachability * reach = [note object];
    
    if([reach isReachable])
    {
        NSLog(@"Notification Says Reachable");
        [bubbleData addObject:[NSBubbleData dataWithText:@"Notification Says Reachable" andDate:[NSDate dateWithTimeIntervalSinceNow:0] andType:BubbleTypeSomeoneElse]];
        [self getNewMessages];
        sendButton.enabled = true;
    }
    else
    {
        NSLog(@"Notification Says Unreachable");
        [bubbleData addObject:[NSBubbleData dataWithText:@"Notification Says Unreachable" andDate:[NSDate dateWithTimeIntervalSinceNow:0] andType:BubbleTypeSomeoneElse]];
        [bubbleTable reloadData];
        sendButton.enabled = false;
    }
}

#pragma mark - keyboard notifications
-(void)keyboardShown:(NSNotification*)note{
    [bubbleTable addGestureRecognizer:tapRecongnizer];
    
    CGRect keyboardFrame;
    [[[note userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardFrame];
    CGRect tableViewFrame = bubbleTable.frame;
    tableViewFrame.size.height -= keyboardFrame.size.height;
    [bubbleTable setFrame:tableViewFrame];

    tableViewFrame = messageView.frame;
    tableViewFrame.origin.y -= keyboardFrame.size.height;
    [messageView setFrame:tableViewFrame];
}
-(void)keyboardHidden:(NSNotification*)note{
    [bubbleTable removeGestureRecognizer:tapRecongnizer];
    
    CGRect keyboardFrame;
    [[[note userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardFrame];
    [self restoreViewPositions:keyboardFrame];
}
-(void)didTapAnywhere:(NSNotification*)note{
    [messageText resignFirstResponder];
}
-(void)restoreViewPositions:(CGRect)keyboardFrame{
    CGRect tableViewFrame = bubbleTable.frame;
    tableViewFrame.size.height += keyboardFrame.size.height;
    [bubbleTable setFrame:tableViewFrame];
    
    CGRect frame = messageView.frame;
    frame.origin.y += keyboardFrame.size.height;
    [messageView setFrame:frame];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (IBAction)send:(id)sender {
    if([messageText.text length] > 0){
        NSString *url = [NSString stringWithFormat:@"http://fmpevolution.free.fr/add.php"];
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc]init];
        [request setURL:[NSURL URLWithString:url]];
        [request setHTTPMethod:@"POST"];
        
        NSMutableData *body = [NSMutableData data];
        NSString *text = [NSString stringWithFormat:@"user=%@&message=%@&latitude=0&longitude=0", username,messageText.text];
        const char *utfstring = [text UTF8String];
        body = [body initWithBytes:utfstring length:strlen(utfstring)];
        [request setHTTPBody:body];
        
        NSHTTPURLResponse *response = nil;
        NSError *error = [[NSError alloc]init];
        [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        
        [self getNewMessages];
    }
    
    //    [bubbleData addObject:[NSBubbleData dataWithText:messageText.text andDate:[NSDate dateWithTimeIntervalSinceNow:0] andType:BubbleTypeMine]];
    //    [bubbleTable reloadData];
    messageText.text = @"";
}

#pragma mark - UIBubbleTableViewDataSource implementation
-(NSInteger)rowsForBubbleTable:(UIBubbleTableView *)tableView{
    return [bubbleData count];
}
-(NSBubbleData *)bubbleTableView:(UIBubbleTableView *)tableView dataForRow:(NSInteger)row{
    return [bubbleData objectAtIndex:row];
}

#pragma mark - Chat messages
-(void)getNewMessages{
    NSString *url = [NSString stringWithFormat:@"http://fmpevolution.free.fr/messages.php?past=%d&t=%ld", lastId, time(0)];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]init];
    [request setURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"GET"];
    
    NSURLConnection *conn = [[NSURLConnection alloc]initWithRequest:request delegate:self];
    if(conn){
        receivedData = [NSMutableData data];
    }
}

#pragma mark - NSURLConnectionDataDelegate implementation
-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    [receivedData setLength:0];
}
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    [receivedData appendData:data];
}
-(void)connectionDidFinishLoading:(NSURLConnection *)connection{
    if(chatParser)
        chatParser = nil;
    
    if(bubbleData == nil)
        bubbleData = [[NSMutableArray alloc]init];
    
    
//    NSString *str = [[NSString alloc]initWithData:receivedData encoding:NSUTF8StringEncoding];
//    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
    
    chatParser = [[NSXMLParser alloc]initWithData:receivedData];
    [chatParser setDelegate:self];
    [chatParser parse];
    
    receivedData = nil;
    [bubbleTable reloadData];
    
    if([bubbleData count] > 0){
        NSIndexPath *scrollIndexPath = [NSIndexPath indexPathForRow:([bubbleTable numberOfRowsInSection:([bubbleTable numberOfSections]-1)]-1) inSection:([bubbleTable numberOfSections]-1)];
        [bubbleTable scrollToRowAtIndexPath:scrollIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
    
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:@selector(timerCallBack)]];
    [invocation setTarget:self];
    [invocation setSelector:@selector(timerCallBack)];
    timer = [NSTimer scheduledTimerWithTimeInterval:5.0 invocation:invocation repeats:NO];
}
-(void)timerCallBack{
    timer = nil;
    [self getNewMessages];
}

#pragma mark - parsing the messages
-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict{
    if([elementName isEqualToString:@"message"]){
        msgAdded = [attributeDict objectForKey:@"added"];
        msgId = [[attributeDict objectForKey:@"id"] intValue];
        msgUser = [[NSMutableString alloc]init];
        msgText = [[NSMutableString alloc]init];
        inUser = NO;
        inText = NO;
    }
    if([elementName isEqualToString:@"user"])
        inUser = YES;
    
    if([elementName isEqualToString:@"text"])
        inText = YES;
}
-(void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string{
    if(inUser)
        [msgUser appendString:string];
    if(inText)
        [msgText appendString:string];
}
-(void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName{
    if([elementName isEqualToString:@"message"]){
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        NSDate *dateAdded = [dateFormatter dateFromString:msgAdded];
        if([msgUser isEqualToString:username]){
            [bubbleData addObject:[NSBubbleData dataWithText:msgText andDate:dateAdded andType:BubbleTypeMine]];
        }
        else{
            [bubbleData addObject:[NSBubbleData dataWithText:[NSString stringWithFormat:@"%@:\r\n%@",msgUser, msgText]  andDate:dateAdded andType:BubbleTypeSomeoneElse]];
        }
        lastId = msgId;
        msgAdded = nil;
        msgUser = nil;
        msgText = nil;
    }
    if([elementName isEqualToString:@"user"])
        inUser = NO;
    if([elementName isEqualToString:@"text"])
        inText = NO;
}

@end
