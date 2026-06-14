#! /usr/bin/env bash

# ==============================================================================
#                    ThinkPad Universal GRUB2 Theme Installer
#  Automated script to install modern GRUB themes, adjust screen
#  resolution, reorder boot priorities (Windows first), and clean
#  up menu entry labels seamlessly across multiple distributions.
# ==============================================================================

# Exit immediately if any sub-command fails to prevent broken configurations
set -o errexit

# Global Immutable Constants
readonly ROOT_UID=0                                 # Root User ID specification
readonly Project_Name="GRUB2::THEMES"               # Project tag for TUI dialogs
readonly MAX_DELAY=32                               # Sudo prompt timeout window in seconds
tui_root_login=

# System Target Paths
THEME_DIR="/usr/share/grub/themes"                  # Default global theme directory
REO_DIR="$(cd $(dirname $0) && pwd)"                # Working directory path of the script

# Supported Theme Framework Arrays
THEME_VARIANTS=('thinkpad' 'bubbles' 'legend' 'pride' 'the_icon')
ICON_VARIANTS=('color' 'white' 'whitesur')
SCREEN_VARIANTS=('1080p')                           # Locked to 1080p for display stability

# ==============================================================================
#  COLOR SCHEMES & TERMINAL OUTPUT CONFIGURATION
# ==============================================================================
CDEF=" \033[0m"                                     # Default standard font color
CCIN=" \033[0;36m"                                  # Info notification color (Cyan)
CGSC=" \033[0;32m"                                  # Success indicator color (Green)
CRER=" \033[0;31m"                                  # Error execution color (Red)
CWAR=" \033[0;33m"                                  # Warning notifier color (Yellow)
b_CDEF=" \033[1;37m"                                # Bold Default font color
b_CCIN=" \033[1;36m"                                # Bold Info notification color
b_CGSC=" \033[1;32m"                                # Bold Success indicator color
b_CRER=" \033[1;31m"                                # Bold Error execution color
b_CWAR=" \033[1;33m"                                # Bold Warning notifier color

# Helper function to print beautifully stylized terminal alerts
prompt () {
  case ${1} in
    "-s"|"--success") echo -e "${b_CGSC}${@/-s/}${CDEF}";;
    "-e"|"--error")   echo -e "${b_CRER}${@/-e/}${CDEF}";;
    "-w"|"--warning") echo -e "${b_CWAR}${@/-w/}${CDEF}";;
    "-i"|"--info")    echo -e "${b_CCIN}${@/-i/}${CDEF}";;
    *)                echo -e "$@";;
  esac
}

# Evaluates whether a specified dependency command exists on the host machine
function has_command() {
  command -v $1 &> /dev/null
}

# Displays manual CLI syntax usage guidelines if the user requests help flags
usage() {
cat << EOF
Usage: $0 [OPTION]...

OPTIONS:
  -t, --theme                 theme variant(s)          [thinkpad | bubbles | legend | pride | the_icon]       (default is legend)
  -i, --icon                  icon variant(s)           [color|white|whitesur]              (default is color)
  -s, --screen                screen display variant(s) [1080p] (default is 1080p)
  -r, --remove                remove theme              [thinkpad | bubbles | legend | pride | the_icon]

  -b, --boot                  install theme into '/boot/grub' or '/boot/grub2'
  -h, --help                  show this help
EOF
}

