#include "status.h"

#include <fcitx/addonfactory.h>
#include <fcitx/addonmanager.h>
#include <fcitx/event.h>
#include <fcitx/instance.h>

#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <string>
#include <system_error>

namespace fcitx {

StatusAddon::StatusAddon(Instance *instance)
    : instance_(instance) {

    inputMethodActivated_ =
        instance_->watchEvent(
            EventType::InputContextInputMethodActivated,
            EventWatcherPhase::Default,
            [this](Event &event) {
                auto &activated =
                    static_cast<InputMethodActivatedEvent &>(event);

                update(activated.name());
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

    const std::filesystem::path tempPath =
        path.string() + ".tmp";

    {
        std::ofstream file(
            tempPath,
            std::ios::out | std::ios::trunc
        );

        if (!file) {
            return;
        }

        file << language << '\n';
        file.flush();

        if (!file) {
            return;
        }
    }

    std::error_code ec;

    std::filesystem::rename(
        tempPath,
        path,
        ec
    );

    if (ec) {
        std::filesystem::remove(
            tempPath,
            ec
        );
    }
}


/*
 * Factory
 *
 * Giữ factory trong .cpp giống cách các addon
 * chính thức của Fcitx5 triển khai.
 */
class StatusAddonFactory final
    : public AddonFactory {
public:
    AddonInstance *create(
        AddonManager *manager
    ) override {
        return new StatusAddon(
            manager->instance()
        );
    }
};

} // namespace fcitx


FCITX_ADDON_FACTORY_V2(
    status,
    fcitx::StatusAddonFactory
);
