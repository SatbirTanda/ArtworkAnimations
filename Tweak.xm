#import "ArtworkAnimations.h"
#define PLIST_FILENAME @"/var/mobile/Library/Preferences/com.sst1337.ArtworkAnimations.plist"
#define TWEAK "com.sst1337.ArtworkAnimations"

//PLIST KEYS
#define ONOFF "OnOff"
#define ANIMATION "Animation"
#define BACKGROUND "Background"

/*ANIMATIONS:*/
#define FLIP_RIGHT @"Flip Right"
#define FLIP_LEFT @"Flip Left"
#define FLIP_TOP @"Flip Top"
#define FLIP_BOTTOM @"Flip Bottom"
#define CURL_UP @"Curl Up"
#define CURL_DOWN @"Curl Down"
#define DISSOVLE @"Dissolve"
#define RANDOM @"Random"

%group iOS9

%hook SBLockScreenViewController

%new
- (BOOL)isTweakEnabled
{
	CFPreferencesAppSynchronize(CFSTR(TWEAK));
	CFPropertyListRef value = CFPreferencesCopyAppValue(CFSTR(ONOFF), CFSTR(TWEAK));
	if(value == nil) return YES;  
	return [CFBridgingRelease(value) boolValue];
}

%new
- (BOOL)isBackgroundAnimationEnabled
{
	CFPreferencesAppSynchronize(CFSTR(TWEAK));
	CFPropertyListRef value = CFPreferencesCopyAppValue(CFSTR(BACKGROUND), CFSTR(TWEAK));
	if(value == nil) return YES;  
	return [CFBridgingRelease(value) boolValue];
}

%new
- (NSString *)getAnimationKey
{
	CFPreferencesAppSynchronize(CFSTR(TWEAK));
	CFPropertyListRef value = CFPreferencesCopyAppValue(CFSTR(ANIMATION), CFSTR(TWEAK));
	NSString *animation = (NSString *)CFBridgingRelease(value);
	if(animation != nil) return animation;
	return RANDOM;
}

%new
- (int)currentAnimation
{
	NSString *key = [self getAnimationKey];
	if([key isEqualToString: FLIP_RIGHT]) return 2 << 20;
	else if([key isEqualToString: FLIP_LEFT]) return 1 << 20;
	else if([key isEqualToString: FLIP_TOP]) return 6 << 20;
	else if([key isEqualToString: FLIP_BOTTOM]) return 7 << 20;
	else if([key isEqualToString: DISSOVLE]) return 5 << 20;
	else
	{
		int animationValues[5] = {2 << 20, 1 << 20, 6 << 20, 7 << 20, 5 << 20};
		int randomIndex = arc4random() % 5;
		return animationValues[randomIndex];
	}
}

%new
- (void)getTrackDescription:(id)notification 
{
	if([self isTweakEnabled])
	{
		NSLog(@"Breakpoint 1");
		if(musicArtworkView == nil && lockScreenView.scrollView != nil)
		{
			NSLog(@"Breakpoint 2");
			[lockScreenView.scrollView loopViewHierarchy:^(UIView* view, BOOL* stop) 
			{
			    if ([view isKindOfClass:[%c(_NowPlayingArtView) class]]) 
			    {
			        /// use the view
			        NSLog(@"Breakpoint 3");
			        musicArtworkView = (_NowPlayingArtView *)view;
			        *stop = YES;
			    }
			}];
		}
		NSLog(@"Breakpoint 4");
    	MPMediaItem* nowPlayingItem = myPlayer.nowPlayingItem;
    	MPMediaItemArtwork* artwork = [nowPlayingItem valueForProperty:MPMediaItemPropertyArtwork];
    	UIImageView* currentArtwork = [[UIImageView alloc] initWithFrame:musicArtworkView.artworkView.frame];
    	if (artwork != nil) 
    	{
    		NSLog(@"Breakpoint 5");
        	currentArtwork.image = [artwork imageWithSize:musicArtworkView.artworkView.frame.size];
        	currentArtwork.contentMode = UIViewContentModeScaleAspectFit;
    	}
		if([self isBackgroundAnimationEnabled])
		{
			NSLog(@"Breakpoint 10");
			if([self isBackgroundAnimationEnabled] && blurView && !blurViewIsAnimating)
			{
				if(currentArtwork.image)
				{
					[blurView.layer removeAllAnimations];
					blurViewIsAnimating = YES;
					[UIView transitionWithView:blurView 
							duration:0.75 
							options:(UIViewAnimationOptionTransitionCrossDissolve) 
							animations:^{ [blurView _setImage:currentArtwork.image style:0 notify: NO]; } 
							completion:^(BOOL finished) { if (finished) blurViewIsAnimating = NO; }];
				}
				else
				{
					[blurView _setImage:nil style:0 notify: NO];
				}
			}
			else
			{
				[blurView.layer removeAllAnimations];
				blurViewIsAnimating = NO;
			}
		}
		if(musicArtworkView && musicArtworkView.artworkView && !viewIsAnimating)
		{
			if(currentArtwork.image)
			{
				NSLog(@"Breakpoint 6");
				[musicArtworkView.layer removeAllAnimations];
				viewIsAnimating = YES;
				[UIView transitionWithView:musicArtworkView 
									duration:0.75 
									options:[self currentAnimation] 
									animations:^{ musicArtworkView.artworkView = currentArtwork; } 
									completion:^(BOOL finished) { if (finished) viewIsAnimating = NO; }];
			}
			else
			{
				musicArtworkView.artworkView.image = nil;
			}
		} 
		else
		{
			[musicArtworkView.layer removeAllAnimations];
			viewIsAnimating = NO;
		}
	}
}

