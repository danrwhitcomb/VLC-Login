//
//  AppDelegate.m
//  CS55-Desktop
//
//  Created by Dan Whitcomb on 10/21/14.
//  Copyright (c) 2014 Dan Whitcomb. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSView *view;

//AV Objects
@property (strong) AVCaptureSession* avSession;
@property (strong) AVCaptureDevice* captureDevice;
@property (strong) AVCaptureInput* captureInput;
@property (strong) AVCaptureVideoDataOutput* captureOutput;


@end


@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    cv::VideoCapture cap(0); // open the default camera
    if(!cap.isOpened())  // check if we succeeded
        return;
    
    cv::Mat edges;
    cv::namedWindow("edges",1);
    for(;;)
    {
        cv::Mat frame;
        cap >> frame; // get a new frame from camera
        cvtColor(frame, edges, CV_BGR2GRAY);
        GaussianBlur(edges, edges, cv::Size(7,7), 1.5, 1.5);
        Canny(edges, edges, 0, 30, 3);
        imshow("edges", edges);
    }
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


/* AVFoundation Camera configuration*/
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
    
    // Configure your output.
    dispatch_queue_t queue = dispatch_queue_create("myQueue", NULL);
    [self.captureOutput setSampleBufferDelegate:self queue:queue];
}


@end
