#import <MediaPlayer/MPMusicPlayerController.h>

@interface SBLockScreenView
@property(readonly, retain, nonatomic) UIScrollView *scrollView;
@end

@interface _NowPlayingArtView: UIView
@property (nonatomic,retain) UIImageView* artworkView;
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