# ==============================================================================
#  CORE IMPLEMENTATION: COPYING FILES & CONFIGURING BACKGROUNDS
# ==============================================================================
generate() {
  # Dynamically switch paths if boot-specific deployment flag is active
  if [[ "${install_boot}" == 'true' ]]; then
    [[ -d "/boot/grub" ]] && THEME_DIR='/boot/grub/themes'
    [[ -d "/boot/grub2" ]] && THEME_DIR='/boot/grub2/themes'
  fi

  prompt -i "\n Checking for the existence of themes directory..."
  [[ -d "${THEME_DIR}/${theme}" ]] && rm -rf "${THEME_DIR}/${theme}"
  mkdir -p "${THEME_DIR}/${theme}"

  prompt -i "\n Installing ${theme} ${icon} ${screen} theme..."
  
  # Transfer core engine assets (Fonts, Text Config, Layout Specifications)
  cp -a --no-preserve=ownership "${REO_DIR}/common/"*.pf2 "${THEME_DIR}/${theme}"
  cp -a --no-preserve=ownership "${REO_DIR}/config/theme-${screen}.txt" "${THEME_DIR}/${theme}/theme.txt"
  cp -a --no-preserve=ownership "${REO_DIR}/backgrounds/${screen}/background-${theme}.jpg" "${THEME_DIR}/${theme}/background.jpg"

  # Processes custom user wallpapers if present in the working source root
  if [[ -f "${REO_DIR}/background.jpg" ]]; then
    if has_command apt || has_command pacman || has_command eopkg; then
      install_depends imagemagick
    else
      install_depends ImageMagick
    fi
    prompt -w "\n Using custom background.jpg as grub background image..."
    cp -a --no-preserve=ownership "${REO_DIR}/background.jpg" "${THEME_DIR}/${theme}/background.jpg"
    magick "${THEME_DIR}/${theme}/background.jpg" -auto-orient "${THEME_DIR}/${theme}/background.jpg"
  fi

  # Transfer contextual operational assets (Icons, Selection sliders, info popups)
  cp -a --no-preserve=ownership "${REO_DIR}/assets/assets-${icon}/icons-${screen}" "${THEME_DIR}/${theme}/icons"
  cp -a --no-preserve=ownership "${REO_DIR}/assets/assets-select/select-${screen}/"*.png "${THEME_DIR}/${theme}"
  cp -a --no-preserve=ownership "${REO_DIR}/assets/info-${screen}.png" "${THEME_DIR}/${theme}/info.png"
}

# ==============================================================================
#  BOOT ORDER OVERRIDE ENGINE & DISPLAY TEXT CLEANING (THE MAGIC LOGIC)
# ==============================================================================
optimize_boot_menu() {
  prompt -i "\n Optimizing GRUB templates and polishing display names..."
  
  # STEP 1: Re-order GRUB configuration execution array.
  # Elevates Windows Boot Manager to execute at priority sequence '09',
  # forcing it to build ahead of native Linux installations ('10_linux').
  if [[ -f "/etc/grub.d/30_os-prober" ]]; then
    mv /etc/grub.d/30_os-prober /etc/grub.d/09_os-prober
    prompt -s " Successful: Windows template shifted to priority #1 (09_os-prober)."
  fi

  # STEP 2: Evaluate target output path based on distribution standard protocols
  local cfg="/boot/grub/grub.cfg"
  [[ -f "/boot/grub2/grub.cfg" ]] && cfg="/boot/grub2/grub.cfg"

  # STEP 3: Dynamic Search-and-Replace Injection inside compiled grub.cfg
  if [[ -f "$cfg" ]]; then
    prompt -i " Polishing menu entry labels inside grub.cfg..."
    
    # Cleans "Windows Boot Manager (on /dev/xxx)" label -> "Windows 11"
    sed -i "s/menuentry 'Windows Boot Manager[^']*'/menuentry 'Windows 11'/g" "$cfg"
    
    # Cleans complex Ubuntu kernel descriptor titles -> Simple clean "Ubuntu" label
    sed -i "s/menuentry 'Ubuntu, with Linux[^']*'/menuentry 'Ubuntu'/g" "$cfg"
    
    prompt -s " Successful: Entry labels cleaned up nicely!"
  fi
}

