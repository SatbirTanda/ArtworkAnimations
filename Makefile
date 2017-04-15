export ARCHS = armv7 arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ArtworkAnimations
ArtworkAnimations_FILES = Tweak.xm
ArtworkAnimations_FRAMEWORKS = Foundation UIKit MediaPlayer QuartzCore
ArtworkAnimations_CFLAGS = "-Wno-error"

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += ArtworkAnimations
include $(THEOS_MAKE_PATH)/aggregate.mk
