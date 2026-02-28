#!/usr/bin/env bash
# =============================================================================
# downloader.sh
# Tiny Search Engine - Bash Edition
#
# Crawls a given URL, recursively finds MP3/MP4/PDF files, and downloads them
# to a user-specified directory, mirroring the folder structure.
# Also supports direct YouTube (and any yt-dlp-compatible) URLs.
#
# Dependencies: curl, wget, yt-dlp, ffmpeg, python3 (for BeautifulSoup crawl)
#               OR pure-bash with lynx/curl for link extraction
#
# Usage:
#   ./downloader.sh [OPTIONS]
#   ./downloader.sh --url <URL> --path <OUTPUT_DIR> [--folder <NAME>] [--format mp3|mp4|all]
#
# Examples:
#   ./downloader.sh --url "https://example.com/audio" --path "/tmp/downloads" --folder "MySeries"
#   ./downloader.sh --url "https://www.youtube.com/playlist?list=XXX" --path "/tmp/downloads" --format mp3
#   ./downloader.sh --url "https://youtu.be/dQw4w9WgXcQ" --path "/tmp/downloads" --format mp4
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Color output helpers
# ---------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}[ERROR]${RESET} $*" >&2; }

# ---------------------------------------------------------------------------
# Dependency checks
# ---------------------------------------------------------------------------
check_deps() {
    local missing=()
    for cmd in curl wget yt-dlp ffmpeg python3; do
        command -v "$cmd" &>/dev/null || missing+=("$cmd")
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        error "Missing required dependencies: ${missing[*]}"
        echo ""
        echo "Install them with:"
        echo "  macOS:  brew install curl wget yt-dlp ffmpeg python3"
        echo "  Ubuntu: sudo apt install curl wget ffmpeg python3 && pip install yt-dlp"
        exit 1
    fi
}

# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------
START_URL=""
OUTPUT_PATH=""
FOLDER_NAME="downloads"
FORMAT="all"           # mp3 | mp4 | all
TOTAL_FILES=0
TOTAL_BYTES=0
START_TIME=""
END_TIME=""

# ---------------------------------------------------------------------------
# Usage / Help
# ---------------------------------------------------------------------------
usage() {
    cat <<EOF

${BOLD}downloader.sh${RESET} — Tiny Search Engine (Bash Edition)

${BOLD}USAGE:${RESET}
  ./downloader.sh --url <URL> --path <DIR> [OPTIONS]

${BOLD}OPTIONS:${RESET}
  --url     <URL>        Starting URL to crawl or YouTube URL/playlist
  --path    <DIR>        Output directory to save files
  --folder  <NAME>       Top-level folder name (default: "downloads")
  --format  <FORMAT>     File format: mp3 | mp4 | all (default: all)
  -h, --help             Show this help message

${BOLD}EXAMPLES:${RESET}
  # Download all MP3s from a website recursively
  ./downloader.sh --url "https://example.com/audio" --path "/tmp/dl" --format mp3

  # Download a YouTube video as MP4
  ./downloader.sh --url "https://youtu.be/dQw4w9WgXcQ" --path "/tmp/dl" --format mp4

  # Download an entire YouTube playlist as MP3
  ./downloader.sh --url "https://youtube.com/playlist?list=PLxxx" --path "/tmp/dl" --format mp3

  # Download all supported files from a site (mp3, mp4, pdf)
  ./downloader.sh --url "https://example.com/files" --path "/tmp/dl" --format all

EOF
    exit 0
}

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --url)    START_URL="$2";    shift 2 ;;
            --path)   OUTPUT_PATH="$2";  shift 2 ;;
            --folder) FOLDER_NAME="$2";  shift 2 ;;
            --format) FORMAT="$2";       shift 2 ;;
            -h|--help) usage ;;
            *) error "Unknown option: $1"; usage ;;
        esac
    done

    # Interactive prompts if args not provided
    if [[ -z "$START_URL" ]]; then
        read -rp "$(echo -e "${CYAN}Enter URL to crawl/download:${RESET} ")" START_URL
    fi
    if [[ -z "$OUTPUT_PATH" ]]; then
        read -rp "$(echo -e "${CYAN}Enter output directory path:${RESET} ")" OUTPUT_PATH
    fi
    if [[ -z "$FORMAT" || "$FORMAT" == "all" ]]; then
        echo -e "${CYAN}Select format:${RESET}"
        select fmt in "mp3" "mp4" "all"; do
            FORMAT="$fmt"
            break
        done
    fi
}

# ---------------------------------------------------------------------------
# Sanitize a filename (mirrors Python's noNo = '\/:*?"<>|')
# ---------------------------------------------------------------------------
sanitize_filename() {
    local name="$1"
    # Replace forbidden characters with #
    echo "$name" | sed 's/[\\/:*?"<>|]/#/g'
}

