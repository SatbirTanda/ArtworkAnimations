export ARCHS = armv7 arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = animovani
animovani_FILES = Tweak.xm
animovani_FRAMEWORKS = UIKit MediaPlayer QuartzCore
animovani_CFLAGS = "-Wno-error"

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
