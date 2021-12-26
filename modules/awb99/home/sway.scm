(define-module (awb99 home sway)
#:use-module (srfi srfi-1)
#:use-module (guix gexp)
#:use-module (gnu home services)
#:use-module (gnu home-services wm)
;#:use-module (awb99 home i3blocks)
;#:use-module (home services mako)
;#:use-module (home services swappy)
#:use-module (gnu packages gnupg)
;#:use-module (kreved packages wm)
)

(define ws-bindings
(map (lambda (ws)
       `(,(string->symbol (format #f "$mod+~d" ws))
         workspace number ,ws))
     (iota 9 1)))

(define ws-move-bindings
(map (lambda (ws)
       `(,(string->symbol (format #f "$mod+Shift+~d" ws))
         move container to workspace number ,ws))
     (iota 9 1)))

(define-public sway-services
(list
 (service
  home-sway-service-type
  (home-sway-configuration
   ;; (package sway-next)
   (config
    `((set $mod Mod4)
      (set $left b)
      (set $right f)
      (set $up p)
      (set $down n)

      (set $term alacritty)
      (set $menu bemenu-run
           --prompt "'run:'"
           --ignorecase)

      (bindsym
       --to-code
       (($mod+Return exec $term)
        ($mod+space exec $menu)
        ($mod+c kill)
        ($mod+q reload)
        ($mod+Shift+q exec swaymsg exit)
        ($mod+$up focus prev)
        ($mod+$down focus next)
        ($mod+Shift+$left move left)
        ($mod+Shift+$right move right)
        ($mod+Shift+$up move up)
        ($mod+Shift+$down move down)
        ($mod+f fullscreen)
        ($mod+Tab layout toggle split tabbed)
        ($mod+Shift+Tab split toggle)
        ($mod+grave floating toggle)
        ($mod+Shift+grave focus mode_toggle)
        ($mod+Shift+s exec "grim -g \"$(slurp)\" - | swappy -f -")
        (Print exec "grim - | wl-copy -t image/png")
        ($mod+g exec makoctl dismiss --all)
        ($mod+m exec makoctl set-mode dnd)
        ($mod+Shift+m exec makoctl set-mode default)
        ($mod+o exec "ykman oath list | bemenu --prompt 'otp:' --ignorecase | xargs -I {} -r ykman oath code -s '{}' | wl-copy")
        ,@ws-bindings
        ,@ws-move-bindings))

      (bindsym
       --locked
       ((XF86MonBrightnessUp exec light -A 10)
        (XF86MonBrightnessDown exec light -U 10)))

      (exec swayidle -w
            before-sleep "'swaylock -f'"
            timeout 1800 "'swaylock -f'"
            timeout 2400 "'swaymsg \"output * dpms off\"'"
            resume "'swaymsg \"output * dpms on\"'")
      (exec wlsunset -l 50.6 -L 36.6 -T 6500 -t 3000)
      (exec mako)

      (xwayland disable)
      (workspace_auto_back_and_forth yes)
      (focus_follows_mouse no)
      (smart_borders on)
      (title_align center)

;      (output * bg ,(local-file "files/wp.jpg") fill)
      (output eDP-1 scale 1.33)

      (input "1:1:AT_Translated_Set_2_keyboard"
             ((xkb_layout us,ru)
              (xkb_options grp:toggle,ctrl:swapcaps)))
      (input "1133:45890:Keyboard_K380_Keyboard"
             ((xkb_layout us,ru)
              (xkb_options grp:toggle,ctrl:swapcaps)))
      (input type:touchpad events disabled)
      (input "2:10:TPPS/2_IBM_TrackPoint"
             ((pointer_accel 0.3)
              (scroll_factor 0.8)))
      (input "1390:268:ELECOM_TrackBall_Mouse_HUGE_TrackBall"
             ((scroll_method on_button_down)
              (scroll_button BTN_TASK)))

      (assign "[app_id=\"nyxt\"]" 2)
      (assign "[app_id=\"chromium-browser\"]" 2)
      (assign "[app_id=\"emacs\"]" 3)
      (assign "[app_id=\"telegramdesktop\"]" 4)

      (for_window
       "[app_id=\"telegramdesktop\" title=\"Media viewer\"]"
       focus)
      (for_window
       "[app_id=\"^.*\"]"
       inhibit_idle fullscreen)
      (for_window
       "[title=\"^(?:Open|Save) (?:File|Folder|As).*\"]"
       floating enable, resize set width 70 ppt height 70 ppt)

      (font "Iosevka, Light 14")
      (client.focused "#f0f0f0" "#f0f0f0" "#721045" "#721045" "#721045")
      (client.unfocused "#ffffff" "#ffffff" "#595959")
      (default_border normal 0)
      (default_floating_border none)
      (gaps inner 8)
      (seat * xcursor_theme Adwaita 24)

      (bar
       ((status_command i3blocks)
        (position top)
        (separator_symbol "|")
        (font "Iosevka, Light 18")
        (pango_markup enabled)
        (colors
         ((statusline "#000000")
          (background "#FFFFFF")
          (focused_workspace "#f0f0f0" "#f0f0f0" "#721045")
          (inactive_workspace "#ffffff" "#ffffff" "#595959")))))))))

 ;(service
 ; home-i3blocks-service-type
 ; (home-i3blocks-configuration
 ;  (config
 ;   `((battery1
 ;      ((command . ,(local-file "files/battery" #:recursive? #t))
 ;       (BAT_NUM . 1)
 ;       (interval . 10)))
 ;     (battery0
 ;      ((command . ,(local-file "files/battery" #:recursive? #t))
 ;       (BAT_NUM . 0)
 ;       (interval . 10)))
 ;     (date
 ;      ((command . "date '+%a, %d %b'")
 ;       (interval . 1)))
 ;     (time
 ;      ((command . "date +%H:%M:%S")
 ;       (interval . 1)))))))


))