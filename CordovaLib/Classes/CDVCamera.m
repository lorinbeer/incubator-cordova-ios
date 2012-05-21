/*
 Licensed to the Apache Software Foundation (ASF) under one
 or more contributor license agreements.  See the NOTICE file
 distributed with this work for additional information
 regarding copyright ownership.  The ASF licenses this file
 to you under the Apache License, Version 2.0 (the
 "License"); you may not use this file except in compliance
 with the License.  You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing,
 software distributed under the License is distributed on an
 "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 KIND, either express or implied.  See the License for the
 specific language governing permissions and limitations
 under the License.
 */

#import "CDVCamera.h"
#import "NSData+Base64.h"
#import "NSDictionary+Extensions.h"
#import <MobileCoreServices/UTCoreTypes.h>


@interface CDVCamera ()

@property (readwrite, assign) BOOL hasPendingOperation;

@end

@implementation CDVCamera

@synthesize hasPendingOperation, pickerController;

- (BOOL) popoverSupported
{
	return ( NSClassFromString(@"UIPopoverController") != nil) && 
	(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
}

/*  takePicture arguments:
 * INDEX   ARGUMENT
 *  0       callbackId
 *  1       quality
 *  2       destination type
 *  3       source type
 *  4       targetWidth
 *  5       targetHeight
 *  6       encodingType
 *  7       mediaType
 *  8       allowsEdit
 *  9       correctOrientation
 *  10      saveToPhotoAlbum
 */
- (void) takePicture:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options
{
	NSString* callbackId = [arguments objectAtIndex:0];
    self.hasPendingOperation = NO;

	NSString* sourceTypeString = [arguments objectAtIndex:3];
	UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypeCamera; // default
	if (sourceTypeString != nil) 
	{
		sourceType = (UIImagePickerControllerSourceType)[sourceTypeString intValue];
	}

	bool hasCamera = [UIImagePickerController isSourceTypeAvailable:sourceType];
	if (!hasCamera) {
		NSLog(@"Camera.getPicture: source type %d not available.", sourceType);
		CDVPluginResult* result = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK messageAsString: @"no camera available"];
        [self writeJavascript:[result toErrorCallbackString:callbackId]];
        return;
        
	} 

    bool allowEdit = [[arguments objectAtIndex:8] boolValue];
    NSNumber* targetWidth = [arguments objectAtIndex:4];
    NSNumber* targetHeight = [arguments objectAtIndex:5];
    NSNumber* mediaValue = [arguments objectAtIndex:7];
    CDVMediaType mediaType = (mediaValue) ? [mediaValue intValue] : MediaTypePicture;
    
    CGSize targetSize = CGSizeMake(0, 0);
    if (targetWidth != nil && targetHeight != nil) {
        targetSize = CGSizeMake([targetWidth floatValue], [targetHeight floatValue]);
    }
    
    CDVCameraPicker* cameraPicker = [[CDVCameraPicker alloc] init];
    self.pickerController = cameraPicker;
    
    cameraPicker.delegate = self;
    cameraPicker.sourceType = sourceType;
    cameraPicker.allowsEditing = allowEdit; // THIS IS ALL IT TAKES FOR CROPPING - jm
    cameraPicker.callbackId = callbackId;
    cameraPicker.targetSize = targetSize;
    cameraPicker.cropToSize = NO;
    // we need to capture this state for memory warnings that dealloc this object
    cameraPicker.webView = self.webView;
    cameraPicker.popoverSupported = [self popoverSupported];
    
    cameraPicker.correctOrientation = [[arguments objectAtIndex:9] boolValue];
    cameraPicker.saveToPhotoAlbum = [[arguments objectAtIndex:10] boolValue];
    
    cameraPicker.encodingType = ([arguments objectAtIndex:6]) ? [[arguments objectAtIndex:6] intValue] : EncodingTypeJPEG;
    
    cameraPicker.quality = ([arguments objectAtIndex:1]) ? [[arguments objectAtIndex:1] intValue] : 50;
    cameraPicker.returnType = ([arguments objectAtIndex:2]) ? [[arguments objectAtIndex:2] intValue] : DestinationTypeFileUri;
   
    if (sourceType == UIImagePickerControllerSourceTypeCamera) {
        // we only allow taking pictures (no video) in this api
        cameraPicker.mediaTypes = [NSArray arrayWithObjects: (NSString*) kUTTypeImage, nil];
    } else if (mediaType == MediaTypeAll) {
        cameraPicker.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType: sourceType];
    } else {
        NSArray* mediaArray = [NSArray arrayWithObjects: (NSString*) (mediaType == MediaTypeVideo ? kUTTypeMovie : kUTTypeImage), nil];
        cameraPicker.mediaTypes = mediaArray;
    }
    
    if ([self popoverSupported] && sourceType != UIImagePickerControllerSourceTypeCamera)
    {
        if (cameraPicker.popoverController == nil) 
        { 
            cameraPicker.popoverController = [[[NSClassFromString(@"UIPopoverController") alloc] 
                                                       initWithContentViewController:cameraPicker] autorelease]; 
        } 
        cameraPicker.popoverController.delegate = self;
        [cameraPicker.popoverController presentPopoverFromRect:CGRectMake(0,32,320,480)
                                                                  inView:[self.webView superview]
                                                permittedArrowDirections:UIPopoverArrowDirectionAny 
                                                                animated:YES]; 
    }
    else 
    { 
        
        if ([self.viewController respondsToSelector:@selector(presentViewController:::)]) {
            [self.viewController presentViewController:cameraPicker animated:YES completion:nil];        
        } else {
            [self.viewController presentModalViewController:cameraPicker animated:YES ];
        }              
    }
    self.hasPendingOperation = YES;
    [cameraPicker release];
}


