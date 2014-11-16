//
//  AppDelegate.h
//  CS55-Desktop
//
//  Created by Dan Whitcomb on 10/21/14.
//  Copyright (c) 2014 Dan Whitcomb. All rights reserved.
//

#include <opencv2/highgui/highgui_c.h>
#include <opencv2/objdetect/objdetect.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/features2d/features2d.hpp>

#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>
#import <QTKit/QTKit.h>


@interface AppDelegate : NSObject <NSApplicationDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>


@end

