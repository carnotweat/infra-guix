(use-modules 
  (gnu)
  (srfi srfi-1) ; remove
  (gnu packages linux) ; wifi aircrack module
  (gnu system) ; %base-firmware
  (gnu packages cups)
  (gnu packages suckless)
  (gnu packages wm)
  (gnu packages finance)  ; trezord-udev-rules
  (gnu packages shells) ; zsh
  (gnu packages docker) ; docker
  (gnu packages package-management) ; nix

  (gnu services base) ; mingetty 
  (gnu services docker) ; docker service
  (gnu services networking) ; ntpd
  (gnu services virtualization) ; qemu
  (gnu services sddm) ; sddm login manager
  (gnu services nix) ; nix
  
  ; non-gnu linux kernel, see: https://gitlab.com/nonguix/nonguix
  (nongnu packages linux)
  (nongnu system linux-initrd)

  (awb99 packages nuc)
  (awb99 services monitor)
  (awb99 services trezord)
  (awb99 services special-files)
  (awb99 services file-sync)
  (awb99 config cron)
  (awb99 config iptables)
  ;(awb99 services ddclient)
  (awb99 services wayland)
)
             
;  (use-service-modules x y …) is just syntactic sugar for (use-modules (gnu services x) (gnu services y) …)
(use-service-modules desktop networking ssh xorg cups mcron certbot web)
(use-service-modules networking ssh)
(use-package-modules certs rsync screen ssh)

; 1 SERVICES ***************************************************

(define i3-service
  (simple-service
    'i3-packages
    profile-service-type
    (list dmenu i3-wm i3lock i3status)))
    

