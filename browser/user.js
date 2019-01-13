// Update parent configs:
// curl 'https://raw.githubusercontent.com/ghacksuserjs/ghacks-user.js/master/user.js' >user.ghacks.js
// curl 'https://raw.githubusercontent.com/pyllyukko/user.js/master/user.js' >user.pyllyukko.js

// user_pref("browser.download.dir", ...) - set from python

user_pref("browser.cache.disk.enable", false);
user_pref("browser.cache.memory.capacity", -1);
user_pref("browser.cache.memory.enable", true);
user_pref("browser.contentblocking.introCount", 20);
user_pref("browser.fullscreen.autohide", false);
user_pref("browser.newtabpage.activity-stream.migrationExpired", true);
user_pref("browser.preferences.defaultPerformanceSettings.enabled", false);
user_pref("browser.search.widget.inNavBar", true);
user_pref("browser.tabs.drawInTitlebar", true);
user_pref("browser.uiCustomization.state", "{\"placements\":{\"widget-overflow-fixed-list\":[],\"PersonalToolbar\":[\"personal-bookmarks\"],\"nav-bar\":[\"back-button\",\"forward-button\",\"stop-reload-button\",\"urlbar-container\",\"search-container\",\"downloads-button\",\"library-button\"],\"TabsToolbar\":[\"tabbrowser-tabs\",\"new-tab-button\",\"alltabs-button\"],\"toolbar-menubar\":[\"menubar-items\"]},\"seen\":[\"developer-button\"],\"dirtyAreaCache\":[\"PersonalToolbar\",\"nav-bar\",\"TabsToolbar\",\"toolbar-menubar\"],\"currentVersion\":15,\"newElementCount\":6}");
user_pref("browser.urlbar.delay", 0);
user_pref("dom.ipc.processCount", 8);
user_pref("general.smoothScroll", false);
user_pref("general.warnOnAboutConfig", false);
user_pref("gfx.downloadable_fonts.fallback_delay", 0);
user_pref("gfx.downloadable_fonts.fallback_delay_short", 0);
user_pref("gfx.font_loader.delay", 0);
user_pref("image.decode-immediately.enabled", true);
user_pref("mousewheel.default.delta_multiplier_y", 150);
user_pref("pdfjs.disablePageMode", true);
user_pref("permissions.default.camera", 2);
user_pref("permissions.default.desktop-notification", 2);
user_pref("permissions.default.geo", 2);
user_pref("permissions.default.microphone", 2);
user_pref("privacy.window.maxInnerHeight", 1200);
user_pref("privacy.window.maxInnerWidth", 1900);
user_pref("toolkit.cosmeticAnimations.enabled", false);

// ghkacs/pyllyukko overrides
user_pref("app.update.enabled", false);
user_pref("browser.display.use_document_fonts", 1);
user_pref("browser.download.useDownloadDir", true);
user_pref("browser.newtabpage.enabled", true);
user_pref("browser.privatebrowsing.autostart", false);
user_pref("browser.startup.homepage", "about:home");
user_pref("browser.startup.page", 1);
user_pref("browser.urlbar.autoFill", true);
user_pref("browser.urlbar.autoFill.typed", true);
user_pref("browser.urlbar.autocomplete.enabled", true);
user_pref("browser.urlbar.suggest.bookmark", true);
user_pref("browser.urlbar.suggest.history", true);
user_pref("browser.urlbar.suggest.openpage", true);
user_pref("gfx.downloadable_fonts.woff2.enabled", true);
user_pref("gfx.font_rendering.opentype_svg.enabled", true);
user_pref("gfx.offscreencanvas.enabled", true);
user_pref("keyword.enabled", true);
user_pref("network.cookie.lifetimePolicy", 0);  // 0=The cookie's lifetime is supplied by the server
user_pref("places.history.enabled", true);
user_pref("privacy.clearOnShutdown.cookies", false);
user_pref("privacy.clearOnShutdown.history", false);
user_pref("privacy.clearOnShutdown.sessions", false);
user_pref("privacy.sanitize.sanitizeOnShutdown", false);
user_pref("security.mixed_content.block_display_content", false);
