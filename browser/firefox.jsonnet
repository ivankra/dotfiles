local ghacks_user_js = import "gen/ghacks.json";
local pyllyukko_user_js = import "gen/pyllyukko.json";

{
  "user.json.static": pyllyukko_user_js + ghacks_user_js + {
    "browser.cache.memory.capacity": -1,
    "browser.cache.memory.enable": true,
    "browser.fullscreen.autohide": false,
    "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons": false,
    "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features": false,
    "browser.newtabpage.activity-stream.migrationExpired": true,
    "browser.preferences.defaultPerformanceSettings.enabled": false,
    "browser.safebrowsing.downloads.enabled": false,
    "browser.safebrowsing.enabled": false,  // tracking cookie
    "browser.safebrowsing.malware.enabled": false,
    "browser.safebrowsing.phishing.enabled": false,
    "browser.search.separatePrivateDefault": true,
    "browser.search.separatePrivateDefault.ui.enabled": true,
    "browser.search.widget.inNavBar": true,
    "browser.tabs.drawInTitlebar": true,
    "browser.uiCustomization.state": "{\"placements\":{\"widget-overflow-fixed-list\":[\"fxa-toolbar-menu-button\",\"library-button\"],\"nav-bar\":[\"back-button\",\"forward-button\",\"stop-reload-button\",\"urlbar-container\",\"search-container\",\"downloads-button\"],\"toolbar-menubar\":[\"menubar-items\"],\"TabsToolbar\":[\"tabbrowser-tabs\",\"new-tab-button\",\"alltabs-button\"],\"PersonalToolbar\":[\"personal-bookmarks\"]},\"seen\":[\"developer-button\"],\"dirtyAreaCache\":[\"PersonalToolbar\",\"nav-bar\",\"TabsToolbar\",\"toolbar-menubar\",\"widget-overflow-fixed-list\"],\"currentVersion\":16,\"newElementCount\":9}",
    "browser.urlbar.delay": 0,
    "dom.ipc.processCount": 8,
    "extensions.activeThemeID": "default-theme@mozilla.org",
    "general.smoothScroll": false,
    "gfx.downloadable_fonts.fallback_delay": 0,
    "gfx.downloadable_fonts.fallback_delay_short": 0,
    "gfx.font_loader.delay": 0,
    "identity.fxaccounts.enabled": false,
    "image.decode-immediately.enabled": true,
    "layers.acceleration.disabled": false,
    "layout.css.text-decoration-skip-ink.enabled": false,  // fugly
    "mousewheel.default.delta_multiplier_y": 150,
    "mousewheel.min_line_scroll_amount": 40,
    "permissions.default.camera": 2,
    "permissions.default.desktop-notification": 2,
    "permissions.default.geo": 2,
    "permissions.default.microphone": 2,
    "privacy.trackingprotection.cryptomining.enabled": true,
    "privacy.trackingprotection.fingerprinting.enabled": true,
    "privacy.window.maxInnerHeight": 1200,
    "privacy.window.maxInnerWidth": 1900,
    "toolkit.cosmeticAnimations.enabled": false,
    "ui.context_menus.after_mouseup": true,  // fix right click menu behaviour
    "ui.key.menuAccessKeyFocuses": false,  // disable window menu on alt press

    // pdfjs, see also handlers.json
    "pdfjs.disabled": false,
    "privacy.firstparty.isolate": false,  // blurry rendering https://github.com/mozilla/pdf.js/issues/10509

    // ghacks/pyllyukko overrides
    "app.update.enabled": false,
    "browser.display.use_document_fonts": 1,
    "browser.download.useDownloadDir": true,
    "browser.newtabpage.enabled": true,
    "browser.privatebrowsing.autostart": false,
    "browser.startup.homepage": "about:home",
    "browser.startup.page": 1,
    "browser.urlbar.autoFill": true,
    "browser.urlbar.autoFill.typed": true,
    "browser.urlbar.autocomplete.enabled": true,
    "browser.urlbar.suggest.bookmark": true,
    "browser.urlbar.suggest.history": true,
    "browser.urlbar.suggest.openpage": true,
    "gfx.downloadable_fonts.woff2.enabled": true,
    "gfx.font_rendering.opentype_svg.enabled": true,
    "gfx.offscreencanvas.enabled": true,
    "keyword.enabled": true,
    "network.cookie.lifetimePolicy": 0,  // 0=The cookie"s lifetime is supplied by the server
    "places.history.enabled": true,
    "privacy.clearOnShutdown.cookies": false,
    "privacy.clearOnShutdown.history": false,
    "privacy.clearOnShutdown.sessions": false,
    "privacy.donottrackheader.enabled": false,  // entropy
    "privacy.resistFingerprinting.letterboxing": false,  // fugly
    "privacy.sanitize.sanitizeOnShutdown": false,
    "security.dialog_enable_delay": 10,
    "security.mixed_content.block_display_content": false,

    // Disable various onboarding notifications
    "browser.aboutConfig.showWarning": false,
    "browser.contentblocking.introCount": 20,
    "browser.messaging-system.whatsNewPanel.enabled": false,
    "browser.onboarding.state": "watermark",
    "browser.onboarding.tour.onboarding-tour-addons.completed": true,
    "browser.onboarding.tour.onboarding-tour-customize.completed": true,
    "browser.onboarding.tour.onboarding-tour-default-browser.completed": true,
    "browser.onboarding.tour.onboarding-tour-performance.completed": true,
    "browser.onboarding.tour.onboarding-tour-private-browsing.completed": true,
    "browser.onboarding.tour.onboarding-tour-screenshots.completed": true,
    "devtools.whatsnew.enabled": false,
    "devtools.whatsnew.feature-enabled": false,
    "extensions.privatebrowsing.notification": true,
    "general.warnOnAboutConfig": false,
    "privacy.trackingprotection.introCount": 20,

    //"network.security.esni.enabled": true,
  },

  "user.json": self["user.json.static"] + {
    // Environment-dependent params.
    "browser.download.dir": std.extVar("DOWNLOAD_DIR"),
    "print.print_to_filename": std.extVar("DOWNLOAD_DIR") + "/mozilla.pdf",
    "browser.uidensity": if std.extVar("HIDPI") == "1" then 1 /*compact*/ else 0 /*normal*/,
  },

  "handlers.json": {
    "defaultHandlersVersion": {"en-US": 4},
    "mimeTypes": {
      "application/pdf": {"action": 3, "extensions": ["pdf"]},  // open in pdfjs
    },
    "schemes": {}
  },

  // Installed system-wide via dotfiles packages.
  // Manually: copy to <firefox installation>/distribution/policies.json
  // Ref: https://github.com/mozilla/policy-templates
  "policies.json": {
    "policies": {
      "AppUpdateURL": "https://127.0.0.1/",
      "DisableAppUpdate": true,
      "DisableFeedbackCommands": true,
      "DisableFirefoxAccounts": true,
      "DisableFirefoxStudies": true,
      "DisableMasterPasswordCreation": true,
      "DisablePocket": true,
      "DisableProfileImport": true,
      "DisableProfileRefresh": true,
      "DisableSetDesktopBackground": true,
      "DisableSystemAddonUpdate": true,
      "DisableTelemetry": true,
      "DontCheckDefaultBrowser": true,
      "Extensions": {
        "Install": [
          // Install on first run.
          "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin",
        ],
      },
      "NetworkPrediction": false,
      "NoDefaultBookmarks": true,
      "SearchSuggestEnabled": false,
    },
  },
}
