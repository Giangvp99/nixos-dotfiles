#pragma once

#include <fcitx/addonfactory.h>
#include <fcitx/addoninstance.h>
#include <fcitx/event.h>
#include <fcitx/instance.h>

#include <memory>
#include <string>

namespace fcitx {

class StatusAddon final : public AddonInstance {
public:
    explicit StatusAddon(Instance *instance);

private:
    void update(
        const std::string &inputMethod
    );

    Instance *instance_;

    std::unique_ptr<
        HandlerTableEntry<EventHandler>
    > inputMethodActivated_;
};

} // namespace fcitx