# ---------------------------------------------------------------------------
# Detect if a URL is a YouTube (or yt-dlp-supported) URL
# ---------------------------------------------------------------------------
is_youtube_url() {
    local url="$1"
    if echo "$url" | grep -qiE "(youtube\.com|youtu\.be|youtube-nocookie\.com)"; then
        return 0
    fi
    return 1
}

is_ytdlp_supported() {
    local url="$1"
    # Try a dry-run; if yt-dlp can resolve it, we use yt-dlp
    yt-dlp --simulate --quiet "$url" &>/dev/null && return 0 || return 1
}

# ---------------------------------------------------------------------------
# Download via yt-dlp (YouTube + other supported platforms)
# ---------------------------------------------------------------------------
ytdlp_download() {
    local url="$1"
    local dest_dir="$2"
    local fmt="${3:-all}"   # mp3 | mp4 | all

    mkdir -p "$dest_dir"

    info "Using yt-dlp for: $url"
    info "Format: $fmt → Destination: $dest_dir"

    local output_tmpl="$dest_dir/%(playlist_index|)s%(title)s.%(ext)s"

    case "$fmt" in
        mp3)
            yt-dlp \
                --extract-audio \
                --audio-format mp3 \
                --audio-quality 0 \
                --embed-thumbnail \
                --add-metadata \
                --yes-playlist \
                --output "$output_tmpl" \
                --progress \
                --no-warnings \
                "$url"
            ;;
        mp4)
            yt-dlp \
                -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]" \
                --merge-output-format mp4 \
                --embed-thumbnail \
                --add-metadata \
                --yes-playlist \
                --output "$output_tmpl" \
                --progress \
                --no-warnings \
                "$url"
            ;;
        all|*)
            yt-dlp \
                -f "bestvideo+bestaudio/best" \
                --merge-output-format mp4 \
                --embed-thumbnail \
                --add-metadata \
                --yes-playlist \
                --output "$output_tmpl" \
                --progress \
                --no-warnings \
                "$url"
            ;;
    esac

    # Count downloaded files
    local count
    count=$(find "$dest_dir" -type f \( -name "*.mp3" -o -name "*.mp4" -o -name "*.m4a" \) | wc -l)
    TOTAL_FILES=$((TOTAL_FILES + count))
    success "yt-dlp downloaded $count file(s) to $dest_dir"
}

# ---------------------------------------------------------------------------
# Recursively crawl a web URL and download matching files
# Mirrors getAllLinks() + download() from the original Python script
# ---------------------------------------------------------------------------

# Build extension filter based on FORMAT
get_ext_pattern() {
    case "$FORMAT" in
        mp3) echo "\.mp3" ;;
        mp4) echo "\.mp4" ;;
        all) echo "\.\(mp3\|mp4\|pdf\|wav\|zip\|m4a\|ogg\)" ;;
    esac
}

# Track visited URLs to prevent infinite recursion
declare -A VISITED_URLS

