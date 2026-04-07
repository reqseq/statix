#
# Statix top-level build file.
#
# Common targets:
#   make            Build the default disk image
#   make run        Build and launch under QEMU
#   make clean      Remove generated files
#   make help       Show available targets and knobs
#

SHELL := /bin/sh

.SUFFIXES:
.DEFAULT_GOAL := all
.DELETE_ON_ERROR:

MAKEFLAGS += -rR

unexport LC_ALL
LC_COLLATE := C
LC_NUMERIC := C
export LC_COLLATE LC_NUMERIC
unexport GREP_OPTIONS

this-makefile := $(lastword $(MAKEFILE_LIST))
srctree       := $(abspath $(dir $(this-makefile)))
KBUILD_OUTPUT := $(or $(O),$(KBUILD_OUTPUT))
objtree       := $(if $(KBUILD_OUTPUT),$(abspath $(KBUILD_OUTPUT)),$(CURDIR))

ARCH          ?= x86
ARCHDIR       := $(srctree)/arch/$(ARCH)
CROSS_COMPILE ?=

CC      := $(or $(CC),$(CROSS_COMPILE)gcc)
AS      := $(or $(AS),$(CROSS_COMPILE)as)
LD      := $(or $(LD),$(CROSS_COMPILE)ld)
OBJCOPY := $(or $(OBJCOPY),$(CROSS_COMPILE)objcopy)
GDB     := $(or $(GDB),$(CROSS_COMPILE)gdb)
QEMU    := $(or $(QEMU),qemu-system-i386)

MKDIR_P := $(or $(MKDIR_P),mkdir -p)
RM      := $(or $(RM),rm -f)
CAT     := $(or $(CAT),cat)
DD      := $(or $(DD),dd)

obj := $(objtree)/build
img := $(objtree)/images

BOOT_ELF   := $(obj)/boot.elf
BOOT_BIN   := $(obj)/boot.bin
KERNEL_ELF := $(obj)/kernel.elf
KERNEL_BIN := $(obj)/kernel.bin
IMAGE      := $(img)/statix.img

BOOT_LDSCRIPT   := $(ARCHDIR)/boot/boot.ld
KERNEL_LDSCRIPT := $(ARCHDIR)/kernel/kernel.ld
GDB_SETUP       := $(srctree)/scripts/gdb_setup.gdb
GDB_PORT        ?= 1234

KBUILD_CPPFLAGS := -I$(srctree)/include
KBUILD_CFLAGS   := -m32 -ffreestanding -O2 -g -Wall -Wextra -fno-pie -fno-pic \
		   -fno-stack-protector -fno-omit-frame-pointer \
		   -ffile-prefix-map=$(srctree)=
KBUILD_AFLAGS   := --32 -g
KBUILD_LDFLAGS  := -m elf_i386

KCFLAGS ?=
KAFLAGS ?=
QEMUFLAGS ?=

CPPFLAGS += $(KBUILD_CPPFLAGS)
CFLAGS   += $(KBUILD_CFLAGS) $(KCFLAGS)
ASFLAGS  += $(KBUILD_AFLAGS) $(KAFLAGS)
LDFLAGS  += $(KBUILD_LDFLAGS)

DEPFLAGS := -MMD -MP