- (void)viewDidAppear:(id)arg1
{
	%orig;

	if([self isTweakEnabled])
	{
		NSLog(@"Breakpoint 7");
	    // creating simple audio player
	    myPlayer = [MPMusicPlayerController systemMusicPlayer];

	    notificationCenter = [NSNotificationCenter defaultCenter];

		[notificationCenter addObserver:self
		                    selector:@selector(getTrackDescription:)
		                        name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification
		                        object:myPlayer];

	    [myPlayer beginGeneratingPlaybackNotifications];
	}	
}

- (void)viewDidDisappear:(id)arg1
{
	%orig;
	
	NSLog(@"Breakpoint 8");

	[notificationCenter removeObserver:self
	                        	name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification
	                        	object:myPlayer];

    [myPlayer endGeneratingPlaybackNotifications];

    myPlayer = nil;

    notificationCenter = nil;

    viewIsAnimating = NO;

	blurViewIsAnimating = NO;

	lockScreenView = nil;
	
	musicArtworkView = nil;

	blurView = nil;
}

%end

%hook SBLockScreenView

%new
- (BOOL)isTweakEnabled
{
	CFPreferencesAppSynchronize(CFSTR(TWEAK));
	CFPropertyListRef value = CFPreferencesCopyAppValue(CFSTR(ONOFF), CFSTR(TWEAK));
	if(value == nil) return YES;  
	return [CFBridgingRelease(value) boolValue];
}

%new
- (BOOL)isBackgroundAnimationEnabled
{
	CFPreferencesAppSynchronize(CFSTR(TWEAK));
	CFPropertyListRef value = CFPreferencesCopyAppValue(CFSTR(BACKGROUND), CFSTR(TWEAK));
	if(value == nil) return YES;  
	return [CFBridgingRelease(value) boolValue];
}


- (void)_layoutScrollView
{
	%orig;
	lockScreenView = self;
	if([self isTweakEnabled] && [self isBackgroundAnimationEnabled])
	{
		NSArray *windows = [UIApplication sharedApplication].windows;
	    for (UIWindow *window in windows) 
	    {
	        if ([NSStringFromClass([window class]) isEqualToString:@"SBSecureWindow"]) 
	        {
				[window loopViewHierarchy:^(UIView* view, BOOL* stop) 
				{
				    if ([view isKindOfClass:[%c(_SBFakeBlurView) class]]) 
				    {
				        /// use the view
				        NSLog(@"FOUND WALLPAPER");
				        blurView = (_SBFakeBlurView *)view;
				        *stop = YES;
				    }
				}];
				break;
	        }
	    }
	}
}

%end

%end

%group iOS10

%hook SBDashBoardMediaArtworkViewController

%new
- (BOOL)isTweakEnabled
{
	CFPreferencesAppSynchronize(CFSTR(TWEAK));
	CFPropertyListRef value = CFPreferencesCopyAppValue(CFSTR(ONOFF), CFSTR(TWEAK));
	if(value == nil) return YES;  
	return [CFBridgingRelease(value) boolValue];
}

%new
- (BOOL)isBackgroundAnimationEnabled
{
	CFPreferencesAppSynchronize(CFSTR(TWEAK));
	CFPropertyListRef value = CFPreferencesCopyAppValue(CFSTR(BACKGROUND), CFSTR(TWEAK));
	if(value == nil) return YES;  
	return [CFBridgingRelease(value) boolValue];
}

%new
- (NSString *)getAnimationKey
{
	CFPreferencesAppSynchronize(CFSTR(TWEAK));
	CFPropertyListRef value = CFPreferencesCopyAppValue(CFSTR(ANIMATION), CFSTR(TWEAK));
	NSString *animation = (NSString *)CFBridgingRelease(value);
	if(animation != nil) return animation;
	return RANDOM;
}

