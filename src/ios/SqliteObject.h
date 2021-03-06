//
//  SqliteObject.h
//  DCBootstrap
//
//  Created by ACE on 12/23/15.
//
//

#ifndef SqliteObject_h
#define SqliteObject_h

#import <sqlite3.h>


@interface SqliteObject : NSObject

+ (id)sharedSQLObj;

-(void)create:(NSString *)path;
-(BOOL)saveSyncOption:(NSMutableDictionary *)option;
-(NSMutableDictionary *)loadSyncOption;

-(NSNumber *)getDocumentCountInPath:(NSString *) path;
-(NSNumber *)getUnsyncedDocumentCountInPath:(NSString *) path;
-(NSArray *)getUnsyncedDocuments;

-(NSArray *)getDCDFromCID:(NSString *) cid;

-(NSArray *)searchDocument:(NSDictionary *) query
                    option:(NSDictionary *) option;

-(void)makeDCDAsSynced:(NSArray *) arrDCDs;

-(void)mergeDCD:(NSMutableArray * )dcdJson;

-(int)updateDCD:(NSMutableDictionary *) document;

-(double)getLatestSyncDate;

-(void)addDCDAsUnsynced:(NSMutableDictionary *) document;

-(void)mergeDJSON:(NSMutableArray *) dJson;

-(void)mergeDJSONFromFile:(NSString *) dJsonFile
                completed:(BOOL) completed;

-(NSArray *)correctDataTypes:arrDocuments;

@property (nonatomic) sqlite3 * dcd;
@property (nonatomic) const char * dbpath;

@end



#endif /* SqliteObject_h */
