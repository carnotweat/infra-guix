(use-modules 
  (gnu)
  ;(gnu packages suckless)
  ;(gnu packages wm)
  ;(gnu packages shells) ; zsh
  (srfi srfi-26)
  (srfi srfi-1)
  ;; rockpro
  (gnu image)
;  (gnu system images rock64)
  (gnu bootloader u-boot)
  (gnu platforms arm)
  (gnu system image)

  ;; servuces
  (gnu services networking) ; ntpd
  (gnu services xorg)
  (gnu services desktop)
  (gnu services ssh) ;dropbear ssh

  ;; packages
  (gnu packages linux)
  (gnu packages shells) ; zsh
  (gnu packages screen)
  (gnu packages autotools)
 
  ; awb99
  (awb99 config users)
  (awb99 config helper)
  (awb99 services ssh)
  (awb99 services bootstrap-files)
  (awb99 services mingetty)
  )

           
;  (use-service-modules x y …) is just syntactic sugar for (use-modules (gnu services x) (gnu services y) …)
;(use-service-modules ; desktop 
;     networking ) ;ssh xorg mcron certbot web
; (use-package-modules certs rsync screen ssh)


; https://gitlab.manjaro.org/manjaro-arm/packages/core/linux/-/blob/master/config
; https://guix.gnu.org/de/blog/2019/guix-on-an-arm-board/
; https://github.com/guix-mirror/guix/blob/master/gnu/system/images/rock64.scm

(define extra-packages
(->packages-output
  (list "nss-certs"
        "openssh-sans-x"
  ;"openssh"
    ;   "dropbear"
        ;
        ; "zlib" ; needed for openssh?
       ;  "git"
       ; "xfce4-screensaver"
       ; "xfce4-systemload-plugin"
       ; "xfce4-mount-plugin"
       ; "xfce4-panel"
       ; "garcon" ; menu manager
       ; "xfce4-places-plugin"
       ; "xdg-desktop-portal" ; xdg-desktop-portal greatly improves the usability of Flatpak-installed apps,
        ; allowing them to open file chooser dialogs, open links, et.c.
        ; xfce4-power-manager       ** add this
        ; xfce4-pulseaudio-plugin   
        ; xfce4-whiskermenu-plugin
        ; xfce4-settings
        ; xfce4-screenshooter
        ; elementary-xfce-icon-theme
      ; shells used in user profiles need to be on system
     ; "fish"
     ; "zsh"
  )))


(display "extra packages:")
(display extra-packages)

(define my-packages
  ;(packages (cons* openssh %base-packages)) ; wpa-supplicant-minimal 
  (append extra-packages
          %base-packages))


(define (remove-services guix-services)
  (remove (lambda (service)
  (let ((type (service-kind service)))
    (or (memq type
            (list gdm-service-type
                  wpa-supplicant-service-type
                  cups-pk-helper-service-type
                  network-manager-service-type
                  modem-manager-service-type
                  openssh-service-type
                ))
        (eq? 'network-manager-applet
           (service-type-name type)))))
    guix-services))



(define my-services
  (append 
   (list 
    (service dhcp-client-service-type) ; Use the DHCP client service rather than NetworkManager.
     service-ssh
    ;service-login-prompt
    ;(service xfce-desktop-service-type)
    ;(set-xorg-configuration
    ;  (xorg-configuration
    ;  (keyboard-layout (keyboard-layout "at"))))
  
       ;   (service agetty-service-type
       ;     (agetty-configuration
       ;       (extra-options '("-L")) ; no carrier detect
       ;       (baud-rate "115200")
       ;       (term "vt100")
       ;       (tty "ttyS0")))
  )
(patch-mingetty 
  (remove-services %base-services)) ;   %desktop-services
))


(define rock64-os
  (operating-system
    (host-name "rockit")
    (timezone "Europe/Amsterdam") ; (timezone "Etc/UTC")
    (locale "en_US.utf8")
  ; (keyboard-layout (keyboard-layout "us" "altgr-intl"))
    (keyboard-layout (keyboard-layout "at"))
    (groups mygroups)
    (users myusers)
    ;; Our /etc/sudoers file.  Since 'guest' initially has an empty password,
    ;; allow for password-less sudo.
    (sudoers-file (plain-file "sudoers" "\
     root ALL=(ALL) ALL
     %wheel ALL=NOPASSWD: ALL\n"))
    (packages my-packages)

    (services my-services)
    (kernel linux-libre-arm64-generic)
    (kernel-arguments 
      '("console=ttyS2,1500000" ; 
      ; "video=HDMI-A-1:1920x1080@60" "video=eDP-1:1920x1080@60"
      ; "vga=current"
      ; "ethaddr=${ethaddr}" "eth1addr=${eth1addr}"
      ; "serial=${serial#}"
      ))     
    ;; microSD: /dev/mmcblk1
    ;;    eMMC: /dev/mmcblk2
    (bootloader 
      (bootloader-configuration
       (bootloader u-boot-rockpro64-rk3399-bootloader)
       (targets '("/dev/mmcblk1p1"))))
    (file-systems
      (cons ; cons* 
        (file-system
          (mount-point "/")
        (device "/dev/mmcblk1p1") ; (device "/dev/mmcblk1p2")
          (type "ext4"))
        ;(file-system
        ;  (mount-point "/multimedia")
        ;  (device
        ;     (uuid "20048579-a0bd-4180-8ea3-4b546309fb3b"
        ;        'btrfs))
        ;  (type "btrfs")
        ;  (options "compress=zstd,discard,space_cache=v2"))

        %base-file-systems))
    ;; This module is required to mount the SD card.
    ; the SD card itself also requires two drivers: sunxi-mmc and sd_mod.
    (initrd-modules '())
    ;(initrd-modules (cons* "sunxi-mmc" 
    ;                       "sd_mod" 
    ;                       "ahci_sunxi" 
    ;                       %base-initrd-modules))
    ;(initrd-modules (cons "omap_hsmmc" %base-initrd-modules))
    ;(initrd-modules
    ;  (cons* "dw_mmc-rockchip"
    ;         "phy-rockchip-emmc"
    ;         "sdhci-of-arasan" ;; I believe this one is for rk3399 only,
    ;         %base-initrd-modules))
   
;;
))



rock64-os