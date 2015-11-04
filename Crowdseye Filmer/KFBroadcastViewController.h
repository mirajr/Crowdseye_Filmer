//
//  KFBroadcastViewController.h
//  Kickflip
//
//  Created by Christopher Ballinger on 1/16/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KFRecorder.h"
#import "Kickflip.h"
#import "KFRecordButton.h"
#import "Parse.h"

/**
 *  This is the main broadcast user interface that presents a start/stop button
 *  and provides the user with the ability to share a link to the stream
 *  when it has buffered enough segments.
 *
 *  You can also use the Kickflip class to show this view from any UIViewController.
 */
@interface KFBroadcastViewController : UIViewController <KFRecorderDelegate, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@property (nonatomic, copy) KFBroadcastReadyBlock readyBlock;
@property (nonatomic, copy) KFBroadcastCompletionBlock completionBlock;

@property (strong, nonatomic) UIView *cameraView;
@property (nonatomic, strong) UIButton *shareButton;
@property (nonatomic, strong) KFRecordButton *recordButton;
@property (nonatomic, strong) UIImageView *liveBanner;

@property (nonatomic, strong) KFRecorder *recorder;
@property (nonatomic, strong) NSURL *shareURL;

@property (nonatomic, strong) UILabel *rotationLabel;
@property (nonatomic, strong) UIImageView *rotationImageView;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) PFObject *eventObject;
//@property (nonatomic, strong) NSString *eventKey;
@property (nonatomic, strong) UITextField *titleText;
@property (nonatomic, strong) UITableView *commentsTable;
@property (nonatomic, strong) NSMutableArray *chats;
@property (nonatomic, strong) NSString *currentView;

@end
