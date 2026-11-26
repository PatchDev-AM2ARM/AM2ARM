/* Sends vibration to the launcher when the controller can't play it. */
#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <time.h>
#include <unistd.h>

typedef struct _SDL_GameController SDL_GameController;

static int motor_fd = -1, last_strength;
static double next_update;
static SDL_GameController *owner;

static int send_strength(int strength) {
    if (motor_fd < 0) {
        const char *path = getenv("AM2ARM_RUMBLE_SOCKET");
        struct sockaddr_un address = {.sun_family = AF_UNIX};
        if (!path || strlen(path) >= sizeof(address.sun_path)) return -1;
        strcpy(address.sun_path, path);
        motor_fd = socket(AF_UNIX, SOCK_DGRAM | SOCK_CLOEXEC | SOCK_NONBLOCK, 0);
        if (motor_fd < 0) return -1;
        if (connect(motor_fd, (struct sockaddr *)&address, sizeof(address)) < 0) {
            close(motor_fd);
            motor_fd = -1;
            return -1;
        }
    }
    unsigned char value = (unsigned char)strength;
    if (send(motor_fd, &value, 1, MSG_NOSIGNAL) != 1) return -1;
    last_strength = strength;
    return 0;
}

__attribute__((visibility("default")))
int SDL_GameControllerRumble(SDL_GameController *controller, uint16_t low, uint16_t high, uint32_t duration) {
    static int (*rumble)(SDL_GameController *, uint16_t, uint16_t, uint32_t);
    if (!rumble) rumble = dlsym(RTLD_NEXT, "SDL_GameControllerRumble");
    if (rumble && rumble(controller, low, high, duration) == 0) return 0;

    int strength = (low > high ? low : high) >> 8;
    /* The loader calls this for every controller, every frame. */
    if (!strength && controller != owner) return -1;
    if (strength) owner = controller;
    if (!strength && !last_strength) return 0;
    struct timespec stamp;
    if (clock_gettime(CLOCK_MONOTONIC, &stamp) < 0) return -1;
    double now = stamp.tv_sec + stamp.tv_nsec / 1000000000.;
    /* Repeated before the launcher's timeout stops the motor. */
    if (strength == last_strength && now < next_update) return 0;
    next_update = now + .25;
    return send_strength(strength);
}

__attribute__((destructor)) static void close_motor(void) {
    if (last_strength) send_strength(0);
    if (motor_fd >= 0) close(motor_fd);
}
