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


@interface ViewController ()

@property (nonatomic, strong) AVCaptureSession* session;

@property (nonatomic, strong) AVCaptureDevice* device;
@property NSData* key;
@property CFBitVectorRef keyVector;
@property long keyVectorLength;
@property NSString* keyString;
@property int bitIndex;
@property (strong, nonatomic) IBOutlet UITextField *keyField;
@property bool isFlashing;

@end

dispatch_source_t timer;
float torch_on = .5;
float torch_off = 0.05;


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];    
    self.keyField.delegate = self;
    self.session = [[AVCaptureSession alloc] init];
    [self configureCamera];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(turnOnTorch) name:UIApplicationDidBecomeActiveNotification object:nil];

    
    self.bitIndex = 0;
}

-(void) turnOnTorch {
    [self.device lockForConfiguration:nil];
    [self.device setTorchMode:AVCaptureTorchModeOn];
    [self.device unlockForConfiguration];
}

-(void) setKeyStringVector:(NSString*)string{
    const char *utfString = [string UTF8String];
    int length = strlen(utfString);
    self.key = [NSData dataWithBytes: utfString length: strlen(utfString)];
    
    CFBitVectorRef vector = CFBitVectorCreate(NULL, [self.key bytes], length * 8);
    CFMutableBitVectorRef mVector = CFBitVectorCreateMutable(kCFAllocatorDefault, 0);
    CFBitVectorSetCount(mVector, length*8+1);
    CFBitVectorSetBitAtIndex(mVector, 0, 0);
    
    
    
    for(int i=1; i <= length*sizeof(char)*8; i++){
        CFBitVectorSetBitAtIndex(mVector, i, CFBitVectorGetBitAtIndex(vector, i-1));
    }
    
    self.keyVectorLength = CFBitVectorGetCount(mVector);
    self.keyVector = CFBitVectorCreateCopy(NULL, mVector);
}


- (void) viewDidAppear:(BOOL)animated {
    [self.device lockForConfiguration:nil];
    [self.device setTorchMode: AVCaptureTorchModeOn];
    [self.device unlockForConfiguration];
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
    [self.device lockForConfiguration:nil];
    if([self.device torchMode] == AVCaptureTorchModeOn){
        [self.device setTorchMode:AVCaptureTorchModeOff];
    } else {
        [self.device setTorchMode:AVCaptureTorchModeOn];
    }
    [self.device unlockForConfiguration];
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
    dispatch_source_t aTimer = CreateDispatchTimer(100000000,
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
    [self setKeyStringVector:self.keyField.text];
    if(!self.isFlashing){
        MyCreateTimer(self);
        self.isFlashing = YES;
    } else if(self.bitIndex > self.keyVectorLength - 1 && self.isFlashing){
        [self cancelFlash];
    }
}

- (IBAction)onBtnStartBit:(id)sender {
    if(!self.isFlashing){
        [self.device lockForConfiguration:nil];
        [self.device setTorchMode:AVCaptureTorchModeOn];
        [self.device unlockForConfiguration];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

-(void) cancelFlash {
    dispatch_source_cancel(timer);
    self.bitIndex = 0;
    [self.device lockForConfiguration:nil];
    [self.device setTorchMode:AVCaptureTorchModeOff];
    [self.device unlockForConfiguration];
    self.isFlashing = NO;

}

- (void) flashNextBit {
    if(self.bitIndex == self.keyVectorLength){
        [self cancelFlash];
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Finished" message:@"The key has been transmitted" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                  [alert dismissViewControllerAnimated:YES completion:nil];
                                                              }];
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];
    } else {
        CFBit bit = CFBitVectorGetBitAtIndex(self.keyVector, self.bitIndex);
        printf("%i",(unsigned int) bit);
        [self.device lockForConfiguration:nil];
        if(bit == 0){
            [self.device setTorchMode:AVCaptureTorchModeOff];
        } else {
            [self.device setTorchMode:AVCaptureTorchModeOn];
        }
        [self.device unlockForConfiguration];
        self.bitIndex++;
    }
}

@end
