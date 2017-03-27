#import "Animovani.h"
#define PLIST_FILENAME @"/var/mobile/Library/Preferences/com.sst1337.animovani.plist"

//PLIST KEYS
#define ONOFF @"OnOff"
#define ANIMATION @"Animation"
#define BACKGROUND @"Background"

/*ANIMATIONS:*/
#define FLIP_RIGHT @"Flip Right"
#define FLIP_LEFT @"Flip Left"
#define FLIP_TOP @"Flip Top"
#define FLIP_BOTTOM @"Flip Bottom"
#define RANDOM @"Random"

%hook SBLockScreenViewController

%new
- (BOOL)isTweakEnabled
{
  NSDictionary *settings = [[%c(NSDictionary) alloc] initWithContentsOfFile:PLIST_FILENAME];
  if([[settings objectForKey: ONOFF] boolValue] || [settings objectForKey: ONOFF] == nil) return YES;  
  return NO;
}

%new
- (BOOL)isBackgroundAnimationEnabled
{
  NSDictionary *settings = [[%c(NSDictionary) alloc] initWithContentsOfFile:PLIST_FILENAME];
  if([[settings objectForKey: BACKGROUND] boolValue] || [settings objectForKey: BACKGROUND] == nil) return YES;  
  return NO;
}

%new
- (NSString *)getAnimationKey
{
  NSDictionary *settings = [[%c(NSDictionary) alloc] initWithContentsOfFile:PLIST_FILENAME];
  if([settings objectForKey:ANIMATION] == nil) return FLIP_RIGHT;
  return [settings objectForKey:ANIMATION];
}

%new
- (int)currentAnimation
{
	NSString *key = [self getAnimationKey];
	if([key isEqualToString: FLIP_RIGHT]) return 2 << 20;
	else if([key isEqualToString: FLIP_LEFT]) return 1 << 20;
	else if([key isEqualToString: FLIP_TOP]) return 6 << 20;
	else if([key isEqualToString: FLIP_BOTTOM]) return 7 << 20;
	else
	{
		int animationValues[4] = {2 << 20, 1 << 20, 6 << 20, 7 << 20};
		int randomIndex = arc4random() % 4;
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
			if(blurView && !blurViewIsAnimating)
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
  NSDictionary *settings = [[%c(NSDictionary) alloc] initWithContentsOfFile:PLIST_FILENAME];
  if([[settings objectForKey: ONOFF] boolValue] || [settings objectForKey: ONOFF] == nil) return YES;  
  return NO;
}

%new
- (BOOL)isBackgroundAnimationEnabled
{
  NSDictionary *settings = [[%c(NSDictionary) alloc] initWithContentsOfFile:PLIST_FILENAME];
  if([[settings objectForKey: BACKGROUND] boolValue] || [settings objectForKey: BACKGROUND] == nil) return YES;  
  return NO;
}

- (void)_layoutScrollView
{
	%orig;
	if([self isTweakEnabled] && [self isBackgroundAnimationEnabled])
	{
		lockScreenView = self;
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