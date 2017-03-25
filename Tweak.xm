#import <MediaPlayer/MPMusicPlayerController.h>

@interface SBLockScreenView
@property(readonly, retain, nonatomic) UIScrollView *scrollView;
@end

@interface _NowPlayingArtView: UIView
@property (nonatomic,retain) UIImageView* artworkView;
@end

static MPMusicPlayerController *myPlayer = nil;
static NSNotificationCenter *notificationCenter = nil;
static SBLockScreenView* lockScreenView = nil;
static _NowPlayingArtView* musicArtworkView = nil;
typedef void(^ViewBlock)(UIView* view, BOOL* stop);

@interface UIView (ViewExtensions)
-(void) loopViewHierarchy:(ViewBlock) block;
@end

@implementation UIView (ViewExtensions)
- (void) loopViewHierarchy:(ViewBlock) block 
{
    BOOL stop = NO;
    if (block) {
        block(self, &stop);
    }
    if (!stop) 
    {
        for (UIView* subview in self.subviews) 
        {
            [subview loopViewHierarchy:block];
        }
    }
}
@end

%hook SBLockScreenViewController

%new
- (void)getTrackDescription:(id)notification 
{
	if(musicArtworkView == nil && lockScreenView.scrollView != nil)
	{
		[lockScreenView.scrollView loopViewHierarchy:^(UIView* view, BOOL* stop) 
		{
		    if ([view isKindOfClass:[%c(_NowPlayingArtView) class]]) 
		    {
		        /// use the view
		        musicArtworkView = (_NowPlayingArtView *)view;
		        *stop = YES;
		    }
		}];
	}
	if(musicArtworkView && musicArtworkView.artworkView)
	{
		// musicArtworkView.artworkView.alpha = 0.0;
		// [UIView animateWithDuration:1.0
		// 			delay:0.0
		// 		options: UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionTransitionFlipFromRight
		// 			animations:
		// 			^{
		// 				musicArtworkView.artworkView.alpha = 1.0;
		// 			}
		// 			completion:nil];
    	MPMediaItem* nowPlayingItem = myPlayer.nowPlayingItem;
    	MPMediaItemArtwork* artwork = [nowPlayingItem valueForProperty:MPMediaItemPropertyArtwork];
    	UIImageView* currentArtwork = [[UIImageView alloc] initWithFrame:musicArtworkView.artworkView.frame];
    	currentArtwork.contentMode = UIViewContentModeScaleAspectFit;
    	if (artwork != nil) {
        	currentArtwork.image = [artwork imageWithSize:musicArtworkView.artworkView.frame.size];
    	}

		// [UIView transitionWithView:musicArtworkView.artworkView
		//                   duration:1.0
		//                    options:UIViewAnimationOptionTransitionFlipFromRight
		//                 animations:^{
		//                     //  Set the new image
		//                     //  Since its done in animation block, the change will be animated
		//                     musicArtworkView.artworkView.image = currentArtwork;
		//                 } completion:^(BOOL finished) {
		//                     //  Do whatever when the animation is finished
		//                 }];

  [UIView transitionFromView:musicArtworkView.artworkView
                        toView:currentArtwork
                      duration:1.0
                       options:UIViewAnimationOptionTransitionFlipFromRight |
                               UIViewAnimationOptionAllowUserInteraction
                    completion:^(BOOL finished) { musicArtworkView.artworkView = currentArtwork; }];
		// [UIView transitionWithView:musicArtworkView 
		// 	duration:1.0 
		// 	options:(UIViewAnimationOptionTransitionFlipFromBottom) 
		// 	animations:^{ musicArtworkView.artworkView.image = currentArtwork; } completion:^(BOOL finished) {}];

		// UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Song Changed" 
		//                                                 message:nil
		//                                                 delegate:nil 
		//                                                 cancelButtonTitle:@"OK" 
		//                                                 otherButtonTitles:nil];
		// [alert show];
	}
}

- (void)viewDidAppear:(id)arg1
{
	%orig;

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
	
    [notificationCenter removeObserver:self
                                name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification
                                object:myPlayer];

    [myPlayer endGeneratingPlaybackNotifications];

    myPlayer = nil;

    notificationCenter = nil;

}

%end

%hook SBLockScreenView

- (void)_layoutScrollView
{
	%orig;
	lockScreenView = self;
}

%end