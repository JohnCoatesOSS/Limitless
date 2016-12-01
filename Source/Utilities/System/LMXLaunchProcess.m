//
//  LMXLaunchProcess.m
//  Limitless
//
//  Created by John Coates on 11/30/16.
//  Copyright © 2016 Limitless. All rights reserved.
//

#import "LMXLaunchProcess.h"
#import <NSTask.h>

@implementation LMXLaunchProcess

/// Synchronous launch
+ (NSString *)launchProcessAtPath:(NSString *)path {
    return [self launchProcessAtPath:path withArguments:nil];
}

/// Synchronous launch
+ (NSString *)launchProcessAtPath:(NSString *)path
                    withArguments:(NSString *)firstArgument, ... NS_REQUIRES_NIL_TERMINATION {
    NSMutableArray <NSString *> *arguments = nil;
    if (firstArgument) {
        arguments = [NSMutableArray array];
        va_list variableArguments;
        va_start(variableArguments, firstArgument);
        
        NSString *currentArgument = firstArgument;
        while (currentArgument) {
            [arguments addObject:currentArgument];
            currentArgument = va_arg(variableArguments, NSString *);
        }
        va_end(variableArguments);
    }
    
    return [self launchProcessAtPath:path outputHandle:nil withArgumentsList:arguments];
}
/// Synchronous launch
+ (NSString *)launchProcessAtPath:(NSString *)path
                     outputPath:(NSString *)outputPath
                    withArguments:(NSString *)firstArgument, ... NS_REQUIRES_NIL_TERMINATION {
    NSMutableArray <NSString *> *arguments = nil;
    if (firstArgument) {
        arguments = [NSMutableArray array];
        va_list variableArguments;
        va_start(variableArguments, firstArgument);
        
        NSString *currentArgument = firstArgument;
        while (currentArgument) {
            [arguments addObject:currentArgument];
            currentArgument = va_arg(variableArguments, NSString *);
        }
        va_end(variableArguments);
    }
    NSFileHandle *outputHandle = [NSFileHandle fileHandleForWritingAtPath:outputPath];
    if(outputHandle == nil) {
        [[NSFileManager defaultManager] createFileAtPath:outputPath
                                                contents:nil attributes:nil];
        outputHandle = [NSFileHandle fileHandleForWritingAtPath:outputPath];
    }
    
    if (outputHandle == nil) {
        NSLog(@"Error: Couldn't get output handle for %@", outputPath);
    }
    return [self launchProcessAtPath:path
                        outputHandle:outputHandle
                   withArgumentsList:arguments];
}

/// Synchronous launch
+ (NSString *)launchProcessAtPath:(NSString *)path
                    outputHandle:(NSFileHandle *)outputHandle
                    withArgumentsList:(NSArray <NSString *> *)argumentsList {
    
    NSTask *task = [NSTask new];
    task.launchPath = path;
    task.arguments = argumentsList;
    
    task.standardInput = [NSFileHandle fileHandleWithNullDevice];
    NSPipe *pipe = [NSPipe pipe];
    if (outputHandle) {
        task.standardOutput = pipe;
    } else {
        task.standardOutput = pipe;
    }
    task.standardError = pipe;
    
    NSLog(@"Running process %@ with arguments: %@", path, argumentsList);
    [task launch];
    
    NSFileHandle *pipeHandle = pipe.fileHandleForReading;
    NSData *outputData = [pipeHandle readDataToEndOfFile];
    NSString *output = [[[NSString alloc] initWithData:outputData
                                              encoding:NSUTF8StringEncoding] autorelease];
    return output;
}

@end
