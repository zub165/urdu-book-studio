# Urdu Book Studio / Book Writer & Publisher - TODO

## Reported bugs / urgent
- [ ] **Urdu vowel input / on-screen keyboard**: Pressing `P` or physical keyboard mappings may not produce expected Urdu vowels depending on OS/input method. Add a side Urdu keyboard/character palette in editor for tap-to-insert vowels and common characters; ideally insert at cursor position.
- [ ] **Isolated character paragraph breaks** (e.g. single `ر` on its own line): add review/repair flow - compare with surrounding text, Join with previous/next, Undo. Detect suspicious one-character/very-short blocks.
- [ ] **Chapter names in sidebar**: show book title once; list chapters by number + own title; unnamed chapters show `باب ۱`/`Chapter 1`; allow rename in list; highlight open chapter; ensure names come from Book Details/chapter metadata, not repeated book title.
- [ ] **Sidebar faint en-US badge / book language**: show readable book language badge (e.g. `اردو`), separate App language and Book language clearly.

## Editor / writing
- [ ] Continuous writing default view (done basic) - refine to match manuscript page exactly.
- [ ] Keep paragraph boxes in optional Block view (done basic toggle).
- [ ] Move repeated paragraph-spacing sliders into one toolbar control (partly done in Format).
- [ ] Deselect N paragraphs label (done).
- [ ] Apply-to scope: Selected text, Selected paragraphs, This chapter, Entire book - make action names explicit (partly done).
- [ ] Add image, video, and rich media insertion.
- [ ] Add extract/import book to different forms/formats (DOCX/PDF/EPUB/MD/TXT/JSON import-export polish; add more extraction options).
- [ ] Undo/Redo visible and reliable across continuous view; Save button visible (added menu Save now; consider toolbar button).
- [ ] Set text to heading / block type from selection (added menu; improve UX).
- [ ] Join with previous/next, split paragraph, move up/down available in appropriate views.
- [ ] Verify Urdu font rendering same in Write, Format preview, live preview, export/PDF.
- [ ] Auto / RTL / LTR per paragraph (done basic); keep Urdu letter spacing natural default.

## Format / preview
- [ ] Larger page preview center, compact side panel; Fit page, Fit width, zoom, draggable divider.
- [ ] Template thumbnails using writer’s own Urdu title/sample paragraph; compare before apply; state fonts/sizes/spacing changes.
- [ ] Page size, margins, paragraph alignment, first-line indent, spacing after paragraphs; sliders with editable numeric values.
- [ ] Book theme separate from app appearance; dark workspace + white printed page preview.

## Library / settings
- [ ] App language and Book language separate and clear everywhere.
- [ ] Settings → Appearance: Light, Dark, Sepia, System (done basic).
- [ ] Format → Book theme for published page design.
- [ ] Book details: subtitle, author, language, cover, TOC generation.
- [ ] Sidebar organization: Outline for chapters; Insert block/Heading in + Insert menu; pin chapter list on desktop without dimming.

## Publishing / export
- [ ] PDF, EPUB, editable document clear labels; check Urdu font rendering and page order.
- [ ] Project backup reopenable for editing.
- [ ] Add image/video/media support in export where possible.
- [ ] KPF workflow guide.

## Accessibility / QA
- [ ] Text labels/tooltips for icons, visible keyboard focus, readable contrast in every theme, keyboard access to menus/editing controls.
- [ ] First release test: open existing Urdu book, change language to اردو with English menus; Dark app + Urdu Novel book; type Urdu/English name/date; reopen/export; verify settings, RTL, punctuation, margins.
