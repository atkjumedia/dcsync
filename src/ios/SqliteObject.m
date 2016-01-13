//
//  SqliteObject.m
//  DCBootstrap
//
//  Created by ACE on 12/23/15.
//
//

#import <Foundation/Foundation.h>
#import "SqliteObject.h"
#import "sqlitemanager.h"


@implementation SqliteObject : NSObject

static SqliteObject *sqlobj = nil;



+ (SqliteObject *)sharedSQLObj{
    
    if (sqlobj == nil) {
        sqlobj = [[SqliteObject alloc] init];
    }
    return sqlobj;
}

-(void)create:(NSString * )path {
    
    NSFileManager *filemgr = [NSFileManager defaultManager];
    
    _dbpath = [path UTF8String];
    
    if ([filemgr fileExistsAtPath: path ] == NO) {
        /*
            called first time.. and
            create table if the db is not exist....

         */
        if (sqlite3_open(_dbpath, &_dcd) == SQLITE_OK) {
            //
            char *errMsg;
            
            // Create table sql...
            const char *sql_stmt =
            // DCDOCUMENTS
            "CREATE TABLE IF NOT EXISTS DCDOCUMENTS "
            "(cid TEXT PRIMARY KEY, "
            "local BOOL, "
            "modified_user TEXT, "
            "document TEXT, "
            "deleted BOOL, "            // deleted....
            "sync_nomedia BOOL, "
            "unsynced BOOL, "           // unsynced flag that is needed for upload sync...
            "files TEXT, "
            "path TEXT, "
            "creation_date BIGINT, "
            "modified_date BIGINT, "
            "server_modified BIGINT, "
            "creator_duid TEXT, "
            "creator_user TEXT, "
            "modified_duid TEXT);"
            // UNSYNCED
            "CREATE TABLE IF NOT EXISTS UNSYNCED "
            "(dcd_id INTEGER PRIMARY KEY, "
            "cid TEXT);"
            // SYNCOPTION
            "CREATE TABLE IF NOT EXISTS SYNCOPTION "
            "(id INTEGER PRIMARY KEY AUTOINCREMENT, "
            "url TEXT, "
            "locale TEXT, "
            "interval INTEGER, "
            "username TEXT, "
            "password TEXT, "
            "duid TEXT, "
            "params TEXT, "
            "insistOnBackground BOOL, "
            "event_filter TEXT);"
            // SYNCINFO
            "CREATE TABLE IF NOT EXISTS SYNCINFO "
            "(id INTEGER PRIMARY KEY AUTOINCREMENT, "
            "latest_timestamp BIGINT, "
            "comment TEXT);";
            
            if (sqlite3_exec(_dcd, sql_stmt, NULL, NULL, &errMsg) != SQLITE_OK) {
                NSLog(@"Failed to create table");
            }
            
            
            // close db....
            sqlite3_close(_dcd);
        }
        else {
            NSLog(@"Failed to open/create database");
        }
    }
    // DB already exists..
    else {
        
    }
    [[SQLiteManager singleton] setDatabasePath:path];
}

-(BOOL)saveSyncOption:(NSMutableDictionary *)option {
    // Reset id..
    [option setValue:@0 forKey:@"id"];
    
    [[SQLiteManager singleton] update:option into:@"SYNCOPTION" primaryKey:@"id"];
    
    return YES;
}


-(NSMutableDictionary *)loadSyncOption {
    NSArray * result = [[SQLiteManager singleton] findAllFrom:@"SYNCOPTION"];
    
    if (![result count]) {
        return  nil;
    }
    
    return result[0];
}



-(void)mergeDCD:(NSMutableArray *) dcdJson {
    /*
     Merge documents ...
     */
    for (NSMutableDictionary * document in dcdJson) {
        NSDictionary * dic = [document valueForKey:@"document"];
        NSDictionary * files = [document valueForKey:@"files"];
        
        
        if (dic.count) {
            NSData * documentData = [NSJSONSerialization dataWithJSONObject:dic options:(NSJSONWritingOptions)NSJSONWritingPrettyPrinted error:nil];
            NSData * filesData = [NSJSONSerialization dataWithJSONObject:files options:(NSJSONWritingOptions)NSJSONWritingPrettyPrinted error:nil];
            
            [document setValue:[[NSString alloc] initWithData:documentData encoding:NSUTF8StringEncoding] forKey:@"document"];
            [document setValue:[[NSString alloc] initWithData:filesData encoding:NSUTF8StringEncoding] forKey:@"files"];
        }
        
        
        NSLog(@"%d", [[SQLiteManager singleton] update:document into:@"DCDOCUMENTS" primaryKey:@"cid"]);
    }
}

