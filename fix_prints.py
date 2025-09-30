#!/usr/bin/env python3
"""
Script to replace print() statements with Logger calls
"""
import re
import sys

def replace_prints_in_file(filepath):
    """Replace print statements with Logger calls in a Dart file"""

    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        original_content = content

        # Pattern replacements
        replacements = [
            # Error messages (❌)
            (r"print\('([^']*)❌([^']*)'\);", r"Logger.error('\1\2', tag: 'KPI');"),
            # Success messages (✅)
            (r"print\('([^']*)✅([^']*)'\);", r"Logger.success('\1\2', tag: 'KPI');"),
            # Warning messages (⚠️)
            (r"print\('([^']*)⚠️([^']*)'\);", r"Logger.warn('\1\2', tag: 'KPI');"),
            # Info messages (📊, 📋, 🔍, 🧮)
            (r"print\('([^']*)(📊|📋|🔍|🧮)([^']*)'\);", r"Logger.info('\1\3', tag: 'KPI');"),
            # Generic print with emojis removed
            (r"print\('([🎯🌿📁]+ *)([^']*)'\);", r"Logger.info('\2', tag: 'KPI');"),
            # Any remaining prints
            (r"print\('([^']*)'\);", r"Logger.info('\1', tag: 'KPI');"),
        ]

        for pattern, replacement in replacements:
            content = re.sub(pattern, replacement, content)

        if content != original_content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"✅ Fixed {filepath}")
            return True
        else:
            print(f"ℹ️  No changes needed in {filepath}")
            return False

    except Exception as e:
        print(f"❌ Error processing {filepath}: {e}")
        return False

if __name__ == "__main__":
    files = [
        r"C:\Users\Gildas\AndroidStudioProjects\ISODash\lib\services\kpi_calculator_service.dart",
        r"C:\Users\Gildas\AndroidStudioProjects\ISODash\lib\services\openproject_explorer.dart",
        r"C:\Users\Gildas\AndroidStudioProjects\ISODash\lib\screens\guided_auth_screen.dart",
        r"C:\Users\Gildas\AndroidStudioProjects\ISODash\lib\screens\kpi_dashboard_screen.dart",
    ]

    total_fixed = 0
    for filepath in files:
        if replace_prints_in_file(filepath):
            total_fixed += 1

    print(f"\n✨ Fixed {total_fixed}/{len(files)} files")