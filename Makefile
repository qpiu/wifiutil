include $(THEOS)/makefiles/common.mk

TOOL_NAME = wifiutil
wifiutil_FILES = $(wildcard src/*.m*)
wifiutil_PRIVATE_FRAMEWORKS = MobileWiFi
wifiutil_CODESIGN_FLAGS = -Ssrc/entitlements.xml

ADDITIONAL_CFLAGS = -I$(THEOS_PROJECT_DIR)/headers/

include $(THEOS_MAKE_PATH)/tool.mk
