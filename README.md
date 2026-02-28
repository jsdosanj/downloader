# 📥 downloader.sh

A powerful Bash-based file downloader and web crawler that recursively finds and saves MP3, MP4, PDF, and other files from any website — with full YouTube (and 1000+ platform) support via `yt-dlp`.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Requirements](#requirements)
- [Installation (macOS)](#installation-macos)
- [How to Run](#how-to-run)
- [Usage Examples](#usage-examples)
- [Options Reference](#options-reference)
- [Common Errors & Fixes](#common-errors--fixes)
- [Tips & Best Practices](#tips--best-practices)

---

## Overview

`downloader.sh` starts at a URL you provide, recursively crawls the page for downloadable files, and saves them to a directory you specify — mirroring the folder structure of the source site. It also supports direct YouTube video/playlist downloads, converting them to MP3 or MP4.

---

## Features

- 🔁 **Recursive web crawling** — mirrors nested folder structures
- 🎵 **MP3 audio extraction** from YouTube and websites
- 🎬 **MP4 video downloads** from YouTube and websites
- 📄 **Multi-format support** — MP3, MP4, PDF, WAV, ZIP, M4A, OGG
- 📺 **YouTube & 1000+ platform support** via `yt-dlp`
- 🏷️ **Metadata & thumbnail embedding** in downloaded files
- 📁 **Playlist support** — entire YouTube playlists in one command
- 🧹 **Filename sanitization** — removes illegal characters automatically
- 📊 **Stats report** — total files, MB/GB downloaded, elapsed time
- 🛡️ **Duplicate detection** — skips already-downloaded files

---

## Requirements

| Tool | Purpose |
|------|---------|
| `curl` | Fetching web page HTML |
| `wget` | Downloading direct file URLs |
| `yt-dlp` | YouTube + platform downloads |
| `ffmpeg` | Audio/video merging and conversion |
| `bc` | Math for stats calculation |

---

## Installation (macOS)

### Step 1 — Install Homebrew (if not already installed)

Homebrew is the package manager for macOS. Open **Terminal** and run:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

After installing, follow any instructions in the terminal to add Homebrew to your PATH. For **Apple Silicon Macs (M1/M2/M3/M4)**, run:

```bash
echo 'export PATH="/opt/homebrew/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

For **Intel Macs**, run:

```bash
echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

Verify Homebrew works:

```bash
brew --version
```

---

### Step 2 — Install all dependencies

```bash
brew update
brew install curl wget yt-dlp ffmpeg bc
```

Verify each tool installed correctly:

```bash
curl --version
wget --version
yt-dlp --version
ffmpeg -version
bc --version
```

Each command should print a version number. If any say `command not found`, see [Common Errors & Fixes](#common-errors--fixes).

---

### Step 3 — Download the script

Save `downloader.sh` to a folder of your choice. For example, your Desktop:

```bash
cd ~/Desktop
# If you cloned the repo:
git clone https://github.com/your-username/your-repo.git
cd your-repo
```

---

### Step 4 — Make the script executable

This is **required** before you can run it:

```bash
chmod +x downloader.sh
```

You only need to do this once.

---

## How to Run

Open **Terminal**, navigate to the folder containing `downloader.sh`, and run:

```bash
./downloader.sh --url "<URL>" --path "<OUTPUT_DIRECTORY>" --folder "<FOLDER_NAME>" --format <mp3|mp4|all>
```

### Interactive Mode

If you run the script without any arguments, it will **prompt you** for each value:

```bash
./downloader.sh
```

You will see:

```
Enter URL to crawl/download: █
Enter output directory path: █
Select format:
1) mp3
2) mp4
3) all
```

---

## Usage Examples

### 1. Download a single YouTube video as MP4

```bash
./downloader.sh \
  --url "https://youtu.be/dQw4w9WgXcQ" \
  --path "$HOME/Downloads" \
  --folder "YouTube" \
  --format mp4
```

### 2. Download a YouTube video as MP3 (audio only)

```bash
./downloader.sh \
  --url "https://youtu.be/dQw4w9WgXcQ" \
  --path "$HOME/Downloads" \
  --folder "Music" \
  --format mp3
```

### 3. Download an entire YouTube playlist as MP3

```bash
./downloader.sh \
  --url "https://www.youtube.com/playlist?list=PLxxxxxxxxxxxxxxxx" \
  --path "$HOME/Downloads" \
  --folder "MyPlaylist" \
  --format mp3
```

### 4. Crawl a website and download all MP3 files

```bash
./downloader.sh \
  --url "https://example.com/audio-library" \
  --path "$HOME/Downloads" \
  --folder "AudioLibrary" \
  --format mp3
```

### 5. Crawl a website and download everything (MP3, MP4, PDF, etc.)

```bash
./downloader.sh \
  --url "https://example.com/resources" \
  --path "$HOME/Desktop/downloads" \
  --folder "Resources" \
  --format all
```

### 6. Save to an external drive

```bash
./downloader.sh \
  --url "https://youtu.be/dQw4w9WgXcQ" \
  --path "/Volumes/MyDrive/Downloads" \
  --folder "Videos" \
  --format mp4
```

---

## Options Reference

| Flag | Description | Required | Default |
|------|-------------|----------|---------|
| `--url` | The starting URL to crawl or YouTube link | ✅ Yes (or prompted) | — |
| `--path` | Output directory where files will be saved | ✅ Yes (or prompted) | — |
| `--folder` | Sub-folder name inside `--path` | ❌ No | `downloads` |
| `--format` | File format: `mp3`, `mp4`, or `all` | ❌ No | `all` |
| `-h`, `--help` | Show help message and exit | ❌ No | — |

---

## Common Errors & Fixes

### ❌ `zsh: permission denied: ./downloader.sh`

**Cause:** The script is not marked as executable.

**Fix:**
```bash
chmod +x downloader.sh
```

---

### ❌ `yt-dlp: command not found`

**Cause:** `yt-dlp` is not installed or not in your PATH.

**Fix:**
```bash
brew install yt-dlp
```

If it's installed but still not found, add Homebrew to your PATH:

```bash
# Apple Silicon (M1/M2/M3/M4)
echo 'export PATH="/opt/homebrew/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Intel Mac
echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

Then verify:
```bash
which yt-dlp
```

---

### ❌ `ERROR: ffmpeg not found`

**Cause:** `ffmpeg` is missing. `yt-dlp` requires it to merge video and audio streams, and to convert to MP3.

**Fix:**
```bash
brew install ffmpeg
```

Verify it works:
```bash
ffmpeg -version
```

If you still see the error after installing, restart your terminal and try again:
```bash
hash -r
ffmpeg -version
```

---

### ❌ `wget: command not found`

**Cause:** `wget` is not installed (macOS does not include it by default).

**Fix:**
```bash
brew install wget
```

---

### ❌ `brew: command not found`

**Cause:** Homebrew is not installed.

**Fix:** Install Homebrew:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

---

### ❌ `Error: No such file or directory` (output path)

**Cause:** The directory you specified in `--path` does not exist.

**Fix:** Create it first, or use a path that already exists:
```bash
mkdir -p "$HOME/Downloads/MyFolder"
./downloader.sh --url "..." --path "$HOME/Downloads/MyFolder"
```

> The script will also attempt to create the directory automatically, but parent directories must exist.

---

### ❌ `ERROR: Sign in to confirm you're not a bot`

**Cause:** YouTube is rate-limiting or blocking the request.

**Fix:** Update `yt-dlp` to the latest version (this is the most common fix):
```bash
brew upgrade yt-dlp
# or
yt-dlp -U
```

---

### ❌ `ERROR: Requested format is not available`

**Cause:** The specific video/audio format you requested is not available for that video.

**Fix:** Try `--format all` instead of `mp3` or `mp4`, or let `yt-dlp` choose the best available format automatically:
```bash
./downloader.sh --url "https://youtu.be/xxxxx" --path "$HOME/Downloads" --format all
```

---

### ❌ `bc: command not found`

**Cause:** `bc` (the math calculator used for stats) is not installed.

**Fix:**
```bash
brew install bc
```

---

### ❌ Brew install fails with permission errors

**Cause:** Incorrect permissions on Homebrew directories.

**Fix:**
```bash
sudo chown -R $(whoami) /usr/local/bin /usr/local/lib
brew doctor
```

---

### ❌ Script runs but downloads nothing from a website

**Cause:** The website may use JavaScript to render links (the crawler uses `curl` + `grep`, which only reads raw HTML).

**Fix:** Try `yt-dlp` directly — it supports many more sites than raw HTML crawling:
```bash
yt-dlp --list-formats "<URL>"
```

If `yt-dlp` supports the site, the script will automatically route through it.

---

## Tips & Best Practices

- 🔄 **Keep `yt-dlp` updated** — YouTube changes frequently and older versions break:
  ```bash
  brew upgrade yt-dlp
  ```

- 💾 **Use an absolute path** for `--path` to avoid confusion:
  ```bash
  --path "$HOME/Downloads/MyDownloads"
  ```

- 📂 **Use `--folder`** to keep different download sessions organized:
  ```bash
  --folder "Kirtan-2024"
  ```

- 🧪 **Test with a single video** before downloading an entire playlist:
  ```bash
  ./downloader.sh --url "https://youtu.be/SINGLE_VIDEO_ID" --path "/tmp/test" --format mp3
  ```

- 📋 **Check what formats are available** for a YouTube video before downloading:
  ```bash
  yt-dlp --list-formats "https://youtu.be/VIDEO_ID"
  ```

- ⚖️ **Respect copyright** — only download content you have permission to download. Always check the terms of service for each website or platform.

---

## Quick Reference Card

```bash
# YouTube video → MP4
./downloader.sh --url "https://youtu.be/ID" --path ~/Downloads --format mp4

# YouTube video → MP3
./downloader.sh --url "https://youtu.be/ID" --path ~/Downloads --format mp3

# YouTube playlist → MP3
./downloader.sh --url "https://youtube.com/playlist?list=ID" --path ~/Downloads --format mp3

# Website crawl → all files
./downloader.sh --url "https://example.com" --path ~/Downloads --format all

# Interactive mode (will prompt you)
./downloader.sh

# Show help
./downloader.sh --help
```
