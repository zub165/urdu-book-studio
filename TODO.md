# Book Writer & Publisher - Comprehensive TODO

Status legend: `[x]` done, `[~]` partial, `[ ]` pending.

## 0. Core workflow (8-tab)
- [x] 8-tab Book Writer flow: My Books, Outline, Write, Review, Layout, Cover & Details, Preview, Export & Publish (`lib/book/book_screen.dart`).
- [x] Book model extended: subtitle/description/ISBN/cover/page size/margins/page numbers/TOC/front-back matter/comments/snapshots/allChapters (`lib/models/book.dart`).
- [x] Exporters/preview/import use `allChapters`; import clears front/back matter (`lib/export/*.dart`, `lib/book/book_preview.dart`, `lib/storage/book_importer.dart`).
- [~] Review: local comments + snapshot save/restore done; inline tracked changes/accept-reject, rich spellcheck engine pending.
- [~] Cover: front cover upload/remove done; full print cover (front/spine/back) pending.
- [~] Export/Publish: all registered exporters + KDP/KPF guidance/checklist done; direct platform API submission pending.

## 1. Reported bugs / urgent
- [ ] **ML Backend / GoDaddy AI not working when selected**: debug end-to-end. Verify AI settings save/load, provider persists, backend URL validation, web CORS/HTTPS/mixed-content, auth token header, response parsing for multi-model `/api/chat` (`reply`) and Ollama `/api/generate`/`/api/chat`, timeout/UI errors. Add in-app "Test connection" and clearer failure reason. Confirm public HTTPS+CORS endpoint for GitHub Pages.
- [~] **Urdu vowel input / on-screen keyboard**: added editor toolbar toggle and on-screen Urdu character/vowel palette with cursor insert/backspace (`lib/editor/chapter_editor.dart`); still needs full phonetic mapping, OS IME guidance, and richer layout.
- [ ] **Isolated character paragraph breaks** (e.g., single `ر` on its own line): add review/repair flow - compare with surrounding text, Join with previous/next, Undo. Detect suspicious one-character/very-short blocks; optional auto-suggest merge (never auto-destructive without confirmation).
- [ ] **Chapter names in sidebar**: show book title once at top; list chapters by number + own title. Unnamed/same-as-book-title chapters show `باب 1` / `Chapter 1`. Allow rename directly in list; clearly highlight open chapter; verify names come from Book Details/chapter metadata, not repeated book title.
- [ ] **Sidebar faint en-US / book language badge**: show readable book language badge (e.g., `اردو`), not faint `en-US`. Separate App language and Book language clearly everywhere.
- [ ] **Heading/selection UX confusion**: Undo/Redo exist in app bar; Save now exists in `+` menu; block type/heading can be set via `+` menu "Set selected/active as". Improve discoverability: visible toolbar Save/Heading controls, selection-aware formatting hint, keyboard shortcuts.

## 2. Language, direction, themes
- [ ] **App language**: Settings → Language. English and `اردو` first. Translate menus/buttons/dialogs/dates/status. Mirror UI for RTL app language. Persist after restart.
- [~] **Book language**: per-book language in New Book/Book Details done; ensure library card shows readable Urdu label, writing direction/font defaults/export metadata follow; changing language preserves manuscript.
- [~] **App appearance**: System/Light/Dark/Sepia in settings done; add sample preview before applying; ensure consistent across library/editor.
- [ ] **Book theme**: Format → Book Theme for published page design (Urdu Novel, English Novel, Nonfiction etc.). Preview actual manuscript with selected fonts/spacing/margins. Apply to preview/export; keep separate from app appearance (dark workspace + white printed page).

## 3. Urdu writing & live preview
- [~] **Writing direction**: Auto/RTL/LTR per paragraph done in Format/block controls; ensure Urdu paragraphs default/start at right margin, English at left; bilingual mixed content wraps correctly.
- [~] **Urdu font defaults**: Noto Nastaliq Urdu bundled; font picker samples added; ensure Nastaliq default/adequate line spacing for Urdu books and natural letter spacing.
- [ ] **Wrapping/clipping**: long Urdu paragraphs wrap inside page margins; check dialogue, quotes, dates, English names/numbers inside Urdu sentences; fix narrow live preview clipping.
- [ ] **Preview controls**: draggable divider, Fit page/Fit width, zoom, full-page preview; Edit/Preview switch on small screens; follow edited paragraph in preview.
- [ ] **Formatting controls clarity**: Line spacing/Paragraph spacing labels done; add units/editable numeric inputs, first-line indent, paragraph alignment, page size/margins in Layout/Format.
- [~] **Continuous writing**: default continuous manuscript page done; optional Block edit view kept. Remove remaining block-chrome clutter; one paragraph-spacing control in top toolbar/Format.
- [x] **Save status / editability**: fixed continuous/block editor to use persistent TextEditingControllers so Write view is editable; Saving…/Saved shown; Save now button added.
- [ ] **Undo/redo robustness**: verify across continuous view, join/split, formatting, block type changes; add visible toolbar buttons if needed.

## 4. Library & book management
- [~] **New/Import visibility**: top toolbar buttons added; ensure visible/responsive on small window sizes.
- [~] **Book cards**: title/author/language/chapter count/labeled last-edited date done; title opens manuscript; make metadata clearer.
- [x] **Delete UX**: moved to book menu with Move to Trash + Undo snackbar.
- [~] **Book menu**: Open/Edit details/Duplicate/Export done; add Move to Trash confirmation/restore polish where needed.
- [x] **Sort/filter**: Recently edited/Title/Author/Language + language filter + search.
- [ ] **Multilingual app name**: "Book Writer & Publisher" used in UI/web metadata; review remaining native/platform names/icons where appropriate.

## 5. Chapters, outline, publishing
- [ ] **Outline**: add/rename/reorder/duplicate chapters; selecting chapter opens in editor; pin chapter list on desktop without page dimming.
- [ ] **Page setup**: book size, margins, chapter page breaks, page numbers, headers/footers; reflect in preview/export.
- [ ] **Book details**: title/subtitle/author/language/cover; generate TOC from chapter headings.
- [ ] **Export clarity**: clear labels for PDF, EPUB, editable document; verify Urdu font rendering/page order in exported files; project backup reopenable for editing.
- [ ] **KPF workflow**: keep guidance; proprietary format not directly generated.

## 6. Media & import/export enhancements
- [ ] **Add image**: insert/manage images in blocks/chapters; cover already supported.
- [ ] **Add video/media**: define supported media/embed behavior per platform/export.
- [ ] **Extract/import book to different forms**: improve import/export flows; DOCX/TXT/MD/RTF/EPUB/JSON support exists partly; add clearer extract/convert UI and fidelity checks.

## 7. Accessibility & QA
- [ ] Text labels/tooltips for unfamiliar icons, visible keyboard focus, readable contrast in every theme, keyboard access to menus/editing controls.
- [ ] Verify save/export behavior, unopened menu features, and platform-specific file handling.
- [ ] **First release test**: Open existing Urdu book, change language from `en-US` to `اردو`, keep menus in English. Select Dark app + Urdu Novel book theme. Type paragraph with Urdu, English name, date. Reopen and export one page. Verify saved settings, RTL text, punctuation, page margins carry through.

## 8. Deployment / ops
- [x] GitHub repo/main pushed; GitHub Pages deployed manually via gh-pages worktree/rsync.
- [ ] Add CI/GitHub Actions deploy once token has `workflow` scope or via repo settings.
- [ ] Smoke-test live site after each deploy: library, editor, RTL, export, AI settings, media.