- (void) popoverControllerDidDismissPopover:(id)popoverController
{
    //[ self imagePickerControllerDidCancel:self.pickerController ];	'
    UIPopoverController* pc = (UIPopoverController*)popoverController;
    [pc dismissPopoverAnimated:YES]; 
    pc.delegate = nil;
    if (self.pickerController && self.pickerController.callbackId && self.pickerController.popoverController) {
        self.pickerController.popoverController = nil;
        NSString* callbackId = self.pickerController.callbackId;
        CDVPluginResult* result = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK messageAsString: @"no image selected"]; // error callback expects string ATM
        // this "delay hack" is in case the callback contains a JavaScript alert. Without this delay or a
        // setTimeout("alert('fail');", 0) on the JS side, the app will hang when the alert is displayed.
        [self.webView performSelector:@selector(stringByEvaluatingJavaScriptFromString:) withObject:[result toErrorCallbackString: callbackId] afterDelay:0.5];
    } 
    self.hasPendingOperation = NO;
}

- (void)imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary*)info
{
    CDVCameraPicker* cameraPicker = (CDVCameraPicker*)picker;

	NSString* callbackId =  cameraPicker.callbackId;
	
	if(cameraPicker.popoverSupported && cameraPicker.popoverController != nil)
	{
		[cameraPicker.popoverController dismissPopoverAnimated:YES]; 
		cameraPicker.popoverController.delegate = nil;
		cameraPicker.popoverController = nil;
	}
	else 
	{
        if ([cameraPicker respondsToSelector:@selector(presentingViewController)]) { 
            [[cameraPicker presentingViewController] dismissModalViewControllerAnimated:YES];
        } else {
            [[cameraPicker parentViewController] dismissModalViewControllerAnimated:YES];
        }        
	}
     
	NSString* jsString = nil;
    CDVPluginResult* result = nil;
    
	NSString* mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    // IMAGE TYPE
	if ([mediaType isEqualToString:(NSString*)kUTTypeImage])
	{
		// get the image
		UIImage* image = nil;
		if (cameraPicker.allowsEditing && [info objectForKey:UIImagePickerControllerEditedImage]){
			image = [info objectForKey:UIImagePickerControllerEditedImage];
		} else {
			image = [info objectForKey:UIImagePickerControllerOriginalImage];
		}
        
        if (cameraPicker.saveToPhotoAlbum) {
          UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
        }
        
        if (cameraPicker.correctOrientation) {
          image = [self imageCorrectedForCaptureOrientation:image];
        }
    
        UIImage *scaledImage = nil;
        
        if (cameraPicker.targetSize.width > 0 && cameraPicker.targetSize.height > 0) {
            // if cropToSize, resize image and crop to target size, otherwise resize to fit target without cropping
            if(cameraPicker.cropToSize) {
                scaledImage = [self imageByScalingAndCroppingForSize:image toSize:cameraPicker.targetSize];
            } else {
                scaledImage = [self imageByScalingNotCroppingForSize:image toSize:cameraPicker.targetSize];
            }
        }
            
        NSData* data = nil;

        if (cameraPicker.encodingType == EncodingTypePNG) {
            data = UIImagePNGRepresentation(scaledImage == nil ? image : scaledImage);
        }
        else {
            data = UIImageJPEGRepresentation(scaledImage == nil ? image : scaledImage, cameraPicker.quality / 100.0f);
        }
            
        if (cameraPicker.returnType == DestinationTypeFileUri) {
        
            // write to temp directory and reutrn URI
            // get the temp directory path
            NSString* docsPath = [NSTemporaryDirectory() stringByStandardizingPath];
            NSError* err = nil;
            NSFileManager* fileMgr = [[NSFileManager alloc] init]; //recommended by apple (vs [NSFileManager defaultManager]) to be theadsafe
            
            // generate unique file name
            NSString* filePath;
            
            int i = 1;
            do 
            {
                filePath = [NSString stringWithFormat:@"%@/photo_%03d.%@", docsPath, i++, cameraPicker.encodingType == EncodingTypePNG ? @"png" : @"jpg"];
            } 
            while ([fileMgr fileExistsAtPath: filePath]);
            
            // save file
            if (![data writeToFile: filePath options: NSAtomicWrite error: &err]) {
                result = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK messageAsString: [err localizedDescription]];
                jsString = [result toErrorCallbackString:callbackId];
            } else {
                result = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK messageAsString: [[NSURL fileURLWithPath: filePath] absoluteString]];
                jsString = [result toSuccessCallbackString:callbackId];
            }
            [fileMgr release];
        
        } else {
            result = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK messageAsString: [data base64EncodedString]];
            jsString = [result toSuccessCallbackString:callbackId];
        }
	} 
    // NOT IMAGE TYPE (MOVIE)
    else 
    {
         NSString *moviePath = [[info objectForKey: UIImagePickerControllerMediaURL] absoluteString];
        result = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK messageAsString: moviePath];
        jsString = [result toSuccessCallbackString:callbackId];
    }

    
    if (jsString) {
        [self.webView stringByEvaluatingJavaScriptFromString:jsString];
    }

        self.hasPendingOperation = NO;
}

