//
//  MainWindowController.m
//  Part II
//
//  Created by Joshua Barrow on 11/7/13.
//  Copyright (c) 2013 Jukaela Enterprises. All rights reserved.
//

#import "MainWindowController.h"
#import <sqlite3.h>
#import "NoodleLineNumberView.h"
#import "AppDelegate.h"
#import "OpenDatabaseWindowController.h"
#import "SQLManager.h"

@interface MainWindowController ()

@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) NoodleLineNumberView	*lineNumberView;
@property (strong, nonatomic) NSURL *databaseURL;

@end

@implementation MainWindowController

@synthesize databaseURL = _databaseURL;

#pragma mark -
#pragma mark Window Lifecycle

- (id)initWithWindowNibName:(NSString *)windowNibName databaseURL:(NSURL *)dbURL;
{
    self = [super initWithWindowNibName:windowNibName];
    if (self) {
        _databaseURL = dbURL;
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    [[SQLManager sharedManager] setMainWindowController:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowWillClose:) name:NSWindowWillCloseNotification object:nil];
    
    [self openDatabase:[self databaseURL]];
    
    [[self logTextView] setAutomaticTextReplacementEnabled:NO];
    [[self logTextView] setAutomaticSpellingCorrectionEnabled:NO];
    [[self logTextView] setContinuousSpellCheckingEnabled:NO];
    [[self logTextView] setFont:[NSFont fontWithName:@"Andale Mono" size:14]];
    
    [[self rawSqlTextView] setAutomaticTextReplacementEnabled:NO];
    [[self rawSqlTextView] setAutomaticSpellingCorrectionEnabled:NO];
    [[self rawSqlTextView] setContinuousSpellCheckingEnabled:NO];
    [[self rawSqlTextView] setFont:[NSFont fontWithName:@"Andale Mono" size:14]];
    
    [[self schemaTextView] setAutomaticTextReplacementEnabled:NO];
    [[self schemaTextView] setAutomaticSpellingCorrectionEnabled:NO];
    [[self schemaTextView] setContinuousSpellCheckingEnabled:NO];
    [[self schemaTextView] setFont:[NSFont fontWithName:@"Andale Mono" size:14]];
    
    [[self logTextView] setTextContainerInset:NSMakeSize(-5, 0)];
    
    _lineNumberView = [[NoodleLineNumberView alloc] initWithScrollView:[[self logTextView] enclosingScrollView]];
    [[[self logTextView] enclosingScrollView] setVerticalRulerView:_lineNumberView];
    [[[self logTextView] enclosingScrollView] setHasHorizontalRuler:NO];
    [[[self logTextView] enclosingScrollView] setHasVerticalRuler:YES];
    [[[self logTextView] enclosingScrollView] setRulersVisible:YES];
    
    _lineNumberView = [[NoodleLineNumberView alloc] initWithScrollView:[[self rawSqlTextView] enclosingScrollView]];
    [[[self rawSqlTextView] enclosingScrollView] setVerticalRulerView:_lineNumberView];
    [[[self rawSqlTextView] enclosingScrollView] setHasHorizontalRuler:NO];
    [[[self rawSqlTextView] enclosingScrollView] setHasVerticalRuler:YES];
    [[[self rawSqlTextView] enclosingScrollView] setRulersVisible:YES];
    
    _lineNumberView = [[NoodleLineNumberView alloc] initWithScrollView:[[self schemaTextView] enclosingScrollView]];
    [[[self schemaTextView] enclosingScrollView] setVerticalRulerView:_lineNumberView];
    [[[self schemaTextView] enclosingScrollView] setHasHorizontalRuler:NO];
    [[[self schemaTextView] enclosingScrollView] setHasVerticalRuler:YES];
    [[[self schemaTextView] enclosingScrollView] setRulersVisible:YES];
}

-(void)windowWillClose:(NSNotification *)aNotification
{
    NSWindow *window = [aNotification object];
    
    if (window == [self window]) {
        AppDelegate *appDelegate = (AppDelegate *)[NSApp delegate];
        
        [[appDelegate openDatabaseWindowController] showWindow:self];
    }
}

#pragma mark -
#pragma mark Methods

-(void)appendTextToLog:(NSString *)text color:(NSColor *)color
{
    NSDate *now = [NSDate date];
    
    text = [[[self dateFormatter] stringFromDate:now] stringByAppendingString:[NSString stringWithFormat:@" %@", text]];
    
    NSMutableAttributedString *attributedString = [self colorizeText:text color:nil];
    
    NSString *pattern = @"(1[012]|[1-9]):[0-5][0-9]:[0-5][0-9](\\s)?(?i)(am|pm)";
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
    NSRange range = NSMakeRange(0, [text length]);
    
    [expression enumerateMatchesInString:text options:0 range:range usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        NSRange range = [result rangeAtIndex:0];
        [attributedString addAttribute:NSForegroundColorAttributeName value:[NSColor darkGrayColor] range:range];
        [attributedString addAttribute:NSBackgroundColorAttributeName value:[NSColor colorWithCalibratedWhite: 0.85 alpha: 1.0] range:range];
    }];
    
    [[[self logTextView] textStorage] appendAttributedString:attributedString];
    [[self logTextView] scrollRangeToVisible:NSMakeRange([[[self logTextView] string] length], 0)];
}

