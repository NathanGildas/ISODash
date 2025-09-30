#!/usr/bin/env python3
"""
Master script to fix all Flutter analyzer issues
- Replaces print() with Logger
- Replaces withOpacity with withValues
- No emojis for Windows console compatibility
"""
import re
import os
import sys
from pathlib import Path

def add_logger_import_if_needed(content):
    """Add Logger import if print() exists but import doesn't"""
    if 'print(' in content and "import '../utils/logger.dart';" not in content:
        import_pattern = r"(import ['\"].*['\"];)"
        imports = list(re.finditer(import_pattern, content))
        if imports:
            last_import = imports[-1]
            insert_pos = last_import.end()
            return (content[:insert_pos] +
                   "\nimport '../utils/logger.dart';" +
                   content[insert_pos:])
    return content

def determine_tag(filepath):
    """Determine tag based on file path"""
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

def fix_print_statements(content, filepath):
    """Replace print() with Logger calls"""
    changes = []
    tag = determine_tag(filepath)

    # Add import if needed
    content = add_logger_import_if_needed(content)

    def replace_print(match):
        text = match.group(1)
        # Determine level based on keywords
        if any(keyword in text.lower() for keyword in ['error', 'erreur', 'failed', 'exception']):
            level = 'error'
        elif any(keyword in text.lower() for keyword in ['success', 'complete', 'done']):
            level = 'success'
        elif any(keyword in text.lower() for keyword in ['warn', 'alert', 'attention']):
            level = 'warn'
        else:
            level = 'info'

        # Remove common emojis
        clean_text = text
        for emoji in ['✅', '❌', '⚠️', '📊', '📋', '🔍', '🧮', '🔄', '📡', '🌐', '📁', '🎯', '🌿', '💾', '🗑️', '🧪', '📦']:
            clean_text = clean_text.replace(emoji, '')
        clean_text = clean_text.strip()

        changes.append((text[:40], level))
        return f"Logger.{level}('{clean_text}', tag: '{tag}');"

    # Replace print statements
    content = re.sub(r"print\('([^']*)'\);", replace_print, content)

    return content, changes

def fix_with_opacity(content):
    """Replace withOpacity with withValues"""
    changes = []

    def replace_opacity(match):
        value = match.group(1)
        changes.append(value)
        return f".withValues(alpha: {value})"

    content = re.sub(r'\.withOpacity\(([\d.]+)\)', replace_opacity, content)
    return content, changes

def process_file(filepath):
    """Process a single Dart file"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            original = f.read()

        content = original
        print_changes = []
        opacity_changes = []

        # Fix print statements
        if 'print(' in content:
            content, print_changes = fix_print_statements(content, filepath)

        # Fix withOpacity
        if '.withOpacity(' in content:
            content, opacity_changes = fix_with_opacity(content)

        if content != original:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)

            print(f"\n[OK] {os.path.relpath(filepath)}")
            if print_changes:
                print(f"  - Fixed {len(print_changes)} print() statements")
            if opacity_changes:
                print(f"  - Fixed {len(opacity_changes)} withOpacity() calls")
            return True
        else:
            return False

    except Exception as e:
        print(f"[ERROR] {filepath}: {e}")
        return False

def find_dart_files(base_path):
    """Find all Dart files"""
    dart_files = []
    for root, dirs, files in os.walk(base_path):
        if any(skip in root for skip in ['.dart_tool', 'build', '.git', 'windows', 'linux', 'macos', 'ios', 'android']):
            continue
        for file in files:
            if file.endswith('.dart'):
                dart_files.append(os.path.join(root, file))
    return dart_files

def main():
    base_path = Path(__file__).parent / 'lib'

    print("=" * 70)
    print("Flutter Code Quality Fixer")
    print("Fixes: print() statements and withOpacity deprecations")
    print("=" * 70)
    print(f"Scanning: {base_path}\n")

    files = find_dart_files(base_path)
    print(f"Found {len(files)} Dart files\n")

    response = input("Proceed with fixes? (y/n): ").strip().lower()
    if response != 'y':
        print("[CANCEL] Operation cancelled")
        return 1

    print("\n[START] Processing files...\n")

    fixed_count = 0
    for filepath in files:
        if process_file(filepath):
            fixed_count += 1

    print("\n" + "=" * 70)
    print("Summary:")
    print(f"  Files processed: {len(files)}")
    print(f"  Files modified: {fixed_count}")
    print("=" * 70)
    print("\n[OK] Done! Run 'flutter analyze' to verify.")

    return 0

if __name__ == "__main__":
    sys.exit(main())