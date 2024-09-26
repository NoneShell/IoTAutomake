SRC_DIR := $(CURDIR)/src
PREBUILDS_DIR := $(CURDIR)/prebuilds
PATCH_DIR := $(CURDIR)/patches

GDB_DIR := $(SRC_DIR)/gdb
GDBSERVER_DIR := $(GDB_DIR)/gdb/gdbserver
GDB_URL := https://ftp.gnu.org/gnu/gdb/gdb-8.0.1.tar.gz
GDB_TAR := $(SRC_DIR)/gdb.tar.gz

STRACE_DIR := $(SRC_DIR)/strace
STRACE_URL := https://strace.io/files/5.10/strace-5.10.tar.xz
STRACE_TAR := $(SRC_DIR)/strace.tar.xz

LTRACE_DIR := $(SRC_DIR)/ltrace
LTRACE_URL := https://ltrace.org/ltrace_0.7.3.orig.tar.bz2
LTRACE_TAR := $(SRC_DIR)/ltrace.tar.bz2

BUSYBOX_DIR := $(SRC_DIR)/busybox
BUSYBOX_URL := https://busybox.net/downloads/busybox-1.30.0.tar.bz2
BUSYBOX_TAR := $(SRC_DIR)/busybox.tar.bz2

HOST ?= x86_64-linux
CONFIGURE_FLAGS ?= CFLAGS='-fPIC -s' LDFLAGS='-static'

all: gdbserver strace ltrace busybox

move_binary:
	@echo "Getting architecture information for $(BINARY)..."
	@ARCH_INFO=$$(file $(BINARY) | awk -F ': ' '{print $$2}'); \
	ARCH_DIR=$$(echo $$ARCH_INFO | sed -E 's/([0-9]+)-bit ([A-Z]+) executable, ([^,]+), ([^,]+).*/\1-\2-\3-\4/; s/ /_/g; s/_\([^)]*\)//g'); \
	MOVE_DIR=$(PREBUILDS_DIR)/$$ARCH_DIR; \
	mkdir -p $$MOVE_DIR; \
	cp $(BINARY) $$MOVE_DIR/; \
	echo "$(BINARY) has been moved to $$MOVE_DIR"

# for gdbserver
$(GDB_TAR):
	@echo "Downloading GDB source code..."
	@wget -q -O $(GDB_TAR) $(GDB_URL)
	@if [ ! -f $(GDB_TAR) ]; then \
		echo "Failed to download GDB source code"; \
		exit 1; \
	fi

$(GDB_DIR): $(GDB_TAR)
	@echo "Extracting GDB source code..."
	@mkdir -p $(GDB_DIR)
	@tar -xzf $(GDB_TAR) -C $(GDB_DIR) --strip-components=1
	@if [ ! -d $(GDB_DIR) ]; then \
		echo "Failed to extract GDB source code"; \
		exit 1; \
	fi

configure_gdb: $(GDB_DIR)
	@echo "Patching GDB source code..."
	@for patch in $(PATCH_DIR)/gdb-patch-*; do \
		if patch --force --dry-run -d $(GDB_DIR) -p0 < $$patch; then \
			echo "Applying $$patch..."; \
			patch --force -d $(GDB_DIR) -p0 < $$patch || (rm -r $(GDB_DIR) && exit 1); \
		else \
			echo "Patch $$patch has already been applied"; \
		fi; \
	done
	@echo "Configuring GDB source code..."
	@cd $(GDBSERVER_DIR) && ./configure --host=$(HOST) $(CONFIGURE_FLAGS)

gdbserver: configure_gdb
	@echo "Compiling gdbserver..."
	@cd $(GDBSERVER_DIR) && make clean && make -j$(shell nproc)
	@if [ ! -f $(GDBSERVER_DIR)/gdbserver ]; then \
		echo "Failed to compile gdbserver"; \
		exit 1; \
	fi
	@$(MAKE) move_binary BINARY=$(GDBSERVER_DIR)/gdbserver

# for strace
$(STRACE_TAR):
	@echo "Downloading strace source code..."
	@wget -q -O $(STRACE_TAR) $(STRACE_URL)
	@if [ ! -f $(STRACE_TAR) ]; then \
		echo "Failed to download strace source code"; \
		exit 1; \
	fi

$(STRACE_DIR): $(STRACE_TAR)
	@echo "Extracting strace source code..."
	@mkdir -p $(STRACE_DIR)
	@tar -xJf $(STRACE_TAR) -C $(STRACE_DIR) --strip-components=1
	@if [ ! -d $(STRACE_DIR) ]; then \
		echo "Failed to extract GDB source code"; \
		exit 1; \
	fi

