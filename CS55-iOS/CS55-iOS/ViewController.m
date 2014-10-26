//
//  ViewController.m
//  CS55-iOS
//
//  Created by Dan Whitcomb on 10/26/14.
//  Copyright (c) 2014 Dan Whitcomb. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreFoundation/CoreFoundation.h>

#define KEY_STRING "TEST!!!"

@interface ViewController ()

@property (nonatomic, strong) AVCaptureSession* session;

@property (nonatomic, strong) AVCaptureDevice* device;
@property NSData* key;
@property CFBitVectorRef keyVector;
@property int keyVectorLength;
@property NSString* keyString;
@property int bitIndex;

@end

dispatch_source_t timer;


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];    
    
    self.session = [[AVCaptureSession alloc] init];
    [self configureCamera];
    
    self.keyString = [NSString stringWithUTF8String:KEY_STRING];
    const char *utfString = [self.keyString UTF8String];
    self.key = [NSData dataWithBytes: utfString length: strlen(utfString)];
    
    self.keyVector = CFBitVectorCreate(NULL, [self.key bytes], [self.keyString length] * 8);
    self.keyVectorLength = CFBitVectorGetCount(self.keyVector);
    self.bitIndex = 0;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)configureCamera{
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    self.device = device;
    
    if ([device hasTorch]) {
        [device lockForConfiguration:nil];
        [device setTorchMode: AVCaptureTorchModeOn];
        [device unlockForConfiguration];
    }

}

-(void) toggleTorch{
    if([self.device torchMode] == AVCaptureTorchModeOn){
        [self.device setTorchMode:AVCaptureTorchModeOff];
    } else {
        [self.device setTorchMode:AVCaptureTorchModeOn];
    }
}

/*
Following code modified from Apple example code
*/
dispatch_source_t CreateDispatchTimer(uint64_t interval,
                                      uint64_t leeway,
                                      dispatch_queue_t queue,
                                      dispatch_block_t block)
{
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,
                                                     0, 0, queue);
    if (timer)
    {
        dispatch_source_set_timer(timer, dispatch_walltime(NULL, 0), interval, leeway);
        dispatch_source_set_event_handler(timer, block);
        dispatch_resume(timer);
    }
    return timer;
}

void MyCreateTimer(id self)
{
    dispatch_source_t aTimer = CreateDispatchTimer(3.32,
                                                   0ull * NSEC_PER_SEC,
                                                   dispatch_get_main_queue(),
                                                   ^{
                                                       [self flashNextBit];
                                                   });
    
    // Store it somewhere for later use.
    if (aTimer)
    {
        timer = aTimer;
    }
}

/*End Example code */


- (IBAction)onBtnFlash:(id)sender {
    [self.device lockForConfiguration:nil];
    [self.device setTorchMode:AVCaptureTorchModeOff];
    [self.device unlockForConfiguration];
    MyCreateTimer(self);
}

- (void) flashNextBit {
    CFBit bit = CFBitVectorGetBitAtIndex(self.keyVector, self.bitIndex);
    NSLog(@"Flash bit: %i", (unsigned int)bit);
    [self.device lockForConfiguration:nil];
    if(bit == 0){
        [self.device setTorchMode:AVCaptureTorchModeOff];
    } else {
        [self.device setTorchMode:AVCaptureTorchModeOn];
    }
    [self.device unlockForConfiguration];
    if(self.keyVectorLength - 1 == self.bitIndex ){
        dispatch_source_cancel(timer);
        self.bitIndex = 0;
        return;
    }
    
    self.bitIndex++;
}

@end
