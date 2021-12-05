
;; This is an operating system configuration template for a "Docker image" setup.

;; stolen from guix tarball
;;'gnu/system/examples/docker-image.tmpl'

;; https://github.com/Millak/guix-config/blob/master/vm_config.scm

; load guile namespaces 
(use-modules (gnu)
             ;(nongnu packages clojure) ; leiningen
             ;(gnu packages python)
             (gorilla packages)
             (gorilla services)
             (gorilla guixutils) 
             (gorilla os-release))

;(use-service-modules ;desktop 
                     ;networking 
 ;                    ssh 
                     ;xorg
  ;                   )


; to see where package is stored use:
; guix show git
;(use-package-modules base  ; hello
;                     version-control ; git
;                     ncdu
;                     wget
;                     java ; jdk ; icedtea 
;                     clojure  ; gnu/packages/clojure
;                     )


(operating-system
 ;(host-name "muzaffarnagar.psychnotebook.org")
  (host-name "gorilla")
  ;(timezone "Europe/Berlin")
  (timezone "Etc/UTC")
  (locale "en_US.utf8")
  ;; This is where user accounts are specified.  The "root" account is
  ;; implicit, and is initially created with the empty password.
  (users (cons (user-account
                 (name "pink")
                 (comment "pink at gorilla")
                 (uid 2002) ; uid needs to match user in host for docker
                 (group "users")
                 ;; "input" and "tty" are needed to start X server without
              ;; root permissions: "input" - to access "/dev/input"
              ;; devices, "tty" - to access "/dev/ttyN".
                 (supplementary-groups '("wheel" ; sudo
                                         "audio" 
                                        "video"
                                        "input"
                                         "tty"
                                         "lp"
                                         ))
                 (home-directory "/home/pink")
                 ;(shell (file-append zsh "/bin/zsh"))
                  ;; Specify a SHA-512-hashed initial password.
                  ;; (password (crypt "InitialPassword!" "$6$abc"))
                  (password "")
                                        )
               %base-user-accounts))

  ;; Globally-installed packages.
  ;; %base-packages: Coompression, Networking Utilities, Zile/nano text editor, find, grep, etc.
  ;; (packages %base-packages)
  ;(packages (append (list hello git wget ncdu
  ;                        icedtea clojure leiningen ; in (nongnu packages clojure)
  ;                        python) %base-packages))
  (packages (append (->packages p-notebook) %base-packages))

  ;; Because the system will run in a Docker container, we may omit many
  ;; things that would normally be required in an operating system
  ;; configuration file.  These things include:
  ;;
  ;;   * bootloader
  ;;   * file-systems
  ;;   * services such as mingetty, udevd, slim, networking, dhcp
  ;;
  ;; Either these things are simply not required, or Docker provides
  ;; similar services for us.

  ;; This will be ignored.
  (bootloader (bootloader-configuration
               (bootloader grub-bootloader)
               (target "does-not-matter")))

  ;; This will be ignored, too.
  (file-systems (list (file-system
                        (device "does-not-matter")
                        (mount-point "/")
                        (type "does-not-matter"))))


 

  ;; more services here:
  ;; https://github.com/Millak/guix-config/blob/master/macbook41_config.scm
  (services 
      (append 
         (list 
            (simple-service 'os-release etc-service-type
               `(("os-release" ,%os-release-file)))
            (gorilla-ssh-service)) 
         %base-services))

  ; end of os
  )





