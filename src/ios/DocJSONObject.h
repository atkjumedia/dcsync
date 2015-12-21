//
//  DocumentJSON.h
//  app
//
//  Created by ACE on 12/18/15.
//
//

#ifndef DocumentJSON_h
#define DocumentJSON_h

@interface DocJSONObject : NSObject

+ (id)sharedDocJSONObject;

-(void)mergeDJSON:(NSMutableArray *) dJson;
-(void)mergeDJSONFromFile:(NSString *) dJsonFile;

-(void)saveDJSON;

-(void)searchDocument:(NSDictionary *) query
               option:(NSDictionary *) option
             callback:(void (^)(NSArray * arrDCDocuments))callback;


@property (nonatomic, retain) NSString * outputPath;
@property (nonatomic, retain) NSMutableArray *arrDocuments;

@end



#endif /* DocumentJSON_h */