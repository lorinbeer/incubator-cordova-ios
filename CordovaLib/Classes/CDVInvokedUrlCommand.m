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

#import "CDVInvokedUrlCommand.h"
#import "JSONKit.h"

@implementation CDVInvokedUrlCommand

@synthesize arguments = _arguments;
@synthesize callbackId = _callbackId;
@synthesize className = _className;
@synthesize methodName = _methodName;

+ (CDVInvokedUrlCommand*) commandFromJson:(NSArray*)jsonEntry
{
    return [[[CDVInvokedUrlCommand alloc] initFromJson:jsonEntry] autorelease];
}
              
- (id) initFromJson:(NSArray*)jsonEntry
{
    NSString* callbackId = [jsonEntry objectAtIndex:0];
    NSString* className = [jsonEntry objectAtIndex:1];
    NSString* methodName = [jsonEntry objectAtIndex:2];
    NSMutableArray* arguments = [jsonEntry objectAtIndex:3];
    
    return [self initWithArguments:arguments
                        callbackId:callbackId
                         className:className
                        methodName:methodName];
}

- (id) initWithArguments:(NSArray*)arguments
              callbackId:(NSString*)callbackId
               className:(NSString*)className
              methodName:(NSString*)methodName
{
    self = [super init];
    if (self != nil) {
        _arguments = [arguments retain];
        _callbackId = [callbackId retain];
        _className = [className retain];
        _methodName = [methodName retain];
    }
    return self;
}

- (void) legacyArguments:(NSMutableArray**)legacyArguments andDict:(NSMutableDictionary**)legacyDict {
    NSMutableArray* newArguments = [NSMutableArray arrayWithArray:_arguments];
    for (NSUInteger i = 0; i < [newArguments count]; ++i) {
        if ([[newArguments objectAtIndex:i] isKindOfClass:[NSDictionary class]]) {
            if (legacyDict != NULL) {
                *legacyDict = [newArguments objectAtIndex:i];
            }
            [newArguments removeObjectAtIndex:i];
            break;
        }
    }
    [newArguments insertObject:_callbackId atIndex:0];
    if (legacyArguments != NULL) {
        *legacyArguments = newArguments;
    }
}


- (void) dealloc
{
    [_arguments release];
    [_callbackId release];
    [_className release];
    [_methodName release];
    
    [super dealloc];
}

@end
