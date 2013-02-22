//
//  Achievement+GameCenter.m
//
//  Created by Rex Sheng on 11/6/12.
//  Copyright (c) 2012 rexsheng.com. All rights reserved.
//

#import "Achievement+GameCenter.h"

@implementation Achievement (GameCenter)

+ (Achievement *)achievementByIdentifier:(NSString *)identifier inContext:(NSManagedObjectContext *)context
{
	NSArray *found = [Achievement MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"identifier = %@", identifier] inContext:context];
	Achievement *achievement = found.lastObject;
	if (!achievement) {
		achievement = [Achievement MR_createInContext:context];
		achievement.identifier = identifier;
	}
	if (found.count > 1) {
		for (Achievement *a in found) {
			if (a != achievement) {
				[a MR_deleteInContext:context];
			}
		}
	}
	return achievement;
}

- (GKAchievement *)gkAchievement
{
	GKAchievement *gkAchievement = [[GKAchievement alloc] initWithIdentifier:self.identifier];
	gkAchievement.percentComplete = [self.percentComplete doubleValue];
	gkAchievement.showsCompletionBanner = YES;
	return gkAchievement;
}

+ (void)updateFromGameCenter:(MRSaveCompletionHandler)complete
{
	NSLog(@"updating from GameCenter...");
	[GKAchievement loadAchievementsWithCompletionHandler:^(NSArray *achievements, NSError *error) {
		[MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
			for (GKAchievement *gkAchievement in achievements) {
				Achievement *achievement = [Achievement achievementByIdentifier:gkAchievement.identifier inContext:localContext];
				double percentComplete = [achievement.percentComplete doubleValue];
				if (achievement.isInserted || percentComplete < gkAchievement.percentComplete) {
					achievement.synced = @YES;
					achievement.percentComplete = @(gkAchievement.percentComplete);
					NSLog(@"download achievement: '%@', gamecenter score is higher(%g>%g)", gkAchievement.identifier,  gkAchievement.percentComplete, percentComplete);
				} else if ([achievement.synced boolValue] && percentComplete > gkAchievement.percentComplete) {
					achievement.synced = @NO;
					NSLog(@"ignore achievement: '%@', local score is higher", achievement.identifier);
				}
			}
		} completion:complete];
	}];
}

+ (void)restoreFromGameCenter:(MRSaveCompletionHandler)complete
{
	[MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
		NSLog(@"remove all achievements...");
		[self MR_truncateAllInContext:localContext];
	} completion:^(BOOL success, NSError *error) {
		[self updateFromGameCenter:complete];
	}];
}

+ (void)sendToGameCenter:(MRSaveCompletionHandler)complete
{
	[MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
		NSArray *achievements = [self MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"synced = NO"] inContext:localContext];
		if (achievements.count == 0) {
			if (complete) complete(YES, nil);
			return;
		}
		NSArray *gkAchievements = [achievements valueForKey:@"gkAchievement"];
		NSLog(@"reporting unsynced achievements: %@", gkAchievements);
		
		[self reportAchievements:gkAchievements completion:^(NSError *error) {
			if (!error)
				[MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
					for (Achievement *a in achievements) {
						[[a MR_inContext:localContext] setSynced:@YES];
					}
				} completion:complete];
			else
				if (complete) complete(YES, nil);
		}];
	}];
}

+ (void)reportAchievements:(NSArray *)gkAchievements completion:(void(^)(NSError *))complete
{
	if ([GKAchievement respondsToSelector:@selector(reportAchievements:withCompletionHandler:)]) {
		return [GKAchievement reportAchievements:gkAchievements withCompletionHandler:complete];
	}
	__block dispatch_group_t group = dispatch_group_create();
	__block NSError *lastError = nil;
	NSMutableArray *succeeded = [@[] mutableCopy];
	for (GKAchievement *achievement in gkAchievements) {
		dispatch_group_enter(group);
		[achievement reportAchievementWithCompletionHandler:^(NSError *error) {
			if (!error) {
				[succeeded addObject:achievement.identifier];
			} else {
				lastError = error;
			}
			dispatch_group_leave(group);
		}];
	}
	dispatch_group_notify(group, dispatch_get_main_queue(), ^{
#if !OS_OBJECT_USE_OBJC
		dispatch_release(group);
#endif
		group = NULL;
		NSLog(@"reported %d/%d achievements", succeeded.count, gkAchievements.count);
		if (complete) complete(lastError);
	});
}

+ (void)checkForNewAchievements:(void(^)(NSManagedObjectContext *context, void(^reportAchievement)(NSString *, double)))math complete:(MRSaveCompletionHandler)complete
{
	static dispatch_group_t achievementsGroup;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		achievementsGroup = dispatch_group_create();
	});
	if (dispatch_group_wait(achievementsGroup, DISPATCH_TIME_NOW)) return;
	dispatch_group_enter(achievementsGroup);
	
	NSLog(@"checking for new achievements...");
	__block NSUInteger newAchievements = 0;
	[MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
		void(^reportAchievement)(NSString *, double) = ^(NSString *identifier, double percentComplete) {
			Achievement *achievement = [Achievement achievementByIdentifier:identifier inContext:localContext];
			if ([achievement.percentComplete doubleValue] < percentComplete) {
				NSLog(@"new achievement: %@(%@ >> %f)", identifier, achievement.percentComplete, percentComplete);
				achievement.percentComplete = @(percentComplete);
				achievement.synced = @NO;
				newAchievements++;
			}
		};
		math(localContext, reportAchievement);
	} completion:^(BOOL success, NSError *error) {
		if (newAchievements) {
			[self sendToGameCenter:^(BOOL success, NSError *error) {
				dispatch_group_leave(achievementsGroup);
				if (complete) complete(success, error);
			}];
		} else {
			NSLog(@"no new achievements");
			dispatch_group_leave(achievementsGroup);
			if (complete) complete(success, error);
		}
	}];
}

@end
