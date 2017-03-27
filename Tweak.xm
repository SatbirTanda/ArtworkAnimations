#import "Animovani.h"

%hook SBLockScreenViewController

%new
- (void)getTrackDescription:(id)notification 
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
	if(musicArtworkView && musicArtworkView.artworkView && !viewIsAnimating && !blurViewIsAnimating && blurView != nil)
	{
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
		if(currentArtwork.image)
		{
			NSLog(@"Breakpoint 6");
			[blurView.layer removeAllAnimations];
			blurViewIsAnimating = YES;
			[UIView transitionWithView:blurView 
					duration:0.75 
					options:(UIViewAnimationOptionTransitionCrossDissolve) 
					animations:^{ [blurView _setImage:currentArtwork.image style:0 notify: NO]; } 
					completion:^(BOOL finished) { if (finished) blurViewIsAnimating = NO; }];
			[musicArtworkView.layer removeAllAnimations];
			viewIsAnimating = YES;
			[UIView transitionWithView:musicArtworkView 
								duration:0.75 
								options:(UIViewAnimationOptionTransitionFlipFromBottom) 
								animations:^{ musicArtworkView.artworkView = currentArtwork; } 
								completion:^(BOOL finished) { if (finished) viewIsAnimating = NO; }];
		}
		else
		{
			musicArtworkView.artworkView.image = nil;
			[blurView _setImage:nil style:0 notify: NO];
		}
	} 
	else
	{
		[blurView.layer removeAllAnimations];
		blurViewIsAnimating = NO;
		[musicArtworkView.layer removeAllAnimations];
		viewIsAnimating = NO;
	}
}

- (void)viewDidAppear:(id)arg1
{
	%orig;

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

- (void)_layoutScrollView
{
	%orig;
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

%end