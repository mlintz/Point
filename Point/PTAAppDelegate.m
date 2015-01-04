//
//  PTAAppDelegate.m
//  Point
//
//  Created by Mikey Lintz on 7/4/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

#import "PTAAppDelegate.h"

#import <Dropbox/Dropbox.h>

#import "PTAAuthenticationValues.h"
#import "PTAMainCollectionViewController.h"
#import "PTAFilesystemManager.h"

static NSString * const kInboxFileName = @"!!inbox.txt";
static NSString * const kOperationAggregatorDefaultsKey = @"OperationAggregator";

@interface PTAAppDelegate ()<PTAFilesystemManagerDelegate>

@end

@implementation PTAAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

  DBAccountManager *accountManager = [[DBAccountManager alloc] initWithAppKey:[PTAAuthenticationValues key]
                                                                       secret:[PTAAuthenticationValues secret]];
  [DBAccountManager setSharedManager:accountManager];
  NSOperationQueue *backgroundQueue = [[NSOperationQueue alloc] init];
  PTAFilesystemManager *manager = [[PTAFilesystemManager alloc] initWithAccountManager:accountManager
                                                                              rootPath:DBPath.root
                                                                         inboxFilePath:[DBPath.root childPath:kInboxFileName]
                                                                        operationQueue:backgroundQueue];
  manager.delegate = self;
  UIViewController *rootViewController = [[PTAMainCollectionViewController alloc] initWithFilesystemManager:manager];
  self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:rootViewController];
  [self.window makeKeyAndVisible];

  if (!accountManager.linkedAccount) {
    [accountManager linkFromController:rootViewController];
  }

  return YES;
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
  DBAccount *account = [[DBAccountManager sharedManager] handleOpenURL:url];
  NSAssert(account, @"Failed to create account.");
  return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
  // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
  // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
  // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
  // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
  // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
  // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
  // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - PTAFilesystemManagerDelegate

- (BOOL)manager:(PTAFilesystemManager *)manager willPublishFileChange:(PTAFile *)file {
  DBPath *path = file.info.path;
  if (file.newerVersionStatus == kPTAFileNewerVersionStatusCached) {
    [manager updateFileForPath:path];
    return NO;
  }
  return YES;
}

- (void)manager:(PTAFilesystemManager *)manager applyInitialTransformToFile:(PTAFile *)file {
  // TODO(mlintz): move into separate function.
  [self manager:manager willPublishFileChange:file];
}

@end
