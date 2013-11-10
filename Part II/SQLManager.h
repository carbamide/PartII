//
//  SQLHelpers.h
//  Part II
//
//  Created by Josh on 11/9/13.
//  Copyright (c) 2013 Jukaela Enterprises. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MainWindowController;

/**
 *  Sql Management Class - Singleton
 */
@interface SQLManager : NSObject

/**
 *  Reference to the main window
 */
@property (strong, nonatomic) MainWindowController *mainWindowController;

/**
 *  Database URL
 */
@property (strong, nonatomic) NSURL *databaseURL;

/**
 *  Singleton initializer
 *
 *  @return A SQLManager object
 */
+(id)sharedManager;

/**
 *  Fetch all table names.  Return as NSMutableArray of table names.
 *
 *  @return NSMutableArray of table names
 */
-(NSMutableArray *)fetchTableNames;

/**
 *  Select all rows from the specified table
 *
 *  @param table The table to select from
 *
 *  @return NSMutableArray of all rows in the table
 */
-(NSMutableArray *)selectAllFromTable:(NSString *)table;

/**
 *  Perfrom specified sql query
 *
 *  @param sql The SQL query to perform
 *
 *  @return NSMutableArray of all rows that are a result of the query
 */
-(NSMutableArray *)performSqlQuery:(NSString *)sql;

/**
 *  Table information of specified table
 *
 *  @param table The table to get information for
 *
 *  @return Table information as a NSMutableArray
 */
-(NSMutableArray *)tableInfo:(NSString *)table;

/**
 *  Schema for table as NSString
 *
 *  @param tableName The table to request the schema for
 *
 *  @return The schema, as an NSString
 */
-(NSString *)schemaForTable:(NSString *)tableName;


/**
 *  Open the database
 */
-(void)openDatabase;

/**
 *  Close the database
 */
-(void)closeDatabase;

/**
 *  Valid SQLite3 reserved words
 *
 *  @return NSArray of reserved SQLite3 keywords
 */
-(NSArray *)sqlKeywords;

@end