head-y := $(obj)/arch/$(ARCH)/kernel/entry.o
boot-y := $(obj)/arch/$(ARCH)/boot/boot.o
core-y := $(patsubst $(srctree)/%.c,$(obj)/%.o,$(sort $(wildcard $(srctree)/kernel/*.c)))
drivers-y := $(patsubst $(srctree)/%.c,$(obj)/%.o,$(sort $(wildcard $(srctree)/drivers/*.c $(srctree)/drivers/*/*.c)))
arch-y := $(filter-out $(head-y),$(patsubst $(srctree)/%.S,$(obj)/%.o,$(sort $(wildcard $(ARCHDIR)/kernel/*.S))))

kernel-y := $(head-y) $(arch-y) $(core-y) $(drivers-y)
deps-y   := $(core-y:.o=.d) $(drivers-y:.o=.d)

QEMU_OPTS := -drive format=raw,file=$(IMAGE) -serial mon:stdio $(QEMUFLAGS)

ifeq ($(origin V),command line)
KBUILD_VERBOSE := $(V)
endif

quiet := quiet_
Q := @

ifneq ($(findstring 1,$(KBUILD_VERBOSE)),)
quiet :=
Q :=
endif

ifneq ($(findstring s,$(firstword -$(MAKEFLAGS))),)
quiet := silent_
override KBUILD_VERBOSE :=
endif

export Q V KBUILD_VERBOSE

ifeq ($(quiet),quiet_)
quiet_msg = @printf '  %-7s %s\n' '$(1)' '$(2)'
cmd_status = printf '  %-7s %s\n' '$(word 1,$(quiet_cmd_$(1)))' '$(wordlist 2,999,$(quiet_cmd_$(1)))';
else
quiet_msg =
endif

quiet_rel     = $(patsubst $(srctree)/%,%,$(1))
quiet_rel_obj = $(patsubst $(objtree)/%,%,$(1))

ifneq ($(objtree),$(CURDIR))
NEED_OBJTREE := 1
endif

export srctree objtree ARCH CROSS_COMPILE

quiet_cmd_as_o_S      = AS      $(call quiet_rel,$<)
      cmd_as_o_S      = $(MKDIR_P) $(dir $@); \
			$(AS) $(ASFLAGS) $< -o $@

quiet_cmd_cc_o_c      = CC      $(call quiet_rel,$<)
      cmd_cc_o_c      = $(MKDIR_P) $(dir $@); \
			$(CC) $(CPPFLAGS) $(CFLAGS) $(DEPFLAGS) -c $< -o $@ -MF $(@:.o=.d)

quiet_cmd_ld_boot     = LD      $(call quiet_rel_obj,$@)
      cmd_ld_boot     = $(MKDIR_P) $(dir $@); \
			$(LD) $(LDFLAGS) -T $(BOOT_LDSCRIPT) $< -o $@

quiet_cmd_objcopy     = OBJCOPY $(call quiet_rel_obj,$@)
      cmd_objcopy     = $(OBJCOPY) -O binary $< $@

quiet_cmd_ld_kernel   = LD      $(call quiet_rel_obj,$@)
      cmd_ld_kernel   = $(MKDIR_P) $(dir $@); \
			$(LD) $(LDFLAGS) -T $(KERNEL_LDSCRIPT) $(kernel-y) -o $@

quiet_cmd_image       = GEN     $(call quiet_rel_obj,$@)
      cmd_image       = $(MKDIR_P) $(dir $@); \
			$(CAT) $(BOOT_BIN) $(KERNEL_BIN) > $@; \
			$(DD) if=/dev/zero bs=512 count=10 >> $@ 2>/dev/null

ifeq ($(quiet),quiet_)
cmd = $(cmd_status) $(cmd_$(1))
else
cmd = $(cmd_$(1))
endif

.PHONY: all boot kernel image clean distclean help \
	run run-headless run-qemu run-qemu-headless \
	run-debug run-qemu-debug run-qemu-debug-headless \
	connect-gdb check-tools toolchain-check

all: image

image: $(IMAGE)
	@printf '\nDisk image ready: %s\n' '$(call quiet_rel_obj,$(IMAGE))'

boot: $(BOOT_BIN)

kernel: $(KERNEL_ELF) $(KERNEL_BIN)

$(obj)/%.o: $(srctree)/%.S
	$(Q)$(call cmd,as_o_S)

$(obj)/%.o: $(srctree)/%.c
	$(Q)$(call cmd,cc_o_c)

$(BOOT_ELF): $(boot-y) $(BOOT_LDSCRIPT)
	$(Q)$(call cmd,ld_boot)

$(BOOT_BIN): $(BOOT_ELF)
	$(Q)$(call cmd,objcopy)

$(KERNEL_ELF): $(kernel-y) $(KERNEL_LDSCRIPT)
	$(Q)$(call cmd,ld_kernel)

$(KERNEL_BIN): $(KERNEL_ELF)
	$(Q)$(call cmd,objcopy)

$(IMAGE): $(BOOT_BIN) $(KERNEL_BIN)
	$(Q)$(call cmd,image)

run: run-qemu

run-qemu: $(IMAGE)
	@printf '\nSerial below. QEMU monitor: Ctrl+A C | Exit: Ctrl+A X\n\n'
	$(Q)$(QEMU) $(QEMU_OPTS)

run-headless: run-qemu-headless

run-qemu-headless: $(IMAGE)
	@printf '\nSerial below. QEMU monitor: Ctrl+A C | Exit: Ctrl+A X\n\n'
	$(Q)$(QEMU) $(QEMU_OPTS) -nographic

run-debug: run-qemu-debug

run-qemu-debug: $(IMAGE)
	@printf 'Starting QEMU (debug, waiting for GDB on port %s)...\n' '$(GDB_PORT)'
	@printf 'Connect with: make connect-gdb\n\n'
	@printf 'Serial below. QEMU monitor: Ctrl+A C | Exit: Ctrl+A X\n\n'
	$(Q)$(QEMU) $(QEMU_OPTS) -gdb tcp::$(GDB_PORT) -S

run-qemu-debug-headless: $(IMAGE)
	@printf 'Starting QEMU (debug headless, GDB on port %s)...\n' '$(GDB_PORT)'
	@printf 'Connect with: make connect-gdb\n\n'
	$(Q)$(QEMU) $(QEMU_OPTS) -nographic -gdb tcp::$(GDB_PORT) -S

connect-gdb: $(KERNEL_ELF)
	$(GDB) -q \
		-ex "source $(GDB_SETUP)" \
		-ex "file $(KERNEL_ELF)" \
		-ex "target remote localhost:$(GDB_PORT)" \
		-ex "b _start" \
		-ex "b kernel_main"

clean:
	@printf '  CLEAN   %s %s\n' \
		'$(call quiet_rel_obj,$(obj))' \
		'$(call quiet_rel_obj,$(img))'
	$(Q)$(RM) -r $(obj) $(img)

distclean: clean

CHECK_TOOLS := $(CC) $(AS) $(LD) $(OBJCOPY) $(GDB) $(QEMU)

check-tools: toolchain-check

toolchain-check:
	@printf '=== Toolchain Check ===\n'
	@for tool in $(CHECK_TOOLS); do \
		printf '%-24s' "$$tool:"; \
		if command -v "$$tool" >/dev/null 2>&1; then \
			printf 'OK\n'; \
		else \
			printf 'NOT FOUND\n'; \
		fi; \
	done
	@printf '\n'

help:
	@printf 'Statix build system\n\n'
	@printf 'Source tree: %s\n' '$(srctree)'
	@printf 'Object tree: %s\n\n' '$(objtree)'
	@printf 'Targets:\n'
	@printf '  %-24s %s\n' 'all' 'Build $(call quiet_rel_obj,$(IMAGE))'
	@printf '  %-24s %s\n' 'boot' 'Build the boot sector binary'
	@printf '  %-24s %s\n' 'kernel' 'Build the kernel ELF and flat binary'
	@printf '  %-24s %s\n' 'image' 'Build $(call quiet_rel_obj,$(IMAGE))'
	@printf '  %-24s %s\n' 'run' 'Build and launch QEMU'
	@printf '  %-24s %s\n' 'run-headless' 'Launch QEMU with -nographic'
	@printf '  %-24s %s\n' 'run-qemu-debug' 'Launch QEMU and wait for GDB on tcp::$(GDB_PORT)'
	@printf '  %-24s %s\n' 'run-qemu-debug-headless' 'Launch debug QEMU with -nographic'
	@printf '  %-24s %s\n' 'connect-gdb' 'Attach GDB to a waiting QEMU instance'
	@printf '  %-24s %s\n' 'toolchain-check' 'Verify required host tools'
	@printf '  %-24s %s\n' 'clean' 'Remove generated files'
	@printf '  %-24s %s\n\n' 'help' 'Show this help'
	@printf 'Variables:\n'
	@printf '  %-24s %s\n' 'O=DIR' 'Place build and image output under DIR'
	@printf '  %-24s %s\n' 'KBUILD_OUTPUT=DIR' 'Same as O=DIR'
	@printf '  %-24s %s\n' 'CROSS_COMPILE=PREFIX' 'Tool prefix, e.g. i686-elf-'
	@printf '  %-24s %s\n' 'KCFLAGS=...' 'Extra C compiler flags'
	@printf '  %-24s %s\n' 'KAFLAGS=...' 'Extra assembler flags'
	@printf '  %-24s %s\n' 'LDFLAGS=...' 'Extra linker flags'
	@printf '  %-24s %s\n' 'QEMUFLAGS=...' 'Extra QEMU arguments'
	@printf '  %-24s %s\n' 'V=1' 'Enable verbose build output'

-include $(deps-y)
