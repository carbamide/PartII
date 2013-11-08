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

@interface MainWindowController ()
{
    sqlite3 *_database;
}

@property (strong, nonatomic) NSArray *tablesListArray;
@property (strong, nonatomic) NSArray *tableColumnsArray;
@property (strong, nonatomic) NSArray *tableColumnTypeArray;
@property (strong, nonatomic) NSString *currentTable;
@property (strong, nonatomic) NSMutableArray *tableDataArray;
@property (strong, nonatomic) NSMutableArray *sqlDataArray;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) NoodleLineNumberView	*lineNumberView;

@end

@implementation MainWindowController

#pragma mark -
#pragma mark Window Lifecycle

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    [[self logTextView] setAutomaticTextReplacementEnabled:NO];
    [[self logTextView] setAutomaticSpellingCorrectionEnabled:NO];
    [[self logTextView] setContinuousSpellCheckingEnabled:NO];
    [[self logTextView] setFont:[NSFont fontWithName:@"Andale Mono" size:14]];
    
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
    
    [[self rawSqlTextView] setFont:[NSFont fontWithName:@"Andale Mono" size:14]];
}

#pragma mark -
#pragma mark Methods

-(void)appendTextToLog:(NSString *)text color:(NSColor *)color
{
    if (!text) {
        text = @"ERROR";
    }
    
    if (!color) {
        color = [NSColor blackColor];
    }
    NSDate *now = [NSDate date];
    
    text = [[[self dateFormatter] stringFromDate:now] stringByAppendingString:[NSString stringWithFormat:@" %@", text]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:[text stringByAppendingString:@"\n"]];
        
        [attributedString addAttribute:NSFontAttributeName value:[NSFont fontWithName:@"Andale Mono" size:14] range:NSMakeRange(0, [text length])];
        
        if (color) {
            [attributedString addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, [text length])];
        }
        
        NSString *pattern = @"select|from|where|pragma";
        NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
        NSRange range = NSMakeRange(0, [text length]);
        
        [expression enumerateMatchesInString:text options:0 range:range usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
            NSRange range = [result rangeAtIndex:0];
            [attributedString addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:range];
        }];
        
        pattern = [[[self tablesListArray] componentsJoinedByString:@"|"] stringByAppendingString:@"|sqlite_master"];
        expression = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
        range = NSMakeRange(0, [text length]);
        
        [expression enumerateMatchesInString:text options:0 range:range usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
            NSRange range = [result rangeAtIndex:0];
            [attributedString addAttribute:NSForegroundColorAttributeName value:[NSColor orangeColor] range:range];
        }];
        
        pattern = @"'(.*)'";
        expression = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
        range = NSMakeRange(0, [text length]);
        
        [expression enumerateMatchesInString:text options:0 range:range usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
            NSRange range = [result rangeAtIndex:0];
            [attributedString addAttribute:NSForegroundColorAttributeName value:[NSColor redColor] range:range];
        }];
        
        pattern = @"(1[012]|[1-9]):[0-5][0-9]:[0-5][0-9](\\s)?(?i)(am|pm)";
        expression = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
        range = NSMakeRange(0, [text length]);
        
        [expression enumerateMatchesInString:text options:0 range:range usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
            NSRange range = [result rangeAtIndex:0];
            [attributedString addAttribute:NSForegroundColorAttributeName value:[NSColor darkGrayColor] range:range];
            [attributedString addAttribute:NSBackgroundColorAttributeName value:[NSColor colorWithCalibratedWhite: 0.85 alpha: 1.0] range:range];
        }];
        
        [[[self logTextView] textStorage] appendAttributedString:attributedString];
        [[self logTextView] scrollRangeToVisible:NSMakeRange([[[self logTextView] string] length], 0)];
    });
}

#pragma mark -
#pragma mark IBActions

-(IBAction)import:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    
    if ([openPanel runModal] == NSOKButton) {
        NSURL *selectedFilePath = [openPanel URL];
        
        if (sqlite3_open([[selectedFilePath path] UTF8String], &_database) != SQLITE_OK) {
            NSAlert *errorAlert = [NSAlert alertWithMessageText:@"Error"
                                                  defaultButton:@"OK"
                                                alternateButton:nil
                                                    otherButton:nil
                                      informativeTextWithFormat:@"Unable to open the database.  Sorry!"];
            
            [errorAlert runModal];
            
            return;
        }
        
        [self setTablesListArray:[self fetchTableNames]];
        
        [[self tableListSourceView] reloadData];
    }
}

-(IBAction)export:(id)sender
{
    NSAlert *errorAlert = [NSAlert alertWithMessageText:@"Not Implemented"
                                          defaultButton:@"OK"
                                        alternateButton:nil
                                            otherButton:nil
                              informativeTextWithFormat:@"This function is not yet implemented."];
    
    [errorAlert runModal];
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
    
    [self performSqlQuery:[[self rawSqlTextView] string]];
}

#pragma mark -
#pragma mark Database Helper Methods

-(NSMutableArray *)fetchTableNames
{
    sqlite3_stmt* statement;
    
    NSString *sql = @"SELECT name FROM sqlite_master WHERE type='table';";
    
    [self appendTextToLog:sql color:nil];
    
    int retVal = sqlite3_prepare_v2(_database,
                                    [sql UTF8String],
                                    -1,
                                    &statement,
                                    NULL);
    
    NSMutableArray *selectedRecords = [NSMutableArray array];
    
    if (retVal == SQLITE_OK) {
        while(sqlite3_step(statement) == SQLITE_ROW) {
            NSString *value = [NSString stringWithCString:(const char *)sqlite3_column_text(statement, 0) encoding:NSUTF8StringEncoding];
            [selectedRecords addObject:value];
        }
    }
    
    sqlite3_clear_bindings(statement);
    sqlite3_finalize(statement);
    
    return selectedRecords;
}

