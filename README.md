![banner](banner.png?raw=true)

# ThinkPad Universal GRUB2 Theme Installer (Dual-Boot Optimized)

This is a highly optimized, universal GRUB2 theme installer crafted specifically for **ThinkPad (1080p)** laptops running Windows and Linux in a dual-boot configuration. 

Unlike standard theme scripts that only copy visual assets, this script acts as a smart structural configuration layer. It safely interacts with GRUB templates to deliver a seamless, polished, and update-safe bootloader layout.

---

## 🌟 Key Features

- **Universal Linux Support:** Dynamically identifies core paths and package managers across Debian/Ubuntu, Arch Linux, and RedHat/Fedora ecosystems.
- **Update-Safe Boot Ordering:** Shifts native GRUB template execution priorities (`30_os-prober` becomes `09_os-prober`). Windows 11 stays locked at position #1 even after system kernel upgrades (`update-grub`).
- **Clean OS Menu Labels:** Automatically scrubs messy partition strings inside `grub.cfg`, renaming them to clean, aesthetic labels: **Windows 11** and **Ubuntu/Linux**.
- **Official Branding Retention:** Safely extracts host distribution identities to ensure official system logos (Ubuntu, Arch, Fedora) render correctly without falling back to generic icons.
- **Robust Failure Windows:** Extends root authentication input windows to **32 seconds** to minimize terminal timeout crashes.
- **1080p Perfection:** Hardlocked to 1920x1080 resolution to eliminate layout stretching or breaking bugs.

---

## ⚙️ Included Theme Backgrounds
* `thinkpad` (Custom tailored ThinkPad aesthetic)
* `bubbles`
* `legend` (Default active theme layout)
* `pride`
* `the_icon`

---

## 🚀 Installation

### Method 1: Interactive Menu (Recommended)
If you run the script without flags, an interactive text user interface (`dialog`) will guide you through choosing layouts and icon presets:

```sh
# 1. Clone your repository
git clone [https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git](https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git)
cd YOUR_REPO_NAME

# 2. Grant execution permissions
chmod +x install.sh

# 3. Launch the installer
./install.sh


🗑️ Uninstalling / Reverting

If you ever wish to completely remove the theme and restore your original Linux GRUB layout, default names, and structural file positions, execute the script with the remove flag:

sudo ./install.sh -r thinkpad

Note: Replace thinkpad with the specific theme folder name you installed.


🛠️ Troubleshooting & Tweaks

1. Manual Display Resolution Adjustments

If the theme looks slightly misaligned, your hardware monitor matrix definitions might be ignoring standard defaults:

    When your laptop boots into the GRUB screen, press c to open the terminal command line layer.

    Type videoinfo (or vbeinfo) and press Enter to see the exact resolution modes supported by your ThinkPad.

    Boot back into Linux, open /etc/default/grub, and check if this line is bound accurately:
    

    GRUB_GFXMODE=1920x1080,auto

    If you modified it, run sudo update-grub (or equivalent sync command for your distro) to push changes.


2. Setting a Custom Background Wallpaper

You can substitute the default variant images with your own custom wallpaper seamlessly:

    Select a high-quality picture and make sure it is cropped exactly to 1920x1080 resolution.

    Rename the image file exactly to background.jpg.

    Move/Copy this image into the root folder of this repository (right next to install.sh).

    Re-run ./install.sh. The installer engine will automatically pick up your image and process it over default assets using imagemagick.


📂 Core CLI Arguments Reference


OPTIONS:
  -t, --theme                 theme variant(s)          [thinkpad | bubbles | legend | pride | the_icon] (default: legend)
  -i, --icon                  icon variant(s)           [color | white | whitesur] (default: color)
  -s, --screen                screen display variant    [1080p] (default: 1080p)
  -r, --remove                completely remove theme   [must specify active theme variant name]
  -b, --boot                  forces installation directly targetting root '/boot/grub' partitions
  -h, --help                  displays these usage guidelines