-(NSMutableAttributedString *)colorizeText:(NSString *)text color:(NSColor *)color
{
    if (!text) {
        text = @"ERROR";
    }
    
    if (!color) {
        color = [NSColor blackColor];
    }
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:[text stringByAppendingString:@"\n"]];
    
    [attributedString addAttribute:NSFontAttributeName value:[NSFont fontWithName:@"Andale Mono" size:14] range:NSMakeRange(0, [text length])];
    
    if (color) {
        [attributedString addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, [text length])];
    }
    
    NSString *pattern = [[[[SQLManager sharedManager] sqlKeywords] componentsJoinedByString:@"\\b|\\b"] stringByAppendingString:@"\\b"];
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
    NSRange range = NSMakeRange(0, [text length]);
    
    [expression enumerateMatchesInString:text options:0 range:range usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        NSRange range = [result rangeAtIndex:0];
        [attributedString addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:range];
    }];
    
    if ([self tablesListArray]) {
        pattern = [[[self tablesListArray] componentsJoinedByString:@"\\b|\\b"] stringByAppendingString:@"|sqlite_master\\b"];
        expression = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
        range = NSMakeRange(0, [text length]);
        
        [expression enumerateMatchesInString:text options:0 range:range usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
            NSRange range = [result rangeAtIndex:0];
            [attributedString addAttribute:NSForegroundColorAttributeName value:[NSColor orangeColor] range:range];
        }];
    }
    
    pattern = @"'(.*)'";
    expression = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
    range = NSMakeRange(0, [text length]);
    
    [expression enumerateMatchesInString:text options:0 range:range usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        NSRange range = [result rangeAtIndex:0];
        [attributedString addAttribute:NSForegroundColorAttributeName value:[NSColor redColor] range:range];
    }];
    
    return attributedString;
}

-(void)notImplemented
{
    NSAlert *errorAlert = [NSAlert alertWithMessageText:@"Not Implemented"
                                          defaultButton:@"OK"
                                        alternateButton:nil
                                            otherButton:nil
                              informativeTextWithFormat:@"This function is not yet implemented."];
    
    [errorAlert runModal];
}

-(void)openDatabase:(NSURL *)url
{
    [self setTablesListArray:nil];
    [self setTableColumnsArray:nil];
    [self setTableColumnTypeArray:nil];
    [self setCurrentTable:nil];
    [self setTableDataArray:nil];
    [self setSqlDataArray:nil];
    
    [[SQLManager sharedManager] setDatabaseURL:url];
    [[SQLManager sharedManager] openDatabase];
}

-(void)setDatabaseURL:(NSURL *)databaseURL
{
    _databaseURL = databaseURL;
    
    [self openDatabase:[self databaseURL]];
}

-(NSURL *)databaseURL
{
    return _databaseURL;
}

#pragma mark -
#pragma mark IBActions

-(IBAction)import:(id)sender
{
    [self notImplemented];
}

-(IBAction)export:(id)sender
{
    [self notImplemented];
}

-(IBAction)clearLog:(id)sender
{
    [[self logTextView] setString:@""];
}

-(IBAction)performQuery:(id)sender
{
    while([[[self sqlQueryTableView] tableColumns] count] > 0) {
        [[self sqlQueryTableView] removeTableColumn:[[[self sqlQueryTableView] tableColumns] lastObject]];
    }
    
    [self setSqlDataArray:[[[SQLManager sharedManager] performSqlQuery:[[self rawSqlTextView] string]] mutableCopy]];
    
    [[self sqlQueryTableView] reloadData];

}

-(IBAction)actionSegmentedControlAction:(id)sender
{
    NSSegmentedControl *control = sender;
    
    if ([control selectedSegment] == 0) {
        [self notImplemented];
    }
    else {
        [NSMenu popUpContextMenu:[self tableMenu] withEvent:nil forView:sender];
    }
}

-(IBAction)rename:(id)sender
{
    [self notImplemented];
}

-(IBAction)alter:(id)sender
{
    [self notImplemented];
}

-(IBAction)drop:(id)sender
{
    [self notImplemented];
}

#pragma mark -
#pragma mark NSOutlineView Delegate and Datasource

-(NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if (outlineView == [self tableListSourceView]) {
        return [[self tablesListArray] count];
    }
    
    return 0;
}

