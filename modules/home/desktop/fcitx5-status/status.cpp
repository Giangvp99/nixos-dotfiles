#include "status.h"

#include <fcitx/addonmanager.h>
#include <fcitx/event.h>
#include <fcitx/instance.h>

#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <string>

namespace fcitx {

StatusAddon::StatusAddon(Instance *instance)
    : instance_(instance) {

    inputMethodActivated_ =
        instance_->watchEvent(
            EventType::InputContextInputMethodActivated,
            EventWatcherPhase::Default,
            [this](Event &event) {
                auto &activated =
                    static_cast<InputMethodActivatedEvent &>(
                        event
                    );

                update(
                    activated.name()
                );
            }
        );
}

void StatusAddon::update(
    const std::string &inputMethod
) {
    std::string language;

    if (inputMethod == "keyboard-us") {
        language = "en";
    } else if (inputMethod == "unikey") {
        language = "vi";
    } else {
        /*
         * Không ghi state sai nếu sau này bạn thêm
         * input method khác.
         */
        return;
    }

    const char *runtimeDir =
        std::getenv("XDG_RUNTIME_DIR");

    if (
        runtimeDir == nullptr
        || *runtimeDir == '\0'
    ) {
        return;
    }

    const std::filesystem::path path =
        std::filesystem::path(runtimeDir)
        / "fcitx5-language";

    /*
     * Ghi atomically:
     *
     *   temp file
     *      ↓
     *   rename
     *
     * Quickshell sẽ không bao giờ đọc phải
     * file đang ghi dở.
     */
    const std::filesystem::path tempPath =
        path.string() + ".tmp";

    {
        std::ofstream file(
            tempPath,
            std::ios::out
            | std::ios::trunc
        );

        if (!file)
            return;

        file << language << '\n';

        file.flush();

        if (!file)
            return;
    }

    std::error_code error;

    std::filesystem::rename(
        tempPath,
        path,
        error
    );

    if (error) {
        std::filesystem::remove(
            tempPath
        );
    }
}

AddonInstance *
StatusAddonFactory::create(
    AddonManager *manager
) {
    return new StatusAddon(
        manager->instance()
    );
}

} // namespace fcitx

FCITX_ADDON_FACTORY(
    fcitx::StatusAddonFactory
)
