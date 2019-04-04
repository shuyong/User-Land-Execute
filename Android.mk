LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

#-UDEBUG
LOCAL_C_INCLUDES := process
LOCAL_CFLAGS     := -Wall -Wextra -fvisibility=hidden -D_FORTIFY_SOURCE=2 -DDEBUG
#LOCAL_LDFLAGS    := -Wl,-O2 -Wl,--as-needed -Wl,-Bsymbolic

LOCAL_ARM_NEON   := true

LIBUEXEC_SOURCES := \
	load_elf_binary.c \
	uland_execl.c \
	uland_execle.c \
	uland_execlp.c \
	uland_execv.c \
	uland_execve.c \
	uland_execvp.c \
	$(empty)

LOCAL_MODULE := uexec
LOCAL_SRC_FILES := $(addprefix process/, $(LIBUEXEC_SOURCES))

include $(BUILD_STATIC_LIBRARY)

include $(CLEAR_VARS)

#-UDEBUG
LOCAL_C_INCLUDES:= process
LOCAL_CFLAGS    := -Wall -Wextra -fvisibility=hidden -D_FORTIFY_SOURCE=2 -DDEBUG
LOCAL_LDFLAGS   := -Wl,-O2 -Wl,--as-needed -Wl,-Bsymbolic
#LOCAL_SHARED_LIBRARIES := uexec
LOCAL_STATIC_LIBRARIES := uexec
LOCAL_EXPORT_C_INCLUDES := process

LOCAL_ARM_NEON  := true

LOCAL_MODULE    := load_elf_binary
LOCAL_SRC_FILES := \
        test/main.c \
	$(empty)

include $(BUILD_EXECUTABLE)

