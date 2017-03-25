export ARCHS = armv7 arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = animovani
animovani_FILES = Tweak.xm
animovani_FRAMEWORKS = UIKit MediaPlayer
animovani_PRIVATE_FRAMEWORKS = UIKit MediaPlayer
animovani_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
