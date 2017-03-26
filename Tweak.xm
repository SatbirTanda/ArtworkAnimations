#import <MediaPlayer/MPMusicPlayerController.h>

@interface SBLockScreenView
@property(readonly, retain, nonatomic) UIScrollView *scrollView;
@end

@interface _NowPlayingArtView: UIView
@property (nonatomic,retain) UIImageView* artworkView;
@end

static MPMusicPlayerController* myPlayer = nil;
static NSNotificationCenter* notificationCenter = nil;
static SBLockScreenView* lockScreenView = nil;
static _NowPlayingArtView* musicArtworkView = nil;
static bool viewIsAnimating = NO;
typedef void(^ViewBlock)(UIView* view, BOOL* stop);

@interface UIView (ViewExtensions)
- (void) loopViewHierarchy:(ViewBlock) block;
@end

@implementation UIView (ViewExtensions)
- (void) loopViewHierarchy:(ViewBlock) block 
{
    BOOL stop = NO;
    if (block) 
    {
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
	if(musicArtworkView && musicArtworkView.artworkView && !viewIsAnimating)
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
			[musicArtworkView.layer removeAllAnimations];
			[UIView transitionWithView:musicArtworkView 
								duration:0.75 
								options:(UIViewAnimationOptionTransitionFlipFromBottom) 
								animations:^{ viewIsAnimating = YES; musicArtworkView.artworkView = currentArtwork; } 
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

	lockScreenView = nil;
	
	musicArtworkView = nil;
}

%end

%hook SBLockScreenView

- (void)_layoutScrollView
{
	%orig;
	lockScreenView = self;
}

%end