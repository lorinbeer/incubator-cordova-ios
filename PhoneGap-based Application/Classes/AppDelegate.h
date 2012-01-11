//
//  AppDelegate.h
//  ___PROJECTNAME___
//
//  Created by ___FULLUSERNAME___ on ___DATE___.
//  Copyright ___ORGANIZATIONNAME___ ___YEAR___. All rights reserved.
//

#import <UIKit/UIKit.h>
#ifdef PHONEGAP_FRAMEWORK
	#import <PhoneGap/PhoneGapDelegate.h>
    #import <PhoneGap/PhoneGapViewController.h>
#else
	#import "PhoneGapDelegate.h"
    #import "PhoneGapViewController.h"
#endif

@interface AppDelegate : PhoneGapDelegate < PGCommandDelegate > {

	NSString* invokeString;
}

// invoke string is passed to your app on launch, this is only valid if you 
// edit ___PROJECTNAME___.plist to add a protocol
// a simple tutorial can be found here : 
// http://iphonedevelopertips.com/cocoa/launching-your-own-application-via-a-custom-url-scheme.html

@property (copy)  NSString* invokeString;

@end

