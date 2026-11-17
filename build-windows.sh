#!/usr/bin/env sh
PLUGIN_SLUG="$(basename $PWD)"
PROJECT_PATH=$(pwd)
BUILD_PATH="./build-zip"
DEST_PATH="$BUILD_PATH/$PLUGIN_SLUG"

export PATH="/c/msys64/usr/bin:$PATH"

# Function to display progress messages
progress_message() {
    local message="$1"
    
    # Define color codes
    local color_reset="\033[0m"
    local color_green="\033[32m"
    
    # Print the colorized message
    echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] ${color_green}${message}${color_reset}"
}

# abort on errors
set -e

# prepare place for build.
progress_message "Preparing build directory..."
rm -rf "$BUILD_PATH"
rm -rf "$PLUGIN_SLUG".zip
mkdir -p "$DEST_PATH"

# copy all files for production
progress_message "Copying files for production..."
rsync -av --exclude-from=".distignore" . "$DEST_PATH/"

## Create zip archive
progress_message "Creating zip archive..."
cd "$BUILD_PATH"
"C:\Program Files\WinRAR\WinRAR.exe" a "$PROJECT_PATH/$PLUGIN_SLUG.zip" "$PLUGIN_SLUG"/*
cd "$PROJECT_PATH"

## Verify the build: every production file must be in the build folder and in the zip.
ZIP_FILE="$PROJECT_PATH/$PLUGIN_SLUG.zip"
EXPECTED_LIST="$BUILD_PATH/expected-files.txt"
ZIPPED_LIST="$BUILD_PATH/zipped-files.txt"

# Fails the build and removes the zip, so an incomplete zip can't be uploaded by mistake.
build_failed() {
    echo -e "\033[31mBUILD FAILED: $1\033[0m"
    rm -f "$ZIP_FILE"
    exit 1
}

progress_message "Verifying build folder against the source..."
# A dry run lists every file whose content differs from the source or is missing from the build folder.
SOURCE_DIFF_LIST="$BUILD_PATH/source-diff.txt"
rsync -rcn --out-format='%n' --exclude-from=".distignore" . "$DEST_PATH/" > "$SOURCE_DIFF_LIST" \
|| build_failed "could not compare the build folder with the source (rsync failed)."
SOURCE_DIFF="$(grep -v '/$' "$SOURCE_DIFF_LIST" || true)"
rm -f "$SOURCE_DIFF_LIST"
if [ -n "$SOURCE_DIFF" ]; then
    echo "$SOURCE_DIFF" | head -50
    build_failed "the files above are missing from (or differ in) $DEST_PATH."
fi

progress_message "Verifying zip archive against the build folder..."
[ -f "$ZIP_FILE" ] || build_failed "$ZIP_FILE was not created."

(cd "$BUILD_PATH" && find "$PLUGIN_SLUG" -type f | LC_ALL=C sort) > "$EXPECTED_LIST"

if command -v unzip >/dev/null 2>&1; then
    unzip -Z1 "$ZIP_FILE" | { grep -v '/$' || true; } | LC_ALL=C sort > "$ZIPPED_LIST"
else
    powershell.exe -NoProfile -Command "Add-Type -AssemblyName System.IO.Compression.FileSystem; \$zip = [System.IO.Compression.ZipFile]::OpenRead('$(cygpath -w "$ZIP_FILE")'); \$zip.Entries | ForEach-Object { \$_.FullName }; \$zip.Dispose()" \
    | tr -d '\r' | sed 's#\\#/#g' | { grep -v '/$' || true; } | LC_ALL=C sort > "$ZIPPED_LIST"
fi

if ! diff -q "$EXPECTED_LIST" "$ZIPPED_LIST" >/dev/null; then
    echo "Lines starting with < are in the build folder but missing from the zip; > are in the zip only:"
    diff "$EXPECTED_LIST" "$ZIPPED_LIST" | grep '^[<>]' | head -50
    build_failed "the zip does not contain exactly the files of the build folder."
fi

FILE_COUNT="$(wc -l < "$EXPECTED_LIST" | tr -d ' ')"
[ "$FILE_COUNT" -gt 0 ] || build_failed "the build folder is empty."
rm -f "$EXPECTED_LIST" "$ZIPPED_LIST"
progress_message "Zip verified: all $FILE_COUNT files present."

# Completion message
progress_message "Build process completed successfully."
exit
