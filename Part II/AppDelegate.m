//
//  AppDelegate.m
//  Part II
//
//  Created by Joshua Barrow on 11/7/13.
//  Copyright (c) 2013 Jukaela Enterprises. All rights reserved.
//

#import "AppDelegate.h"
#import "OpenDatabaseWindowController.h"
#import "MainWindowController.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self setOpenDatabaseWindowController:[[OpenDatabaseWindowController alloc] initWithWindowNibName:@"OpenDatabase"]];
    
    [[self openDatabaseWindowController] showWindow:self];
}

@end
