;; -*- lexical-binding: t; -*-
;; Initialize package sources
(require 'package)

(setq package-archives '(("melpa" . "https://melpa.org/packages/")
                         ("org" . "https://orgmode.org/elpa/")
                         ("elpa" . "https://elpa.gnu.org/packages/")))

(package-initialize)
(unless package-archive-contents
 (package-refresh-contents))

;; Initialize use-package on non-Linux platforms
(unless (package-installed-p 'use-package)
   (package-install 'use-package))

(require 'use-package)
(setq use-package-always-ensure t)

(setq inhibit-startup-message t)

  (scroll-bar-mode -1)        ; Disable visible scrollbar
  (tool-bar-mode -1)          ; Disable the toolbar
  (tooltip-mode -1)           ; Disable tooltips
  (set-fringe-mode 10)        ; Give some breathing room

  (menu-bar-mode -1)            ; Disable the menu bar

  ;; Set up the visible bell
  (setq visible-bell t)

;; Show line numbers in some modes
(column-number-mode)
(dolist (mode '(prog-mode-hook))
  (add-hook mode (lambda () (display-line-numbers-mode 1))))

;; Disable line numbers in some modes
(dolist (mode '(org-mode-hook
  	      term-mode-hook
  	      eshell-mode-hook
  	      shell-mode-hook))

  (add-hook mode (lambda () (display-line-numbers-mode 0))))

(use-package doom-themes)
(use-package doom-modeline
  :ensure t
  :init (doom-modeline-mode 1)
  :custom ((doom-modeline-height 15)))

(load-theme 'doom-laserwave t)

;; Rainbow brackets
(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

;; Scale the font by the display size. For example, for a 4k display, it is 2160/10 = font size 216
(defun scaled-font-size()
  (/ (x-display-pixel-height) 8))

;; Set default font
(set-face-attribute 'default nil :font "Fira Code Retina" :height (scaled-font-size))

;; Set the fixed pitch face
(set-face-attribute 'fixed-pitch nil :font "Fira Code Retina" :height  (scaled-font-size))

;; Set the variable pitch face
(set-face-attribute 'variable-pitch nil :font "Cantarell" :height  (scaled-font-size) :weight 'regular)

(setq select-active-regions nil)

;; Make ESC quit prompts
(global-set-key (kbd "<escape>") 'keyboard-escape-quit)

;; general is useful for defining custom keybindings
(use-package general)

(general-define-key
 :prefix "C-c"
  "c" 'org-capture
  "j" 'vulpea-journal
  "f" 'vulpea-find)

(use-package which-key
  :init (which-key-mode)
  :diminish which-key-mode
  :config
  (setq which-key-idle-delay 0.5))

(org-babel-do-load-languages
   'org-babel-load-languages
   '((emacs-lisp . t)
     (python . t)))

(setq org-confirm-babel-evaluate nil)

(require 'org-tempo)

(add-to-list 'org-structure-template-alist '("sh" . "src shell"))
(add-to-list 'org-structure-template-alist '("el" . "src emacs-lisp"))
(add-to-list 'org-structure-template-alist '("py" . "src python"))

(defun efs/org-font-setup ()
  ;; Replace list hyphen with dot
  (font-lock-add-keywords 'org-mode
                          '(("^ *\\([-]\\) "
                             (0 (prog1 () (compose-region (match-beginning 1) (match-end 1) "•"))))))

  ;; Set faces for heading levels
  (dolist (face '((org-level-1 . 1.2)
                  (org-level-2 . 1.1)
                  (org-level-3 . 1.05)
                  (org-level-4 . 1.0)
                  (org-level-5 . 1.1)
                  (org-level-6 . 1.1)
                  (org-level-7 . 1.1)
                  (org-level-8 . 1.1)))
    (set-face-attribute (car face) nil :font "Cantarell" :weight 'regular :height (cdr face)))

  ;; Ensure that anything that should be fixed-pitch in Org files appears that way
  (set-face-attribute 'org-block nil :foreground nil :inherit 'fixed-pitch)
  (set-face-attribute 'org-code nil   :inherit '(shadow fixed-pitch))
  (set-face-attribute 'org-table nil   :inherit '(shadow fixed-pitch))
  (set-face-attribute 'org-verbatim nil :inherit '(shadow fixed-pitch))
  (set-face-attribute 'org-special-keyword nil :inherit '(font-lock-comment-face fixed-pitch))
  (set-face-attribute 'org-meta-line nil :inherit '(font-lock-comment-face fixed-pitch))
  (set-face-attribute 'org-checkbox nil :inherit 'fixed-pitch))


(defun efs/org-mode-setup ()
  (org-indent-mode)
  (variable-pitch-mode 1)
  (visual-line-mode 1))

(use-package org
  :hook (org-mode . efs/org-mode-setup)
  :config
  (setq org-ellipsis " ▾"
	org-hide-emphasis-markers t)
  (efs/org-font-setup))


(use-package org-bullets
  :after org
  :hook (org-mode . org-bullets-mode)
  :custom
  (org-bullets-bullet-list '("◉" "○" "●" "○" "●" "○" "●")))

(defun efs/org-mode-visual-fill ()
  (setq visual-fill-column-width 100
        visual-fill-column-center-text t)
  (visual-fill-column-mode 1))

(use-package visual-fill-column
  :hook (org-mode . efs/org-mode-visual-fill))

;; Automatically tangle our Emacs.org config file when we save it
(defun efs/org-babel-tangle-config ()
  (when (string-equal (buffer-file-name)
                      (expand-file-name "~/.emacs.d/emacs.org"))
    ;; Dynamic scoping to the rescue
    (let ((org-confirm-babel-evaluate nil))
      (org-babel-tangle))))

(add-hook 'org-mode-hook (lambda () (add-hook 'after-save-hook #'efs/org-babel-tangle-config)))

(require 'org-attach)

(setq org-directory (expand-file-name "~/org/"))
(setq org-attach-id-dir (expand-file-name "attach/" org-directory))
(setq org-attach-method 'cp)              ; copy, never move or symlink
(setq org-attach-store-link-p 'attached)
(setq org-attach-use-inheritance t)       ; sub-headings share the node's dir
(setq org-startup-with-inline-images t)

;; don't let org-roam index .org files you happen to attach
(setq org-roam-file-exclude-regexp '("^attach/" "\\.stversions/"))


;; The custom keybinds and functions to easily attach from windows WSL
(defun ap/wslpath (path &optional to-windows)
  (string-trim (shell-command-to-string
                (format "wslpath %s %s" (if to-windows "-w" "-u")
                        (shell-quote-argument path)))))

(defun ap/org-attach-from-windows-clipboard ()
  "Attach the file whose Windows path is on the Windows clipboard."
  (interactive)
  (let* ((raw (shell-command-to-string "powershell.exe -NoProfile -Command Get-Clipboard"))
         (win (string-trim raw "[ \t\n\r\"]+" "[ \t\n\r\"]+"))
         (file (ap/wslpath win)))
    (unless (file-regular-p file)
      (user-error "Not a file: %s" file))
    (org-attach-attach file nil 'cp)
    (insert (format "[[attachment:%s]]" (file-name-nondirectory file)))
    (org-display-inline-images)))

(defun ap/org-attach-clipboard-image ()
  "Save the image on the Windows clipboard as an attachment and link it."
  (interactive)
  (let* ((name (format-time-string "clip-%Y%m%d-%H%M%S.png"))
         (file (expand-file-name name (org-attach-dir 'create)))
         (win  (ap/wslpath file t)))
    (call-process
     "powershell.exe" nil nil nil "-Sta" "-NoProfile" "-Command"
     (format "Add-Type -AssemblyName System.Windows.Forms,System.Drawing; \
$i=[Windows.Forms.Clipboard]::GetImage(); if($null -eq $i){exit 1}; \
$i.Save('%s',[System.Drawing.Imaging.ImageFormat]::Png)" win))
    (unless (file-exists-p file)
      (user-error "No image on the Windows clipboard"))
    (insert (format "[[attachment:%s]]" name))
    (org-display-inline-images)))

(with-eval-after-load 'org
  (define-key org-mode-map (kbd "C-c C-x w") #'ap/org-attach-from-windows-clipboard)
  (define-key org-mode-map (kbd "C-c C-x v") #'ap/org-attach-clipboard-image))

;; Make sure the ~/org/ directory exists:
(unless (file-exists-p "~/org/")
  (make-directory "~/org/" t))   


(use-package vulpea)
(use-package vulpea-journal
  :after (vulpea-ui)
  :config
(vulpea-journal-setup))

(setq vulpea-db-sync-directories '("~/org/"))

;; Trigger the database scan.
;; I don't actually need to have this in here, its just so I don't forget the command.
(vulpea-db-sync-full-scan)

;; Enable auto syncing
(vulpea-db-autosync-mode +1)

;; Open journal on Emacs startup
(add-hook 'emacs-startup-hook #'vulpea-journal)

;; Default journal template
   (use-package vulpea-journal
     :after (vulpea vulpea-ui)
     :config
     (vulpea-journal-setup)

     (setq vulpea-journal-default-template
           (vulpea-journal-template-daily
            :file-name "daily/%Y-%m-%d.org"
            :title "%A, %B %d, %Y"
            :head "#+created: %<[%Y-%m-%d]>"
            :body "* Notes\n")))

   ;; Helper: build an org-capture `target' that prompts for a title,
   ;; creates a vulpea note with the given tags, and always stamps CREATED.
   ;; EXTRA-PROPERTIES, if given, is a zero-arg function returning an
   ;; alist of additional properties (called once, at capture time).
(cl-defun my/vulpea-capture-target (&key title-prompt (tags '()) extra-properties)
  (lambda ()
    (let* ((title (read-string title-prompt))
           (extra (when extra-properties (funcall extra-properties)))
           (defaults `(("CREATED" . ,(format-time-string "[%Y-%m-%d]"))
                       ("ALIASES" . "")))
           ;; keep every DEFAULTS entry whose key isn't already set by EXTRA
           (props (append extra
                           (seq-remove (lambda (kv) (assoc (car kv) extra))
                                       defaults))))
      (vulpea-note-path
       (vulpea-create title nil :tags tags :properties props)))))


   (setq org-capture-templates
         `(("n" "Note" plain
  (file ,(my/vulpea-capture-target :title-prompt "Quick Note Title: "))
  "%?")

           ("l" "Lab notebook entry" plain
            (file ,(my/vulpea-capture-target
                    :title-prompt "Lab entry title: "
                    :tags '("lab")
                    :extra-properties
                    (lambda ()
                      (let ((page-id (read-string "Page ID: ")))
                        `(("PAGE_ID" . ,page-id)
                          ("ALIASES" . ,page-id))))))
            "* Notes\n%?"
            :unnarrowed t)

           ("e" "Experiment" plain
            (file ,(my/vulpea-capture-target
                    :title-prompt "Experiment Title: "
                    :tags '("exp")))
            "* Notes\n%?"
            :unnarrowed t)

             ("s" "Supplier" plain
            (file ,(my/vulpea-capture-target
                    :title-prompt "Supplier Name : "
                    :tags '("supplier")
                    :extra-properties
                    (lambda ()
                      (let ((parts-supplied (read-string "Parts Supplied : ")))
                        `(("PARTS_SUPPLIED" . ,parts-supplied)
                          ("ALIASES" . ,parts-supplied))))))
            "* Notes\n%?"
            :unnarrowed t)))

;; Disable  unwanted widgets
(use-package vulpea-ui
  :config
  (dolist (widget '(stats previous-years))
  (vulpea-ui-unregister-widget widget)))

;; Journal ui widget order
(setq vulpea-journal-ui-widget-ui-orders
 '((nav . 50)
   (calendar . 150)
   (created-today . 350)
   (previous-years . 360)))

(add-hook 'after-init-hook
          (lambda ()
            (start-process "syncthing" "*syncthing-output" "syncthing" "-no-browser")))

(use-package ivy
    :diminish
    :demand t
    :bind (("C-s" . swiper)
           :map ivy-minibuffer-map
           ("TAB" . ivy-alt-done)	
           ("C-l" . ivy-alt-done)
           ("C-j" . ivy-next-line)
           ("C-k" . ivy-previous-line)
           :map ivy-switch-buffer-map
           ("C-k" . ivy-previous-line)
           ("C-l" . ivy-done)
           ("C-d" . ivy-switch-buffer-kill)
           :map ivy-reverse-i-search-map
           ("C-k" . ivy-previous-line)
           ("C-d" . ivy-reverse-i-search-kill))
    :config
    (ivy-mode 1))



(use-package ivy-rich
  :init
  (ivy-rich-mode 1))

(use-package counsel
  :bind (("M-x" . counsel-M-x)
	 ("C-x b" . counsel-ibuffer)
	 ("C-x C-f" . counsel-find-file)
	 :map minibuffer-local-map
	 ("C-r" . 'counsel-minibuffer-history))
  :config
  (setq ivy-initial-inputs-alist nil)) ;; Don't start searches with ^

(use-package helpful
  :ensure t
  :custom
  (counsel-describe-function-function #'helpful-callable)
  (counsel-describe=variablefunction #'helpful=variable)
  :bind
  ([remap describe-function] . counsel-describe-function)
  ([remap describe-command] . helpful-command)
  ([remap describe-variable] . counsel-describe-variable)
  ([remap describe-key] . helpful-key))

;; Projectile detects you're in a code repo folder and loads some project-specific behaviour
(use-package projectile
  :diminish projectile-mode
  :config (projectile-mode)
  :custom ((projectile-completion-system 'ivy))
  :bind-keymap
  ("C-c p" . projectile-command-map)
  :init
  (when (file-directory-p "~/Projects/Code")
    (setq projecitle-project-search-path '("~/Projects/Code")))
  (setq projecitle-switch-project-action #'projectile-dired))

(use-package counsel-projectile
  :config (counsel-projectile-mode))

(use-package gcmh
  :ensure t
  :config
  (gcmh-mode 1))