crawl_and_download() {
    local url="$1"
    local dest_dir="$2"

    # Avoid re-visiting the same URL
    if [[ -n "${VISITED_URLS[$url]+_}" ]]; then
        warn "Already visited: $url — skipping."
        return
    fi
    VISITED_URLS["$url"]=1

    info "Crawling: $url"
    mkdir -p "$dest_dir"

    # Fetch the page HTML
    local page_html
    page_html=$(curl --silent --location --max-time 30 "$url") || {
        warn "Failed to fetch: $url"
        return
    }

    # Extract the base URL (scheme + host) for resolving relative links
    local base_url
    base_url=$(echo "$url" | grep -oE "^https?://[^/]+")

    # Extract all href links from the page
    local -a all_links
    mapfile -t all_links < <(
        echo "$page_html" \
        | grep -oE 'href="[^"]+"' \
        | sed 's/href="//;s/"//' \
        | sort -u
    )

    local ext_pattern
    ext_pattern=$(get_ext_pattern)

    for link in "${all_links[@]}"; do
        # Resolve relative URLs
        if [[ "$link" == http* ]]; then
            full_url="$link"
        elif [[ "$link" == //* ]]; then
            full_url="$(echo "$url" | grep -oE '^https?:')$link"
        elif [[ "$link" == /* ]]; then
            full_url="${base_url}${link}"
        else
            # Relative path — join with current URL's directory
            local base_path
            base_path=$(echo "$url" | sed 's|[^/]*$||')
            full_url="${base_path}${link}"
        fi

        # Skip anchors, mailto, javascript links
        if echo "$full_url" | grep -qiE "^(mailto:|javascript:|#)"; then
            continue
        fi

        # If link points to a downloadable file — download it
        if echo "$full_url" | grep -qiE "$ext_pattern"; then
            download_direct_file "$full_url" "$dest_dir"

        # If link looks like a directory/subfolder on the same domain — recurse
        elif echo "$full_url" | grep -qiE "^${base_url}" \
            && ! echo "$full_url" | grep -qiE "\.[a-zA-Z0-9]{2,5}$"; then
            local subfolder_name
            subfolder_name=$(sanitize_filename "$(basename "$full_url")")
            if [[ -n "$subfolder_name" && "$subfolder_name" != "." ]]; then
                crawl_and_download "$full_url" "$dest_dir/$subfolder_name"
            fi
        fi
    done
}

# ---------------------------------------------------------------------------
# Download a single direct file URL via wget
# ---------------------------------------------------------------------------
download_direct_file() {
    local file_url="$1"
    local dest_dir="$2"

    # Extract filename from URL and sanitize it
    local raw_name
    raw_name=$(basename "$(echo "$file_url" | sed 's/?.*//')")
    local safe_name
    safe_name=$(sanitize_filename "$raw_name")

    local dest_file="$dest_dir/$safe_name"

    if [[ -f "$dest_file" ]]; then
        warn "Already exists, skipping: $safe_name"
        return
    fi

    info "Downloading: $safe_name"
    if wget --quiet --show-progress -O "$dest_file" "$file_url"; then
        local file_bytes
        file_bytes=$(wc -c < "$dest_file")
        TOTAL_BYTES=$((TOTAL_BYTES + file_bytes))
        TOTAL_FILES=$((TOTAL_FILES + 1))
        success "Saved: $dest_file"
    else
        warn "Failed to download: $file_url"
        rm -f "$dest_file"
    fi
}

# ---------------------------------------------------------------------------
# Print final stats (mirrors EnterUrl's print block)
# ---------------------------------------------------------------------------
print_stats() {
    local start="$1"
    local end="$2"

    local total_mb
    total_mb=$(echo "scale=2; $TOTAL_BYTES / 1048576" | bc)
    local total_gb
    total_gb=$(echo "scale=4; $TOTAL_BYTES / 1073741824" | bc)

    local elapsed_secs=$(( end - start ))
    local elapsed_mins
    elapsed_mins=$(echo "scale=2; $elapsed_secs / 60" | bc)
    local elapsed_hrs
    elapsed_hrs=$(echo "scale=4; $elapsed_secs / 3600" | bc)

    echo ""
    echo -e "${BOLD}==============================${RESET}"
    echo -e "${BOLD}         DOWNLOAD STATS       ${RESET}"
    echo -e "${BOLD}==============================${RESET}"
    echo -e "  Total files : ${GREEN}${TOTAL_FILES}${RESET}"
    echo -e "  Total MB    : ${GREEN}${total_mb} MB${RESET}"
    echo -e "  Total GB    : ${GREEN}${total_gb} GB${RESET}"
    echo -e "  Start time  : $(date -d @"$start" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date -r "$start" '+%Y-%m-%d %H:%M:%S')"
    echo -e "  End time    : $(date -d @"$end"   '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date -r "$end"   '+%Y-%m-%d %H:%M:%S')"
    echo -e "  Elapsed     : ${elapsed_secs}s / ${elapsed_mins}min / ${elapsed_hrs}hrs"
    echo -e "${BOLD}==============================${RESET}"
    echo ""
}

# ---------------------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------------------
main() {
    check_deps
    parse_args "$@"

    # Validate inputs
    if [[ -z "$START_URL" ]]; then
        error "No URL provided. Use --url <URL> or enter it when prompted."
        exit 1
    fi
    if [[ -z "$OUTPUT_PATH" ]]; then
        error "No output path provided. Use --path <DIR> or enter it when prompted."
        exit 1
    fi

    # Ensure output directory exists
    local full_dest="${OUTPUT_PATH}/${FOLDER_NAME}"
    mkdir -p "$full_dest" || { error "Cannot create output directory: $full_dest"; exit 1; }

    START_TIME=$(date +%s)
    echo ""
    info "Starting downloader..."
    info "URL    : $START_URL"
    info "Output : $full_dest"
    info "Format : $FORMAT"
    echo ""

    # Decide: YouTube/yt-dlp route vs. direct web crawl route
    if is_youtube_url "$START_URL"; then
        ytdlp_download "$START_URL" "$full_dest" "$FORMAT"
    elif is_ytdlp_supported "$START_URL"; then
        warn "URL appears to be supported by yt-dlp (non-YouTube). Using yt-dlp."
        ytdlp_download "$START_URL" "$full_dest" "$FORMAT"
    else
        info "Using recursive web crawl mode."
        crawl_and_download "$START_URL" "$full_dest"
    fi

    END_TIME=$(date +%s)
    print_stats "$START_TIME" "$END_TIME"
}

main "$@"