// older api calls newer didFinishPickingMediaWithInfo
- (void) imagePickerController:(UIImagePickerController*)picker didFinishPickingImage:(UIImage*)image editingInfo:(NSDictionary*)editingInfo
{
	NSDictionary* imageInfo = [NSDictionary dictionaryWithObject:image forKey:UIImagePickerControllerOriginalImage];
	[self imagePickerController:picker didFinishPickingMediaWithInfo: imageInfo];
}

- (void) closePicker:(CDVCameraPicker*)cameraPicker
{
    NSLog(@"closePicker is DEPRECATED and will be removed in 2.0!");
    if ([cameraPicker respondsToSelector:@selector(presentingViewController)]) { 
        [[cameraPicker presentingViewController] dismissModalViewControllerAnimated:YES];
    } else {
        [[cameraPicker parentViewController] dismissModalViewControllerAnimated:YES];
    }        
    
    if (cameraPicker.popoverSupported && cameraPicker.popoverController != nil)
    {
        cameraPicker.popoverController.delegate = nil;
        cameraPicker.popoverController = nil;
    }
}

- (void) imagePickerControllerDidCancel:(UIImagePickerController*)picker
{	
    CDVCameraPicker* cameraPicker = (CDVCameraPicker*)picker;
	NSString* callbackId = cameraPicker.callbackId;
    
    if ([cameraPicker respondsToSelector:@selector(presentingViewController)]) { 
        [[cameraPicker presentingViewController] dismissModalViewControllerAnimated:YES];
    } else {
        [[cameraPicker parentViewController] dismissModalViewControllerAnimated:YES];
    }        
    //popoverControllerDidDismissPopover:(id)popoverController is called if popover is cancelled
        
    CDVPluginResult* result = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK messageAsString: @"no image selected"]; // error callback expects string ATM
    [cameraPicker.webView stringByEvaluatingJavaScriptFromString:[result toErrorCallbackString: callbackId]];
    
    self.hasPendingOperation = NO;
}

- (UIImage*) imageByScalingAndCroppingForSize:(UIImage*)anImage toSize:(CGSize)targetSize
{
    UIImage *sourceImage = anImage;
    UIImage *newImage = nil;        
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
    
    if (CGSizeEqualToSize(imageSize, targetSize) == NO) 
    {
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        
        if (widthFactor > heightFactor) 
            scaleFactor = widthFactor; // scale to fit height
        else
            scaleFactor = heightFactor; // scale to fit width
        scaledWidth  = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        
        // center the image
        if (widthFactor > heightFactor)
        {
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5; 
        }
        else if (widthFactor < heightFactor)
        {
            thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
        }
    }       
    
    UIGraphicsBeginImageContext(targetSize); // this will crop
    
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width  = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    
    [sourceImage drawInRect:thumbnailRect];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    if(newImage == nil) {
        NSLog(@"could not scale image");
    }
    
    //pop the context to get back to the default
    UIGraphicsEndImageContext();
    return newImage;
}

