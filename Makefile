LOCAL_C_INCLUDES = -I process
CFLAGS = -Wall -Wextra -g -O2 -std=c99 $(LOCAL_C_INCLUDES)
CFLAGS += -ffunction-sections -funwind-tables -fstack-protector-strong -fPIC -Wno-invalid-command-line-argument -Wno-unused-command-line-argument -fvisibility=hidden -D_FORTIFY_SOURCE=2 -DDEBUG -Wa,--noexecstack -Wformat -Werror=format-security -fPIE
LDFLAGS = -Wl,--gc-sections -Wl,--build-id -Wl,--no-undefined -Wl,-z,noexecstack -Wl,-z,relro -Wl,-z,now -Wl,--warn-shared-textrel -Wl,--fatal-warnings -fPIE -pie  -Wl,-O2 -Wl,--as-needed -Wl,-Bsymbolic
LDLIBS = -L process -luexec -pthread

TARGETS = test/load_elf_binary

LOBJS = \
	process/load_elf_binary.o \
	process/uland_execl.o \
	process/uland_execle.o \
	process/uland_execlp.o \
	process/uland_execv.o \
	process/uland_execve.o \
	process/uland_execvp.o \
	$(empty)

OBJS = \
       test/main.o \
       $(empty)

all: $(TARGETS)

$(TARGETS) : $(OBJS) process/libuexec.a
	$(CC) $(CFLAGS) $(LDFLAGS) -o $(TARGETS) $(OBJS) $(LDLIBS)

process/libuexec.a : $(LOBJS)
	$(AR) rcs $@ $(LOBJS)
	@#$(RANLIB) $@

clean :
	rm -f $(TARGETS) $(OBJS) process/libuexec.a $(LOBJS)

%.o : %.c
	@$(CC) -c $(CFLAGS) $< -o $@

%.o : %.cpp
	@$(CXX) -c $(CXXFLAGS) $< -o $@

%.o : %.S
	@$(CC) -c $(CFLAGS) $< -o $@


.PHONY: all clean
