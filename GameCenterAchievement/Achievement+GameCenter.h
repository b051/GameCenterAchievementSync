//
//  Achievement+GameCenter.h
//
//  Created by Rex Sheng on 11/6/12.
//  Copyright (c) 2012 rexsheng.com. All rights reserved.
//

#import "Achievement.h"

typedef void(^reportAchievementBlock)(NSString *identifier, double percentComplete);

@interface Achievement (GameCenter)

+ (void)updateFromGameCenter:(MRSaveCompletionHandler)complete;
+ (void)restoreFromGameCenter:(MRSaveCompletionHandler)complete;
+ (void)sendToGameCenter:(MRSaveCompletionHandler)complete;
+ (void)checkForNewAchievements:(void(^)(NSManagedObjectContext *context, reportAchievementBlock block))math complete:(MRSaveCompletionHandler)complete;

+ (Achievement *)achievementByIdentifier:(NSString *)identifier inContext:(NSManagedObjectContext *)context;
- (GKAchievement *)gkAchievement;

@end
