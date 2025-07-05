;;; ~/.config/nyxt/dark-reader.lisp
(define-configuration nx-dark-reader:dark-reader-mode
  ;; Note the nxdr: short package prefix. It's for your convenience :)
  ((nxdr:brightness 100)
   (nxdr:contrast 50)
   (nxdr:text-color "white")))

;; Add dark-reader to default modes
(define-configuration web-buffer
  ((default-modes `(nxdr:dark-reader-mode ,@%slot-value%))))
