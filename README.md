# emacs

New to Emacs or to this setup?  Start with the
[cheat sheet](CHEATSHEET.org): the basic keys, and the keys this config
adds for notes, the journal, the lab notebook and citations.  In Emacs,
`C-c h` opens it.

Settings that differ between computers (font size, fonts, theme, notes
folder, Zotero PDF folder) go in `local.el`, which isn't tracked in git.
Emacs creates it from `local.el.example` on first start.  Saving it in
Emacs applies the theme and fonts straight away; a new notes or Zotero
folder needs a restart.