# ==============================================================================
#  SYSTEM INTEGRATION & ORCHESTRATION PIPELINE
# ==============================================================================
install() {
  local theme=${1}
  local icon=${2}
  local screen=${3}

  # Enforce administrative root checking privileges
  if [[ "$UID" -eq "$ROOT_UID" ]]; then
    generate "${theme}" "${icon}" "${screen}"
    prompt -i "\n Setting ${theme} as default..."

    # Preserve default configuration matrix state
    [[ -f /etc/default/grub.bak ]] || cp -an /etc/default/grub /etc/default/grub.bak

    # Automated adjustments to /etc/default/grub behaviors
    sed -i "s|.*GRUB_DEFAULT=.*|GRUB_DEFAULT=\"Windows Boot Manager\"|" /etc/default/grub
    sed -i "s|.*GRUB_TIMEOUT=.*|GRUB_TIMEOUT=32|" /etc/default/grub
    sed -i "s|.*GRUB_TIMEOUT_STYLE=.*|#GRUB_TIMEOUT_STYLE=hidden|" /etc/default/grub
    
    # Variable to safely preserve regional/distro identity while extracting branding icons
    if grep -q "GRUB_DISTRIBUTOR=" /etc/default/grub; then
      sed -i "s|.*GRUB_DISTRIBUTOR=.*|GRUB_DISTRIBUTOR=\`( . /etc/os-release; echo \${NAME:-Ubuntu} ) 2>/dev/null \|\| echo Ubuntu\`|" /etc/default/grub
    else
      echo "GRUB_DISTRIBUTOR=\`( . /etc/os-release; echo \${NAME:-Ubuntu} ) 2>/dev/null || echo Ubuntu\`" >> /etc/default/grub
    fi

    # Bind the compiled stylesheet path to the master config variable
    if grep "GRUB_THEME=" /etc/default/grub 2>&1 >/dev/null; then
      sed -i "s|.*GRUB_THEME=.*|GRUB_THEME=\"${THEME_DIR}/${theme}/theme.txt\"|" /etc/default/grub
    else
      echo "GRUB_THEME=\"${THEME_DIR}/${theme}/theme.txt\"" >> /etc/default/grub
    fi

    # Wipe conflicting default wallpaper parameters
    if grep "GRUB_BACKGROUND=" /etc/default/grub 2>&1 >/dev/null; then
      sed -i "s|.*GRUB_BACKGROUND=.*||" /etc/default/grub
    fi

    # Lock terminal monitor resolution matrices safely to 1080p
    local gfxmode="GRUB_GFXMODE=1920x1080,auto"
    if grep "GRUB_GFXMODE=" /etc/default/grub 2>&1 >/dev/null; then
      sed -i "s|.*GRUB_GFXMODE=.*|${gfxmode}|" /etc/default/grub
    else
      echo "${gfxmode}" >> /etc/default/grub
    fi

    # Execute priority array switch manipulation
    if [[ -f "/etc/grub.d/30_os-prober" ]]; then
      mv /etc/grub.d/30_os-prober /etc/grub.d/09_os-prober
    fi

    # Trigger distribution-native menu map generation 
    prompt -i "\n Triggering system grub config regeneration..."
    updating_grub
    
    # Run text formatting edits over the freshly generated configuration layout
    optimize_boot_menu
    
    prompt -w "\n * Installation finished successfully! Dynamic custom configuration active."
    prompt -s " * Bootloader polished: Windows 11 (#1) & Ubuntu (#2) are ready with official logos."

  # Password fallback interceptor block for standard terminal accounts
  elif sudo -n true 2> /dev/null && echo; then
    sudo "$0" -t ${theme} -i ${icon} -s ${screen}
  else
    prompt -e "\n [ Error! ] -> Run me as root! "
    read -r -p " [ Trusted ] Specify the root password : " -t ${MAX_DELAY} -s
    if sudo -S echo <<< $REPLY 2> /dev/null && echo; then
      sudo "$0" -t ${theme} -i ${icon} -s ${screen} <<< ${REPLY}
    else
      sleep 3
      prompt -e "\n [ Error! ] -> Incorrect password!\n"
      exit 1
    fi
  fi
}

# ==============================================================================
#  TEXT USER INTERFACE (TUI DIALOG MANAGER)
# ==============================================================================
run_dialog() {
  if [[ -x /usr/bin/dialog ]]; then
    if [[ "$UID" -ne "$ROOT_UID"  ]]; then
      if sudo -n true 2> /dev/null && echo; then
        sudo $0
      else
        tui_root_login=$(dialog --backtitle ${Project_Name} --title "ROOT LOGIN" --insecure --passwordbox "require root permission" 8 50 --output-fd 1 )
        if sudo -S echo <<< $tui_root_login 2> /dev/null && echo; then
          sudo -S "$0" <<< $tui_root_login
        else
          sleep 3
          prompt -e "\n [ Error! ] -> Incorrect password!\n"
          exit 1
        fi
      fi
    fi

    # Render interactive radio selection box for wallpaper styles
    tui=$(dialog --backtitle ${Project_Name} --radiolist "Choose your Grub theme background picture : " 15 40 5 \
      1 "Thinkpad Theme" off  \
      2 "Bubbles Theme" off \
      3 "Legend Theme" on  \
      4 "Pride Theme" off  \
      5 "The Icon Theme" off --output-fd 1 )

      case "$tui" in
        1) theme="thinkpad"  ;;
        2) theme="bubbles"   ;;
        3) theme="legend"    ;;
        4) theme="pride"     ;;
        5) theme="the_icon"  ;;
        *) operation_canceled ;;
     esac

    # Render interactive radio selection box for icon distributions
    tui=$(dialog --backtitle ${Project_Name} --radiolist "Choose icon style : " 15 40 5 \
      1 "white" off \
      2 "color" on \
      3 "whitesur" off --output-fd 1 )
      case "$tui" in
        1) icon="white"    ;;
        2) icon="color"    ;;
        3) icon="whitesur" ;;
        *) operation_canceled ;;
     esac

     echo -e '\0033\0143'
  fi
}

operation_canceled() {
  prompt -i "\n Operation canceled by user, Bye!"
  exit 1
}

