//
//  MainWindowController.h
//  Part II
//
//  Created by Joshua Barrow on 11/7/13.
//  Copyright (c) 2013 Jukaela Enterprises. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MainWindowController : NSWindowController <NSOutlineViewDelegate, NSOutlineViewDataSource, NSTableViewDelegate, NSTableViewDataSource, NSTextDelegate>

@property (strong) IBOutlet NSOutlineView *tableListSourceView;
@property (strong) IBOutlet NSSegmentedControl *viewSelectorSegmentedControl;
@property (strong) IBOutlet NSTableView *schemaTableView;
@property (strong) IBOutlet NSTableView *dataTableView;
@property (strong) IBOutlet NSTextView *rawSqlTextView;
@property (strong) IBOutlet NSTextView *schemaTextView;

@property (strong) IBOutlet NSTableView *sqlQueryTableView;
@property (strong) IBOutlet NSButton *sqlQueryButton;
@property (strong) IBOutlet NSTextView *logTextView;
@property (strong) IBOutlet NSTabView *mainTabView;
@property (strong) IBOutlet NSMenu *tableMenu;


-(id)initWithWindowNibName:(NSString *)windowNibName databaseURL:(NSURL *)dbURL;;

-(IBAction)import:(id)sender;
-(IBAction)export:(id)sender;
-(IBAction)clearLog:(id)sender;
-(IBAction)performQuery:(id)sender;
-(IBAction)actionSegmentedControlAction:(id)sender;
-(IBAction)rename:(id)sender;
-(IBAction)alter:(id)sender;
-(IBAction)drop:(id)sender;
@end
