#!/usr/bin/env python3
"""
Script to replace all print() statements with secure Logger calls in Dart files
Handles emoji patterns and converts them to appropriate Logger levels
"""
import re
import os
import sys
from pathlib import Path

# Emoji to Logger level mapping
EMOJI_PATTERNS = {
    'error': ['❌', '🔴', '💥'],
    'success': ['✅', '✔️', '🎉', '🟢'],
    'warn': ['⚠️', '⚡', '🟡', '🔶'],
    'info': ['📊', '📋', '🔍', '🧮', '🔄', '📡', '🌐', '📁', '🎯', '🌿', '💾', '🗑️', '🧪', '📦'],
}

def get_logger_level(text):
    """Determine the appropriate Logger level based on emoji in text"""
    for level, emojis in EMOJI_PATTERNS.items():
        for emoji in emojis:
            if emoji in text:
                return level
    return 'info'  # Default

def remove_emojis(text):
    """Remove all emojis from text"""
    # Remove all emojis using regex
    emoji_pattern = re.compile("["
        u"\U0001F600-\U0001F64F"  # emoticons
        u"\U0001F300-\U0001F5FF"  # symbols & pictographs
        u"\U0001F680-\U0001F6FF"  # transport & map symbols
        u"\U0001F1E0-\U0001F1FF"  # flags (iOS)
        u"\U00002702-\U000027B0"
        u"\U000024C2-\U0001F251"
        "]+", flags=re.UNICODE)
    return emoji_pattern.sub('', text).strip()

def determine_tag(filepath):
    """Determine appropriate tag based on file path"""
    path_lower = filepath.lower()
    if 'kpi' in path_lower:
        return 'KPI'
    elif 'provider' in path_lower:
        return 'Provider'
    elif 'service' in path_lower:
        return 'Service'
    elif 'screen' in path_lower:
        return 'UI'
    elif 'widget' in path_lower:
        return 'Widget'
    else:
        return 'App'

def fix_print_statements(filepath, dry_run=False):
    """Fix print statements in a single file"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        original_content = content
        changes = []
        tag = determine_tag(filepath)

        # Add Logger import if not present and print() exists
        if 'print(' in content and "import '../utils/logger.dart';" not in content:
            # Find the last import statement
            import_pattern = r"(import ['\"].*['\"];)"
            imports = list(re.finditer(import_pattern, content))
            if imports:
                last_import = imports[-1]
                insert_pos = last_import.end()
                content = (content[:insert_pos] +
                          "\nimport '../utils/logger.dart';" +
                          content[insert_pos:])
                changes.append(f"  + Added Logger import")

        # Pattern for single-line print statements
        # Match: print('...');
        def replace_print(match):
            """Replace a single print statement with Logger call"""
            full_match = match.group(0)
            content_text = match.group(1)

            # Determine logger level based on content
            level = get_logger_level(content_text)

            # Remove emojis from content
            clean_text = remove_emojis(content_text)

            # Build Logger call
            logger_call = f"Logger.{level}('{clean_text}', tag: '{tag}');"

            changes.append(f"  - print('{content_text[:50]}...') → Logger.{level}()")
            return logger_call

        # Replace all print statements
        pattern = r"print\('([^']*)'\);"
        content = re.sub(pattern, replace_print, content)

        # Handle multi-line print statements (less common)
        multiline_pattern = r"print\(\s*'([^']*?)'\s*\);"
        content = re.sub(multiline_pattern, replace_print, content, flags=re.MULTILINE | re.DOTALL)

        if content != original_content:
            if not dry_run:
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(content)
                print(f"[OK] Fixed: {filepath}")
                for change in changes[:5]:  # Show first 5 changes
                    print(change)
                if len(changes) > 5:
                    print(f"  ... and {len(changes) - 5} more changes")
                return True, len(changes)
            else:
                print(f"[DRY] Would fix: {filepath}")
                for change in changes[:5]:
                    print(change)
                if len(changes) > 5:
                    print(f"  ... and {len(changes) - 5} more changes")
                return True, len(changes)
        else:
            print(f"[SKIP] No changes needed: {filepath}")
            return False, 0

    except Exception as e:
        print(f"[ERROR] Error processing {filepath}: {e}")
        return False, 0

def find_dart_files_with_prints(base_path):
    """Find all Dart files containing print statements"""
    dart_files = []
    for root, dirs, files in os.walk(base_path):
        # Skip certain directories
        if any(skip in root for skip in ['.dart_tool', 'build', '.git', 'windows', 'linux', 'macos', 'ios', 'android']):
            continue

        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file)
                try:
                    with open(filepath, 'r', encoding='utf-8') as f:
                        if 'print(' in f.read():
                            dart_files.append(filepath)
                except:
                    pass

    return dart_files

def main():
    base_path = Path(__file__).parent / 'lib'

    print("=" * 70)
    print("Dart Print Statement Fixer")
    print("=" * 70)
    print(f"Scanning: {base_path}")
    print()

    # Find all files with print statements
    files_to_fix = find_dart_files_with_prints(base_path)

    if not files_to_fix:
        print("[OK] No print statements found!")
        return 0

    print(f"Found {len(files_to_fix)} files with print statements:")
    for f in files_to_fix:
        print(f"  - {os.path.relpath(f, base_path.parent)}")
    print()

    # Ask for confirmation
    response = input("Fix all files? (y/n, or 'd' for dry-run): ").strip().lower()

    if response == 'd':
        dry_run = True
        print("\n[DRY RUN] No files will be modified\n")
    elif response == 'y':
        dry_run = False
        print("\n[START] Starting fixes...\n")
    else:
        print("[CANCEL] Cancelled")
        return 1

    # Fix all files
    fixed_count = 0
    total_changes = 0

    for filepath in files_to_fix:
        fixed, changes = fix_print_statements(filepath, dry_run=dry_run)
        if fixed:
            fixed_count += 1
            total_changes += changes
        print()

    # Summary
    print("=" * 70)
    print(f"Summary:")
    print(f"  Files processed: {len(files_to_fix)}")
    print(f"  Files {'would be ' if dry_run else ''}fixed: {fixed_count}")
    print(f"  Total print statements {'would be ' if dry_run else ''}replaced: {total_changes}")
    print("=" * 70)

    if not dry_run and fixed_count > 0:
        print("\n[OK] All print statements have been replaced with Logger calls!")
        print("[INFO] Run 'flutter analyze' to verify the changes")

    return 0

if __name__ == "__main__":
    sys.exit(main())