/* Linux controller vibration, using the selected GameMaker controller GUID. */
#include <errno.h>
#include <fcntl.h>
#include <glob.h>
#include <linux/input.h>
#include <math.h>
#include <stdint.h>
#include <string.h>
#include <sys/ioctl.h>
#include <time.h>
#include <unistd.h>

#define PUBLIC __attribute__((visibility("default")))

static int device_fd = -1, effect_id = -1, playing;
static uint16_t last_strong, last_weak;
static uint64_t next_scan, next_refresh;
static char selected_guid[33];

static uint64_t milliseconds(void) {
    struct timespec value;
    if (clock_gettime(CLOCK_MONOTONIC, &value) < 0) return 0;
    return (uint64_t)value.tv_sec * 1000 + value.tv_nsec / 1000000;
}

static int hex_digit(char c) {
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    return -1;
}

static int controller_id(const char *guid, struct input_id *id) {
    if (!guid || strlen(guid) != 32) return 0;
    unsigned char bytes[16];
    for (int i = 0; i < 16; ++i) {
        int high = hex_digit(guid[2 * i]), low = hex_digit(guid[2 * i + 1]);
        if (high < 0 || low < 0) return 0;
        bytes[i] = (unsigned char)(16 * high + low);
    }
    id->bustype = bytes[0] | (bytes[1] << 8);
    id->vendor = bytes[4] | (bytes[5] << 8);
    id->product = bytes[8] | (bytes[9] << 8);
    id->version = bytes[12] | (bytes[13] << 8);
    return id->bustype != 0;
}

static int play_effect(int value) {
    struct input_event event = {0};
    event.type = EV_FF;
    event.code = (unsigned short)effect_id;
    event.value = value;
    ssize_t count;
    do { count = write(device_fd, &event, sizeof(event)); } while (count < 0 && errno == EINTR);
    return count == sizeof(event);
}

static void close_device(void) {
    if (device_fd >= 0) {
        if (effect_id >= 0) {
            if (playing) play_effect(0);
            ioctl(device_fd, EVIOCRMFF, effect_id);
        }
        close(device_fd);
    }
    device_fd = effect_id = -1;
    playing = 0;
    last_strong = last_weak = 0;
    next_refresh = 0;
}

PUBLIC double AM2ARM_RumbleStop(void) {
    close_device();
    selected_guid[0] = 0;
    next_scan = 0;
    return 0;
}

static int open_controller(const struct input_id *wanted) {
    glob_t paths = {0};
    if (glob("/dev/input/event*", 0, NULL, &paths) != 0) {
        globfree(&paths);
        return -1;
    }
    int found = -1, matches = 0;
    for (size_t i = 0; i < paths.gl_pathc; ++i) {
        int fd = open(paths.gl_pathv[i], O_RDWR | O_CLOEXEC | O_NONBLOCK);
        if (fd < 0) continue;
        struct input_id actual;
        unsigned long capabilities[(FF_CNT + 8 * sizeof(unsigned long) - 1) / (8 * sizeof(unsigned long))] = {0};
        int slots = 0;
        if (ioctl(fd, EVIOCGID, &actual) < 0 ||
            actual.bustype != wanted->bustype || actual.vendor != wanted->vendor ||
            actual.product != wanted->product || actual.version != wanted->version ||
            ioctl(fd, EVIOCGBIT(EV_FF, sizeof(capabilities)), capabilities) < 0 ||
            !(capabilities[FF_RUMBLE / (8 * sizeof(unsigned long))] &
              (1UL << (FF_RUMBLE % (8 * sizeof(unsigned long))))) ||
            ioctl(fd, EVIOCGEFFECTS, &slots) < 0 || slots < 1) {
            close(fd);
            continue;
        }
        ++matches;
        if (matches == 1) found = fd;
        else {
            /* Identical pads cannot be distinguished by the supplied GUID. */
            close(fd);
            if (found >= 0) close(found);
            found = -1;
        }
    }
    globfree(&paths);
    return found;
}

static uint16_t magnitude(double value) {
    if (!isfinite(value) || value <= 0) return 0;
    if (value >= 1) return 65535;
    return (uint16_t)(value * 65535 + .5);
}

PUBLIC double AM2ARM_Rumble(const char *guid, double strong, double weak) {
    uint16_t strong_value = magnitude(strong), weak_value = magnitude(weak);
    struct input_id wanted;
    if ((!strong_value && !weak_value) || !controller_id(guid, &wanted))
        return AM2ARM_RumbleStop();
    uint64_t now = milliseconds();
    if (!now) return AM2ARM_RumbleStop();
    if (strcmp(guid, selected_guid)) {
        close_device();
        memcpy(selected_guid, guid, sizeof(selected_guid));
        next_scan = 0;
    }
    if (device_fd < 0) {
        if (now < next_scan) return 0;
        next_scan = now + 5000;
        device_fd = open_controller(&wanted);
        if (device_fd < 0) return 0;
    }
    int changed = effect_id < 0 || strong_value != last_strong || weak_value != last_weak;
    if (changed) {
        struct ff_effect effect = {0};
        effect.type = FF_RUMBLE;
        effect.id = (short)effect_id;
        /* Expire if the game stalls, loses focus, or cannot send another update. */
        effect.replay.length = 600;
        effect.u.rumble.strong_magnitude = strong_value;
        effect.u.rumble.weak_magnitude = weak_value;
        if (ioctl(device_fd, EVIOCSFF, &effect) < 0) goto failed;
        effect_id = effect.id;
        last_strong = strong_value;
        last_weak = weak_value;
    }
    if (changed || now >= next_refresh) {
        if (!play_effect(1)) goto failed;
        playing = 1;
        next_refresh = now + 250;
    }
    return 1;
failed:
    close_device();
    next_scan = now + 5000;
    return 0;
}

__attribute__((destructor)) static void release_rumble(void) {
    AM2ARM_RumbleStop();
}
