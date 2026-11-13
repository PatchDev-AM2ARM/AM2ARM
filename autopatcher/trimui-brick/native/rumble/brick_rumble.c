/* Brick motor routing; other controllers retain Linux force feedback. */
#include <math.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <time.h>
#include <unistd.h>

#define PUBLIC __attribute__((visibility("default")))

double AM2ARM_EvdevRumble(const char *, double, double);
double AM2ARM_EvdevRumbleStop(void);

static int motor_fd = -1, last_strength;
static double next_update;

static int send_strength(int strength) {
    if (motor_fd < 0) {
        const char *path = getenv("AM2ARM_RUMBLE_SOCKET");
        struct sockaddr_un address = {.sun_family = AF_UNIX};
        if (!path || strlen(path) >= sizeof(address.sun_path)) return 0;
        strcpy(address.sun_path, path);
        motor_fd = socket(AF_UNIX, SOCK_DGRAM | SOCK_CLOEXEC | SOCK_NONBLOCK, 0);
        if (motor_fd < 0) return 0;
        if (connect(motor_fd, (struct sockaddr *)&address, sizeof(address)) < 0) {
            close(motor_fd);
            motor_fd = -1;
            return 0;
        }
    }
    unsigned char value = (unsigned char)strength;
    if (send(motor_fd, &value, 1, MSG_NOSIGNAL) != 1) return 0;
    last_strength = strength;
    return 1;
}

PUBLIC double AM2ARM_RumbleStop(void) {
    if (last_strength) send_strength(0);
    next_update = 0;
    return AM2ARM_EvdevRumbleStop();
}

static double bounded(double value) {
    return !isfinite(value) || value < 0 ? 0 : value > 1 ? 1 : value;
}

PUBLIC double AM2ARM_Rumble(const char *guid, double strong, double weak) {
    const char *builtin = getenv("AM2ARM_RUMBLE_GUID");
    if (!builtin || !guid || strcmp(guid, builtin)) {
        if (last_strength) send_strength(0);
        return AM2ARM_EvdevRumble(guid, strong, weak);
    }
    AM2ARM_EvdevRumbleStop();
    int strength = (int)(fmax(bounded(strong), bounded(weak)) * 255 + .5);
    if (!strength) return AM2ARM_RumbleStop();
    struct timespec stamp;
    if (clock_gettime(CLOCK_MONOTONIC, &stamp) < 0) return AM2ARM_RumbleStop();
    double now = stamp.tv_sec + stamp.tv_nsec / 1000000000.;
    if (strength == last_strength && now < next_update) return 1;
    next_update = now + .25;
    return send_strength(strength);
}

__attribute__((destructor)) static void close_motor(void) {
    AM2ARM_RumbleStop();
    if (motor_fd >= 0) close(motor_fd);
}
