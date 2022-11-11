(use-modules
(awb99 packages systemcli)
(awb99 packages fonts))

(define-public desktop-packages
(append 
   desktop-chat-packages
  desktop-multimedia-packages
  desktop-office-packages
  desktop-browser-packages 
  desktop-tool-packages
))


(specifications->manifest desktop-packages)

