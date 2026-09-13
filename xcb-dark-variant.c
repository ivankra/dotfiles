// LD_PRELOAD shim: set _GTK_THEME_VARIANT=dark on X11 windows right before
// they are mapped, so muffin/mutter draws a dark title bar without flicker.
//
// Qt loads libxcb through a RTLD_LOCAL plugin, so libxcb symbols are looked
// up via its own handle instead of being linked against.

#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

typedef struct xcb_connection_t xcb_connection_t;
typedef struct { unsigned int sequence; } xcb_cookie_t;
typedef struct {
  uint8_t response_type;
  uint8_t pad0;
  uint16_t sequence;
  uint32_t length;
  uint32_t atom;
} xcb_intern_atom_reply_t;

static xcb_cookie_t (*real_map)(xcb_connection_t *, uint32_t);
static xcb_cookie_t (*real_map_checked)(xcb_connection_t *, uint32_t);
static xcb_cookie_t (*intern_atom)(xcb_connection_t *, uint8_t, uint16_t, const char *);
static xcb_intern_atom_reply_t *(*intern_atom_reply)(xcb_connection_t *, xcb_cookie_t, void **);
static xcb_cookie_t (*change_property)(xcb_connection_t *, uint8_t, uint32_t, uint32_t, uint32_t, uint8_t, uint32_t, const void *);

static void init(void) {
  if (real_map)
    return;
  void *xcb = dlopen("libxcb.so.1", RTLD_LAZY | RTLD_NOLOAD);
  if (!xcb)
    abort();
  intern_atom = dlsym(xcb, "xcb_intern_atom");
  intern_atom_reply = dlsym(xcb, "xcb_intern_atom_reply");
  change_property = dlsym(xcb, "xcb_change_property");
  real_map_checked = dlsym(xcb, "xcb_map_window_checked");
  real_map = dlsym(xcb, "xcb_map_window");
}

static uint32_t atom(xcb_connection_t *c, const char *name) {
  xcb_intern_atom_reply_t *r = intern_atom_reply(c, intern_atom(c, 0, strlen(name), name), NULL);
  uint32_t a = r ? r->atom : 0;
  free(r);
  return a;
}

static void set_dark(xcb_connection_t *c, uint32_t window) {
  uint32_t prop = atom(c, "_GTK_THEME_VARIANT");
  uint32_t type = atom(c, "UTF8_STRING");
  if (prop && type)
    change_property(c, 0 /* XCB_PROP_MODE_REPLACE */, window, prop, type, 8, 4, "dark");
}

xcb_cookie_t xcb_map_window(xcb_connection_t *c, uint32_t window) {
  init();
  set_dark(c, window);
  return real_map(c, window);
}

xcb_cookie_t xcb_map_window_checked(xcb_connection_t *c, uint32_t window) {
  init();
  set_dark(c, window);
  return real_map_checked(c, window);
}
