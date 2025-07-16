{ writeShellApplication, bc, poppler-utils, coreutils, claude-code, ripgrep, ... }:
let
  # Custom script to extract PDF pages to text files
  # Usage: extract-pdf-pages <pdf-file> <start-page> <end-page>
  extract-pdf-pages = writeShellApplication {
    name = "extract-pdf-pages";
    runtimeInputs = [ poppler-utils coreutils ];
    text = ''
      if [ $# -ne 3 ]; then
          echo "Usage: extract-pdf-pages <pdf-file> <start-page> <end-page>"
          exit 1
      fi
      
      PDF_FILE="$1"
      START_PAGE="$2"
      END_PAGE="$3"
      
      # Extract pages individually using seq and xargs
      seq "$START_PAGE" "$END_PAGE" | xargs -I {} pdftotext -layout -f {} -l {} "$PDF_FILE" page_{}.txt
    '';
  };

  # Custom script to calculate page offset
  # Usage: calc-offset <actual-page> <toc-page>
  calc-offset = writeShellApplication {
    name = "calc-offset";
    runtimeInputs = [ bc coreutils ];
    text = ''
      if [ $# -ne 2 ]; then
          echo "Usage: calc-offset <actual-page> <toc-page>"
          exit 1
      fi
      
      ACTUAL_PAGE="$1"
      TOC_PAGE="$2"
      
      # Calculate offset using bc
      echo "$ACTUAL_PAGE - $TOC_PAGE" | bc
    '';
  };

  # Custom script to calculate final page number
  # Usage: calc-final-page <toc-page> <offset>
  calc-final-page = writeShellApplication {
    name = "calc-final-page";
    runtimeInputs = [ bc coreutils ];
    text = ''
      if [ $# -ne 2 ]; then
          echo "Usage: calc-final-page <toc-page> <offset>"
          exit 1
      fi
      
      TOC_PAGE="$1"
      OFFSET="$2"
      
      # Calculate final page using bc
      echo "$TOC_PAGE + ($OFFSET)" | bc
    '';
  };

  # Custom script to validate chapter location
  # Usage: validate-chapter-location <chapter-name> <previous-page-file> <guessed-page-file>
  validate-chapter-location = writeShellApplication {
    name = "validate-chapter-location";
    runtimeInputs = [ ripgrep coreutils ];
    text = ''
      if [ $# -ne 3 ]; then
          echo "Usage: validate-chapter-location <chapter-name> <previous-page-file> <guessed-page-file>"
          exit 1
      fi
      
      CHAPTER_NAME="$1"
      PREVIOUS_PAGE_FILE="$2"
      GUESSED_PAGE_FILE="$3"
      
      # Check if both files exist
      if [ ! -f "$PREVIOUS_PAGE_FILE" ]; then
          echo "**Not found**"
          exit 1
      fi
      
      if [ ! -f "$GUESSED_PAGE_FILE" ]; then
          echo "**Not found**"
          exit 1
      fi
      
      # Check that previous page DOESN'T match the chapter name
      if rg -q "$CHAPTER_NAME" "$PREVIOUS_PAGE_FILE"; then
          echo "**Not found**"
          exit 1
      fi
      
      # Check that guessed page DOES match the chapter name
      if rg -q "$CHAPTER_NAME" "$GUESSED_PAGE_FILE"; then
          echo "$GUESSED_PAGE_FILE"
          exit 0
      else
          echo "**Not found**"
          exit 1
      fi
    '';
  };

in
writeShellApplication {
  name = "ai-add-bookmarks";
  runtimeInputs = [
    claude-code
    bc
    poppler-utils  # provides pdftotext
    coreutils      # provides seq
    ripgrep        # provides rg
    extract-pdf-pages
    calc-offset
    calc-final-page
    validate-chapter-location
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
      "Bash(ls:*)",
      "Bash(extract-pdf-pages:*)",
      "Bash(calc-offset:*)",
      "Bash(calc-final-page:*)",
      "Bash(validate-chapter-location:*)",
      "Bash(rg:*)",
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
