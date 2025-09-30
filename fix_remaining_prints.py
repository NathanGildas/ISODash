#!/usr/bin/env python3
"""
Fix remaining print() statements in kpi_calculator_service.dart and openproject_explorer.dart
"""
import re

def fix_file(filepath):
    """Fix print statements in a file"""
    print(f"\n[PROCESSING] {filepath}")

    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content

    # Replace print( with Logger.info( (preserving multiline)
    # This handles multiline print statements
    content = re.sub(
        r'\bprint\(',
        'Logger.info(',
        content
    )

    # Add tag: 'KPI' or 'Service' before closing parenthesis if not present
    # This is a simple heuristic - add tag parameter to Logger calls without it
    lines = content.split('\n')
    new_lines = []
    in_logger_call = False
    logger_indent = 0

    for i, line in enumerate(lines):
        # Check if this line starts a Logger call
        if 'Logger.' in line and '(' in line:
            in_logger_call = True
            logger_indent = len(line) - len(line.lstrip())
            # Check if this is a single-line call with closing )
            if line.count('(') == line.count(')'):
                # Single line Logger call - check if it has tag parameter
                if 'tag:' not in line and ');' in line:
                    # Add tag parameter before closing
                    tag = "'Service'" if 'openproject' in filepath else "'KPI'"
                    line = line.replace(');', f', tag: {tag});')
                in_logger_call = False
        elif in_logger_call:
            # Check if this is the closing line
            stripped = line.strip()
            if stripped == ');' or stripped.startswith(');'):
                # Add tag parameter
                tag = "'Service'" if 'openproject' in filepath else "'KPI'"
                indent_str = ' ' * (logger_indent + 2)
                new_lines.append(f'{indent_str}tag: {tag},')
                in_logger_call = False

        new_lines.append(line)

    content = '\n'.join(new_lines)

    if content != original_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"[OK] Fixed {filepath}")
        return True
    else:
        print(f"[SKIP] No changes needed in {filepath}")
        return False

if __name__ == '__main__':
    files = [
        r'C:\Users\Gildas\AndroidStudioProjects\ISODash\lib\services\kpi_calculator_service.dart',
        r'C:\Users\Gildas\AndroidStudioProjects\ISODash\lib\services\openproject_explorer.dart',
    ]

    print("="*70)
    print("Fix Remaining Print Statements")
    print("="*70)

    modified = 0
    for filepath in files:
        if fix_file(filepath):
            modified += 1

    print("\n" + "="*70)
    print(f"Summary: {modified}/{len(files)} files modified")
    print("="*70)
    print("\n[OK] Done! Run 'flutter analyze' to verify.")