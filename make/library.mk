FAT_LIB_LIBRARY = $(ARCH_LIB_DIR)/lib$(FAT_LIB_NAME).a
FAT_LIB_ARCH_LIBS = $(J2OBJC_ARCHS:%=$(ARCH_BUILD_DIR)/%-lib$(FAT_LIB_NAME).a)

FAT_LIB_PLIST_DIR = $(ARCH_BUILD_DIR)/plists
FAT_LIB_PLISTS = \
  $(foreach src,$(FAT_LIB_SOURCES_RELATIVE),$(FAT_LIB_PLIST_DIR)/$(basename $(src)).plist)

FAT_LIB_MACOSX_SDK_DIR := $(shell bash $(SYSROOT_SCRIPT))
FAT_LIB_IPHONE_SDK_DIR := $(shell bash $(SYSROOT_SCRIPT) --iphoneos)
FAT_LIB_SIMULATOR_SDK_DIR := $(shell bash $(SYSROOT_SCRIPT) --iphonesimulator)

# If you can define different architectures and include them into arch_flags array
# e.g. FAT_LIB_IPHONEV7S_FLAGS = -arch armv7s -miphoneos-version-min=5.0 -isysroot $(FAT_LIB_IPHONE_SDK_DIR)
FAT_LIB_IPHONE64_FLAGS = -arch arm64 -miphoneos-version-min=14.0 -isysroot $(FAT_LIB_IPHONE_SDK_DIR)
FAT_LIB_SIMULATOR_FLAGS = -arch x86_64 -miphoneos-version-min=14.0 -isysroot $(FAT_LIB_SIMULATOR_SDK_DIR)
FAT_LIB_SIMULATORM1_FLAGS = -arch arm64 -target arm64-apple-ios14.0-simulator -miphoneos-version-min=14.0 -isysroot $(FAT_LIB_SIMULATOR_SDK_DIR)
FAT_LIB_XCODE_FLAGS = $(ARCH_FLAGS) -miphoneos-version-min=14.0 -isysroot $(SDKROOT)

ifdef FAT_LIB_PRECOMPILED_HEADER
#ifndef CONFIGURATION_BUILD_DIR
J2OBJC_PRECOMPILED_HEADER = $(FAT_LIB_PRECOMPILED_HEADER)
#endif
endif

# Command-line pattern for calling libtool and filtering the "same member name"
# errors from having object files of the same name. (but in different directory)
fat_lib_filtered_libtool = set -o pipefail && $(LIBTOOL) -static -o $1 -filelist $2 2>&1 \
  | (grep -v "same member name" || true)

ifneq ($(MAKECMDGOALS),clean)

arch_flags = $(strip \
  $(patsubst iphone64,$(FAT_LIB_IPHONE64_FLAGS),\
  $(patsubst simulator,$(FAT_LIB_SIMULATOR_FLAGS),\
  $(patsubst simulatorm1,$(FAT_LIB_SIMULATORM1_FLAGS),$(1)))))

fat_lib_dependencies:
	@:

# Generates compile rule.
# Args:
#   1: output directory
#   2: input directory
#   3: precompiled header file, if J2OBJC_PRECOMPILED_HEADER is defined
#   4: precompiled header include, if J2OBJC_PRECOMPILED_HEADER is defined
#   5: other compiler flags
define compile_rule
$(1)/%.o: $(2)/%.m $(3) | fat_lib_dependencies
	@mkdir -p $$(@D)
	$(FAT_LIB_COMPILE) $(4) $(5) -MD -c $$< -o $$@

$(1)/%.o: $(2)/%.mm $(3) | fat_lib_dependencies
	@mkdir -p $$(@D)
	$(FAT_LIB_COMPILE) -x objective-c++ $(4) $(5) -MD -c $$< -o $$@
endef

# Generates rule to build precompiled headers file.
# Args:
#   1: output file name
#   2: input file
#   3: other compiler flags
define compile_pch_rule
$(1): $(2) | fat_lib_dependencies
	@mkdir -p $$(@D)
	$(FAT_LIB_COMPILE) -x objective-c-header $(3) -MD -c $$< -o $$@
endef

