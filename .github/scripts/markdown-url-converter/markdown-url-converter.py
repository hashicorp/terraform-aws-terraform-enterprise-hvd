#!/usr/bin/env python3
import re
import sys
import os
from urllib.parse import urljoin
from pathlib import Path
from typing import List, Tuple
import argparse

"""
Markdown URL Converter

This script converts relative URLs in Markdown files to absolute URLs. It's useful
for preparing documentation that will be displayed in different contexts (e.g., on
GitHub, documentation websites, or repositories).

The script supports:
  - Converting relative links to absolute URLs using a base URL
  - Generating GitHub URLs from repository and release information
  - Processing single files or entire directory trees
  - Dry-run mode to preview changes without modifying files
  - Overwriting original files or creating new files with _converted suffix

Supported Markdown URL formats:
  - Inline links: [text](url)
  - Image links: ![alt](image-url)
  - Reference-style definitions: [text]: url

Usage examples:
  # Convert using a base URL
  python3 markdown-url-converter.py ./docs --base-url https://example.com/docs/

  # Convert using GitHub repository info
  python3 markdown-url-converter.py ./docs --repo owner/repo --release main

  # Dry run to preview changes
  python3 markdown-url-converter.py ./docs --base-url https://example.com/ --dry-run

  # Overwrite original files
  python3 markdown-url-converter.py ./docs --base-url https://example.com/ --overwrite

Environment variables:
  BASE_URL: Default base URL for relative links (can be overridden with --base-url)

Author: HashiCorp
"""

def construct_github_url(repo: str, release: str) -> str:
    """
    Construct GitHub URL from repo and release information.

    Args:
        repo (str): Repository in format "owner/repo"
        release (str): Release tag or branch name

    Returns:
        str: Complete GitHub base URL
    """
    if not repo or not release:
        return None

    if not re.match(r'^[^/]+/[^/]+$', repo):
        raise ValueError("Repository must be in format 'owner/repo'")

    return f"https://github.com/{repo}/blob/{release}/"

def convert_markdown_urls(content: str, base_url: str, file_path: Path, root_dir: Path) -> str:
    """
    Convert relative Markdown URLs to absolute URLs using the provided base URL.

    Args:
        content (str): Markdown content containing URLs
        base_url (str): Base URL to prepend to relative URLs
        file_path (Path): Path to the current file being processed
        root_dir (Path): Root directory of the documentation

    Returns:
        str: Markdown content with converted absolute URLs
    """
    # Calculate the relative path from root to get the correct base URL for this file
    rel_path = file_path.parent.relative_to(root_dir)
    if str(rel_path) == '.':
        current_base_url = base_url.rstrip('/')
    else:
        current_base_url = f"{base_url.rstrip('/')}/{rel_path}"

    # Regular expression patterns for different types of Markdown URLs
    patterns = [
        # [text](url) format
        (r'\[([^\]]+)\]\((?!http|#|mailto:)([^)]+)\)',
         lambda m: f'[{m.group(1)}]({urljoin(current_base_url + "/", m.group(2))})'
        ),
        # ![alt](image-url) format
        (r'!\[([^\]]*)\]\((?!http|#)([^)]+)\)',
         lambda m: f'![{m.group(1)}]({urljoin(current_base_url + "/", m.group(2))})'
        ),
        # Reference-style [text][ref] definitions
        (r'^\[([^\]]+)\]:\s*(?!http|#|mailto:)([^\s]+)(.*)$',
         lambda m: f'[{m.group(1)}]: {urljoin(current_base_url + "/", m.group(2))}{m.group(3)}',
         re.MULTILINE
        )
    ]

    # Apply each pattern to the content
    result = content
    for pattern, replacement, *flags in patterns:
        if flags:
            result = re.sub(pattern, replacement, result, flags=flags[0])
        else:
            result = re.sub(pattern, replacement, result)

    return result

def find_markdown_files(directory: Path) -> List[Path]:
    """Find all markdown files in the directory tree."""
    markdown_files = []
    for ext in ['.md', '.markdown']:
        markdown_files.extend(directory.rglob(f'*{ext}'))
    return sorted(markdown_files)

def process_file(file_path: Path, base_url: str, root_dir: Path, dry_run: bool = False, overwrite: bool = False) -> Tuple[bool, str]:
    """Process a single markdown file."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        converted_content = convert_markdown_urls(content, base_url, file_path, root_dir)

        if content == converted_content:
            return True, f"No changes needed for {file_path}"

        if not dry_run:
            if overwrite:
                output_file = file_path
                action = "Overwrote"
            else:
                output_file = file_path.with_stem(f"{file_path.stem}_converted")
                action = "Converted"

            with open(output_file, 'w', encoding='utf-8') as f:
                f.write(converted_content)
            return True, f"{action} {file_path}"
        else:
            return True, f"Would convert {file_path} (dry run)"

    except Exception as e:
        return False, f"Error processing {file_path}: {e}"

def main():
    parser = argparse.ArgumentParser(description='Convert relative Markdown URLs to absolute URLs')
    parser.add_argument('path', type=Path, help='File or directory to process')

    # URL source group (mutually exclusive)
    url_group = parser.add_mutually_exclusive_group(required=True)
    url_group.add_argument('--base-url', type=str,
                        help='Base URL for absolute links (overrides BASE_URL environment variable)')
    url_group.add_argument('--repo', type=str,
                        help='GitHub repository in format "owner/repo"')

    parser.add_argument('--release', type=str,
                      help='Release tag or branch name (required when --repo is used)')
    parser.add_argument('--dry-run', action='store_true',
                      help='Show what would be done without making changes')
    parser.add_argument('--overwrite', action='store_true',
                      help='Overwrite original files instead of creating new ones with _converted suffix')
    args = parser.parse_args()

    if args.dry_run and args.overwrite:
        print("Warning: --overwrite has no effect with --dry-run")

    # Handle GitHub URL construction
    if args.repo:
        if not args.release:
            parser.error("--release is required when using --repo")
        try:
            base_url = construct_github_url(args.repo, args.release)
        except ValueError as e:
            parser.error(str(e))
    else:
        # Get base URL from argument or environment
        base_url = args.base_url or os.environ.get('BASE_URL')

    if not base_url:
        parser.error("BASE_URL must be provided via environment variable or --base-url argument\n" +
                    "Or use --repo and --release to construct a GitHub URL")

    # Determine if input is file or directory
    input_path = args.path.resolve()
    if not input_path.exists():
        print(f"Error: Path '{input_path}' not found")
        sys.exit(1)

    # Process single file or directory
    if input_path.is_file():
        files_to_process = [input_path]
        root_dir = input_path.parent
    else:
        files_to_process = find_markdown_files(input_path)
        root_dir = input_path

    if not files_to_process:
        print("No markdown files found to process")
        sys.exit(0)

    # Process all files
    success_count = 0
    error_count = 0

    print(f"Processing files with base URL: {base_url}")
    print(f"{'DRY RUN - ' if args.dry_run else ''}Root directory: {root_dir}")
    print(f"Mode: {'Overwrite' if args.overwrite and not args.dry_run else 'Create new files'}")
    print("-" * 60)

    for file_path in files_to_process:
        success, message = process_file(file_path, base_url, root_dir, args.dry_run, args.overwrite)
        print(message)
        if success:
            success_count += 1
        else:
            error_count += 1

    print("-" * 60)
    print(f"Processed {len(files_to_process)} files:")
    print(f"  Success: {success_count}")
    print(f"  Errors: {error_count}")

if __name__ == "__main__":
    main()
