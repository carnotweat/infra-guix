(define-module (awb99 packages desktopsystem)
  #:use-module (gnu packages linux) ; wifi driver
  #:use-module (awb99 packages tools)
  #:use-module (awb99 packages fonts)
  #:use-module (awb99 packages wm)
  #:use-module (awb99 packages desktop)
  #:use-module (awb99 packages programming)
  #:use-module (awb99 packages emacs)
)

(define packages-desktop-other
  (list
    "swaylock"
    "nix"
    ; awb99 - rtl8812au module no longer exists in guix kernel. removed due to blobs.
    ;"rtl8812au-aircrack-ng-linux-module" ; rtl8812au USB wifi driver
    "wpa-supplicant" ; manage wifi networks
    ;  "mcron"
    ;  "shepherd"
    ))


(define-public packages-desktop-system
  (append
    packages-wm-sway
    packages-wm-gnome
    ;packages-wm-xfce
    ;packages-wm-i3
    packages-desktop-extra
    packages-desktop-printer
    font-packages
    virtual-machine-packages
    crypto-packages
    services-packages
    guix-core-packages
    shell-packages
    packages-desktop-other ; defined above
  ))