-(BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    if (outlineView == [self tableListSourceView]) {
        return NO;
    }
    
    return NO;
}

-(id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    if (outlineView == [self tableListSourceView]) {
        return item;
    }
    
    return nil;
}

-(id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    if (outlineView == [self tableListSourceView]) {
        return [self tablesListArray][index];
    }
    
    return nil;
}

-(void)outlineViewSelectionDidChange:(NSNotification *)notification
{
    NSOutlineView *outlineView = [notification object];
    
    while([[[self dataTableView] tableColumns] count] > 0) {
        [[self dataTableView] removeTableColumn:[[[self dataTableView] tableColumns] lastObject]];
    }
    
    if (outlineView == [self tableListSourceView]) {
        id selectedItem = [outlineView itemAtRow:[outlineView selectedRow]];
        
        [self setCurrentTable:selectedItem];
        
        [[self schemaTextView] setString:@""];
        
        [[[self schemaTextView] textStorage] appendAttributedString:[self colorizeText:[[SQLManager sharedManager] schemaForTable:[self currentTable]] color:nil]];

        [self setTableDataArray:[[[SQLManager sharedManager] selectAllFromTable:[self currentTable]] mutableCopy]];

        [[self dataTableView] reloadData];
        
        [self setTableColumnsArray:[[SQLManager sharedManager] tableInfo:selectedItem][0]];
        [self setTableColumnTypeArray:[[SQLManager sharedManager] tableInfo:selectedItem][1]];
        
        [[self schemaTableView] reloadData];
    }
}

#pragma mark -
#pragma mark NSTableView Delegate and Datasource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    if (aTableView == [self schemaTableView]) {
        return [[self tableColumnsArray] count];
    }
    else if (aTableView == [self dataTableView]) {
        return [[self tableDataArray] count];
    }
    else if (aTableView == [self sqlQueryTableView]) {
        return [[self sqlDataArray] count];
    }
    
    return 0;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    if (aTableView == [self schemaTableView]) {
        if ([[aTableColumn identifier] isEqualToString:@"columnName"]) {
            return [self tableColumnsArray][rowIndex];
        }
        else {
            return [self tableColumnTypeArray][rowIndex];
        }
        return nil;
    }
    else if (aTableView == [self dataTableView]) {
        NSDictionary *dict = [self tableDataArray][rowIndex];
        
        for (id key in dict) {
            NSString *obj = dict[key];
            
            NSString *identifer = [NSString stringWithFormat:@"%@", key];
            
            if ([identifer isEqualToString:[aTableColumn identifier]]) {
                return obj;
            }
        }
    }
    else if (aTableView == [self sqlQueryTableView]) {
        NSDictionary *dict = [self sqlDataArray][rowIndex];
        
        for (id key in dict) {
            NSString *obj = dict[key];
            
            NSString *identifer = [NSString stringWithFormat:@"%@", key];
            
            if ([identifer isEqualToString:[aTableColumn identifier]]) {
                return obj;
            }
        }
    }
    return nil;
}

#pragma mark -
#pragma mark NSTextDelegate

-(void)textDidChange:(NSNotification *)notification
{
    //    NSRange wordRange = [[[self rawSqlTextView] string] rangeOfString:@" " options:NSBackwardsSearch];
    //
    //    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] init];
    //    NSString *text = [[self rawSqlTextView] string];
    //
    //    NSString *pattern = @"select|from|where|pragma";
    //    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
    //    NSRange range = NSMakeRange(0, [text length]);
    //
    //    [expression enumerateMatchesInString:text options:0 range:range usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
    //        NSRange range = [result rangeAtIndex:0];
    //        [attributedString addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:range];
    //    }];
    //
    //    pattern = [[[self tablesListArray] componentsJoinedByString:@"|"] stringByAppendingString:@"|sqlite_master"];
    //    expression = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
    //    range = NSMakeRange(0, [text length]);
    //
    //    [expression enumerateMatchesInString:text options:0 range:range usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
    //        NSRange range = [result rangeAtIndex:0];
    //        [attributedString addAttribute:NSForegroundColorAttributeName value:[NSColor orangeColor] range:range];
    //    }];
    //
    //    pattern = @"'(.*)'";
    //    expression = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
    //    range = NSMakeRange(0, [text length]);
    //
    //    [expression enumerateMatchesInString:text options:0 range:range usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
    //        NSRange range = [result rangeAtIndex:0];
    //        [attributedString addAttribute:NSForegroundColorAttributeName value:[NSColor redColor] range:range];
    //    }];
    //
    //    if ([attributedString length] > 0) {
    //        [[[self rawSqlTextView] textStorage] replaceCharactersInRange:NSMakeRange(0, [text length]) withAttributedString:attributedString];
    //    }
    //
    //    [[[self rawSqlTextView] textStorage] replaceCharactersInRange:wordRange withAttributedString:attributedString];
}

@end