- (UIImage*) imageCorrectedForCaptureOrientation:(UIImage*)anImage
{   
   float rotation_radians = 0;
   bool perpendicular = false;

   switch ([anImage imageOrientation]) {
    case UIImageOrientationUp:
      rotation_radians = 0.0;
      break;
    case UIImageOrientationDown:   
      rotation_radians = M_PI; //don't be scared of radians, if you're reading this, you're good at math
      break;
    case UIImageOrientationRight:
      rotation_radians = M_PI_2;
      perpendicular = true;
      break;
    case UIImageOrientationLeft:
      rotation_radians = -M_PI_2;
      perpendicular = true;
      break;
    default:
      break;
   }
   
   UIGraphicsBeginImageContext(CGSizeMake(anImage.size.width, anImage.size.height));
   CGContextRef context = UIGraphicsGetCurrentContext();
   
   //Rotate around the center point
   CGContextTranslateCTM(context, anImage.size.width/2, anImage.size.height/2);
   CGContextRotateCTM(context, rotation_radians);
   
   CGContextScaleCTM(context, 1.0, -1.0);
   float width = perpendicular ? anImage.size.height : anImage.size.width;
   float height = perpendicular ? anImage.size.width : anImage.size.height;
   CGContextDrawImage(context, CGRectMake(-width / 2, -height / 2, width, height), [anImage CGImage]);
   
   // Move the origin back since the rotation might've change it (if its 90 degrees)
   if (perpendicular) {
     CGContextTranslateCTM(context, -anImage.size.height/2, -anImage.size.width/2);
   }
   
   UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
   UIGraphicsEndImageContext();
   return newImage;
}

- (UIImage*) imageByScalingNotCroppingForSize:(UIImage*)anImage toSize:(CGSize)frameSize
{
    UIImage *sourceImage = anImage;
    UIImage *newImage = nil;        
    CGSize	imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = frameSize.width;
    CGFloat targetHeight = frameSize.height;
    CGFloat scaleFactor = 0.0;
    CGSize	scaledSize = frameSize;
    
    if (CGSizeEqualToSize(imageSize, frameSize) == NO) 
    {
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        
        // opposite comparison to imageByScalingAndCroppingForSize in order to contain the image within the given bounds
        if (widthFactor > heightFactor) {
            scaleFactor = heightFactor; // scale to fit height
        } else {
            scaleFactor = widthFactor; // scale to fit width
        }
        scaledSize = CGSizeMake(MIN(width * scaleFactor, targetWidth), MIN(height * scaleFactor, targetHeight));
    }
    
    UIGraphicsBeginImageContext(scaledSize); // this will resize
    
    [sourceImage drawInRect:CGRectMake(0, 0, scaledSize.width, scaledSize.height)];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    if(newImage == nil) {
        NSLog(@"could not scale image");
    }
    
    //pop the context to get back to the default
    UIGraphicsEndImageContext();
    return newImage;
}

- (void) postImage:(UIImage*)anImage withFilename:(NSString*)filename toUrl:(NSURL*)url 
{
    self.hasPendingOperation = YES;
    
	NSString *boundary = @"----BOUNDARY_IS_I";

	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
	[req setHTTPMethod:@"POST"];
	
	NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
	[req setValue:contentType forHTTPHeaderField:@"Content-type"];
	
	NSData *imageData = UIImagePNGRepresentation(anImage);
	
	// adding the body
	NSMutableData *postBody = [NSMutableData data];
	
	// first parameter an image
	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"upload\"; filename=\"%@\"\r\n", filename] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[@"Content-Type: image/png\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:imageData];
	
//	// second parameter information
//	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
//	[postBody appendData:[@"Content-Disposition: form-data; name=\"some_other_name\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
//	[postBody appendData:[@"some_other_value" dataUsingEncoding:NSUTF8StringEncoding]];
//	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r \n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	[req setHTTPBody:postBody];
	
	NSURLResponse* response;
	NSError* error;
	[NSURLConnection sendSynchronousRequest:req returningResponse:&response error:&error];

//  NSData* result = [NSURLConnection sendSynchronousRequest:req returningResponse:&response error:&error];
//	NSString * resultStr =  [[[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding] autorelease];
    
    self.hasPendingOperation = NO;
}


- (void) dealloc
{
	[super dealloc];
}

@end


@implementation CDVCameraPicker

@synthesize quality, postUrl;
@synthesize returnType;
@synthesize callbackId;
@synthesize popoverController;
@synthesize targetSize;
@synthesize correctOrientation;
@synthesize saveToPhotoAlbum;
@synthesize encodingType;
@synthesize cropToSize;
@synthesize webView;
@synthesize popoverSupported;

- (void) dealloc
{
	[super dealloc];
}

@end
