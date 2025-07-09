{ writeShellApplication, bc, poppler-utils, coreutils, claude-code, ... }:
writeShellApplication {
  name = "ai-add-bookmarks";
  runtimeInputs = [
    claude-code
    bc
    poppler-utils  # provides pdftotext
    coreutils      # provides seq
  ];
  text = ''
    # Check if PDF filename is provided
    if [ $# -eq 0 ]; then
        echo "Usage: ai-add-bookmarks <pdf-file>"
        echo "Example: ai-add-bookmarks book.pdf"
        exit 1
    fi
    
    PDF_FILE="$1"
    
    # Check if file exists
    if [ ! -f "$PDF_FILE" ]; then
        echo "Error: File '$PDF_FILE' not found."
        exit 1
    fi
    
    # Read the prompt template
    PROMPT_FILE="${./prompt.md}"
    tempfile=$(mktemp ./prompt.XXXXXX)
    cat "$PROMPT_FILE" <(echo "$PDF_FILE") > "$tempfile"
    
    # Create .claude directory if it doesn't exist
    mkdir -p .claude
    
    # Write settings.local.json with permissions
    cat > .claude/settings.local.json << 'EOF'
{
  "permissions": {
    "allow": [
      "Bash(pdfcpu:*)",
      "Bash(pdftotext:*)",
      "Bash(seq:*)",
      "Bash(xargs:*)",
      "Bash(bc:*)",
      "Bash(cat:*)",
      "Bash(echo:*)",
      "Read",
      "Write",
      "Edit",
      "MultiEdit",
      "Glob",
      "Grep",
      "LS",
      "TodoWrite"
    ],
    "deny": []
  }
}
EOF
    
    # Call Claude with the full prompt
    claude "Please, do what it says in $tempfile"
  '';
}
