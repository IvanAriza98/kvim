;; when experiencing rendering issues
(setf (uiop/os:getenv "WEBKIT_DISABLE_COMPOSITING_MODE") "1")


(defvar *my-search-engines*
  (list
   ;; General Places
   '("gg" "https://google.com/search?q=~a" "https://google.com")
   '("yt" "https://www.youtube.com/results?search_query=~a" "https://youtube.com")
   '("wa" "https://web.whatsapp.com/?locale=~a" "https://web.whatsapp.com")
   ;; Artificial Intelligence
   '("ia-gpt" "https://chatgpt.com/#" "https://chatgpt.com/#")
   '("ia-dps" "https://chat.deepseek.com/" "https://chat.deepseek.com/")
   '("ia-mis" "https://chat.mistral.ai/chat" "https://chat.mistral.ai/chat"))
  "List of search engines.")

(define-configuration context-buffer
  "Go through the search engines above and make-search-engine out of them."
  ((search-engines
    (append
     (mapcar (lambda (engine) (apply 'make-search-engine engine))
             *my-search-engines*)
     %slot-default%))))


(define-configuration browser
    ((keymap
       (let ((map (make-keymap)))
	    (define-key map
		"C-h" 'history-backward
		"C-l" 'history-forward)
	     map))))

;; Change automatically when I'm in a input html code
(define-configuration prompt-buffer
    ((default-modes (append '(vi-insert-mode) %slot-default%))))

;; ~~~~~~~ EXTENSIONS ~~~~~~~
;; Adding Dark Reader Extension
;; (define-nyxt-user-system-and-load "nyxt-user/dark-reader"
;;     :components ("dark-reader.lisp")
;;     :depends-on (:nx-dark-reader))

;; ~~~~~~~ GENERAL THEME ~~~~~~~
(defvar invader-theme 
  (make-instance 'theme:theme
		 :dark-p t
		 :background-color-	"#303240"
		 :background-color	"#282A36"
		 :background-color+	"#1E2029"
		 :on-background-color	"#F7FBFC"

		 :primary-color-	"#679BCF"
		 :primary-color		"#789FE8"
		 :primary-color+	"#7FABD7"
		 :on-primary-color	"#0C0C0D"
		    
		 :secondary-color-	"#44475A"
		 :secondary-color	"#44475A"
		 :secondary-color+	"#535A6E"
		 :on-secondary-color	"#F7FBFC"

		 :action-color-		"#5EEDE1"
		 :action-color		"#10E0CC"
		 :action-color+		"#0BB29F"
		 :on-action-color	"#0C0C0D"

		 :success-color-	"#86D58E"
		 :success-color		"#8AEA92"
		 :success-color+	"#71FE7D"
		 :on-success-color	"#0C0C0D"
		
		 :highlight-color-	"#EA43DD"
		 :highlight-color	"#F45DE8"
		 :highlight-color+	"#FC83F2"
		 :on-highlight-color	"#0C0C0D"
		 
		 :warning-color-	"#FCA904"
		 :warning-color		"#FCBA04"
		 :warning-color+	"#FFD152"
		 :on-warning-color	"#0C0C0D"

		 :codeblock-color-	"#3C5FAA"
		 :codeblock-color	"#355496"
		 :codeblock-color+	"#2D4880"
		 :on-codeblock-color	"#F7FBFC"))

(define-configuration browser
    ((theme invader-theme)))


;; TODOOOO
;; Close buffer
;; Close Nyxt -> Z Z
