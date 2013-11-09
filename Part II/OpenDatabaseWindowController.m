//
//  OpenDatabaseWindowController.m
//  Part II
//
//  Created by Josh on 11/8/13.
//  Copyright (c) 2013 Jukaela Enterprises. All rights reserved.
//

#import "OpenDatabaseWindowController.h"
#import "AppDelegate.h"
#import "MainWindowController.h"

@interface OpenDatabaseWindowController ()

@end

@implementation OpenDatabaseWindowController

#pragma mark -
#pragma Window Lifecycle

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

#pragma mark -
#pragma IBActions

-(IBAction)newDatabase:(id)sender
{
    [self notImplemented];
}

-(IBAction)openDatabase:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    
    if ([openPanel runModal] == NSOKButton) {
        AppDelegate *appDelegate = (AppDelegate *)[NSApp delegate];
        
        [appDelegate setMainWindowController:[[MainWindowController alloc] initWithWindowNibName:@"MainWindow" databaseURL:[openPanel URL]]];
        [[appDelegate mainWindowController] showWindow:self];
        
        [[self window] close];
    }
}

-(IBAction)help:(id)sender
{
    [self notImplemented];
}

#pragma mark -
#pragma Methods

-(void)notImplemented
{
    NSAlert *errorAlert = [NSAlert alertWithMessageText:@"Not Implemented"
                                          defaultButton:@"OK"
                                        alternateButton:nil
                                            otherButton:nil
                              informativeTextWithFormat:@"This function is not yet implemented."];
    
    [errorAlert runModal];
}

@end