-(NSNumber *)getDocumentCountInPath:(NSString *) path {
    NSArray * result = [[SQLiteManager singleton] find:@"cid" from:@"DCDOCUMENTS" where:[NSString stringWithFormat:@"path like '%@%@%@'", @"%", path, @"%"]];
    
    return [NSNumber numberWithInteger:result.count];
}


-(NSNumber *)getUnsyncedDocumentCountInPath:(NSString *) path {
    NSArray * result = [[SQLiteManager singleton] find:@"cid" from:@"DCDOCUMENTS" where:[NSString stringWithFormat:@"path like '%@%@%@' and unsynced like 1", @"%", path, @"%"]];
    
    return [NSNumber numberWithInteger:result.count];
}

-(NSArray *)getUnsyncedDocuments {
    return [self correctDataTypes:[[SQLiteManager singleton] find:@"*" from:@"DCDOCUMENTS" where:@"unsynced like 1"]];
}

-(NSArray *)correctDataTypes:arrDocuments {
    for (NSDictionary * dic in arrDocuments) {
        NSData *objectData = [[dic valueForKey:@"files"] dataUsingEncoding:NSUTF8StringEncoding];
        NSMutableArray *files = [NSJSONSerialization JSONObjectWithData:objectData options:NSJSONReadingMutableContainers error:nil];
        [dic setValue:files forKey:@"files"];
        
        [dic setValue:[NSNumber numberWithBool:[[dic valueForKey:@"deleted"] boolValue]] forKey:@"deleted"];
        [dic setValue:[NSNumber numberWithBool:[[dic valueForKey:@"unsynced"] boolValue]] forKey:@"unsynced"];
        [dic setValue:[NSNumber numberWithBool:[[dic valueForKey:@"local"] boolValue]] forKey:@"local"];
        [dic setValue:[NSNumber numberWithInt:[[dic valueForKey:@"creation_date"] integerValue]] forKey:@"creation_date"];
        [dic setValue:[NSNumber numberWithInt:[[dic valueForKey:@"modified_date"] integerValue]] forKey:@"modified_date"];
        [dic setValue:[NSNumber numberWithInt:[[dic valueForKey:@"server_modified"] integerValue]] forKey:@"server_modified"];
    }
    
    return arrDocuments;
}


-(NSArray *)getDCDFromCID:(NSString *) cid {
    return [self correctDataTypes:[[SQLiteManager singleton] find:@"*" from:@"DCDOCUMENTS" where:[NSString stringWithFormat:@"cid = '%@'", cid]]];
}


-(NSArray *)searchDocument:(NSDictionary *) query
                    option:(NSDictionary *) option {
    
    NSString * searchPath = [option valueForKey:@"path"];
    NSString * condition = [NSString stringWithFormat:@"path like '%@%@%@'", @"%", searchPath, @"%"];
    
    return [self correctDataTypes:[[SQLiteManager singleton] find:@"*" from:@"DCDOCUMENTS" where:condition]];
}


-(int)updateDCD:(NSMutableDictionary *) document {
    return [[SQLiteManager singleton] update:document into:@"DCDOCUMENTS" primaryKey:@"cid"];
}

-(double)getLatestSyncDate {
    NSArray * result = [[SQLiteManager singleton] find:@"*" from:@"SYNCINFO" where:@" id = 1 "];
    
    if (result.count == 0)
        return 0;
    
    return [[[result objectAtIndex:0] valueForKey:@"latest_timestamp"] doubleValue];
}

-(void)addDCDAsUnsynced:(NSMutableDictionary *) unsyncedDoc {
    
    [[SQLiteManager singleton] update:unsyncedDoc into:@"UNSYNCED" primaryKey:@"dcd_id"];
}

-(void)mergeDJSON:(NSMutableArray *) dJson {
    [[SqliteObject sharedSQLObj] mergeDCD:dJson];
}

-(void)mergeDJSONFromFile:(NSString *) dJsonFile
                completed:(BOOL) completed
{
    NSData *data = [NSData dataWithContentsOfFile:dJsonFile];
    NSMutableArray *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    
    [self mergeDJSON:json];
    
    if (completed) {
        NSNumber * timeStamp = [NSNumber numberWithDouble:[NSDate date].timeIntervalSince1970];
        
        NSDictionary * timestamp = @{@"latest_timestamp": timeStamp,
                                     @"id": @1};
        
        [[SQLiteManager singleton] update:[timestamp mutableCopy] into:@"SYNCINFO" primaryKey:@"id"];
    }
}

@end