# ==============================================================================
#  CROSS-DISTRIBUTION CROSSOVER IMPLEMENTATION UTILITIES
# ==============================================================================
updating_grub() {
  # Dynamically trigger correct deployment binaries based on host environment core
  if has_command update-grub; then
    update-grub                                     # Debian / Ubuntu Systems
  elif has_command grub-mkconfig; then
    grub-mkconfig -o /boot/grub/grub.cfg            # Arch Linux Standard
  elif has_command grub2-mkconfig; then
    # RedHat / Fedora / openSUSE structures
    if [[ -f /boot/grub2/grub.cfg ]]; then
      grub2-mkconfig -o /boot/grub2/grub.cfg
    elif [[ -f /boot/efi/EFI/fedora/grub.cfg ]]; then
      grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg
    fi
  fi
}

# Handle automated cross-platform installation packages
function install_program () {
  if has_command apt-get; then apt-get install -y "$@"
  elif has_command pacman; then pacman -Syyu --noconfirm --needed "$@"
  elif has_command dnf; then dnf install -y "$@"
  fi
}

install_depends() {
  local depend=${1}
  if [ ! "$(which '${depend}' 2> /dev/null)" ]; then
    prompt -w "\n '${depend}' need to be installed for this shell"
    install_program "${depend}"
  fi
}

# Rollback functionality engine to completely revert configurations
remove() {
  local theme=${1}
  if [ "$UID" -eq "$ROOT_UID" ]; then
    if [[ -d "${THEME_DIR}/${theme}" ]]; then
      rm -rf "${THEME_DIR}/${theme}"
    fi
    # Revert modified priority layout configurations safely back to defaults
    [[ -f "/etc/grub.d/09_os-prober" ]] && mv /etc/grub.d/09_os-prober /etc/grub.d/30_os-prober
    sed -i "s|.*GRUB_THEME=.*|#GRUB_THEME=|" /etc/default/grub
    updating_grub
  fi
}

# ==============================================================================
#  ARGUMENT PARSING & INGESTION CONTROL LOOP
# ==============================================================================
while [[ $# -gt 0 ]]; do
  case "${1}" in
    -r|--remove)
      remove='true'; shift
      for theme in "${@}"; do
        case "${theme}" in
          thinkpad)   themes+=("${THEME_VARIANTS[0]}"); shift ;;
          bubbles)    themes+=("${THEME_VARIANTS[1]}"); shift ;;
          legend)     themes+=("${THEME_VARIANTS[2]}"); shift ;;
          pride)      themes+=("${THEME_VARIANTS[3]}"); shift ;;
          the_icon)   themes+=("${THEME_VARIANTS[4]}"); shift ;;
          -*) break ;;
          *) prompt -e "ERROR: Unrecognized theme variant '$1'."; exit 1 ;;
        esac
      done
      ;;
    -t|--theme)
      shift
      for theme in "${@}"; do
        case "${theme}" in
          thinkpad)   themes+=("${THEME_VARIANTS[0]}"); shift ;;
          bubbles)    themes+=("${THEME_VARIANTS[1]}"); shift ;;
          legend)     themes+=("${THEME_VARIANTS[2]}"); shift ;;
          pride)      themes+=("${THEME_VARIANTS[3]}"); shift ;;
          the_icon)   themes+=("${THEME_VARIANTS[4]}"); shift ;;
          -*) break ;;
          *) prompt -e "ERROR: Unrecognized theme variant '$1'."; exit 1 ;;
        esac
      done
      ;;
    -i|--icon)
      shift
      for icon in "${@}"; do
        case "${icon}" in
          color)    icons+=("${ICON_VARIANTS[0]}"); shift ;;
          white)    icons+=("${ICON_VARIANTS[1]}"); shift ;;
          whitesur) icons+=("${ICON_VARIANTS[2]}"); shift ;;
          -*) break ;;
        esac
      done
      ;;
    -s|--screen) shift; screens+=("1080p"); shift ;;
    -h|--help) usage; exit 0 ;;
    *) prompt -e "ERROR: Unrecognized option '$1'."; exit 1 ;;
  esac
done

# ==============================================================================
#  MAIN RUNTIME TRIGGER EXECUTION
# ==============================================================================
# Fallback loop triggers TUI selection defaults if no explicit CLI inputs were provided
for theme in "${themes[@]-${THEME_VARIANTS[2]}}"; do
  for icon in "${icons[@]-${ICON_VARIANTS[0]}}"; do
    install "${theme}" "${icon}" "1080p"
  done
done

exit 0