configure_strace: $(STRACE_DIR)
	@echo "Configuring strace source code..."
	@cd $(STRACE_DIR) && ./configure --host=$(HOST) $(CONFIGURE_FLAGS)

strace: configure_strace
	@echo "Compiling strace..."
	@cd $(STRACE_DIR) && make clean && make -j$(shell nproc)
	@if [ ! -f $(STRACE_DIR)/strace ]; then \
		echo "Failed to compile strace"; \
		exit 1; \
	fi
	@$(MAKE) move_binary BINARY=$(STRACE_DIR)/strace


# for ltrace
$(LTRACE_TAR):
	@echo "Downloading ltrace source code..."
	@wget -q -O $(LTRACE_TAR) $(LTRACE_URL)
	@if [ ! -f $(LTRACE_TAR) ]; then \
		echo "Failed to download ltrace source code"; \
		exit 1; \
	fi

$(LTRACE_DIR): $(LTRACE_TAR)
	@echo "Extracting strace source code..."
	@mkdir -p $(LTRACE_DIR)
	@tar -xjf $(LTRACE_TAR) -C $(LTRACE_DIR) --strip-components=1
	@if [ ! -d $(LTRACE_DIR) ]; then \
		echo "Failed to extract ltrace source code"; \
		exit 1; \
	fi

configure_ltrace: $(LTRACE_DIR)
	@echo "Configuring ltrace source code..."
	@cd $(LTRACE_DIR)/config/autoconf && \
		wget http://git.savannah.gnu.org/gitweb/\?p\=config.git\;a\=blob_plain\;f\=config.sub\;hb\=HEAD -O config.sub && \
		wget http://git.savannah.gnu.org/gitweb/\?p\=config.git\;a\=blob_plain\;f\=config.guess\;hb\=HEAD -O config.guess
	@cd $(LTRACE_DIR) && ./configure --host=$(HOST) CFLAGS="-Wno-error -Wl,-static -static-libgcc -static" LDFLAGS="-static -s"

ltrace: configure_ltrace
	@echo "Compiling ltrace..."
	@cd $(LTRACE_DIR) && make clean && make -j$(shell nproc)
	@if [ ! -f $(LTRACE_DIR)/ltrace ]; then \
		echo "Failed to compile ltrace"; \
		exit 1; \
	fi
	@$(MAKE) move_binary BINARY=$(LTRACE_DIR)/ltrace

# for busybox
$(BUSYBOX_TAR):
	@echo "Downloading busybox source code..."
	@wget -q -O $(BUSYBOX_TAR) $(BUSYBOX_URL)
	@if [ ! -f $(BUSYBOX_TAR) ]; then \
		echo "Failed to download busybox source code"; \
		exit 1; \
	fi

$(BUSYBOX_DIR): $(BUSYBOX_TAR)
	@echo "Extracting busybox source code..."
	@mkdir -p $(BUSYBOX_DIR)
	@tar -xjf $(BUSYBOX_TAR) -C $(BUSYBOX_DIR) --strip-components=1
	@if [ ! -d $(BUSYBOX_DIR) ]; then \
		echo "Failed to extract busybox source code"; \
		rm -r $(BUSYBOX_DIR); \
		exit 1; \
	fi

busybox: $(BUSYBOX_DIR)
	@echo "Patching BUSYBOX source code..."
	@cd $(BUSYBOX_DIR) && make defconfig
	@for patch in $(PATCH_DIR)/busybox-patch-*; do \
		if patch --force --dry-run -d $(BUSYBOX_DIR) -p0 < $$patch; then \
			echo "Applying $$patch..."; \
			patch --force -d $(BUSYBOX_DIR) -p0 < $$patch || (rm -r $(BUSYBOX_DIR) && exit 1); \
		else \
			echo "Patch $$patch has already been applied"; \
		fi; \
	done
	@echo "Compiling busybox..."
	@cd $(BUSYBOX_DIR) && make clean && make CROSS_COMPILE=$(HOST)- -j$(shell nproc)
	@if [ ! -f $(BUSYBOX_DIR)/busybox ]; then \
		echo "Failed to compile busybox"; \
		exit 1; \
	fi
	@$(MAKE) move_binary BINARY=$(BUSYBOX_DIR)/busybox


clean:
	@rm -rf $(SRC_DIR)/*
	@echo "Cleaned up"