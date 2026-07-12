# pdf2kindle

A fully local, OCR-first PDF → Kindle converter. The PDF never leaves the machine — no cloud OCR, no conversion service, and the systemd unit runs with `PrivateNetwork=yes` so it *can't* phone home even if something tries.

Two output variants:

| variant | contains | use for |
|---|---|---|
| `full` | text + images | tablet / colour Kindle / archive |
| `paperwhite` | text only, every image stripped and the removal **verified** | Paperwhite — small file, fast page turns |

## Why OCR is not optional

A PDF can "have text" and still have a corrupt text layer. Feed that straight into a converter and you get a beautifully formatted book full of garbage. `pdf2kindle` runs `ocrmypdf --force-ocr` by default: it throws away the existing text layer and re-recognizes from the pixels. `--skip-ocr` exists, and using it on a known-bad file is how you get a Kindle book you can't read.

## Guardrails

Each stage asserts a postcondition and the tool exits non-zero if any fail — it reports what it *verified*, not what it *attempted*:

- `ocrmypdf` exit code and non-empty output PDF
- OCR word density (words/page ≥ threshold) and recognizable-character ratio ≥ 90%
- first 300 chars of OCR text printed so you can eyeball it
- EPUB exists and has content documents
- for `paperwhite`: the EPUB zip is re-opened and image count asserted to be **zero**

## Install (Ubuntu / Debian)

```bash
git clone git@github.com:NiranEC77/pdf2kindle.git
cd pdf2kindle
./install.sh          # ocrmypdf, tesseract, ghostscript, poppler, calibre
```

## One-shot use

```bash
bin/pdf2kindle ~/book.pdf -o ./out --variant paperwhite --format azw3
```

Options:

```
--variant full|paperwhite|both   default: both
--format  epub|azw3|both         default: both  (azw3 = best on Kindle)
--lang    eng | eng+heb | ...    tesseract languages
--skip-ocr                       trust the existing text layer (usually a mistake)
--no-force-ocr                   only OCR pages with no text at all
--clean                          unpaper pre-clean, for scans
--optimize 0-3                   image downsampling (3 = smallest)
--min-words-per-page N           OCR sanity threshold, default 50
```

## Pipeline mode (drop-folder)

This is the intended path: you never invoke a command, you just drop a file.

```bash
sudo mkdir -p /opt/pdf2kindle
sudo cp -r bin scripts /opt/pdf2kindle/
sudo mkdir -p /srv/pdf2kindle/{inbox,outbox,archive,logs}
sudo chown -R hermes:hermes /srv/pdf2kindle
sudo cp systemd/pdf2kindle.{path,service} /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now pdf2kindle.path
```

Then:

```
/srv/pdf2kindle/inbox/     <- drop the PDF here
/srv/pdf2kindle/outbox/<name>/  -> book.epub, book-paperwhite.epub, .azw3, .ocr.txt
/srv/pdf2kindle/archive/   <- original PDF, timestamped
/srv/pdf2kindle/logs/      <- one log per job
```

The watcher waits for the file size to stop changing before it starts, so a slow `scp` won't trigger a conversion of a half-written file. Follow along with:

```bash
journalctl -u pdf2kindle.service -f
```

## Getting the book onto the Kindle

Plug the Paperwhite in via USB and copy the `.azw3` into `documents/`. That keeps the whole round trip local. (Send-to-Kindle by email works too, but it uploads the file to Amazon — which defeats the point.)

## Success condition

Open it on the Paperwhite: is the text clean, is the font adjustable, does the table of contents move you around? If the text is clean but the layout is soupy, bump `--optimize` down and re-run; PDF→EPUB reflow is a heuristic, not a science.
