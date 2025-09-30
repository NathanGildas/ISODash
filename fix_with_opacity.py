#!/usr/bin/env python3
"""
Script to replace deprecated .withOpacity() with .withValues() in Flutter code
Flutter 3.x deprecates withOpacity in favor of withValues for better precision
"""
import re
import os
import sys
from pathlib import Path

def fix_with_opacity(filepath, dry_run=False):
    """Fix withOpacity deprecations in a single file"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        original_content = content
        changes = []

        # Pattern to match .withOpacity(number)
        # Handles: .withOpacity(0.5), .withOpacity(0.2), etc.
        def replace_opacity(match):
            """Replace withOpacity with withValues"""
            full_match = match.group(0)
            opacity_value = match.group(1)

            # Convert to withValues(alpha: value)
            replacement = f".withValues(alpha: {opacity_value})"

            changes.append(f"  - {full_match} → {replacement}")
            return replacement

        # Replace all .withOpacity(value) with .withValues(alpha: value)
        pattern = r'\.withOpacity\(([\d.]+)\)'
        content = re.sub(pattern, replace_opacity, content)

        if content != original_content:
            if not dry_run:
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(content)
                print(f"✅ Fixed: {filepath}")
                print(f"   Replaced {len(changes)} occurrences")
                if len(changes) <= 5:
                    for change in changes:
                        print(change)
                else:
                    for change in changes[:3]:
                        print(change)
                    print(f"   ... and {len(changes) - 3} more")
                return True, len(changes)
            else:
                print(f"🔍 Would fix: {filepath}")
                print(f"   Would replace {len(changes)} occurrences")
                if len(changes) <= 5:
                    for change in changes:
                        print(change)
                else:
                    for change in changes[:3]:
                        print(change)
                    print(f"   ... and {len(changes) - 3} more")
                return True, len(changes)
        else:
            print(f"ℹ️  No changes needed: {filepath}")
            return False, 0

    except Exception as e:
        print(f"❌ Error processing {filepath}: {e}")
        return False, 0

def find_dart_files_with_opacity(base_path):
    """Find all Dart files containing withOpacity"""
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
                        if '.withOpacity(' in f.read():
                            dart_files.append(filepath)
                except:
                    pass

    return dart_files

def main():
    base_path = Path(__file__).parent / 'lib'

    print("=" * 70)
    print("Flutter withOpacity Deprecation Fixer")
    print("=" * 70)
    print(f"Scanning: {base_path}")
    print()

    # Find all files with withOpacity
    files_to_fix = find_dart_files_with_opacity(base_path)

    if not files_to_fix:
        print("✨ No withOpacity usage found!")
        return 0

    print(f"Found {len(files_to_fix)} files with withOpacity:")
    for f in files_to_fix:
        print(f"  - {os.path.relpath(f, base_path.parent)}")
    print()

    # Ask for confirmation
    response = input("Fix all files? (y/n, or 'd' for dry-run): ").strip().lower()

    if response == 'd':
        dry_run = True
        print("\n🔍 DRY RUN MODE - No files will be modified\n")
    elif response == 'y':
        dry_run = False
        print("\n🚀 Starting fixes...\n")
    else:
        print("❌ Cancelled")
        return 1

    # Fix all files
    fixed_count = 0
    total_changes = 0

    for filepath in files_to_fix:
        fixed, changes = fix_with_opacity(filepath, dry_run=dry_run)
        if fixed:
            fixed_count += 1
            total_changes += changes
        print()

    # Summary
    print("=" * 70)
    print(f"✨ Summary:")
    print(f"  Files processed: {len(files_to_fix)}")
    print(f"  Files {'would be ' if dry_run else ''}fixed: {fixed_count}")
    print(f"  Total withOpacity calls {'would be ' if dry_run else ''}replaced: {total_changes}")
    print("=" * 70)

    if not dry_run and fixed_count > 0:
        print("\n✅ All withOpacity calls have been replaced with withValues!")
        print("🔄 Run 'flutter analyze' to verify the changes")

    return 0

if __name__ == "__main__":
    sys.exit(main())