; stolen from:
; https://github.com/mnd/guix-mnd-pkgs/blob/master/mnd/services/minidlna.scm

(define-module (awb99 services readymedia)
#:use-module (gnu services)
#:use-module (gnu services shepherd)
#:use-module (gnu system shadow)
#:use-module (gnu packages admin)
#:use-module (gnu packages upnp) ; minidlna=readymedia
#:use-module (guix gexp)
#:use-module (guix records)
#:use-module (ice-9 match)
#:export (minidlna-service
          minidlna-service-type
          minidlna-configuration))

(define-record-type* <minidlna-configuration>
minidlna-configuration make-minidlna-configuration
minidlna-configuration?
(minidlna      minidlna-configuration-minidlna      ;<package>
               (default readymedia))
(user          minidlna-configuration-user          ;string
               (default "minidlna"))
(usergroup     minidlna-configuration-user          ;string
              (default "minidlna"))
(mediadir      minidlna-configuration-mediadir)     ;string
(dbdir         minidlna-configuration-dbdir         ;string
               (default "/var/cache/minidlna"))
(logdir        minidlna-configuration-logdir        ;string
               (default "/var/log"))
(pidfile       minidlna-configuration-pidfile       ;string
               (default "/var/run/minidlna/minidlna.pid"))
(extra-config  minidlna-configuration-extra-config  ;string
               (default ""))
(extra-options minidlna-configuration-extra-options ;list of strings
               (default '())))

;;; TODO: There should be minissdpd service that will be used by minidlna
;;; to allow several UPnP devices on single machine
(define minidlna-config-file
(match-lambda
  (($ <minidlna-configuration> minidlna user usergroup mediadir dbdir logdir pidfile extra-config extra-options)
   (plain-file "minidlna.conf"
               (string-append "#Generated by minidlna-service
port=8200
user=" user "
media_dir=" mediadir "
db_dir=" dbdir "
log_dir=" logdir "
album_art_names=Cover.jpg/cover.jpg/AlbumArtSmall.jpg/albumartsmall.jpg/AlbumArt.jpg/albumart.jpg/Album.jpg/album.jpg/Folder.jpg/folder.jpg/Thumb.jpg/thumb.jpg
inotify=yes
strict_dlna=no
" extra-config)))))

(define minidlna-accounts
(match-lambda
  (($ <minidlna-configuration> minidlna user usergroup mediadir dbdir logdir pidfile extra-config extra-options)
   (list (user-group (name user) (system? #t))
         (user-account
          (name user)
          (group user)
          (supplementary-groups (list usergroup))
          (system? #t)
          (comment "minidlna daemon system account")
          (home-directory "/var/empty") 
          (shell (file-append shadow "/sbin/nologin")))))))

(define minidlna-activation
(match-lambda
  (($ <minidlna-configuration> minidlna user usergroup mediadir dbdir logdir pidfile extra-config extra-options)
   #~(begin
       (use-modules (guix build utils))
       ;(mkdir-p #$mediadir)
       (mkdir-p #$dbdir)
       (mkdir-p #$logdir)
       (mkdir-p #$(dirname pidfile))
      ; (let ((user2 (getpwnam "minidlna")))
      ;   (chown #$(dirname pidfile) #$(passwd:uid user2) #$(passwd:gid user2)))
       ))))

(define (minidlna-shepherd-service config)
(match config
  (($ <minidlna-configuration> minidlna user usergroup mediadir dbdir logdir pidfile extra-config extra-options)
   (list (shepherd-service
          (provision '(minidlna))
          (documentation "Run minidlna daemon")
          (requirement '(networking user-processes))
          (start #~(make-forkexec-constructor
                    (list #$(file-append minidlna "/sbin/minidlnad")
                          "-d" "-f" #$(minidlna-config-file config)
                          "-P" #$pidfile
			  )
;		    #:user #$user
                    #:pid-file #$pidfile
                    #:log-file "/var/log/minidlnad.log"))
          (stop #~(make-kill-destructor)))))))

(define minidlna-service-type
(service-type (name 'minidlna)
              (description "minidlna service that allow to share media resources to TVsets")
              (extensions
               (list (service-extension shepherd-root-service-type
                                        minidlna-shepherd-service)
                     (service-extension activation-service-type
                                        minidlna-activation)
                     (service-extension account-service-type
                                        minidlna-accounts)))))

(define* (minidlna-service #:key (minidlna minidlna)
                                 (user "minidlna")
                                 (usergroup "minidlna")
                                 (mediadir "/var/lib/minidlna")
                                 (dbdir "/var/cache/minidlna")
                                 (logdir "/var/log")
                                 (pidfile "/var/run/minidlna/minidlna.pid")
                                 (extra-config  "")
                                 (extra-options '()))
"Return a service that runs @command{minidlnad} daemon with specified @var{user} and directories"
(service minidlna-service-type
         (minidlna-configuration
            (minidlna minidlna) 
            (user user)
            (usergroup usergroup)
            (mediadir mediadir) 
            (dbdir dbdir)
            (logdir logdir) 
            (pidfile pidfile)
            (extra-config extra-config)
            (extra-options extra-options))))
