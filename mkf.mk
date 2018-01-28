CC=gcc
AS=gas
RM=rm -rf
PWD=$(shell pwd)
MKDIR=mkdir -p
BUILD_TARGET_DIR=$(PWD)/output
BUILD_TARGETS=$(build_dlls) $(build_bins)
BUILD_SOURCES=$(addprefix $(PWD)/, $(sort $(foreach srcs,$(addsuffix _sources, $(BUILD_TARGETS)), $($(srcs)))))
BUILD_CS=$(filter %.c, $(BUILD_SOURCES))
BUILD_ASMS=$(filter %.s, $(BUILD_SOURCES))
BUILD_OBJS=$(call OBJ_tmp, $(BUILD_SOURCES))
BUILD_DLLS=$(addsuffix .so, $(addprefix $(BUILD_TARGET_DIR)/lib, $(build_dlls)))
BUILD_BINS=$(addprefix $(BUILD_TARGET_DIR)/, $(build_bins))
BUILD_DIRS=$(addprefix sub_, $(build_dirs))
BUILD_ALLS=$(BUILD_DLLS) $(BUILD_BINS) $(BUILD_DIRS)
BUILD_LDEX:=
BUILD_LDFLAGS:=
BUILD_LDFLAGS= -Wl,-rpath-link=$(BUILD_LDEX)
BUILD_DLLS_LDFLAGS=$(BUILD_LDFLAGS) -fPIC -shared
BUILD_BINS_LDFLAGS=$(BUILD_LDFLAGS)
BUILD_MKF=$(firstword $(MAKEFILE_LIST))
BUILD_INCS=$(filter-out %deps, $(MAKEFILE_LIST))
BUILD_CFLAGS=$(BUILD_LDFLAGS)
ifneq ($(build_include),)
	BUILD_CFLAGS += $(build_include)
endif

## objs
define OBJ_tmp
$(addprefix $(BUILD_TARGET_DIR)/, $(addsuffix .o, $(notdir $(basename $(1)))))
endef

## c files
define C_tmp
$$(call OBJ_tmp, $(1)) $$(call OBJ_tmp, $(1)).dep: $(1) $(BUILD_INCS)
	@$(MKDIR) $(BUILD_TARGET_DIR)
	$(CC) -fPIC -shared -o $$(call OBJ_tmp, $(1)) $(1) $(BUILD_CFLAGS) -c -MMD -MP -MF $$(call OBJ_tmp, $(1)).dep
endef

## asm files
define ASM_tmp
$$(call OBJ_tmp, $(1)) $$(call OBJ_tmp, (1)).dep: $(1) $(BUILD_INCS)
	@$(MKDIR) $(BUILD_TARGET_DIR)
	$(AS) -c $$(call OBJ_tmp, $(1)) $(1)
	touch $$(call OBJ_tmp, (1)).dep
endef

## dirs
define DIR_tmp
.PHONY: sub_$(1)
$(1)_PREBUILD_DIRS=$$(addprefix sub_, $$($(1)_prebuild_dirs))
sub_$(1):$$($(1)_PREBUILD_DIRS)
	@make -C $(1)
endef


## dlls
define DLL_tmp
$(1)_BUILD_DLL=$(BUILD_TARGET_DIR)/lib$(1).so
$(1)_BUILD_DLL_OBJS=$$(call OBJ_tmp, $$($(1)_sources))
ifneq ($$($(1)_prebuild_so),)
$(1)_PREBUILD_SO=$$(addsuffix .so, $$(addprefix lib, $$($(1)_prebuild_so)))
endif

$$($(1)_BUILD_DLL):$$($(1)_BUILD_DLL_OBJS) $$($(1)_PREBUILD_SO)
	@$(MKDIR) $(BUILD_TARGET_DIR)
	$(CC) -o $$@ $$($(1)_BUILD_DLL_OBJS) $$(BUILD_DLLS_LDFLAGS)
endef

## bins
define BIN_tmp
$(1)_BUILD_BIN=$$(addprefix $(BUILD_TARGET_DIR)/, $(1))
$(1)_BUILD_BIN_OBJS=$$(call OBJ_tmp, $$($(1)_sources))
ifneq ($$($(1)_prebuild_so), )
$(1)_BUILD_BIN_PREBUILD_SO=$$(addsuffix .so, $$(addprefix lib, $$($(1)_prebuild_so)))
endif
$$($(1)_BUILD_BIN):$$($(1)_BUILD_BIN_OBJS) $$($(1)_BUILD_BIN_PREBUILD_SO)
	@$(MKDIR) $(BUILD_TARGET_DIR)
	$(CC) -o $$@ $$($(1)_BUILD_BIN_OBJS) $$($(1)_ld_so) $$(BUILD_BINS_LDFLAGS)
endef

all:$(BUILD_ALLS)
	
$(foreach dll, $(build_dlls), $(eval $(call DLL_tmp,$(dll))))
$(foreach bin, $(build_bins), $(eval $(call BIN_tmp,$(bin))))
$(foreach c, $(BUILD_CS), $(eval $(call C_tmp,$(c))))
$(foreach d, $(build_dirs), $(eval, $(call DIR_tmp,$(d))))
$(foreach asm, $(BUILD_ASMS), $(eval, $(call ASM_tmp,$(asm))))

BUILD_ALL_DEP=$(addsuffix .dep, $(BUILD_OBJS))
BUILD_DEPS=$(BUILD_TARGET_DIR)/deps
ifeq ($(filter %clean %cleanall, $(MAKECMDGOALS)), )
ifneq ($(BUILD_OBJS), )
-include $(BUILD_DEPS)

$(BUILD_DEPS):$(BUILD_ALL_DEP) $(BUILD_INCS)
	@$(MKDIR) $(BUILD_TARGET_DIR)
	@cat $(BUILD_ALL_DEP) > $@
endif
endif

.PHONY: clean clean-subdirs
clean: clean-subdirs
	$(RM) $(BUILD_TARGET_DIR)
	
clean-subdirs:
	@for d in $(build_dirs); do \
		$(MAKE) -C $${d} clean; \
	done





