(define my-services
  (list 
    ; use "guix system search" to search for available services

    ; Because the GNOME, Xfce and MATE desktop services pull in so many packages, 
    ; the default %desktop-services variable doesn’t include any of them by default. 
    (service xfce-desktop-service-type)
    (service gnome-desktop-service-type)
   ; (service mate-desktop-service-type)
   ; (service lxqt-desktop-service-type)
    (service enlightenment-desktop-service-type)
  
    (screen-locker-service swaylock "swaylock")

    ; Wayland needs sddm-service instead of GDM as the graphical login manager

  ; printer: HP LJ Pro MFP M148fdw MFG Laser
  ; https://developers.hp.com/hp-linux-imaging-and-printing
  ; guix install hplip
  ; HP LaserJet m14-m17, hpcups 3.21.10
    (service cups-service-type
      (cups-configuration
        (default-paper-size "A4")
        (web-interface? #t)
        (extensions
          (list cups-filters hplip splix ))))

 ;   (service certbot-service-type
 ;    (certbot-configuration
 ;     (email "hoertlehner@gmail.com")
 ;     (webroot "/var/www")
 ;      (certificates
 ;       (list
 ;        (certificate-configuration
 ;            (name "wien")
 ;            (domains '("wien.hoertlehner.com" )))
 ;        ))))

    (service iptables-service-type
     (iptables-configuration
      (ipv4-rules (plain-file "iptables.rules" 
       ;iptables-allow-8080 
       iptables-port-redirect
     ))))

    (service mcron-service-type
      (mcron-configuration
        (jobs my-guix-maintenance-jobs)))

    (service trezord-service-type
      (trezord-configuration))

    service-bin-links
    service-syncthing
    ; service-ddclient-nuc 

    (service docker-service-type)
    (service qemu-binfmt-service-type ; needed for qemu arm system compile
      (qemu-binfmt-configuration
        (platforms (lookup-qemu-platforms "arm" "aarch64" ; "i686" "ppc"
       ))))

    ;(set-xorg-configuration
    ;  (xorg-configuration
    ;    (keyboard-layout (keyboard-layout "at"))))
      (service nix-service-type)



    ))

; https://framagit.org/tyreunom/system-configuration/-/blob/master/modules/config/os.scm

(define (remove-gdm system-services)
  (remove 
    (lambda (service)
       (eq? (service-kind service) gdm-service-type)) ;; Remove GDM.
      system-services))


(define (custom-udev system-services)
  (modify-services system-services
      (udev-service-type config =>
        (udev-configuration
          (inherit config)
          (rules (cons* trezord-udev-rules
                      ;  (list %backlight-udev-rule)
                        (udev-configuration-rules config)))))
          ))

(define (add-nongnu-substitute-servers services)
  (modify-services services
      (guix-service-type config => (guix-configuration
        (inherit config)
        (substitute-urls
          (append (list "https://substitutes.nonguix.org")
          %default-substitute-urls))
        (authorized-keys
   (append (list (plain-file "non-guix.pub"
                    "(public-key 
                      (ecc 
                       (curve Ed25519)
                       (q #C1FD53E5D4CE971933EC50C9F307AE2171A2D3B52C804642A7A35F84F3A4EA98#)
                      ))"))
     %default-authorized-guix-keys))))))

(define os-services
   (append
      my-services
      ; %desktop-services
      ;(custom-udev %desktop-services)
      (add-nongnu-substitute-servers
        (modify-gdm-wayland 
          (custom-udev %desktop-services)))
      ))

; 2 USERS/GROUPS *****************************************************

(define my-groups
  (cons* 
     (user-group 
        (system? #f) 
        (name "bongotrotters"))
      %base-groups))


(define my-users
  (cons* 
    (user-account
      (name "florian")
      (comment "Florian")
      (group "users")
      (home-directory "/home/florian")
      ;(shell (file-append fish "/bin/fish"))
      (shell (file-append zsh "/bin/zsh"))
     ; (identity "/home/florian/repo/myLinux/data/ssh/coin")
      (supplementary-groups
      '("wheel" 
        "lp"  ; line printer ; control bluetooth devices
        "lpadmin" ; line printer admin
        "netdev" ; network/wifi admin
        "audio" 
        "video"
        "kvm"  ; run qemu as florian with kvm support.
       ; "libvirt"
        ;;"wireshark"
        ; "realtime"  ;; Enable realtime scheduling
      )))
    (user-account
      (name "bob")
      (comment "Alice's bro")
      (group "users")
      (home-directory "/home/robert")
      (shell (file-append zsh "/bin/zsh")))
    %base-user-accounts))

; 3 PACKAGES *****************************************************

(define (->packages-output specs)
  (map specification->package+output specs))

(define (specifications->package specs)
   (map specification->package specs))

 (define my-packages
  (append
    (specifications->package packages-nuc-root-only)
    %base-packages))

  ; 4 OS ***********************************************************

(operating-system
  ; (locale "de_AT.utf8")
  (locale "en_US.utf8")
  (timezone "Europe/Amsterdam")
  (keyboard-layout (keyboard-layout "at"))
  (host-name "nuc27")
  (issue "Guix is Great!  Ave Guix!!  Ave!!!\n\n")
  (groups my-groups)
  (users my-users)
  (packages my-packages)
  (services os-services)
  (bootloader
    (bootloader-configuration
      (bootloader grub-efi-bootloader)
      ;(target "/boot/efi")
      (targets '("/boot/efi"))
      (keyboard-layout keyboard-layout)))
  (mapped-devices
    (list (mapped-device
            (source
              (uuid "968b319a-2e32-476b-ad85-323a4c607c81"))
            (target "cryptroot")
            (type luks-device-mapping))))

   ; awb99: old config, when we had rtl-8812au-aircrack-ng-linux module in gnu guix.
   ;(kernel-loadable-modules 
   ;   (list 
   ;     rtl8812au-aircrack-ng-linux-module ; for usb wifi card
   ;   ))

   ; non-gnu kernel
  (kernel linux)
  (initrd microcode-initrd); CPU microcode updates are nonfree blobs 
  (kernel-loadable-modules '()) ;A list of objects (usually packages) to collect loadable kernel modules from–e.g. (list ddcci-driver-linux).
  ; (kernel linux-nonfree)
  (firmware (list linux-firmware))
  ;(firmware %base-firmware)
  ;(firmware (cons* radeon-RS780-firmware-non-free %base-firmware))


  ; swapfile has to be created first.
  ; (swap-devices 
  ;  (list "/swapfile"))

  (file-systems
    (cons* (file-system
             (mount-point "/boot/efi")
             (device (uuid "E778-7CA3" 'fat32))
             (type "vfat"))
           (file-system
             (mount-point "/")
             (device "/dev/mapper/cryptroot")
             (type "ext4")
             (dependencies mapped-devices))
           %base-file-systems)))
