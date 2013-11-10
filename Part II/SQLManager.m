//
//  SQLHelpers.m
//  Part II
//
//  Created by Josh on 11/9/13.
//  Copyright (c) 2013 Jukaela Enterprises. All rights reserved.
//

#import "SQLManager.h"
#import <sqlite3.h>
#import "MainWindowController.h"

@interface SQLManager ()
{
    sqlite3 *_database;
}

@end
@implementation SQLManager

+(id)sharedManager
{
    static SQLManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    
    return sharedMyManager;
}

#pragma mark -
#pragma mark Database Helper Methods

-(NSMutableArray *)fetchTableNames
{
    sqlite3_stmt* statement;
    
    NSString *sql = @"SELECT name FROM sqlite_master WHERE type='table';";
    
    [[self mainWindowController] appendTextToLog:sql color:nil];
    
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

-(NSMutableArray *)selectAllFromTable:(NSString *)table
{
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@;", table];
    
    [[self mainWindowController] appendTextToLog:sql color:nil];
    
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
    
    return finalArray;
}

-(NSMutableArray *)performSqlQuery:(NSString *)sql
{
    [[self mainWindowController] appendTextToLog:sql color:nil];
    
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
    
    [[self mainWindowController] appendTextToLog:sql color:nil];
    
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
        [[[self mainWindowController] sqlQueryTableView] addTableColumn:column[i]];
    }
    
    return finalArray;
}

-(NSMutableArray *)tableInfo:(NSString *)table
{
    sqlite3_stmt *sqlStatement;
    
    NSMutableArray *result = [NSMutableArray array];
    NSMutableArray *typeResultSet = [NSMutableArray array];
    
    NSString *sql = [NSString stringWithFormat:@"PRAGMA table_info('%@');", table];
    
    [[self mainWindowController] appendTextToLog:sql color:nil];
    
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
        [[[self mainWindowController] dataTableView] addTableColumn:column[i]];
    }
    
    
    return @[result, typeResultSet];
}

-(NSString *)schemaForTable:(NSString *)tableName
{
    sqlite3_stmt *statement;
    
    NSString *result = nil;
    
    NSString *sql = [NSString stringWithFormat:@"SELECT sql from sqlite_master where tbl_name = '%@'", tableName];
    
    [[self mainWindowController] appendTextToLog:sql color:nil];
    
    if (sqlite3_prepare_v2(_database, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
        while(sqlite3_step(statement) == SQLITE_ROW) {
            char *text = (char *)sqlite3_column_text(statement, 0);
            
            result = [NSString stringWithUTF8String:text];
        }
    }
    
    return result;
}

-(void)openDatabase
{
    if (sqlite3_open([[[self databaseURL] path] UTF8String], &_database) != SQLITE_OK) {
        NSAlert *errorAlert = [NSAlert alertWithMessageText:@"Error"
                                              defaultButton:@"OK"
                                            alternateButton:nil
                                                otherButton:nil
                                  informativeTextWithFormat:@"Unable to open the database.  Sorry!"];
        
        [errorAlert runModal];
        
        return;
    }
    
    [[self mainWindowController] setTablesListArray:[self fetchTableNames]];
    [[[self mainWindowController] tableListSourceView] reloadData];
}

-(void)closeDatabase
{
    sqlite3_close(_database);
}

-(NSArray *)sqlKeywords
{
    return @[@"ABORT",
             @"ACTION",
             @"ADD",
             @"AFTER",
             @"ALL",
             @"ALTER",
             @"ANALYZE",
             @"AND",
             @"AS",
             @"ASC",
             @"ATTACH",
             @"AUTOINCREMENT",
             @"BEFORE",
             @"BEGIN",
             @"BETWEEN",
             @"BY",
             @"CASCADE",
             @"CASE",
             @"CAST",
             @"CHECK",
             @"COLLATE",
             @"COLUMN",
             @"COMMIT",
             @"CONFLICT",
             @"CONSTRAINT",
             @"CREATE",
             @"CROSS",
             @"CURRENT_DATE",
             @"CURRENT_TIME",
             @"CURRENT_TIMESTAMP",
             @"DATABASE",
             @"DEFAULT",
             @"DEFERRABLE",
             @"DEFERRED",
             @"DELETE",
             @"DESC",
             @"DETACH",
             @"DISTINCT",
             @"DROP",
             @"EACH",
             @"ELSE",
             @"END",
             @"ESCAPE",
             @"EXCEPT",
             @"EXCLUSIVE",
             @"EXISTS",
             @"EXPLAIN",
             @"FAIL",
             @"FOR",
             @"FOREIGN",
             @"FROM",
             @"FULL",
             @"GLOB",
             @"GROUP",
             @"HAVING",
             @"IF",
             @"IGNORE",
             @"IMMEDIATE",
             @"IN",
             @"INDEX",
             @"INDEXED",
             @"INITIALLY",
             @"INNER",
             @"INSERT",
             @"INSTEAD",
             @"INTERSECT",
             @"INTO",
             @"IS",
             @"ISNULL",
             @"JOIN",
             @"KEY",
             @"LEFT",
             @"LIKE",
             @"LIMIT",
             @"MATCH",
             @"NATURAL",
             @"NO",
             @"NOT",
             @"NOTNULL",
             @"NULL",
             @"OF",
             @"OFFSET",
             @"ON",
             @"OR",
             @"ORDER",
             @"OUTER",
             @"PLAN",
             @"PRAGMA",
             @"PRIMARY",
             @"QUERY",
             @"RAISE",
             @"REFERENCES",
             @"REGEXP",
             @"REINDEX",
             @"RELEASE",
             @"RENAME",
             @"REPLACE",
             @"RESTRICT",
             @"RIGHT",
             @"ROLLBACK",
             @"ROW",
             @"SAVEPOINT",
             @"SELECT",
             @"SET",
             @"TABLE",
             @"TEMP",
             @"TEMPORARY",
             @"THEN",
             @"TO",
             @"TRANSACTION",
             @"TRIGGER",
             @"UNION",
             @"UNIQUE",
             @"UPDATE",
             @"USING",
             @"VACUUM",
             @"VALUES",
             @"VIEW",
             @"VIRTUAL",
             @"WHEN",
             @"WHERE"];
}

@end
