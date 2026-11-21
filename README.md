# Urdu Book Studio

A Flutter app for writing and publishing books in many languages, with first-class
Urdu (right-to-left, Nastaliq/Naskh) support. Targets macOS, Windows, Linux, Web,
and Android.

See `context.md` for requirements, architecture, and milestones.

Live web app: https://zub165.github.io/urdu-book-studio/

## Features

- multilingual library: Urdu, English, Arabic, Persian, Pashto, Sindhi, Hindi,
  Punjabi, Hebrew, French and Spanish; RTL is detected from the language code
- paragraph editor with headings, quotes, centered text and per-paragraph direction
- font controls: bundled Urdu fonts, size, line height, letter spacing, color,
  bold, italic and underline
- editor utilities: undo/redo, find and replace, word and character counts
- AI translation (English to Urdu and 11 other languages) and AI heading outlines,
  with template, font, size and color controls before inserting into the chapter
  (add your Gemini or OpenAI key under the editor's AI menu)
- live book preview while writing and in the book view; colorful language-coded library
- book metadata, chapters with add/rename/delete/reorder, and heading-based TOC in exports
- local JSON storage that works on web, Android and desktop
- import book files (JSON, TXT, MD, DOCX, RTF) into the library or an open book
- exports: DOCX, DOC (HTML-based), PDF, RTF, EPUB 3, HTML, TXT, Markdown and editable JSON

## Setup

1. Install Flutter 3.22 or newer (`flutter doctor` should pass for your targets).
2. Get dependencies and run:

   ```bash
   flutter pub get
   flutter analyze
   flutter test
   flutter run -d chrome        # web
   flutter run -d macos         # or windows / linux / android device id
   ```

3. Platform folders are already included in the repository. To regenerate them:

   ```bash
   flutter create . --platforms=android,web,macos,windows,linux \
     --project-name urdu_book_studio --org com.urdubookstudio
   ```

Fonts are bundled in `assets/fonts/` (Noto Nastaliq Urdu and Noto Naskh Arabic,
variable TTFs under the SIL Open Font License; licence texts are included).

## Export formats

| Format | Status | Notes |
|---|---|---|
| DOCX | Implemented | Real Word file, RTL paragraphs, Urdu language tags |
| PDF | Implemented | Real vector PDF with OpenType shaping for Urdu; works on web too |
| DOC | Implemented (limited) | HTML saved as .doc; Word opens it, but it is not the binary format |
| RTF | Implemented | Unicode-escaped Urdu, RTL paragraphs |
| EPUB 3 | Implemented | Reflowable, RTL spine, navigation document |
| HTML | Implemented | Single page, RTL when the book is Urdu |
| TXT | Implemented | UTF-8 with BOM for Notepad |
| Markdown | Implemented | RTL blocks wrapped in `<div dir="rtl">` |
| JSON | Implemented | Full-fidelity editable book file; import it back to keep all styles |
| KPF | Not generated | Amazon proprietary. Export EPUB, then use Kindle Create or KDP |

## Import formats

| Format | Notes |
|---|---|
| JSON | Restores chapters, blocks and styles; gets a new book id on import |
| TXT / Markdown | Paragraphs and headings become editable blocks |
| DOCX | Paragraphs and Heading 1-3 styles are read from `word/document.xml` |
| RTF | Basic text and paragraph import; complex formatting is ignored |

## Deployment

The web app is published to GitHub Pages from the `gh-pages` branch. To refresh
it after changes:

```bash
flutter test
flutter build web --release --base-href /urdu-book-studio/
```

Because `build/` is gitignored, copy `build/web` into a temporary clone of the
`gh-pages` branch and push from there:

```bash
git fetch origin gh-pages
git worktree add /tmp/urdu-book-studio-pages origin/gh-pages
cp -R build/web/. /tmp/urdu-book-studio-pages/
git -C /tmp/urdu-book-studio-pages add --all
git -C /tmp/urdu-book-studio-pages commit -m "Deploy web app"
git -C /tmp/urdu-book-studio-pages push origin HEAD:gh-pages
git worktree remove /tmp/urdu-book-studio-pages
```

GitHub Pages must be set to deploy from `gh-pages / (root)`.

## Known limits (v1)

- Desktop saves use `file_picker`'s save dialog with bytes.
- EPUB does not embed custom fonts yet; readers fall back to their own fonts.
- The library is one JSON document in shared preferences; large libraries should
  move to one file per book.
- UI strings are English; localization is a later milestone.
- AI translation requires a Gemini or OpenAI API key; requests are sent directly from the browser to the provider.
