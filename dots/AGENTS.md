
# NixOS Desktop UI Project

## Project context
- NixOS 26.05 with Flakes and Home Manager.
- Main development host: j4n9-proxmox.
- Reference laptop host: j4n9-hplaptop.
- Desktop compositor: Hyprland with Lua configuration.
- Shell and widgets: Quickshell using QML.
- Repository: /etc/nixos.
- UI source: /etc/nixos/dots.

## Main objective
Build a beautiful, fast, cohesive, highly personalized
Linux desktop environment using Hyprland and Quickshell.

## Architecture
- Hyprland configuration: dots/hypr/
- Quickshell configuration: dots/quickshell/
- UI files must remain live-editable.
- Never replace live configuration with generated
  Nix Store configuration.

## Scope
- You may edit files under dots/hypr and dots/quickshell.
- Do not change flake.nix, hosts, modules, profiles,
  or users without explicit approval.
- Do not modify the laptop-specific configuration.
- Do not install packages or change system services
  without approval.

## Design principles
- Modern, minimal, consistent visual language.
- Rounded corners and restrained animations.
- Consistent spacing, iconography, and typography.
- Dark mode as the primary appearance.
- Reusable QML components.
- Avoid unnecessary dependencies.
- Prioritize performance on a Proxmox virtual machine.

## Development workflow
1. Inspect existing code before editing.
2. Explain planned changes.
3. Edit only necessary files.
4. Preserve existing functionality.
5. Validate QML/Lua changes.
6. Test live reload when possible.
7. Report modified files and any errors.
8. Never run nixosctl switch automatically.

## Safety
- Never run destructive Git commands.
- Never reset or overwrite unrelated changes.
- Never modify secrets or SSH keys.
- Never run sudo without explicit approval.
- Do not commit or push automatically.

