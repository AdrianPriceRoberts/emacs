;; -*- lexical-binding: t; -*-
;; Initialize package sources
(require 'package)

(setq package-archives '(("melpa" . "https://melpa.org/packages/")
                         ("org" . "https://orgmode.org/elpa/")
                         ("elpa" . "https://elpa.gnu.org/packages/")
                         ("nongnu" . "https://elpa.nongnu.org/nongnu/")))

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

(custom-theme-set-faces
 'doom-laserwave
 '(gnus-group-news-low-empty ((t :inherit gnus-group-mail-1-empty))))

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

(use-package tablist)

;; Splits comma/semicolon-separated TEXT into an OR-regexp of literal
;; terms, e.g. "distillation, extraction" -> "distillation\|extraction"
;; -- answers "check for a few different keywords" without requiring
;; regexp syntax from the user.
(defun my/browser--terms-regexp (text)
  (mapconcat #'regexp-quote (split-string text "[,;]" t "[ \t]+") "\\|"))

(defun my/browser--column-filter (column regexp)
  "A tablist filter form: REGEXP against COLUMN, or every column if
 COLUMN is nil (\"All columns\")."
  (if column
      (list '=~ column regexp)
    (cl-reduce (lambda (a b) (list 'or a b))
               (mapcar (lambda (name) (list '=~ name regexp))
                       (mapcar #'car (append tabulated-list-format nil))))))

(defun my/browser-filter ()
  "Pick a column (or \"All columns\"), then push a filter for it onto
 tablist's filter stack live as you type -- comma/semicolon-separate
 multiple keywords for an OR match (e.g. \"distillation, extraction\").
 Repeat to AND another column's filter on top of this one. RET keeps
 it; C-g discards it and restores the filter stack to what it was
 before this call."
  (interactive)
  (let* ((buf (current-buffer))
         (base tablist-current-filter)
         (col-names (mapcar #'car (append tabulated-list-format nil)))
         (choice (completing-read "Filter by column: "
                                   (cons "All columns" col-names)
                                   nil t nil nil "All columns"))
         (column (unless (string= choice "All columns") choice)))
    (cl-flet ((live-apply
               (text)
               (with-current-buffer buf
                 (setq tablist-current-filter
                       (if (string-empty-p text)
                           base
                         (tablist-filter-push
                          base (my/browser--column-filter
                                column (my/browser--terms-regexp text)))))
                 (tablist-apply-filter))))
      (condition-case nil
          (minibuffer-with-setup-hook
              (lambda ()
                (add-hook 'post-command-hook
                          (lambda () (live-apply (minibuffer-contents-no-properties)))
                          nil t))
            (read-string (format "Filter [%s] (comma/semicolon = or): " choice)))
        (quit
         (with-current-buffer buf
           (setq tablist-current-filter base)
           (tablist-apply-filter))
         (signal 'quit nil))))))

(defun my/browser-clear-filter ()
  (interactive)
  (setq tablist-current-filter nil)
  (tablist-apply-filter))

(defun my/browser-sort-by-column ()
  "Prompt for a column and sort the table by it (repeat to flip direction)."
  (interactive)
  (let* ((names (mapcar #'car (append tabulated-list-format nil)))
         (name (completing-read "Sort by: " names nil t))
         (col (seq-position names name)))
    (tabulated-list-sort col)))

(defun my/browser-refresh ()
  "Invalidate this browser's row cache (`my/browser-refresh-function',
 set by the specific major mode) and redisplay. Any active filter
 stays applied."
  (interactive)
  (when my/browser-refresh-function
    (funcall my/browser-refresh-function))
  (tabulated-list-print t))

(defvar my/browser-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "g" #'my/browser-refresh)
    (define-key map "s" #'my/browser-sort-by-column)
    (define-key map "/" #'my/browser-filter)
    (define-key map "c" #'my/browser-clear-filter)
    map)
  "Keymap for `my/browser-mode'.")

(defvar-local my/browser-eldoc-hint nil
  "Static hint string shown in the echo area once idle; set by the
 specific derived major mode before turning on `my/browser-mode'.")

(defvar-local my/browser-refresh-function nil
  "Zero-arg function invalidating this browser's row cache; set by the
 specific derived major mode before turning on `my/browser-mode'.")

(defvar my/browser-point-entry-functions nil
  "Abnormal hook, args (ID ENTRY), run when point moves onto a
 different row in a `my/browser-mode' buffer -- the same ID/ENTRY
 `tabulated-list-get-id'/`tabulated-list-get-entry' return for the row
 now at point. Reserved for future per-row features; empty for now.")

(defvar-local my/browser--last-point-id 'my/browser-unset)

(defun my/browser--check-point-entry ()
  (when (derived-mode-p 'tabulated-list-mode)
    (let ((id (tabulated-list-get-id)))
      (unless (equal id my/browser--last-point-id)
        (setq my/browser--last-point-id id)
        (when id
          (run-hook-with-args 'my/browser-point-entry-functions
                               id (tabulated-list-get-entry)))))))

(define-minor-mode my/browser-mode
  "Shared behavior for the browsing buffers in this config: an eldoc
keybinding hint, a refreshable row cache, tablist-backed multi-column
live filtering, generic column sorting, and a point-entry hook future
per-row features can hang off of."
  :lighter " Browser"
  :keymap my/browser-mode-map
  (if my/browser-mode
      (progn
        (tablist-minor-mode 1)
        (when my/browser-eldoc-hint
          (setq-local eldoc-idle-delay 1.5)
          (add-hook 'eldoc-documentation-functions
                    (let ((hint my/browser-eldoc-hint))
                      (lambda (callback &rest _) (funcall callback hint)))
                    nil t)
          (eldoc-mode 1))
        (add-hook 'post-command-hook #'my/browser--check-point-entry nil t))
    (tablist-minor-mode -1)
    (remove-hook 'post-command-hook #'my/browser--check-point-entry t)))

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
;; Sorting, filtering, the row cache, and the eldoc hint all come from
;; `my/browser-mode' (see "Browser Infrastructure" near the top of this
;; file) -- this is only what's actually specific to lab notebook notes:
;; the columns, how to build a row, and what RET does.

(defvar-local my/lab-notebook--row-cache nil)

(defun my/lab-notebook--invalidate-cache ()
  (setq my/lab-notebook--row-cache nil))

(defun my/lab-notebook--all-rows ()
  (or my/lab-notebook--row-cache
      (setq my/lab-notebook--row-cache
            (seq-keep
             (lambda (note)
               (let* ((page-id (or (my/lab-notebook--page-id note) ""))
                      (created (or (alist-get "CREATED" (vulpea-note-properties note) nil nil #'string=) ""))
                      (title (or (vulpea-note-title note) "")))
                 (list (vulpea-note-path note)
                       (vector (propertize page-id 'face 'font-lock-keyword-face)
                               (propertize created 'face 'font-lock-comment-face)
                               title))))
             (my/lab-notebook--notes)))))

(define-derived-mode lab-notebook-list-mode tabulated-list-mode "Lab-Notebook"
  "Major mode listing all lab notebook entries."
  (setq tabulated-list-format [("Page ID" 12 t) ("Date" 12 t) ("Title" 0 t)])
  (setq tabulated-list-sort-key (cons "Date" t)) ; most recent first
  (setq tabulated-list-entries #'my/lab-notebook--all-rows)
  (tabulated-list-init-header)
  (setq my/browser-eldoc-hint "s:sort  /:filter  c:clear  g:refresh  RET:open")
  (setq my/browser-refresh-function #'my/lab-notebook--invalidate-cache)
  (my/browser-mode 1))

(defun lab-notebook-list-visit ()
  (interactive)
  (let ((path (tabulated-list-get-id)))
    (when path (find-file path))))

(define-key lab-notebook-list-mode-map (kbd "RET") #'lab-notebook-list-visit)

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

(defun my/journal-file-p (&optional file)
  "Non-nil if FILE (default: the current buffer's file) is a daily journal entry."
  (when-let ((file (or file (buffer-file-name))))
    (string-match-p "/org/daily/[^/]+\\.org\\'" file)))

(defun my/journal-body-text ()
  "Return the current buffer's journal content with template scaffolding stripped.
Strips the :PROPERTIES: drawer, #+title/#+filetags/#+created lines, the
\"* Notes\" heading, and blank lines, leaving only what was actually typed."
  (let ((text (buffer-substring-no-properties (point-min) (point-max))))
    (with-temp-buffer
      (insert text)
      (goto-char (point-min))
      (when (re-search-forward "^[ \t]*:PROPERTIES:\n\\(?:.*\n\\)*?[ \t]*:END:\n" nil t)
        (replace-match ""))
      (goto-char (point-min))
      (while (re-search-forward "^#\\+\\(title\\|filetags\\|created\\):.*\n" nil t)
        (replace-match ""))
      (goto-char (point-min))
      (when (re-search-forward "^\\*+[ \t]+Notes[ \t]*\n" nil t)
        (replace-match ""))
      (string-trim (buffer-substring-no-properties (point-min) (point-max))))))

(defun my/journal-template-only-p ()
  "Non-nil if the current journal buffer has no real content beyond the template."
  (string-empty-p (my/journal-body-text)))

(defun my/effectively-empty-buffer-p ()
  "Non-nil if the current buffer has no content worth protecting.
For daily journal files this means template-only; for everything else,
truly zero bytes (the original, narrower check)."
  (if (my/journal-file-p)
      (my/journal-template-only-p)
    (= (buffer-size) 0)))

(defun my/guard-empty-overwrite (fn &rest args)
  (when (and (buffer-file-name)
             (file-exists-p (buffer-file-name))
             (my/effectively-empty-buffer-p)
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

(defun my/diff-and-choose (show-diff prompt choices)
  "Call SHOW-DIFF to display a *Diff* buffer, then ask PROMPT with CHOICES.
CHOICES is a `read-multiple-choice' list; return the chosen key.  The
question is always asked in the minibuffer, never as a GUI dialog.  The
*Diff* buffer is killed and the window layout restored afterwards.
SHOW-DIFF may be nil to just ask."
  (let ((use-dialog-box nil))
    (save-current-buffer
      (save-window-excursion
        (unwind-protect
            (progn
              (when show-diff
                (funcall show-diff)
                (when-let* ((win (get-buffer-window "*Diff*")))
                  (select-window win)))
              (car (read-multiple-choice prompt choices)))
          (when (get-buffer "*Diff*")
            (kill-buffer "*Diff*")))))))

(defvar-local my/journal-conflict-pending nil
  "Non-nil while a journal conflict prompt is scheduled or open for this buffer.")

(defun my/journal-buffer-stale-function (&optional noconfirm)
  "`buffer-stale-function' for daily journal buffers.
Defers to the default staleness check; if the file changed on disk and
this buffer still has real content, never silently revert -- schedule
a conflict prompt instead and report \"not stale\" so auto-revert
leaves the buffer alone until the user decides."
  (let ((default-stale (buffer-stale--default-function noconfirm)))
    (cond
     ((not default-stale) default-stale)
     ((my/journal-template-only-p) default-stale)
     (my/journal-conflict-pending nil)
     (t
      (setq my/journal-conflict-pending t)
      (run-with-timer 0 nil #'my/journal-handle-conflict (current-buffer))
      nil))))

(defun my/journal-ediff-merge (buffer)
  "Open an ediff session merging BUFFER against what is currently on disk."
  (let ((disk-buf (generate-new-buffer (format " *disk:%s*" (buffer-name buffer)))))
    (with-current-buffer disk-buf
      (insert-file-contents-literally (buffer-file-name buffer))
      (setq buffer-read-only t))
    (ediff-buffers disk-buf buffer)))

(defun my/journal-handle-conflict (buffer)
  "Prompt the user to resolve a blocked auto-revert conflict on BUFFER."
  (when (buffer-live-p buffer)
    (with-current-buffer buffer
      (unwind-protect
          (pcase (my/diff-and-choose
                  (lambda () (diff-buffer-with-file buffer))
                  (format "Buffer %s has content but the file changed on disk. What now?"
                          (buffer-name))
                  '((?k "keep buffer" "Discard the disk change; keep this buffer as-is.")
                    (?t "take disk" "Discard this buffer's content; load what is on disk.")
                    (?e "merge" "Open an ediff session to merge the two by hand.")))
            (?t (revert-buffer 'ignore-auto 'dont-ask 'preserve-modes))
            (?e (my/journal-ediff-merge buffer))
            (_ nil))
        (setq my/journal-conflict-pending nil)))))

(add-hook 'find-file-hook
          (lambda ()
            (when (my/journal-file-p)
              (setq-local buffer-stale-function #'my/journal-buffer-stale-function))))

(defconst my/sync-conflict-regexp
  "\\.sync-conflict-[0-9]\\{8\\}-[0-9]\\{6\\}-\\([A-Z0-9]\\{7\\}\\)"
  "Matches the marker Syncthing inserts into conflict copy file names.
Group 1 is the short ID of the device that wrote the conflicting copy.")

(defvar my/sync-conflict-skipped nil
  "Conflict files skipped this session; not offered again until restart.")

(defun my/sync-conflicts ()
  "Return all unskipped Syncthing conflict files under ~/org, oldest name first."
  (seq-remove (lambda (file) (member file my/sync-conflict-skipped))
              (sort (directory-files-recursively
                     "~/org" my/sync-conflict-regexp nil
                     ;; Skip .stversions, .stfolder and other dot directories.
                     (lambda (dir)
                       (not (string-prefix-p "." (file-name-nondirectory dir)))))
                    #'string<)))

(defun my/sync-conflict-original (conflict)
  "Return the file that CONFLICT is a Syncthing conflict copy of."
  (replace-regexp-in-string my/sync-conflict-regexp "" conflict))

(defun my/file-string (file)
  "Return FILE's contents as a string."
  (with-temp-buffer
    (insert-file-contents file)
    (buffer-string)))

(defun my/journal-text-template-only-p (text)
  "Non-nil if journal TEXT has no real content beyond the template."
  (with-temp-buffer
    (insert text)
    (my/journal-template-only-p)))

(defun my/sync-conflict-trash (conflict)
  "Kill any buffer visiting CONFLICT and move the file to the trash."
  (when-let* ((buf (find-buffer-visiting conflict)))
    (kill-buffer buf))
  (let ((delete-by-moving-to-trash t))
    (delete-file conflict t))
  (message "Trashed %s" (file-name-nondirectory conflict)))

(defun my/buffer-ids ()
  "Return every :ID: property value in the current buffer, in order."
  (let (ids)
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward "^[ \t]*:ID:[ \t]+\\(\\S-+\\)[ \t]*$" nil t)
        (push (match-string-no-properties 1) ids)))
    (nreverse ids)))

(defun my/dedupe-drawer-properties ()
  "Drop repeated properties within each property drawer; the first one wins.
KEY+ lines (Org's way of appending to a value) are left alone.  Return an
alist of (DROPPED-ID . KEPT-ID) for every :ID: line removed."
  (let ((case-fold-search t)
        dropped)
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward "^[ \t]*:PROPERTIES:[ \t]*$" nil t)
        (let ((end (save-excursion
                     (and (re-search-forward "^[ \t]*:END:[ \t]*$" nil t)
                          (copy-marker (match-beginning 0)))))
              seen)
          (forward-line 1)
          (while (and end (< (point) end))
            (if (looking-at "[ \t]*:\\([^: \t\n]+\\):[ \t]*\\(.*?\\)[ \t]*$")
                (let ((key (upcase (match-string-no-properties 1)))
                      (value (match-string-no-properties 2)))
                  (cond
                   ((string-suffix-p "+" key)
                    (forward-line 1))
                   ((assoc key seen)
                    (when (equal key "ID")
                      (push (cons value (cdr (assoc key seen))) dropped))
                    (delete-region (line-beginning-position) (line-beginning-position 2)))
                   (t
                    (push (cons key value) seen)
                    (forward-line 1))))
              (forward-line 1))))))
    (nreverse dropped)))

(defun my/id-link-files (id)
  "Return the .org files under ~/org that link to ID (conflict copies excluded)."
  (seq-remove (lambda (file) (string-match-p my/sync-conflict-regexp file))
              (process-lines-ignore-status
               "grep" "-rlF" "--include=*.org" "--exclude-dir=.*"
               "-e" (concat "id:" id) (expand-file-name "~/org"))))

(defun my/offer-id-link-redirect (old new)
  "If any note links to id:OLD, offer to point those links at id:NEW."
  (when-let* ((files (my/id-link-files old)))
    (when (eq ?r (my/diff-and-choose
                  nil
                  (format "%d file%s to id:%s, which no longer exists (the note is now id:%s):"
                          (length files) (if (cdr files) "s link" " links") old new)
                  '((?r "redirect" "Point those links at the ID that was kept.")
                    (?l "leave" "Leave the links as they are."))))
      (dolist (file files)
        (with-current-buffer (find-file-noselect file)
          (save-excursion
            (goto-char (point-min))
            (while (search-forward (concat "id:" old) nil t)
              (replace-match (concat "id:" new) t t)))
          (save-buffer)))
      (message "Redirected links in %d file%s to id:%s"
               (length files) (if (cdr files) "s" "") new))))

(defun my/tidy-ids-and-save (before)
  "Drop repeated drawer properties in the current buffer and save it.
BEFORE is the buffer's list of IDs before it was changed; for any of those
that is now gone, offer to redirect links to it."
  (let ((dropped (my/dedupe-drawer-properties)))
    (save-buffer)
    (let ((after (my/buffer-ids))
          (file-id (org-entry-get (point-min) "ID")))
      (dolist (id (seq-difference (seq-uniq (append before (mapcar #'car dropped)))
                                  after))
        (when-let* ((target (or (cdr (assoc id dropped)) file-id)))
          (my/offer-id-link-redirect id target))))
    dropped))

(defun my/fix-duplicate-properties ()
  "Remove repeated properties from this buffer's drawers, keeping the first.
Saves the buffer, and offers to redirect links to any :ID: that was removed."
  (interactive)
  (message (if (my/tidy-ids-and-save (my/buffer-ids))
               "Removed duplicate properties"
             "No duplicate properties")))

(defun my/sync-conflict-write (original text)
  "Replace ORIGINAL's contents with TEXT and save, through its normal buffer.
Repeated drawer properties (e.g. both machines' :ID:) are reduced to the
first, and links to any ID that disappears are offered a redirect."
  (with-current-buffer (find-file-noselect original)
    (let ((before (my/buffer-ids)))
      (erase-buffer)
      (insert text)
      (my/tidy-ids-and-save before))))

(defun my/sync-conflict-original-text (original)
  "Return ORIGINAL's text, from its open buffer if there is one.
That way unsaved typing counts, rather than only what's on disk."
  (if-let* ((buf (find-buffer-visiting original)))
      (with-current-buffer buf (buffer-string))
    (my/file-string original)))

(defvar my/sync-conflict-archive-dir
  (expand-file-name "sync-conflict-archive/" user-emacs-directory)
  "Where both sides of every conflict are copied before anything is changed.
Outside ~/org on purpose, so Syncthing doesn't sync it and org-roam doesn't
index it.")

(defun my/syncthing-device-name (short-id)
  "Return the name Syncthing's config gives the device SHORT-ID, or SHORT-ID."
  (or (when-let* ((config (seq-find #'file-exists-p
                                    '("~/.local/state/syncthing/config.xml"
                                      "~/.config/syncthing/config.xml"))))
        (with-temp-buffer
          (insert-file-contents config)
          (when (re-search-forward
                 (format "<device id=\"%s[^\"]*\" name=\"\\([^\"]*\\)\""
                         (regexp-quote short-id))
                 nil t)
            (match-string 1))))
      short-id))

(defun my/sync-conflict-time (time)
  "Format TIME for conflict prompts, e.g. \"Thu Sep 24 16:43\"."
  (format-time-string "%a %b %-d %H:%M" time))

(defun my/sync-conflict-sides (original conflict)
  "Return (OLDER . NEWER): the two sides of CONFLICT, sorted by last save.
Each side is a plist with :text, :label and :short.  Unsaved typing in
ORIGINAL's buffer makes ORIGINAL the newer side; on a tie it is too."
  (let* ((buf (find-buffer-visiting original))
         (unsaved (and buf (buffer-modified-p buf)))
         (otime (if unsaved
                    (current-time)
                  (file-attribute-modification-time (file-attributes original))))
         (ctime (file-attribute-modification-time (file-attributes conflict)))
         (device (my/syncthing-device-name
                  (and (string-match my/sync-conflict-regexp conflict)
                       (match-string 1 conflict))))
         (name (file-name-nondirectory original))
         (orig (list :text (my/sync-conflict-original-text original)
                     :label (format "%s -- %s" name
                                    (if unsaved "unsaved edits in Emacs"
                                      (concat "saved " (my/sync-conflict-time otime))))
                     :short (format "this file, %s"
                                    (if unsaved "unsaved" (my/sync-conflict-time otime)))))
         (conf (list :text (my/file-string conflict)
                     :label (format "conflict copy from %s -- saved %s"
                                    device (my/sync-conflict-time ctime))
                     :short (format "%s copy, %s" device (my/sync-conflict-time ctime)))))
    (if (time-less-p otime ctime) (cons orig conf) (cons conf orig))))

(defun my/diff-texts (old-text new-text &rest formats)
  "Run GNU diff on OLD-TEXT and NEW-TEXT with line FORMATS; return its output."
  (let ((old (make-temp-file "sync-old" nil nil old-text))
        (new (make-temp-file "sync-new" nil nil new-text)))
    (unwind-protect
        (with-temp-buffer
          ;; diff exits 0 for no differences, 1 for some, 2 for trouble.
          (unless (memq (apply #'call-process "diff" nil t nil
                               (append formats (list old new)))
                        '(0 1))
            (error "diff failed: %s" (buffer-string)))
          (buffer-string))
      (delete-file old)
      (delete-file new))))

(defun my/sync-conflict-union (first-text second-text)
  "Return FIRST-TEXT and SECOND-TEXT combined, keeping every line of both.
Shared lines appear once; where they differ, FIRST-TEXT's lines come
first.  There are no conflict markers in the result."
  (my/diff-texts first-text second-text
                 "--unchanged-line-format=%L"
                 "--old-line-format=%L"
                 "--new-line-format=%L"))

(defun my/sync-conflict-line-changes (old-text new-text)
  "Return (REMOVED . ADDED): how many lines turning OLD-TEXT into NEW-TEXT
deletes and adds."
  (let ((out (my/diff-texts old-text new-text
                            "--unchanged-line-format="
                            "--old-line-format=-"
                            "--new-line-format=+")))
    (cons (seq-count (lambda (c) (eq c ?-)) out)
          (seq-count (lambda (c) (eq c ?+)) out))))

(defun my/sync-conflict-show-diff (old-text new-text legend &optional old-name new-name)
  "Show a unified diff of OLD-TEXT against NEW-TEXT in *Diff*, LEGEND on top.
OLD-NAME and NEW-NAME label the --- and +++ lines."
  (let ((old (generate-new-buffer (or old-name "OLDER")))
        (new (generate-new-buffer (or new-name "NEWER"))))
    (unwind-protect
        (progn
          (with-current-buffer old (insert old-text))
          (with-current-buffer new (insert new-text))
          (diff old new "-u" 'no-async)
          (with-current-buffer "*Diff*"
            (let ((inhibit-read-only t))
              (goto-char (point-min))
              ;; Legend lines start with spaces so diff-mode doesn't
              ;; mistake them for - or + lines.
              (insert (propertize legend 'face 'bold) "\n\n"))))
      (kill-buffer old)
      (kill-buffer new))))

(defun my/sync-conflict-archive (original conflict choice)
  "Copy ORIGINAL and CONFLICT into a new folder in the archive; return it.
CHOICE is recorded so `my/sync-conflict-undo-last' can say what it undoes."
  (let* ((ext (file-name-extension original t))
         (dir (file-name-as-directory
               (expand-file-name (format "%s-%s"
                                         (format-time-string "%Y%m%d-%H%M%S")
                                         (file-name-base original))
                                 my/sync-conflict-archive-dir))))
    (make-directory dir t)
    (with-temp-file (expand-file-name (concat "original-before" ext) dir)
      (insert (my/sync-conflict-original-text original)))
    (copy-file conflict (expand-file-name (concat "conflict-copy" ext) dir) t t)
    (with-temp-file (expand-file-name "meta.eld" dir)
      (prin1 (list :original original :conflict conflict :choice choice)
             (current-buffer)))
    dir))

(defun my/sync-conflict-resolve-to (original conflict text choice)
  "Archive both sides, make ORIGINAL contain TEXT, then trash CONFLICT.
CHOICE is a short description of what was picked, for the archive."
  (let ((dir (my/sync-conflict-archive original conflict choice)))
    (unless (string= text (my/sync-conflict-original-text original))
      (my/sync-conflict-write original text))
    (my/sync-conflict-trash conflict)
    (message "%s: %s.  Both versions archived in %s -- M-x my/sync-conflict-undo-last reverts"
             (file-name-nondirectory original) choice (abbreviate-file-name dir))))

(defun my/sync-conflict-confirm (original text)
  "Show exactly how ORIGINAL would change if it became TEXT; non-nil to go ahead.
Losing any line needs a typed \"yes\"."
  (let* ((name (file-name-nondirectory original))
         (current (my/sync-conflict-original-text original))
         (changes (my/sync-conflict-line-changes current text))
         (removed (car changes))
         (added (cdr changes))
         (use-dialog-box nil))
    (if (and (zerop removed) (zerop added))
        (y-or-n-p (format "%s stays exactly as it is; only the conflict copy is archived and trashed.  OK? "
                          name))
      (save-window-excursion
        (unwind-protect
            (progn
              (my/sync-conflict-show-diff
               current text
               (format "  PREVIEW -- if you confirm, %s changes like this:\n  - lines will be DELETED from it (%d)\n  + lines will be ADDED to it (%d)\n  Both versions are archived first; M-x my/sync-conflict-undo-last puts them back."
                       name removed added)
               (concat name " NOW") (concat name " AFTER"))
              (when-let* ((win (get-buffer-window "*Diff*")))
                (select-window win))
              (if (> removed 0)
                  (yes-or-no-p (format "DELETE %d line%s from %s (and add %d)? "
                                       removed (if (= removed 1) "" "s") name added))
                (y-or-n-p (format "Add %d line%s to %s, deleting nothing? "
                                  added (if (= added 1) "" "s") name))))
          (when (get-buffer "*Diff*")
            (kill-buffer "*Diff*")))))))

(defun my/sync-conflict-choose (original conflict)
  "Ask which lines ORIGINAL should keep until a choice is confirmed.
Return (TEXT . CHOICE), or nil to skip."
  (pcase-let* ((`(,older . ,newer) (my/sync-conflict-sides original conflict))
               (name (file-name-nondirectory original))
               (legend (format "  - lines exist only in the OLDER version:  %s\n  + lines exist only in the NEWER version:  %s\n  Whichever you keep ends up in %s; the other copy is archived and trashed."
                               (plist-get older :label) (plist-get newer :label) name))
               (result nil))
    (while (not result)
      (pcase (my/diff-and-choose
              (lambda ()
                (my/sync-conflict-show-diff (plist-get older :text)
                                            (plist-get newer :text) legend))
              (format "%s  [+ newer: %s]  [- older: %s]  Keep:"
                      name (plist-get newer :short) (plist-get older :short))
              '((?+ "+ lines only (newer)" "Keep the NEWER version.  Every - line is deleted.")
                (?- "- lines only (older)" "Keep the OLDER version.  Every + line is deleted.")
                (?b "both + and -" "Keep every + and every - line.  Nothing is deleted; tidy by hand afterwards.")
                (?s "skip" "Change nothing now; ask again after Emacs restarts.")))
        (?s (setq result 'skip))
        (?+ (let ((text (plist-get newer :text)))
              (when (my/sync-conflict-confirm original text)
                (setq result (cons text "kept the newer version (+ lines)")))))
        (?- (let ((text (plist-get older :text)))
              (when (my/sync-conflict-confirm original text)
                (setq result (cons text "kept the older version (- lines)")))))
        (?b (let ((text (my/sync-conflict-union
                         ;; The original's lines go first, so its :ID: wins.
                         (my/sync-conflict-original-text original)
                         (my/file-string conflict))))
              (when (my/sync-conflict-confirm original text)
                (setq result (cons text "kept both (+ and - lines)")))))))
    (unless (eq result 'skip) result)))

(defun my/sync-conflict-auto-resolve (conflict original)
  "Resolve CONFLICT without asking if one side has nothing worth keeping.
Return non-nil if it was resolved.  Both sides are archived either way."
  (let ((text (my/file-string conflict))
        (orig-text (my/sync-conflict-original-text original))
        (journal (my/journal-file-p original)))
    (cond
     ((or (string= text orig-text)
          (and journal (my/journal-text-template-only-p text)))
      (my/sync-conflict-resolve-to original conflict orig-text
                                   "conflict copy was identical or only the template")
      t)
     ((and journal (my/journal-text-template-only-p orig-text))
      (my/sync-conflict-resolve-to original conflict text
                                   "original was only the template; took the conflict copy")
      t))))

(defun my/resolve-sync-conflict (conflict)
  "Show the diff between CONFLICT and its original, then ask what to keep."
  (interactive
   (let ((conflicts (my/sync-conflicts)))
     (unless conflicts (user-error "No Syncthing conflict files under ~/org"))
     (list (completing-read "Resolve conflict: " conflicts nil t nil nil
                            (car conflicts)))))
  (let ((original (my/sync-conflict-original conflict))
        (device (and (string-match my/sync-conflict-regexp conflict)
                     (match-string 1 conflict))))
    (cond
     ((not (file-exists-p original))
      (pcase (my/diff-and-choose
              nil
              (format "%s is gone but has a conflict copy from %s:"
                      (file-name-nondirectory original)
                      (my/syncthing-device-name device))
              '((?r "restore" "Rename the conflict copy back to the original name.")
                (?s "skip" "Leave it for now.")))
        (?r (rename-file conflict original))
        (_ (push conflict my/sync-conflict-skipped))))
     ((my/sync-conflict-auto-resolve conflict original))
     (t
      (if-let* ((choice (my/sync-conflict-choose original conflict)))
          (my/sync-conflict-resolve-to original conflict (car choice) (cdr choice))
        (push conflict my/sync-conflict-skipped))))))

(defun my/sync-conflict-undo-last ()
  "Put the most recently resolved conflict back as it was: the original's
old text and the conflict copy, so it can be resolved again.  Undoing
again goes one resolution further back."
  (interactive)
  (let ((dir (car (last (and (file-directory-p my/sync-conflict-archive-dir)
                             (directory-files my/sync-conflict-archive-dir t
                                              "\\`[0-9]\\{8\\}-[0-9]\\{6\\}-"))))))
    (unless dir (user-error "No resolved conflicts left to undo"))
    (let* ((meta (with-temp-buffer
                   (insert-file-contents (expand-file-name "meta.eld" dir))
                   (read (current-buffer))))
           (original (plist-get meta :original))
           (conflict (plist-get meta :conflict))
           (ext (file-name-extension original t)))
      (when (yes-or-no-p (format "Undo \"%s\" on %s (from %s)? "
                                 (plist-get meta :choice)
                                 (file-name-nondirectory original)
                                 (file-name-nondirectory (directory-file-name dir))))
        ;; Keep what's there now too, in case this undo is the mistake.
        (when (file-exists-p original)
          (copy-file original (expand-file-name (concat "original-before-undo" ext) dir) t t))
        (with-current-buffer (find-file-noselect original)
          (erase-buffer)
          (insert-file-contents (expand-file-name (concat "original-before" ext) dir))
          (save-buffer))
        (copy-file (expand-file-name (concat "conflict-copy" ext) dir) conflict t t)
        (setq my/sync-conflict-skipped (delete conflict my/sync-conflict-skipped))
        (rename-file dir (expand-file-name
                          (concat "undone-" (file-name-nondirectory (directory-file-name dir)))
                          my/sync-conflict-archive-dir))
        (message "Restored %s and its conflict copy; M-x my/resolve-sync-conflict to try again"
                 (file-name-nondirectory original))))))

(defvar my/sync-conflict-timer nil
  "Pending timer for the next conflict-file prompt, used to debounce bursts.")

(defun my/sync-conflict-schedule-check (&optional delay)
  "Prompt about conflict files after DELAY idle seconds (default 2)."
  (unless (timerp my/sync-conflict-timer)
    (setq my/sync-conflict-timer
          (run-with-idle-timer (or delay 2) nil #'my/sync-conflict-check))))

(defun my/sync-conflict-check ()
  "Offer to walk through Syncthing conflict files, if there are any."
  (setq my/sync-conflict-timer nil)
  (if (active-minibuffer-window)
      ;; Busy with another prompt: ask again later.
      (my/sync-conflict-schedule-check 10)
    ;; Clear the ones that need no decision before asking about the rest.
    (dolist (conflict (my/sync-conflicts))
      (let ((original (my/sync-conflict-original conflict)))
        (when (file-exists-p original)
          (my/sync-conflict-auto-resolve conflict original))))
    (when-let* ((conflicts (my/sync-conflicts)))
      (when (eq ?y (my/diff-and-choose
                    nil
                    (format "%d Syncthing conflict file%s under ~/org:"
                            (length conflicts) (if (cdr conflicts) "s" ""))
                    '((?y "review" "Go through them one at a time.")
                      (?n "later" "Ask again next time a conflict appears or Emacs starts."))))
        (mapc #'my/resolve-sync-conflict conflicts)))))

(defun my/sync-conflict-watch-callback (event)
  "Schedule a conflict prompt when Syncthing drops a conflict file."
  (pcase-let ((`(,_ ,action ,file ,file1) event))
    (when (and (memq action '(created renamed))
               (string-match-p my/sync-conflict-regexp
                               (or (and (eq action 'renamed) file1) file)))
      (my/sync-conflict-schedule-check))))

(require 'filenotify)
(add-hook 'emacs-startup-hook
          (lambda ()
            (my/sync-conflict-schedule-check 5)
            (when (file-directory-p "~/org/daily")
              (file-notify-add-watch (expand-file-name "~/org/daily")
                                     '(change)
                                     #'my/sync-conflict-watch-callback))))

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

(defvar-local my/bibliography--row-cache nil)

(defun my/bibliography--invalidate-cache ()
  (setq my/bibliography--row-cache nil))

(defun my/bibliography--all-rows ()
  (or my/bibliography--row-cache
      (setq my/bibliography--row-cache
            ;; `citar-has-notes'/`citar-has-files' return nil outright
            ;; (not a predicate) when *nothing* in the library has
            ;; notes/files yet -- only a non-empty library gets a
            ;; callable predicate back.
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
               (hash-table-keys (citar-get-entries)))))))

(define-derived-mode bibliography-list-mode tabulated-list-mode "Bibliography"
  "Major mode listing all bibliography entries."
  (setq tabulated-list-format [("Year" 6 t) ("Author" 25 t) ("Title" 0 t)
                                ("Tags" 20 t) ("Note" 5 t) ("PDF" 5 t)])
  (setq tabulated-list-sort-key (cons "Year" t)) ; most recent first
  (setq tabulated-list-entries #'my/bibliography--all-rows)
  (tabulated-list-init-header)
  (setq my/browser-eldoc-hint "s:sort  /:filter  c:clear  g:refresh  RET:note  o:pdf")
  (setq my/browser-refresh-function #'my/bibliography--invalidate-cache)
  (my/browser-mode 1))

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

(define-key bibliography-list-mode-map (kbd "RET") #'bibliography-list-visit)
(define-key bibliography-list-mode-map (kbd "o") #'bibliography-list-open-file)

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

;; Per-machine settings that should never sync between machines.
;; Not tracked in git -- create local.el separately on each machine.
;; Keep this heading last in the file: init.el runs top to bottom, so
;; whatever local.el sets here overrides everything defined above it.
(let ((local (expand-file-name "local.el" user-emacs-directory)))
  (when (file-exists-p local)
    (load local)))
