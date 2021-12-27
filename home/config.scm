(use-modules
  (guix) 
  (gnu) 
  (gnu home)
  (gnu packages)
  (gnu packages shells)
  (gnu services)
  (guix gexp)
;(mcron scripts mcron)
;(mcron base)
;(mcron config)
(mcron job-specifier)    ; For user/system files.
;(mcron utils)
;(mcron vixie-specification)
;(mcron core)

  (gnu home services)
  (gnu home services shells)
  (gnu home services mcron)
  (awb99 guixutils) 
  (awb99 config helper)
  (awb99 packages nuc)
  ;((awb99 home emacs) #:prefix emacs:)
  ;(awb99 home sway)
  ;(awb99 home emacs)
  ;(awb99 home alacritty)
  
  )



(define (specifications->package specs)
  (map specification->package specs))

(define bash-service
  (service home-bash-service-type
    (home-bash-configuration
      (aliases
        '(("grep='grep --color" . "auto")
          ("ll" . "ls -l")
          ("psg" . "ps aux | grep -i")
          ("ls='ls -p --color" . "auto")
          ("tml" . "tmux list-sessions")
          ("tma" . "TERM=xterm-24bits tmux attach-session -t")
        ))
      (bashrc
        (list (local-file "./bash/.bashrc" "bashrc")))
      (bash-profile
        (list (local-file "./bash/.bash_profile" "bash_profile"))))))

; guix install glibc-locales
; export GUIX_LOCPATH=$HOME/.guix-profile/lib/locale
; Hinweis: Vielleicht möchten Sie die nötigen Umgebungsvariablen festlegen, indem Sie dies ausführen:
; nano ~/.bashrc
;     GUIX_PROFILE="/home/florian/.guix-profile"
;     . "$GUIX_PROFILE/etc/profile"


(define-public fish-service
  (service home-fish-service-type
    (home-fish-configuration
      (aliases
       '(("l" . "ls -a")))
      (abbreviations
       '(("gc" . "guix gc")))
      (environment-variables
       '(("TEST" . "val")
         ("GDK_SCALE" . "2")
      ))
    )))

(define dummy-job-1
   #~(job '(next-minute (range 0 60 10))
   (lambda ()
     (system* "date" ))))

(define dummy-job-2
  #~(job next-minute-from
      (lambda ()
        (call-with-output-file (string-append (getenv "HOME") "/mcron-file")
          (lambda (port)
            (display "Mcron service" port))))))

(define hello-job-1
  (job
    '(next-hour '(0 15 30 45))
     "echo `date` >> /tmp/d.txt"))

(define hello-job-2
  #~(job '(next-minute '(1))
       (lambda ()
          (execl "echo"
                "hello > /tmp/hello.txt"))))



(define user-garbage-job
  ;; Collect garbage 5 minutes after 0am every day.
  ;; The job's action is a shell command.
  #~(job "35 0 * * *"            ;Vixie cron syntax
         "guix gc -d 5d && guix pull && guix package --upgrade"
         #:user "florian"
       ))


(define mcron-service
  ;; Example configuration, the first job runs mbsync once every ten
  ;; minutes, the second one writes "Mcron service" to ~/mcron-file once
  ;; every minute.
  (service home-mcron-service-type
    (home-mcron-configuration
      (jobs 
        (list 
          dummy-job-1
         ; dummy-job-2
         ; hello-job-1  ; does not work.
         ; hello-job-2
         ; user-garbage-job
                )))))


(define my-config-service
  (simple-service 'test-config
    home-files-service-type
      (list `("config/test.conf" ,(plain-file "tmp-file.txt" "the content of ~/.config/test.conf"))
            `("ssh/config" ,(local-file "./ssh/config"))
            `("config/alacritty/alacritty.yml" ,(local-file "./alacritty/alacritty.yml"))
            `("config/sway/config" ,(local-file "./sway/config"))
            ;`("xsettingsd" ,(local-file "./xsettingsd/xsettingsd.conf"))
       )))


(define env-vars-service
  (simple-service 
    'some-useful-env-vars-service
    home-environment-variables-service-type
      `(("LESSHISTFILE" . "$XDG_CACHE_HOME/.lesshst")
        ("SHELL" . ,(file-append zsh "/bin/zsh"))
        ("USELESS_VAR" . #f)
        ("_JAVA_AWT_WM_NONREPARENTING" . #t))))


(home-environment
  (packages
    ;(append
       (->packages-output ; ->packages ; map specification->package
          nuc-packages)
     ;  emacs-packages
     ; )
      
      )
  (services
    (append 
      (list
        bash-service
        fish-service
       ; mcron-service
        ;env-vars-service
        my-config-service)
      ;sway-services
      ;emacs-services
      ;alacritty-services
    )

    ))
