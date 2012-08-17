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

#import "CDVURLProtocol.h"
#import "CDVWhitelist.h"
#import "CDVViewController.h"

static CDVWhitelist* gWhitelist = nil;
// Contains a set of NSNumbers of addresses of controllers. It doesn't store
// the actual pointer to avoid retaining.
static NSMutableSet* gRegisteredControllers = nil;

@implementation CDVURLProtocol

+ (void) registerPGHttpURLProtocol {
}

+ (void) registerURLProtocol {
}

// Called to register the URLProtocol, and to make it away of an instance of
// a ViewController.
+ (void)registerViewController:(CDVViewController*)viewController {
    if (gRegisteredControllers == nil) {
        [NSURLProtocol registerClass:[CDVURLProtocol class]];
        gRegisteredControllers = [[NSMutableSet alloc] initWithCapacity:8];
        // The whitelist doesn't change, so grab the first one and store it.
        gWhitelist = viewController.whitelist;
    }
    @synchronized (gRegisteredControllers) {
        [gRegisteredControllers addObject:[NSNumber numberWithLongLong:(long long)viewController]];
    }
}

+ (void)unregisterViewController:(CDVViewController*)viewController {
    [gRegisteredControllers removeObject:viewController];
}


+ (BOOL) canInitWithRequest:(NSURLRequest *)theRequest
{
    NSURL* theUrl = [theRequest URL];
    NSString* theScheme = [theUrl scheme];
    
    if ([[theUrl path] isEqualToString:@"/!gap_exec"]) {
        NSString* viewControllerAddressStr = [theRequest valueForHTTPHeaderField:@"vc"];
        if (viewControllerAddressStr == nil) {
            NSLog(@"!cordova request missing vc header");
            return NO;
        }
        long long viewControllerAddress = [viewControllerAddressStr longLongValue];
        // Ensure that the CDVViewController has not been dealloc'ed.
        @synchronized (gRegisteredControllers) {
            if (![gRegisteredControllers containsObject:[NSNumber numberWithLongLong:viewControllerAddress]]) {
                return NO;
            }
            CDVViewController* viewController = (__bridge CDVViewController*)(void *)viewControllerAddress;
            
            NSString* queuedCommandsJSON = [theRequest valueForHTTPHeaderField:@"cmds"];
            if ([queuedCommandsJSON length] > 0) {
                [viewController performSelectorOnMainThread:@selector(executeCommandsFromJson:) withObject:queuedCommandsJSON waitUntilDone:NO];
            } else {
                [viewController performSelectorOnMainThread:@selector(flushCommandQueue) withObject:nil waitUntilDone:NO];
            }
        }
        return NO;
	}
    
    
    // we only care about http and https connections
	if ([gWhitelist schemeIsAllowed:theScheme])
    {
        // if it FAILS the whitelist, we return TRUE, so we can fail the connection later
        return ![gWhitelist URLIsAllowed:theUrl];
    }
    
    return NO;
}

+ (NSURLRequest*) canonicalRequestForRequest:(NSURLRequest*) request 
{
    //NSLog(@"%@ received %@", self, NSStringFromSelector(_cmd));
    return request;
}

- (void) startLoading
{    
    //NSLog(@"%@ received %@ - start", self, NSStringFromSelector(_cmd));
    NSURL* url = [[self request] URL];
    NSString* body = [gWhitelist errorStringForURL:url];

    CDVHTTPURLResponse* response = [[CDVHTTPURLResponse alloc] initWithUnauthorizedURL:url];
    
    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    
    [[self client] URLProtocol:self didLoadData:[body dataUsingEncoding:NSASCIIStringEncoding]];

    [[self client] URLProtocolDidFinishLoading:self];                

}

- (void) stopLoading
{
    // do any cleanup here
}

+ (BOOL) requestIsCacheEquivalent: (NSURLRequest*)requestA toRequest: (NSURLRequest*)requestB 
{
    return NO;
}

@end



@implementation CDVHTTPURLResponse

- (id) initWithUnauthorizedURL:(__unsafe_unretained NSURL*)url
{
    NSInteger statusCode = 401;
    NSDictionary* __unsafe_unretained headerFields = [NSDictionary dictionaryWithObject:@"Digest realm = \"Cordova.plist/ExternalHosts\"" forKey:@"WWW-Authenticate"];
    double requestTime = 1;
    
    SEL selector = NSSelectorFromString(@"initWithURL:statusCode:headerFields:requestTime:");
    NSMethodSignature* signature = [self methodSignatureForSelector:selector];
    
    NSInvocation* inv = [NSInvocation invocationWithMethodSignature:signature];
    [inv setTarget:self];
    [inv setSelector:selector];
    [inv setArgument:&url atIndex:2];
    [inv setArgument:&statusCode atIndex:3];
    [inv setArgument:&headerFields atIndex:4];
    [inv setArgument:&requestTime atIndex:5];
    
    [inv invoke];
    
    return self;
}

@end