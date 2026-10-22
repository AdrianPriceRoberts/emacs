# Emacs configuration

## Never edit init.el directly

`emacs.org` is the source; `init.el` is generated from it by
`org-babel-tangle`. To change the configuration:

1. Edit the `emacs-lisp` blocks (and the prose around them) in `emacs.org`.
2. Regenerate `init.el`:

       emacs -Q --batch --eval '(progn (require (quote org)) (org-babel-tangle-file "emacs.org"))'

   (Saving `emacs.org` in Emacs does the same.)
3. Commit `emacs.org` and `init.el` together.

A change made only in `init.el` is silently lost the next time `emacs.org`
is saved. If `init.el` ever differs from what `emacs.org` tangles to, port
the difference into `emacs.org` first; don't regenerate over it.

## Keep the cheat sheet current

`CHEATSHEET.org` is the beginner's guide to this config (`C-c h` opens
it in Emacs; `README.md` links to it on GitHub). Whenever a change adds,
removes, or rebinds a custom keybinding, or adds a command users are
meant to run with `M-x`, update `CHEATSHEET.org` in the same commit, in
the section matching its prefix (`C-x` is Emacs's own keys, `C-c` is
this config's). Check that each key listed there is still bound to
what it says.

## Per-machine settings

Fonts, font sizes, theme and folder paths are `defvar`s under
*Per-machine settings* in `emacs.org`, overridden per computer in `local.el`
(gitignored, created from `local.el.example` on first start). A new
per-machine setting needs a `defvar` there and an entry in
`local.el.example`. Never hard-code `~/org`; use `org-directory`.

## Privacy: the user's notes are off limits

Never read, open, list, search, grep, or summarize the user's notes
without explicit permission for that specific request. Permission given
once does not carry over to later requests or sessions. This covers:

- the notes folder (`~/org` by default, or whatever `my/org-dir` is set to),
  including `.stversions`, `daily/`, `attach/`, `biblio/` and conflict copies;
- files derived from the notes: `vulpea.db`, `.org-id-locations`,
  `sync-conflict-archive/`, `backups/`, `bookmarks`, `projectile-*.eld`;
- indirect reads: loading `init.el` (even `emacs --batch -l init.el`) makes
  vulpea scan the notes folder, so ask before running the configuration.

When something needs testing against notes, ask, or use a throwaway folder
of made-up `.org` files.