# Generates analyze rule.
# Args:
#   1: source directory
define analyze_rule
$(FAT_LIB_PLIST_DIR)/%.plist: $(1)/%.m | fat_lib_dependencies
	@mkdir -p $$(@D)
	$(FAT_LIB_COMPILE) $(STATIC_ANALYZER_FLAGS) -c $$< -o $$@

$(FAT_LIB_PLIST_DIR)/%.plist: $(1)/%.mm | fat_lib_dependencies
	@mkdir -p $$(@D)
	$(FAT_LIB_COMPILE) -x objective-c++ $(STATIC_ANALYZER_FLAGS) -c $$< -o $$@
endef

$(foreach src_dir,$(FAT_LIB_SOURCE_DIRS),$(eval $(call analyze_rule,$(src_dir))))

# Generates compile rules.
# Args:
#   1: output directory
#   2: compilation flags
emit_general_compile_rules = $(foreach src_dir,$(FAT_LIB_SOURCE_DIRS),\
  $(eval $(call compile_pch_rule,$(1)/%.pch,$(src_dir)/%,$(2)))\
  $(if $(J2OBJC_PRECOMPILED_HEADER),\
  $(eval $(call compile_rule,$(1),$(src_dir),\
    $(1)/$(J2OBJC_PRECOMPILED_HEADER).pch,\
    -include $(1)/$(J2OBJC_PRECOMPILED_HEADER),$(2))),\
  $(eval $(call compile_rule,$(1),$(src_dir),,,$(2)))))

FAT_LIB_OBJS = $(foreach file,$(FAT_LIB_SOURCES_RELATIVE),$(basename $(file)).o)

ifdef TARGET_TEMP_DIR
# Targets specific to an xcode build

-include $(FAT_LIB_OBJS:%.o=$(TARGET_TEMP_DIR)/%.d)
-include $(TARGET_TEMP_DIR)/$(J2OBJC_PRECOMPILED_HEADER).d

$(FAT_LIB_LIBRARY): $(FAT_LIB_OBJS:%=$(TARGET_TEMP_DIR)/%)
	@mkdir -p $(@D)
	@echo "Building $(notdir $@)"
	$(call long_list_to_file,$(ARCH_BUILD_DIR)/fat_lib_objs_list,$^)
	$(call fat_lib_filtered_libtool,$@,$(ARCH_BUILD_DIR)/fat_lib_objs_list)

$(call emit_general_compile_rules,$(TARGET_TEMP_DIR),$(FAT_LIB_XCODE_FLAGS))

else
# Targets specific to a command-line build

$(FAT_LIB_LIBRARY): $(FAT_LIB_ARCH_LIBS)
	$(LIPO) -create $^ -output $@

define arch_lib_rule
-include $(FAT_LIB_OBJS:%.o=$(ARCH_BUILD_DIR)/objs-$(1)/%.d)
-include $(ARCH_BUILD_DIR)/objs-$(1)/$(J2OBJC_PRECOMPILED_HEADER).d

$(ARCH_BUILD_DIR)/$(1)-lib$(FAT_LIB_NAME).a: \
    $(J2OBJC_PRECOMPILED_HEADER:%=$(ARCH_BUILD_DIR)/objs-$(1)/%.pch) \
    $(FAT_LIB_OBJS:%=$(ARCH_BUILD_DIR)/objs-$(1)/%)
	@echo "Building $$(notdir $$@)"
	$$(call long_list_to_file,$(ARCH_BUILD_DIR)/objs-$(1)/fat_lib_objs_list,\
	  $(FAT_LIB_OBJS:%=$(ARCH_BUILD_DIR)/objs-$(1)/%))
	$$(call fat_lib_filtered_libtool,$$@,$(ARCH_BUILD_DIR)/objs-$(1)/fat_lib_objs_list)
endef

$(foreach arch,$(J2OBJC_ARCHS),$(eval $(call arch_lib_rule,$(arch))))

$(foreach arch,$(J2OBJC_ARCHS),\
  $(call emit_general_compile_rules,$(ARCH_BUILD_DIR)/objs-$(arch),$(call arch_flags,$(arch))))

endif

analyze: $(FAT_LIB_PLISTS)
	@:

endif  # ifneq ($(MAKECMDGOALS),clean)
