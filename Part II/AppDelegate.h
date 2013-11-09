//
//  AppDelegate.h
//  Part II
//
//  Created by Joshua Barrow on 11/7/13.
//  Copyright (c) 2013 Jukaela Enterprises. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class OpenDatabaseWindowController, MainWindowController;

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (strong, nonatomic) MainWindowController *mainWindowController;
@property (strong, nonatomic) OpenDatabaseWindowController *openDatabaseWindowController;

@end
