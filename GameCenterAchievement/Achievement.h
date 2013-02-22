//
//  Achievement.h
//
//  Created by Rex Sheng on 11/14/12.
//  Copyright (c) 2012 rexsheng.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Achievement : NSManagedObject

@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSNumber * percentComplete;
@property (nonatomic, retain) NSNumber * synced;

@end
