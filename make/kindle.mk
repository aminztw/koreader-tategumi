KINDLE_DIR = $(PLATFORM_DIR)/kindle
KINDLE_PACKAGE = koreader-$(DIST)$(KODEDUG_SUFFIX)-$(VERSION).zip

# Don't bundle launchpad on touch devices..
ifeq ($(TARGET), kindle-legacy)
  KINDLE_LEGACY_LAUNCHER = launchpad
endif

ifneq (,$(filter kindlehf kindlepw2,$(TARGET)))
  KINDLE_SCRIPTLET_DIR = documents
endif

define UPDATE_PATH_EXCLUDES +=
tools
endef

update-prepare: all
	# ensure that the binaries were built for ARM
	file --dereference $(INSTALL_DIR)/koreader/luajit | grep ARM
	# Kindle launching scripts
	$(SYMLINK) $(KINDLE_DIR)/extensions $(INSTALL_DIR)/
	$(SYMLINK) $(KINDLE_DIR)/launchpad $(INSTALL_DIR)/
	$(SYMLINK) $(KINDLE_DIR)/koreader.sh $(INSTALL_DIR)/koreader/
	$(SYMLINK) $(KINDLE_DIR)/libkohelper.sh $(INSTALL_DIR)/koreader/
	$(SYMLINK) $(KINDLE_DIR)/libkohelper.sh $(INSTALL_DIR)/extensions/koreader/bin/
	$(SYMLINK) $(KINDLE_DIR)/wmctrl $(INSTALL_DIR)/koreader/

ifneq (,$(KINDLE_SCRIPTLET_DIR))
	install -D -m 755 "$(KINDLE_DIR)/library-launcher.sh" "$(INSTALL_DIR)/documents/KOReader-TW.sh"
endif

update-zip: update-prepare
	$(strip $(call mkupdate,$(KINDLE_PACKAGE))) extensions $(KINDLE_LEGACY_LAUNCHER) $(KINDLE_SCRIPTLET_DIR)

update: update-zip
