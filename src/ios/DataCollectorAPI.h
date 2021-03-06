//
//  DataCollectorAPI.h
//  app
//
//  Created by ACE on 12/18/15.
//
//

#ifndef DataCollectorAPI_h
#define DataCollectorAPI_h

#import "DCSync.h"
#import "Reachability.h"

@interface DataCollectorAPI : NSObject <NSURLSessionTaskDelegate>

+ (id)sharedAPI;

-(void)authenticate:(NSString *) username
           password:(NSString *)password;

-(int)checkConnectivity:(NSString *)url;
-(int)sync:(NSDictionary *) param
        url:(NSString *) url
   listener:(DCSync *)listener;


@property (nonatomic, retain) NSString *rootPath;
@property (nonatomic, retain) DCSync * listener;
@property (nonatomic, retain) Reachability * reachability;


@end


#endif /* DataCollectorAPI_h */
