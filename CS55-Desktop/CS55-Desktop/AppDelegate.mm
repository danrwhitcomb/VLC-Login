//
//  AppDelegate.m
//  CS55-Desktop
//
//  Created by Dan Whitcomb on 10/21/14.
//  Copyright (c) 2014 Dan Whitcomb. All rights reserved.
//

#import "AppDelegate.h"
#import <string.h>

#define MEAN_SAMPLES 90
#define KEY_LENGTH 9

using namespace std;
using namespace cv;

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSView *view;
@property (weak) NSString* keyString;

//AV Objects
@property (strong) AVCaptureSession* avSession;
@property (strong) AVCaptureDevice* captureDevice;
@property (strong) AVCaptureInput* captureInput;
@property (strong) AVCaptureVideoDataOutput* captureOutput;

@end

int threshold_value = 250;

string windowName = "CS55_Receiver";
dispatch_source_t timer;
vector<cv::KeyPoint> keypoints;
Mat global_frame, prev_frame;

cv::Rect rect(600, 200, 200, 200);

int keyArray[KEY_LENGTH];
int keyCursor = 0;

int startBit = 0;
float maxSize;
float minSize;

float sizeThreshold = 0.4;

int key[KEY_LENGTH];

double stdDevVals[MEAN_SAMPLES];
float stdDev;
int meanCount = 0;
double meanTotal = 0;
float maxMean = 0;

int receiveCount = 0;
enum StateDef {
    WaitForStart,
    DetectingLight,
    ReadingBits,
    DisplayResult
};

StateDef currentState = WaitForStart;


@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    [NSEvent addLocalMonitorForEventsMatchingMask:NSLeftMouseUp handler:^NSEvent *(NSEvent * event) {
        currentState = DetectingLight;
        return event;
    }];

    //releases and window destroy are automatic in C++ interface
    VideoCapture cap(0); // open the default camera
    if(!cap.isOpened())  // check if we succeeded
        return;
    
    Mat gray_frame, dst;
    namedWindow(windowName,1);
    SimpleBlobDetector::Params params;
    params.minDistBetweenBlobs = 100.0f;
    params.filterByInertia = false;
    params.filterByConvexity = false;
    params.filterByColor = false;
    params.filterByCircularity = false;
    params.filterByArea = true;
    params.blobColor = 255;
    params.minArea = 200;
    params.maxArea = 700;
    // ... any other params you don't want default value
    
    // set up and create the detector using the parameters
    //cv::Ptr<cv::FeatureDetector> blob_detector = cv::SimpleBlobDetector::create(params);

    for(;;)
    {
        cv::Mat frame, gray_frame, thresh;
        cap >> frame; // get a new frame from camera
        cvtColor(frame, gray_frame, CV_BGR2GRAY);
        threshold(gray_frame, thresh, 253, 255, 3);
        
                        // detect!
        //blob_detector->detect(thresh, keypoints);
        global_frame = thresh(rect);
        if(prev_frame.empty()){
            prev_frame = global_frame;
        }
        
        if(currentState == DetectingLight && stdDev != 0){
            Scalar brightness = mean(global_frame);
            Scalar prevbrightness = mean(prev_frame);
            if([self brightnessIsLow:brightness] && [self brightnessIsLow:prevbrightness]){
                currentState = ReadingBits;
            }
        }
        
        [self updateState];
        
        
        //drawKeypoints(thresh, keypoints, keyed,  Scalar::all(-1), DrawMatchesFlags::DRAW_RICH_KEYPOINTS);
        Scalar rectColor;
        if(currentState != ReadingBits && currentState != DetectingLight){
            rectColor = Scalar(0, 0, 255);
        } else if(stdDev != 0){
            rectColor = Scalar(0, 255, 255);
        } else {
            rectColor = Scalar(0, 255, 0);
        }
        
        
        rectangle(frame, rect, rectColor);
        imshow(windowName, frame);
        prev_frame = global_frame;
        if(cv::waitKey(30) >= 0) break;
    }
}

- (void)mouseUp:(NSEvent *)theEvent {
    NSLog(@"Mouse click detected!!!!");
    currentState = DetectingLight;
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
                                                       [self readImage];
                                                   });
    
    // Store it somewhere for later use.
    if (aTimer)
    {
        timer = aTimer;
    }
}

/*End Example code */

-(void) calculateStdDev {
    double diffTotal = 0;
    double diff = 0;
    for(int i; i < KEY_LENGTH; i++){
        diff = (stdDevVals[i] - maxMean);
        diffTotal += pow(diff, 2);
    }
    
    stdDev = sqrt(diffTotal/(maxMean * 1.0));
}



-(void) updateState {
    
    switch (currentState) {
        case WaitForStart:
        {
            break;
        }
            
        case DetectingLight:
        {
            if(meanCount >= MEAN_SAMPLES){
                maxMean = meanTotal / (MEAN_SAMPLES * 1.0);
                dispatch_queue_t backgroundQueue = dispatch_queue_create("calculate", NULL);
                dispatch_async(backgroundQueue, ^{
                    [self calculateStdDev];
                });
                
            } else {
                Scalar meanBrightness = mean(global_frame);
                meanTotal += meanBrightness[0];
                stdDevVals[meanCount] = meanBrightness[0];
                meanCount++;
            }
            break;
        }
            
        case ReadingBits:
        {
            if(!timer){
                MyCreateTimer(self);
            } else if (receiveCount == KEY_LENGTH){
                dispatch_source_cancel(timer);
                currentState = DisplayResult;
            }
            break;
        }
            
        case DisplayResult:
        {
            [self buildBitString];
            NSAlert* alert = [[NSAlert alloc] init];
            for (int i = 0; i < KEY_LENGTH; i++) {
                printf("%i", key[i]);
            }
            printf("\n");
            //[alert runModal];
            stdDev = 0;
            receiveCount = 0;
            meanCount = 0;
            maxMean = 0;
            meanTotal = 0;
            currentState = WaitForStart;
            timer = NULL;
            break;
        }
            
        default:{
            break;
        }
    }
    
}

-(void) buildBitString {
    NSMutableData* data = [NSMutableData data];
    char* total = (char*)malloc(sizeof(char));
    for(int i = 0; i < KEY_LENGTH/8; i++){
        for(int j = 0; j < 8; j++){
            total[j] = key[(i*8)+j];
        }
        [data appendBytes:total length:1];
    }
    
    self.keyString = [data base64EncodedStringWithOptions:NSDataBase64DecodingIgnoreUnknownCharacters];
    free(total);
}

-(BOOL) brightnessIsLow:(Scalar)brightness {
    return (brightness[0] < maxMean - (stdDev * 4));
}

-(void) readImage {
    Scalar meanBrightness = mean(global_frame);
    if([self brightnessIsLow:meanBrightness]){
        key[receiveCount] = 0;
    } else {
        key[receiveCount] = 1;
    }
    
    receiveCount++;
    
}



@end
