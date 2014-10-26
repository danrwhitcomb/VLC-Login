//
//  AppDelegate.m
//  CS55-Desktop
//
//  Created by Dan Whitcomb on 10/21/14.
//  Copyright (c) 2014 Dan Whitcomb. All rights reserved.
//

#import "AppDelegate.h"
#import <AVFoundation/AVFoundation.h>

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSView *view;

//AV Objects
@property (strong) AVCaptureSession* avSession;
@property (strong) AVCaptureDevice* captureDevice;
@property (strong) AVCaptureInput* captureInput;
@property (strong) AVCaptureOutput* captureOutput;


@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    dispatch_async(dispatch_get_main_queue(), ^{
        [self configureCamera];
        
        CALayer *viewLayer = [[self view] layer];
        [viewLayer setBackgroundColor:CGColorGetConstantColor(kCGColorBlack)];
        
        AVCaptureVideoPreviewLayer *captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.avSession];
        [captureVideoPreviewLayer setFrame:[viewLayer bounds]];
        [viewLayer addSublayer:captureVideoPreviewLayer];
        [self.avSession startRunning];
    });
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

-(void) configureCamera {
    self.avSession = [[AVCaptureSession alloc] init];
    self.avSession.sessionPreset = AVCaptureSessionPresetHigh;
    //Select Device
    self.captureDevice = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    //Select Input
    self.captureInput = [AVCaptureDeviceInput deviceInputWithDevice:self.captureDevice error:nil];
    
    if ([self.avSession canAddInput:self.captureInput]) {
        [self.avSession addInput:self.captureInput];
    }
    
    //select ouput
    self.captureOutput = [AVCaptureVideoDataOutput new];
    
    if ( [self.avSession canAddOutput:self.captureOutput] )
        [self.avSession addOutput:self.captureOutput];
}

@end
