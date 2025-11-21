# Markdown URL converter

A Python script that converts relative URLs in markdown files to absolute URLs. This is particularly useful for documentation that needs to reference files from a specific base URL, such as GitHub repository documentation or hosted documentation sites.

## Features

- Convert relative URLs to absolute URLs in Markdown files
- Process single files or entire directory trees
- Smart handling of nested directories for correct URL paths
- GitHub repository URL support with release/tag specification
- Overwrite option for in-place updates
- Dry-run mode to preview changes
- Support for various Markdown link formats

## Installation

1. Ensure you have Python 3.6 or later installed
1. Download the `convert_markdown_urls.py` script
1. Make it executable (Unix-like systems):

   ```bash
   chmod +x convert_markdown_urls.py
   ```

## Usage

### Basic usage

Process a single file or directory using a base URL:

```bash
python convert_markdown_urls.py --base-url="https://example.com" docs/
```

### GitHub repository usage

Convert URLs to point to specific GitHub repository release:

```bash
python convert_markdown_urls.py --repo="owner/repo" --release="0.1.0" docs/
```

This will create URLs in the format: `https://github.com/owner/repo/blob/0.1.0/path/to/file`

### Command line options

```pre
usage: convert_markdown_urls.py [-h] (--base-url BASE_URL | --repo REPO)
                              [--release RELEASE] [--dry-run] [--overwrite]
                              path

Convert relative Markdown URLs to absolute URLs

positional arguments:
  path                  File or directory to process

options:
  -h, --help           show this help message and exit
  --base-url BASE_URL  Base URL for absolute links (overrides BASE_URL environment variable)
  --repo REPO          GitHub repository in format "owner/repo"
  --release RELEASE    Release tag or branch name (required when --repo is used)
  --dry-run           Show what would be done without making changes
  --overwrite         Overwrite original files instead of creating new ones
```

### Environment variable

Instead of using `--base-url`, you can set the `BASE_URL` environment variable:

```bash
export BASE_URL="https://example.com"
python convert_markdown_urls.py docs/
```

## Examples

### 1. Process a file

```bash
# Create new file with _converted suffix
python convert_markdown_urls.py --base-url="https://example.com" README.md

# Overwrite original file
python convert_markdown_urls.py --base-url="https://example.com" --overwrite README.md
```

### 2. Process a tree

```bash
# Convert all markdown files in docs/ directory and subdirectories
python convert_markdown_urls.py --base-url="https://example.com" docs/
```

### 3. Process a tree using a GitHub repository

```bash
# Convert URLs to point to specific release
python convert_markdown_urls.py --repo="owner/repo" --release="1.0.0" docs/

# Use branch name instead of release tag
python convert_markdown_urls.py --repo="owner/repo" --release="main" docs/
```

### 4. Preview which files would change

```bash
# Dry run to see what would be changed
python convert_markdown_urls.py --repo="owner/repo" --release="v1.0.0" --dry-run docs/
```

## URL handling

The script handles various Markdown URL formats:

1. Inline links: `[text](url)`
2. Image links: `![alt](url)`
3. Reference-style definitions: `[ref]: url`

### Nested directory handling

For nested directories, the script maintains the correct path structure:

```pre
docs/
  ├── README.md                   # Uses base_url/README.md
  ├── guide/
  │   └── setup.md               # Uses base_url/guide/setup.md
  └── api/
      └── reference/
          └── endpoints.md       # Uses base_url/api/reference/endpoints.md
```

### URL conversion rules

- Relative URLs are converted to absolute URLs
- Already absolute URLs (starting with `http://` or `https://`) are left unchanged
- Fragment links (starting with `#`) are left unchanged
- `mailto:` links are left unchanged

## Output

The script provides detailed progress information:

```pre
Processing files with base URL: https://example.com
Root directory: /path/to/docs
Mode: Create new files
------------------------------------------------------------
Converted /path/to/docs/README.md
Converted /path/to/docs/guide/setup.md
No changes needed for /path/to/docs/api/reference/endpoints.md
------------------------------------------------------------
Processed 3 files:
  Success: 3
  Errors: 0
```

## Error handling

- Invalid repository format errors
- Missing release tag errors when using `--repo`
- File access and processing errors
- Input path validation