-(void)selectAllFromTable:(NSString *)table
{
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@;", table];
    
    [self appendTextToLog:sql color:nil];

    sqlite3_stmt *statement;
    
    NSMutableArray *finalArray = [NSMutableArray array];
    
    if (sqlite3_prepare_v2(_database, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
        int columnCount = sqlite3_column_count(statement);
        
        while(sqlite3_step(statement) == SQLITE_ROW) {
            NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
            
            for (int index = 0; index <= columnCount; index++) {
                char *text = (char *)sqlite3_column_text(statement, index);
                
                if (text != NULL) {
                    [dictionary addEntriesFromDictionary:@{[NSNumber numberWithInt:index]: [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, index)]}];
                }
                else {
                    [dictionary addEntriesFromDictionary:@{[NSNumber numberWithInt:index]: @"NULL"}];
                }
            }
            
            [finalArray addObject:dictionary];
        }
    }
    
    [self setTableDataArray:finalArray];
}

-(void)performSqlQuery:(NSString *)sql
{
    [self appendTextToLog:sql color:nil];
    
    sqlite3_stmt *statement;
    
    NSMutableArray *finalArray = [NSMutableArray array];
    
    NSString *tableName = nil;
    
    if (sqlite3_prepare_v2(_database, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
        int columnCount = sqlite3_column_count(statement);
        
        tableName = [NSString stringWithUTF8String:(char *)sqlite3_column_table_name(statement, 0)];
        
        while(sqlite3_step(statement) == SQLITE_ROW) {
            NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
            
            for (int index = 0; index <= columnCount; index++) {
                char *text = (char *)sqlite3_column_text(statement, index);
                

                
                if (text != NULL) {
                    [dictionary addEntriesFromDictionary:@{[NSNumber numberWithInt:index]: [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, index)]}];
                }
                else {
                    [dictionary addEntriesFromDictionary:@{[NSNumber numberWithInt:index]: @"NULL"}];
                }
            }
            
            [finalArray addObject:dictionary];
        }
    }
    
    sqlite3_stmt *sqlStatement;
    
    NSMutableArray *result = [NSMutableArray array];
    
    sql = [NSString stringWithFormat:@"PRAGMA table_info('%@');", tableName];
    
    [self appendTextToLog:sql color:nil];
    
    if(sqlite3_prepare(_database, [sql UTF8String], -1, &sqlStatement, NULL) != SQLITE_OK) {
        NSLog(@"Problem with prepare statement tableInfo %@", [NSString stringWithUTF8String:(const char *)sqlite3_errmsg(_database)]);
    }
    
    while (sqlite3_step(sqlStatement) == SQLITE_ROW) {
        [result addObject:[NSString stringWithUTF8String:(char *)sqlite3_column_text(sqlStatement, 1)]];
    }
    
    NSTableColumn *column[[result count]];
    
    for (int i = 0; i < [result count]; i++){
        column[i] = [[NSTableColumn alloc] initWithIdentifier:[NSString stringWithFormat:@"%i", i]];
        [column[i] setWidth:100];
        [[column[i] headerCell] setStringValue:result[i]];
        [[self sqlQueryTableView] addTableColumn:column[i]];
    }
    
    [self setSqlDataArray:finalArray];
    
    [[self sqlQueryTableView] reloadData];
}

-(NSArray *)tableInfo:(NSString *)table
{
    sqlite3_stmt *sqlStatement;
    
    NSMutableArray *result = [NSMutableArray array];
    NSMutableArray *typeResultSet = [NSMutableArray array];
    
    NSString *sql = [NSString stringWithFormat:@"PRAGMA table_info('%@');", table];
    
    [self appendTextToLog:sql color:nil];
    
    if(sqlite3_prepare(_database, [sql UTF8String], -1, &sqlStatement, NULL) != SQLITE_OK) {
        NSLog(@"Problem with prepare statement tableInfo %@", [NSString stringWithUTF8String:(const char *)sqlite3_errmsg(_database)]);
    }
    
    while (sqlite3_step(sqlStatement) == SQLITE_ROW) {
        [result addObject:[NSString stringWithUTF8String:(char *)sqlite3_column_text(sqlStatement, 1)]];
        [typeResultSet addObject:[NSString stringWithUTF8String:(char *)sqlite3_column_text(sqlStatement, 2)]];
    }
    
    NSTableColumn *column[[result count]];
    
    for (int i = 0; i < [result count]; i++){
        column[i] = [[NSTableColumn alloc] initWithIdentifier:[NSString stringWithFormat:@"%i", i]];
        [column[i] setWidth:100];
        [[column[i] headerCell] setStringValue:result[i]];
        [[self dataTableView] addTableColumn:column[i]];
    }
    
    return @[result, typeResultSet];
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
        
        [self selectAllFromTable:[self currentTable]];
        [[self dataTableView] reloadData];
        
        [self setTableColumnsArray:[self tableInfo:selectedItem][0]];
        [self setTableColumnTypeArray:[self tableInfo:selectedItem][1]];
        
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
