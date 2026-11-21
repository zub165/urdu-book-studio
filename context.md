# Urdu Book Studio — Project Context

## Goal
A Flutter application (Windows/macOS/Linux desktop, Web, Android) for writing and publishing online books in many languages, with first-class support for **Urdu** (right-to-left, Nastaliq and Naskh fonts), rich font-enhancement editing, and export to multiple document and e-book formats.

## Target platforms
- Desktop: macOS, Windows, Linux
- Web (Chrome, Edge, Safari)
- Android (phone and tablet)

## Core requirements
1. **Multilingual writing**
   - Left-to-right and right-to-left languages in the same app.
   - Urdu is the priority: RTL paragraph direction, correct Arabic-script shaping, Urdu digits option (۰-۹ vs 0-9).
   - Language selector per book and per paragraph.
   - Ready for Hindi, Arabic, Persian, English and others.

2. **Editing and font enhancement**
   - Paragraph-based editor: heading levels, body, quote, list, centered text.
   - Font family picker with bundled Urdu fonts (Noto Nastaliq Urdu, Noto Naskh Arabic) plus system fonts.
   - Size, weight, italic, underline, color, line height, letter spacing.
   - Alignment that follows text direction (start/end, not left/right).
   - Undo/redo, find and replace, word and character count.

3. **Book structure**
   - Book metadata: title, author, language, direction, cover, ISBN (optional), description.
   - Chapters with ordering, add, rename, delete, reorder.
   - Table of contents generated from headings.

4. **Export formats**
   - **DOCX** (Office Open XML, real Word file, RTL-aware).
   - **DOC** (legacy Word): produced as Word-readable HTML saved with a .doc extension. Limitation: not a true binary Word 97-2003 file.
    - **PDF** (real vector PDF with OpenType shaping for Urdu, pure Dart so it works on web).
    - **RTF** (Rich Text Format, plain text readable everywhere).
   - **EPUB 3** (reflowable e-book, RTL via `page-progression-direction` and `dir` attributes).
   - **KPF** (Kindle Package Format): proprietary to Amazon. Not generated directly by this app. Export EPUB or DOCX, then open in **Kindle Create** (see the screenshots: Reflowable layout, then Export as KPF) or upload to **Kindle Direct Publishing**, which accepts DOCX and EPUB.
   - **Plain text (.txt)** and **Markdown (.md)**.
   - **HTML** (single page, for web publishing).

5. **Storage and sync**
   - Local storage with JSON per book (works on all platforms; web uses IndexedDB through the package).
   - Import: DOCX, TXT, Markdown, RTF (basic).
   - Export to a file and share sheet on mobile.

## Architecture
```
lib/
  main.dart                 App entry, theme, locale setup
  app.dart                  MaterialApp, routes, l10n
  core/
    constants.dart          Supported languages, fonts, export formats
    text_direction.dart     Detects RTL from language code or script
  models/
    book.dart               Book, metadata
    chapter.dart            Chapter (list of blocks)
    block.dart              Paragraph block with style runs
    style.dart              Text style model (font, size, weight, color, direction)
  storage/
    book_repository.dart    Save and load books (JSON)
  book/
    book_screen.dart        Book details, chapter list and export menu
  editor/
    chapter_editor.dart     Chapter editor with RTL-aware blocks
    font_toolbar.dart       Font and style controls
  library/
    library_screen.dart     List of books, create and open
  export/
    exporter.dart           Export interface and format registry
    exporter_base.dart      Shared zip/XML helpers
    docx_exporter.dart      Builds .docx (zip with WordprocessingML)
    pdf_exporter.dart       Builds a shaped vector PDF (pure Dart, works on web)
    rtf_exporter.dart       Builds .rtf
    epub_exporter.dart      Builds .epub 3
    html_exporter.dart      Builds .html and .doc (Word-readable HTML)
    text_exporter.dart      Builds .txt and .md
  services/                 Reserved for platform save/share helpers
assets/
  fonts/                    Bundled Noto Nastaliq Urdu and Noto Naskh Arabic (variable TTF + OFL licences)
test/
  exporters_test.dart       Unit tests for exporters
  widget_test.dart           Library screen smoke test
```

## Key technical decisions
- **Framework:** Flutter 3.x, Dart null-safety.
- **Key packages:** `archive` (zip for DOCX and EPUB), `payv` (pure-Dart OpenType shaping and PDF), `path_provider`, `file_picker`, `share_plus`, `shared_preferences`, `google_fonts` (optional), `uuid`.
- **Data model:** Book to Chapters to Blocks. Each block holds plain text plus a style. Text is stored as UTF-8, so Urdu characters are preserved in every format.
- **RTL:** `Directionality` and `TextDirection.rtl` in the editor. Each block has a `direction` field, which defaults from the book language. Export writes `w:bidi` and `w:rtl` in DOCX, `dir="rtl"` in HTML and EPUB, and `\rtlch` in RTF.
- **Shaping:** Flutter's text engine shapes Urdu text. Bundled fonts ensure Nastaliq joins correctly on every platform.
- **Web limits:** Writing files uses browser downloads. No `dart:io` on web, so file operations go through conditional imports.

## Milestones
1. Project scaffold, models, JSON storage. (in progress)
2. Editor with RTL paragraphs and font toolbar.
3. Library screen, create and open books.
4. Exporters: TXT, MD, HTML, DOC, RTF, DOCX.
5. EPUB 3 exporter with table of contents.
6. Import from DOCX and TXT.
7. Responsive layout for Android and web, testing on each platform.
8. KPF workflow guide and documentation.

## Open decisions
- Include a rich-text editor package such as `flutter_quill`, or keep a custom block editor? Current choice: custom block editor for full control of RTL and Nastaliq shaping.
- Cloud sync (Firebase or Supabase) is out of scope for v1.
- Authentication is out of scope for v1.

## Status log
- Project folder created at `urdu_book_studio/`.
- context.md written.
- Milestone 1 (models, JSON storage): done.
- Milestone 2 (chapter editor with RTL blocks and font toolbar): first version done.
- Milestone 3 (library, create and open books): first version done.
- Milestone 4 (TXT, MD, HTML, DOC, RTF, DOCX, PDF exporters): first version done.
- Milestone 5 (EPUB 3 exporter): first version done.
- Bundled fonts added from Google Fonts (SIL OFL): Noto Nastaliq Urdu and Noto Naskh Arabic variable TTFs.
- Platform folders generated for Android, Web, macOS, Windows and Linux.
- Verified with Flutter 3.47.2: `flutter analyze` (no issues), `flutter test` (all tests pass), `flutter build web --release` (success).
- GitHub repository: `zub165/urdu-book-studio`; web app deployed to GitHub Pages.
- Pending: milestone 6 (DOCX/TXT import), milestone 7 (device testing on every platform), milestone 8 (full KPF guide).