%new
- (int)currentAnimation
{
	NSString *key = [self getAnimationKey];
	if([key isEqualToString: FLIP_RIGHT]) return 2 << 20;
	else if([key isEqualToString: FLIP_LEFT]) return 1 << 20;
	else if([key isEqualToString: FLIP_TOP]) return 6 << 20;
	else if([key isEqualToString: FLIP_BOTTOM]) return 7 << 20;
	else if([key isEqualToString: CURL_UP]) return 3 << 20;
	else if([key isEqualToString: CURL_DOWN]) return 4 << 20;
	else if([key isEqualToString: DISSOVLE]) return 5 << 20;
	else
	{
		int animationValues[7] = {2 << 20, 1 << 20, 6 << 20, 7 << 20, 5 << 20, 3 << 20, 4 << 20};
		int randomIndex = arc4random() % 7;
		return animationValues[randomIndex];
	}
}

%new
- (void)getTrackDescription:(id)notification
{
	if([self isTweakEnabled])
	{
		if(artworkView == nil)
		{
			[self.view loopViewHierarchy:^(UIView* view, BOOL* stop) 
			{
			    if ([view isKindOfClass:[%c(MPUNowPlayingArtworkView) class]]) 
			    {
			        /// use the view
			        artworkView = (MPUNowPlayingArtworkView *)view;
			        *stop = YES;
			    }
			}];
		}
		if(artworkView)
		{
			UIImageView *artworkImageView = MSHookIvar<UIImageView *>(artworkView, "_artworkImageView");
			MPMediaItem *nowPlayingItem = myPlayer.nowPlayingItem;
	    	MPMediaItemArtwork *artwork = [nowPlayingItem valueForProperty:MPMediaItemPropertyArtwork];
			UIImage *currentImage = [artwork imageWithSize:artworkView.frame.size];	
			if(wallpaper && !wallPaperIsAnimating && [self isBackgroundAnimationEnabled])
			{
				wallPaperIsAnimating = YES;
				[UIView transitionWithView:wallpaper 
											duration:0.75 
											options: UIViewAnimationOptionTransitionCrossDissolve 
											animations:^{ wallpaper.image = currentImage; } 
											completion:^(BOOL finished) { if (finished) wallPaperIsAnimating = NO; }];
			}			
			if(!artworkIsAnimating)
			{
				artworkIsAnimating = YES;
				[UIView transitionWithView:artworkImageView 
											duration:0.75 
											options:[self currentAnimation] 
											animations:^{ artworkImageView.image = currentImage; } 
											completion:^(BOOL finished) { if (finished) artworkIsAnimating = NO; }];
			}
		}
	}
}

- (void)viewDidAppear:(id)arg1
{
	%orig;

	if([self isTweakEnabled])
	{
	    // creating simple audio player
	    myPlayer = [MPMusicPlayerController systemMusicPlayer];

	    notificationCenter = [NSNotificationCenter defaultCenter];

		[notificationCenter addObserver:self
		                    selector:@selector(getTrackDescription:)
		                        name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification
		                        object:myPlayer];

	    [myPlayer beginGeneratingPlaybackNotifications];

		if([self isBackgroundAnimationEnabled])
		{
		    NSArray *windows = [UIApplication sharedApplication].windows;
		    for (UIWindow *window in windows) 
		    {
		        if ([NSStringFromClass([window class]) isEqualToString:@"_SBWallpaperWindow"]) 
		        {
					[window loopViewHierarchy:^(UIView* view, BOOL* stop) 
					{
					    if ([view isKindOfClass:[%c(SBFStaticWallpaperImageView) class]]) 
					    {
					        /// use the view
					        wallpaper = (SBFStaticWallpaperImageView *)view;
					        *stop = YES;
					    }
					}];
					break;
		        }
		    }

		    if(wallpaper) originalImage = wallpaper.image;
		}
	}
}

- (void)viewWillDisappear:(id)arg1
{
	%orig;
	if(wallpaper && originalImage) wallpaper.image = originalImage;
}

- (void)viewDidDisappear:(id)arg1
{
	%orig;
	
	[notificationCenter removeObserver:self
	                        	name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification
	                        	object:myPlayer];

    [myPlayer endGeneratingPlaybackNotifications];

    myPlayer = nil;

    notificationCenter = nil;

    artworkView = nil;

    wallpaper = nil;

    originalImage = nil;
}

%end

%end

%ctor 
{
    if(kCFCoreFoundationVersionNumber >= 1300) // iOS 10
    {
        %init(iOS10);
    }
    else
    {
    	 %init(iOS9);
    }
}