//
//  AppDelegate.m
//  Part II
//
//  Created by Joshua Barrow on 11/7/13.
//  Copyright (c) 2013 Jukaela Enterprises. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self setMainWindowController:[[MainWindowController alloc] initWithWindowNibName:@"MainWindow"]];
    
    [[self mainWindowController] showWindow:self];
}

@end
