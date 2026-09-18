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

(when (< emacs-major-version 29)
  (error "This config requires Emacs 29+, but you're running %s. Update Emacs before proceeding." emacs-version))

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

(defun my-org-insert-current-datetime ()
  "Insert an active timestamp with the current date and time."
  (interactive)
  (org-insert-time-stamp (current-time) t))

;; Make ESC quit prompts
(global-set-key (kbd "<escape>") 'keyboard-escape-quit)

;; general is useful for defining custom keybindings
(use-package general)

(general-define-key
 :prefix "C-c"
  "c" 'org-capture
  "j" 'vulpea-journal
  "f" 'vulpea-find
  "i" 'vulpea-insert
  "t" 'my-org-insert-current-datetime
  "l" 'my/lab-notebook-list)

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
  (file ,(my/vulpea-capture-target
          :title-prompt "Quick Note Title: "
          :tags '("")))
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

;; Shared helpers -----------------------------------------------------

(defun my/lab-notebook--notes ()
  "All vulpea notes tagged \"lab\"."
  (vulpea-db-query-by-tags-some '("lab")))

(defun my/lab-notebook--page-id (note)
  (alist-get "PAGE_ID" (vulpea-note-properties note) nil nil #'string=))

(defun my/lab-notebook--parse-page-id (page-id)
  "Split PAGE-ID into (INITIALS BOOK-NUM PAGE-NUM), or nil if it doesn't match."
  (when (and page-id
             (string-match "\\`\\([A-Za-z]+\\)\\([0-9]\\)\\([0-9][0-9][0-9]\\)\\'" page-id))
    (list (match-string 1 page-id)
          (string-to-number (match-string 2 page-id))
          (string-to-number (match-string 3 page-id)))))

;; Next / previous page navigation ------------------------------------

(defun my/lab-notebook--notebook-notes (initials book)
  "(PAGE-NUM . NOTE) pairs for INITIALS/BOOK, ascending by page number."
  (let (result)
    (dolist (note (my/lab-notebook--notes))
      (let ((parsed (my/lab-notebook--parse-page-id (my/lab-notebook--page-id note))))
        (when (and parsed (string= (nth 0 parsed) initials) (= (nth 1 parsed) book))
          (push (cons (nth 2 parsed) note) result))))
    (sort result (lambda (a b) (< (car a) (car b))))))

(defun my/lab-notebook--goto (direction)
  (let* ((current-id (org-entry-get (point-min) "PAGE_ID"))
         (parsed (and current-id (my/lab-notebook--parse-page-id current-id))))
    (unless parsed
      (user-error "Not a lab notebook entry (no PAGE_ID property found)"))
    (cl-destructuring-bind (initials book page) parsed
      (let* ((immediate-page (+ page direction))
             (immediate-id (format "%s%d%03d" initials book immediate-page))
             (candidates (my/lab-notebook--notebook-notes initials book))
             (target (if (> direction 0)
                         (seq-find (lambda (c) (> (car c) page)) candidates)
                       (car (last (seq-filter (lambda (c) (< (car c) page)) candidates))))))
        (when (or (not target) (/= (car target) immediate-page))
          (message "No entry found for %s" immediate-id))
        (when target
          (find-file (vulpea-note-path (cdr target))))))))

(defun my/lab-notebook-next-page ()
  (interactive)
  (my/lab-notebook--goto 1))

(defun my/lab-notebook-previous-page ()
  (interactive)
  (my/lab-notebook--goto -1))

;; Minor mode: fast C-c n / C-c p, scoped to lab notebook buffers only ---
;;
;; C-c p is also projectile's command-map prefix. Rather than avoid "p"
;; globally, this minor mode's keymap is registered in
;; `emulation-mode-map-alists', which Emacs consults before ordinary
;; minor-mode keymaps (including projectile-mode's), so C-c n/C-c p always
;; mean "next/previous page" here regardless of load order -- and are
;; simply inert everywhere else, where projectile's C-c p is untouched.

(defvar lab-notebook-entry-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c n") #'my/lab-notebook-next-page)
    (define-key map (kbd "C-c p") #'my/lab-notebook-previous-page)
    map)
  "Keymap for `lab-notebook-entry-mode'.")

(define-minor-mode lab-notebook-entry-mode
  "Minor mode with fast navigation keys for a lab notebook entry."
  :lighter " Lab"
  :keymap lab-notebook-entry-mode-map)

(add-to-list 'emulation-mode-map-alists
             `((lab-notebook-entry-mode . ,lab-notebook-entry-mode-map)))

(defun my/lab-notebook-entry-mode-maybe-enable ()
  (when (org-entry-get (point-min) "PAGE_ID")
    (lab-notebook-entry-mode 1)))

(add-hook 'org-mode-hook #'my/lab-notebook-entry-mode-maybe-enable)

;; Tabulated overview buffer -------------------------------------------

(defvar-local lab-notebook-list--filter nil
  "Substring filter (matched against Page ID or Title), or nil for none.")

(defun my/lab-notebook-list--entries ()
  (let ((filter lab-notebook-list--filter))
    (seq-keep
     (lambda (note)
       (let* ((page-id (or (my/lab-notebook--page-id note) ""))
              (created (or (alist-get "CREATED" (vulpea-note-properties note) nil nil #'string=) ""))
              (title (or (vulpea-note-title note) "")))
         (when (or (not filter)
                   (string-match-p (regexp-quote filter) page-id)
                   (string-match-p (regexp-quote filter) title))
           (list (vulpea-note-path note)
                 (vector (propertize page-id 'face 'font-lock-keyword-face)
                         (propertize created 'face 'font-lock-comment-face)
                         title)))))
     (my/lab-notebook--notes))))

(define-derived-mode lab-notebook-list-mode tabulated-list-mode "Lab-Notebook"
  "Major mode listing all lab notebook entries."
  (setq tabulated-list-format [("Page ID" 12 t) ("Date" 12 t) ("Title" 0 t)])
  (setq tabulated-list-sort-key (cons "Date" t)) ; most recent first
  (setq tabulated-list-entries #'my/lab-notebook-list--entries)
  (tabulated-list-init-header))

(defun lab-notebook-list-visit ()
  (interactive)
  (let ((path (tabulated-list-get-id)))
    (when path (find-file path))))

(defun lab-notebook-list-sort-by-column ()
  "Prompt for a column and sort the table by it (repeat to flip direction)."
  (interactive)
  (let* ((names (mapcar #'car (append tabulated-list-format nil)))
         (name (completing-read "Sort by: " names nil t))
         (col (seq-position names name)))
    (tabulated-list-sort col)))

(defun lab-notebook-list-set-filter (filter)
  "Filter the table to entries whose Page ID or Title contains FILTER."
  (interactive
   (list (read-string "Filter (Page ID/Title substring, empty to clear): "
                       lab-notebook-list--filter)))
  (setq lab-notebook-list--filter (unless (string-empty-p filter) filter))
  (tabulated-list-print t))

(defun lab-notebook-list-clear-filter ()
  (interactive)
  (setq lab-notebook-list--filter nil)
  (tabulated-list-print t))

(define-key lab-notebook-list-mode-map (kbd "RET") #'lab-notebook-list-visit)
(define-key lab-notebook-list-mode-map (kbd "s") #'lab-notebook-list-sort-by-column)
(define-key lab-notebook-list-mode-map (kbd "/") #'lab-notebook-list-set-filter)
(define-key lab-notebook-list-mode-map (kbd "c") #'lab-notebook-list-clear-filter)

(defun my/lab-notebook-list ()
  (interactive)
  (let ((buf (get-buffer-create "*Lab Notebook*")))
    (with-current-buffer buf
      (lab-notebook-list-mode)
      (tabulated-list-print t))
    (switch-to-buffer buf)))

(add-hook 'after-init-hook
          (lambda ()
            (start-process "syncthing" "*syncthing-output" "syncthing" "-no-browser")))

(setq make-backup-files t
      backup-by-copying t
      version-control t
      delete-old-versions t
      kept-new-versions 20
      kept-old-versions 5
      backup-directory-alist '(("." . "~/.emacs.d/backups")))

(defun my/guard-empty-overwrite (fn &rest args)
  (when (and (buffer-file-name)
             (file-exists-p (buffer-file-name))
             (= (buffer-size) 0)
             (> (file-attribute-size (file-attributes (buffer-file-name))) 0))
    (unless (yes-or-no-p
             (format "Buffer for %s is EMPTY but disk file has content. Save anyway? "
                     (buffer-file-name)))
      (user-error "Aborted: buffer empty, disk file is not")))
  (apply fn args))
(advice-add 'save-buffer :around #'my/guard-empty-overwrite)

(defun my/diff-before-supersession-prompt (fn &rest args)
  (when (buffer-file-name)
    (diff-buffer-with-file (current-buffer))
    (when-let ((win (get-buffer-window "*Diff*")))
      (select-window win)))
  (apply fn args))
(advice-add 'ask-user-about-supersession-threat
            :around #'my/diff-before-supersession-prompt)

(global-auto-revert-mode 1)
(setq auto-revert-avoid-polling-method 'watch
      auto-revert-verbose nil)

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

(use-package prescient
  :config
  (setq prescient-filter-method '(literal fuzzy))
  (prescient-persist-mode 1))

(use-package ivy-prescient
  :after (ivy counsel)
  :custom
  ;; Frecency-sort everything EXCEPT commands where you're searching by
  ;; content for one specific thing (a note, a citation) rather than
  ;; picking from a short list of usual suspects.
  (ivy-prescient-sort-commands
   '(:not swiper swiper-isearch ivy-switch-buffer
     vulpea-find vulpea-insert
     citar-insert-citation citar-open citar-open-notes
     citar-open-files citar-dwim))
  :config
  (ivy-prescient-mode 1))

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

(require 'org-attach)

   ;;; ---------------------------------------------------------------- helpers

(defun ap/wslpath (path &optional to-windows)
  "Convert PATH between WSL and Windows form.  Return nil on failure."
  (with-temp-buffer
    (when (zerop (call-process "wslpath" nil t nil
                               (if to-windows "-w" "-u") path))
      (string-trim (buffer-string)))))


(defcustom ap/org-attach-image-max-dimension 1920
  "Longest edge, in pixels, for images pasted from the clipboard."
  :type 'integer)

(defcustom ap/org-attach-image-format 'auto
  "Encoding for clipboard images.
 `auto' picks JPEG for sources above `ap/org-attach-image-photo-pixels'
 \(camera photos, full-screen grabs) and PNG below it (cropped
 screenshots, diagrams), where lossless text matters."
  :type '(choice (const auto) (const png) (const jpeg)))

(defcustom ap/org-attach-image-photo-pixels 2000000
  "Source pixel count above which `auto' format chooses JPEG."
  :type 'integer)

(defcustom ap/org-attach-image-jpeg-quality 85
  "JPEG quality, 1-100."
  :type 'integer)

(defconst ap/org-attach--probe-script
  (concat
   "[Console]::OutputEncoding=[Text.Encoding]::UTF8; "
   "Add-Type -AssemblyName System.Windows.Forms,System.Drawing; "
   "if ([Windows.Forms.Clipboard]::ContainsFileDropList()) "
   "{ 'files'; [Windows.Forms.Clipboard]::GetFileDropList() | ForEach-Object { $_ } } "
   "elseif ([Windows.Forms.Clipboard]::ContainsImage()) "
   "{ $i=[Windows.Forms.Clipboard]::GetImage(); "
   "if ($null -eq $i) { 'none' } else { "
   "$max=%d; $mp=%d; $q=%d; $fmt='%s'; $base='%s'; "
   "$src=$i.Width*$i.Height; "
   "if ($i.Width -gt $max -or $i.Height -gt $max) { "
   "$r=[Math]::Min($max/$i.Width,$max/$i.Height); "
   "$w=[int]($i.Width*$r); $h=[int]($i.Height*$r); "
   "$b=New-Object Drawing.Bitmap $w,$h; "
   "$g=[Drawing.Graphics]::FromImage($b); "
   "$g.InterpolationMode='HighQualityBicubic'; "
   "$g.PixelOffsetMode='HighQuality'; $g.SmoothingMode='HighQuality'; "
   "$g.DrawImage($i,0,0,$w,$h); $g.Dispose(); $i.Dispose(); $i=$b } "
   "if ($fmt -eq 'auto') { if ($src -gt $mp) { $fmt='jpeg' } else { $fmt='png' } } "
   "if ($fmt -eq 'jpeg') { "
   "$flat=New-Object Drawing.Bitmap $i.Width,$i.Height; "
   "$g2=[Drawing.Graphics]::FromImage($flat); "
   "$g2.Clear([Drawing.Color]::White); "
   "$g2.DrawImage($i,0,0,$i.Width,$i.Height); $g2.Dispose(); "
   "$ec=[Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | "
   "Where-Object { $_.MimeType -eq 'image/jpeg' }; "
   "$ep=New-Object Drawing.Imaging.EncoderParameters 1; "
   "$ep.Param[0]=New-Object Drawing.Imaging.EncoderParameter "
   "([Drawing.Imaging.Encoder]::Quality),([int64]$q); "
   "$out=$base + '.jpg'; $flat.Save($out,$ec,$ep) } "
   "else { $out=$base + '.png'; "
   "$i.Save($out,[Drawing.Imaging.ImageFormat]::Png) } "
   "'image'; $out } } "
   "elseif ([Windows.Forms.Clipboard]::ContainsText()) "
   "{ 'text'; [Windows.Forms.Clipboard]::GetText() } "
   "else { 'none' }")
  "Clipboard probe.  Format args: max edge, photo threshold, JPEG
 quality, format name, and an EXTENSIONLESS Windows base path  the
 script picks the extension and echoes the path it actually wrote.
 Deliberately free of double quotes so it survives WSL interop.
 Run under `powershell.exe' -Sta; pwsh 7 is MTA and GetImage
 returns null there.")

(defun ap/org-attach--probe-clipboard (image-base)
  "Inspect the Windows clipboard once, writing any bitmap near IMAGE-BASE.
 IMAGE-BASE has no extension.  Return (KIND . LINES); for `image',
 the single line is the Windows path actually written."
  (let* ((win (or (ap/wslpath image-base t)
                  (user-error "wslpath could not map %s" image-base)))
         (script (format ap/org-attach--probe-script
                         ap/org-attach-image-max-dimension
                         ap/org-attach-image-photo-pixels
                         ap/org-attach-image-jpeg-quality
                         (symbol-name ap/org-attach-image-format)
                         (replace-regexp-in-string "'" "''" win)))
         (coding-system-for-read 'utf-8-dos))
    (with-temp-buffer
      (unless (zerop (call-process "powershell.exe" nil t nil
                                   "-NoProfile" "-NonInteractive" "-Sta"
                                   "-Command" script))
        (user-error "Clipboard probe failed: %s"
                    (string-trim (buffer-string))))
      (let ((lines (split-string (buffer-string) "\n" t "[ \t\r]+")))
        (cons (intern (or (car lines) "none")) (cdr lines))))))


(defun ap/org-attach--sanitize (name)
  "Strip characters from NAME that Syncthing cannot write onto Windows peers."
  (replace-regexp-in-string "[[:cntrl:]:*?\"<>|]" "_" name))

(defun ap/org-attach--free-name (dir name)
  "Return NAME, or NAME-1, NAME-2 ... so it does not exist in DIR."
  (let* ((base (file-name-base name))
         (ext (or (file-name-extension name t) ""))
         (try name)
         (n 0))
    (while (file-exists-p (expand-file-name try dir))
      (setq try (format "%s-%d%s" base (cl-incf n) ext)))
    try))

(defun ap/org-attach--place (src &optional rename)
  "Attach SRC to the node at point, copying it.  Return the basename used.
   Never clobbers an existing attachment.  With RENAME, prompt for the name."
  (let* ((dir (org-attach-dir-get-create))
         (want (ap/org-attach--sanitize (file-name-nondirectory src)))
         (want (if rename
                   (ap/org-attach--sanitize
                    (read-string "Attach as: " want))
                 want))
         (final (ap/org-attach--free-name dir want)))
    (if (equal final want)
        (org-attach-attach src nil 'cp)
      ;; Stage under the free name so `org-attach-attach' still runs its
      ;; hooks and adds the ATTACH tag, rather than hand-rolling the copy.
      (let* ((stage (make-temp-file "org-attach-" t))
             (staged (expand-file-name final stage)))
        (unwind-protect
            (progn (copy-file src staged)
                   (org-attach-attach staged nil 'mv))
          (delete-directory stage t))))
    final))

(defun ap/org-attach--resolve (s)
  "Return an existing file named by string S, or nil."
  (let ((s (string-trim s "[ \t\r\n\"']+" "[ \t\r\n\"']+")))
    (cond
     ((string-empty-p s) nil)
     ((string-match-p "\\`\\([a-zA-Z]:\\|\\\\\\\\\\)" s)
      (let ((p (ap/wslpath s))) (and p (file-regular-p p) p)))
     ((file-regular-p (expand-file-name s)) (expand-file-name s))
     (t nil))))

   ;;; ---------------------------------------------------------------- command

(defun ap/org-attach-clipboard (&optional rename)
  "Attach whatever is on the Windows clipboard to the Org node at point.

   Handles, in priority order: files copied in Explorer, a bitmap image
   \(Win+Shift+S), or text naming an existing file (Copy as path).  Inserts
   an `attachment:' link for each.  With prefix RENAME, prompt for names."
  (interactive "P")
  (unless (derived-mode-p 'org-mode)
    (user-error "Not in an Org buffer"))
  (let* ((stage (make-temp-file "org-clip-" t))
         (shot (expand-file-name                       ; no extension now
                (format-time-string "clip-%Y%m%d-%H%M%S") stage))
         names)
    (unwind-protect
        (pcase-let ((`(,kind . ,lines) (ap/org-attach--probe-clipboard shot)))
          (pcase kind
            ('files
             (dolist (f lines)
               (let ((p (ap/wslpath f)))
                 (cond ((and p (file-regular-p p))
                        (push (ap/org-attach--place p rename) names))
                       ((and p (file-directory-p p))
                        (message "Skipping directory: %s" f))))))

            ('image
             (let ((saved (and lines (ap/wslpath (car lines)))))
               (unless (and saved (file-regular-p saved))
                 (user-error "Clipboard bitmap could not be saved"))
               (push (ap/org-attach--place saved rename) names)))



            ('text
             (let ((hits (delq nil (mapcar #'ap/org-attach--resolve lines))))
               (unless hits
                 (user-error "Clipboard text is not a path to an existing file: %s"
                             (truncate-string-to-width
                              (or (car lines) "") 60 nil nil t)))
               (dolist (p hits) (push (ap/org-attach--place p rename) names))))
            (_ (user-error "Clipboard is empty"))))
      (delete-directory stage t))
    (setq names (nreverse names))
    (unless names (user-error "Nothing was attached"))
    (when (org-at-heading-p) (org-end-of-meta-data t))
    (insert (mapconcat (lambda (n) (format "[[attachment:%s]]" n)) names "\n")
            "\n")
    (org-display-inline-images)
    (message "Attached %d file%s: %s"
             (length names) (if (cdr names) "s" "")
             (string-join names ", "))))

(with-eval-after-load 'org
  (define-key org-mode-map (kbd "C-c v") #'ap/org-attach-clipboard))

;; Inline images in Org buffers: 600px unless the block says otherwise.
;; List form = honour #+ATTR_ORG :width, fall back to 600.
(setq org-image-actual-width '(600))

;; Opening an attachment in image-mode: fit it, and stop WSLg's
;; auto HiDPI factor from quadrupling the surface.
(setq image-auto-resize 'fit-window
      image-auto-resize-on-window-resize 1
      image-scaling-factor 1.0)

(defvar my/biblio-dir (expand-file-name "biblio/" org-directory))
(defvar my/reference-notes-dir (expand-file-name "references/" org-directory))
(defvar my/biblio-file (expand-file-name "library.bib" my/biblio-dir))

(dolist (d (list my/biblio-dir my/reference-notes-dir))
  (unless (file-exists-p d) (make-directory d t)))

;; Resolve the uWaterloo (work/school) OneDrive specifically --
;; %OneDriveCommercial% names it by account type, unlike plain
;; %OneDrive%, which just points at whichever account was set up
;; first/primary and isn't guaranteed to be the uWaterloo one or to
;; agree across machines. Uses powershell.exe, not cmd.exe: cmd.exe
;; refuses a WSL UNC working directory and prints a warning onto
;; stdout ("UNC paths are not supported...") that corrupts the
;; captured value; powershell.exe (already used elsewhere in this
;; file for clipboard interop) doesn't have that problem.
(defun ap/onedrive-root ()
  "Local WSL path to the uWaterloo OneDrive root, or nil if unresolved."
  (let ((raw (string-trim
              (shell-command-to-string
               "powershell.exe -NoProfile -Command \"[Environment]::GetEnvironmentVariable('OneDriveCommercial')\""))))
    (unless (string-empty-p raw) (ap/wslpath raw))))

(use-package citar
  :custom
  (citar-bibliography (list my/biblio-file))
  (org-cite-global-bibliography (list my/biblio-file))
  (citar-library-paths (list (expand-file-name "zotero-pdfs/" (ap/onedrive-root))))
  (citar-notes-paths (list my/reference-notes-dir))
  (org-cite-insert-processor 'citar)
  (org-cite-follow-processor 'citar)
  (org-cite-activate-processor 'citar)
  :hook
  (LaTeX-mode . citar-capf-setup)
  (org-mode . citar-capf-setup)
  :config
  ;; citar's default note-creation formatter (citar-org-format-note-default)
  ;; only adds an org-id when it detects an org-roam buffer, which Vulpea
  ;; never is -- so reference notes need their own formatter to get an ID,
  ;; CREATED, and a tag, matching how every other Vulpea note is built
  ;; (see `my/vulpea-capture-target' above).
  (defun my/citar-format-reference-note (key entry)
    "Format a freshly created, empty reference-note buffer for citekey KEY."
    (let ((title (or (citar-get-value "title" entry) key))
          (author (or (citar-get-value "author" entry)
                      (citar-get-value "editor" entry) ""))
          (year (or (citar-get-value "year" entry)
                    (citar-get-value "date" entry) "")))
      (insert (format "#+title: %s (%s) %s\n" author year title))
      ;; `org-set-tags' needs a heading; file-level tags go via the
      ;; #+filetags keyword instead (same convention Vulpea/org-roam
      ;; single-file notes use).
      (insert "#+filetags: :reference:\n\n")
      (org-id-get-create)
      (org-set-property "CREATED" (format-time-string "[%Y-%m-%d]"))
      (org-set-property "CITEKEY" key)
      (org-set-property "ALIASES" "")
      (goto-char (point-max))
      (insert "\n* Notes\n")))
  (setq citar-note-format-function #'my/citar-format-reference-note))

(use-package auctex)

(defun my/bibliography--entries ()
  ;; `citar-has-notes'/`citar-has-files' return nil outright (not a
  ;; predicate) when *nothing* in the library has notes/files yet --
  ;; only a non-empty library gets a callable predicate back.
  ;; Faces mirror `my/lab-notebook-list--entries': the "date-like"
  ;; column gets `font-lock-comment-face', the "identifier-like" column
  ;; gets `font-lock-keyword-face' -- both theme-aware, not hardcoded
  ;; colors, so they follow whatever theme is active.
  (let ((has-notes (citar-has-notes))
        (has-files (citar-has-files)))
    (mapcar
     (lambda (key)
       (let* ((entry (citar-get-entry key))
              (year (or (citar-get-value "year" entry)
                        (citar-get-value "date" entry) ""))
              (author (or (citar-get-value "author" entry)
                          (citar-get-value "editor" entry) ""))
              (title (or (citar-get-value "title" entry) ""))
              (tags (or (citar-get-value "keywords" entry) ""))
              (has-note (and has-notes (funcall has-notes key)))
              (has-file (and has-files (funcall has-files key))))
         (list key
               (vector (propertize year 'face 'font-lock-comment-face)
                       (propertize author 'face 'font-lock-keyword-face)
                       title
                       (propertize tags 'face 'font-lock-string-face)
                       (if has-note (propertize "Y" 'face 'success) "")
                       (if has-file (propertize "Y" 'face 'success) "")))))
     (hash-table-keys (citar-get-entries)))))

(defvar-local bibliography-list--filter nil
  "Substring filter (matched against any column), or nil for none.")

(defun my/bibliography-list--entries ()
  (let ((filter bibliography-list--filter))
    (if (not filter)
        (my/bibliography--entries)
      (seq-filter
       (lambda (row)
         (seq-some (lambda (col) (string-match-p (regexp-quote filter) col))
                    (append (cadr row) nil)))
       (my/bibliography--entries)))))

(define-derived-mode bibliography-list-mode tabulated-list-mode "Bibliography"
  "Major mode listing all bibliography entries."
  (setq tabulated-list-format [("Year" 6 t) ("Author" 25 t) ("Title" 0 t)
                                ("Tags" 20 t) ("Note" 5 t) ("PDF" 5 t)])
  (setq tabulated-list-sort-key (cons "Year" t)) ; most recent first
  (setq tabulated-list-entries #'my/bibliography-list--entries)
  (tabulated-list-init-header))

(defun bibliography-list-visit ()
  "Open (or create) the reference note for the entry at point."
  (interactive)
  (when-let ((key (tabulated-list-get-id)))
    (citar-open-notes (list key))))

(defun bibliography-list-open-file ()
  "Open the library PDF for the entry at point."
  (interactive)
  (when-let ((key (tabulated-list-get-id)))
    (citar-open-files (list key))))

(defun bibliography-list-sort-by-column ()
  "Prompt for a column and sort the table by it (repeat to flip direction)."
  (interactive)
  (let* ((names (mapcar #'car (append tabulated-list-format nil)))
         (name (completing-read "Sort by: " names nil t))
         (col (seq-position names name)))
    (tabulated-list-sort col)))

(defun bibliography-list-set-filter (filter)
  "Filter the table to entries whose columns contain FILTER."
  (interactive
   (list (read-string "Filter (author/title/tag substring, empty to clear): "
                       bibliography-list--filter)))
  (setq bibliography-list--filter (unless (string-empty-p filter) filter))
  (tabulated-list-print t))

(defun bibliography-list-clear-filter ()
  (interactive)
  (setq bibliography-list--filter nil)
  (tabulated-list-print t))

(define-key bibliography-list-mode-map (kbd "RET") #'bibliography-list-visit)
(define-key bibliography-list-mode-map (kbd "o") #'bibliography-list-open-file)
(define-key bibliography-list-mode-map (kbd "s") #'bibliography-list-sort-by-column)
(define-key bibliography-list-mode-map (kbd "/") #'bibliography-list-set-filter)
(define-key bibliography-list-mode-map (kbd "c") #'bibliography-list-clear-filter)

(defun my/bibliography-list ()
  (interactive)
  (let ((buf (get-buffer-create "*Bibliography*")))
    (with-current-buffer buf
      (bibliography-list-mode)
      (tabulated-list-print t))
    (switch-to-buffer buf)))

(general-define-key
 :prefix "C-c"
 "b" 'citar-insert-citation
 "n" 'citar-open-notes
 "r" 'my/bibliography-list)
