#import <MediaPlayer/MPMusicPlayerController.h>

@interface SBLockScreenViewController
// NEW
- (BOOL)isTweakEnabled;
- (BOOL)isBackgroundAnimationEnabled;
- (NSString *)getAnimationKey;
- (int)currentAnimation;
- (void)getTrackDescription:(id)notification;
@end

@interface SBLockScreenView
@property(readonly, retain, nonatomic) UIScrollView *scrollView;
// NEW
- (BOOL)isTweakEnabled;
- (BOOL)isBackgroundAnimationEnabled;
@end

@interface _NowPlayingArtView: UIView
@property (nonatomic,retain) UIImageView* artworkView;
@end

@interface SBUIController: UIViewController
+ (id)sharedInstance;
- (BOOL)isTweakEnabled;
- (BOOL)isBackgroundAnimationEnabled;
- (NSString *)getAnimationKey;
- (int)currentAnimation;
- (void)currentSongChanged:(NSNotification *)notification;
- (void)updateLockscreenArtwork;
@end

@interface SBMediaController: UIViewController
+ (id)sharedInstance;
- (id)_nowPlayingInfo;
@end


@interface _SBFakeBlurView : UIView
- (void)_setImage:(id)arg1 style:(long long)arg2 notify:(_Bool)arg3;
@end

static MPMusicPlayerController* myPlayer = nil;
static NSNotificationCenter* notificationCenter = nil;
static SBLockScreenView* lockScreenView = nil;
static _NowPlayingArtView* musicArtworkView = nil;
static _SBFakeBlurView* blurView = nil;
static bool viewIsAnimating = NO;
static bool blurViewIsAnimating = NO;
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

@interface SBDashBoardMediaArtworkViewController : UIViewController
- (void)getTrackDescription:(id)notification;
- (BOOL)isTweakEnabled;
- (BOOL)isBackgroundAnimationEnabled;
- (NSString *)getAnimationKey;
- (int)currentAnimation;
@end

@interface MPUNowPlayingArtworkView : UIView
@end

@interface SBFStaticWallpaperImageView : UIImageView
@end

static MPUNowPlayingArtworkView *artworkView = nil;
static SBFStaticWallpaperImageView *wallpaper = nil;
static UIImage *originalImage = nil;
static bool artworkIsAnimating = NO;
static bool wallPaperIsAnimating = NO;
