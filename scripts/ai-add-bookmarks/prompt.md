# AI Command: Adding Bookmarks to PDFs

## Your Task

You are going to extract the table of contents from a PDF and add hierarchical bookmarks using pdfcpu. You will also extract and add proper PDF metadata (title, authors, etc.) from the book's content. All necessary tools are already installed.

## What You Must Do

### Step 1: Analyze the PDF

Start by checking the PDF structure:
```bash
pdfcpu info input.pdf
```
Note the total page count and verify the PDF is accessible.

### Step 2: Extract Text for Analysis

Extract the first 15-20 pages individually to get both metadata and table of contents:
```bash
seq 1 15 | xargs -I {} pdftotext -layout -f {} -l {} input.pdf page_{}.txt
```
**Critical**: Always use the `-layout` flag to preserve formatting. If the TOC appears to be later in the document, extract more pages as needed using the same pattern.

### Step 3: Extract Book Metadata

Read the extracted page files to find:
- **Book Title**: Usually prominently displayed on the first few pages
- **Authors**: Look for author names, often listed after the title
- **Publication Info**: Publisher, year, edition if available
- **Subject**: The topic or field of the book

Record this information exactly as it appears in the text.

### Step 4: Locate the Table of Contents

**DO NOT** search for patterns or try to guess TOC location. Instead:
- Read through the extracted page files systematically
- Look for the actual table of contents section within the pages
- Identify the exact page file where TOC starts

### Step 5: Extract TOC Structure

**Important**: The table of contents can span multiple pages. You must:
- Start reading from the page where TOC begins
- Continue reading subsequent pages until you find content that is clearly not part of the TOC anymore
- If you need more pages beyond your initial extraction, use:
  ```bash
  seq 16 25 | xargs -I {} pdftotext -layout -f {} -l {} input.pdf page_{}.txt
  ```
  (adjust range as needed)

For the complete TOC:
- Read through all TOC pages line by line
- Identify hierarchical levels (chapters, sections, subsections)
- Extract titles and their corresponding page numbers exactly as they appear
- Note the format but don't assume patterns

### Step 6: Calculate Page Offset (Critical Step)

The TOC page numbers often don't match the actual PDF page numbers. You must calculate the exact offset:

1. Take a chapter/section from TOC (e.g., "Tema 1" on page 41)
2. Extract that page number from PDF:
   ```bash
   pdftotext -layout -f PAGE_NUM -l PAGE_NUM input.pdf check_page.txt
   ```
3. Check if content matches
4. If not, try nearby pages systematically
5. **Use bc for offset calculation** (never do mental arithmetic):
   ```bash
   echo "actual_page - toc_page" | bc
   ```

**Example**:
```bash
# If TOC shows "Tema 1" on page 41, but actual content is on page 39
echo "39 - 41" | bc
# Result: -2 (so offset is -2)
```

### Step 7: Verify Offset Consistency

Test the offset with 3-4 different chapters using bc for each calculation:
```bash
echo "actual_page1 - toc_page1" | bc
echo "actual_page2 - toc_page2" | bc
echo "actual_page3 - toc_page3" | bc
```
Ensure the offset is consistent across the document. If offsets vary, use the most common one.

### Step 8: Create Bookmark JSON Structure

Create the JSON file with the correct pdfcpu format. **Critical**: Use the extracted metadata in the header:

```json
{
    "header": {
        "source": "input.pdf",
        "version": "pdfcpu v0.5.0 dev",
        "creation": "2025-01-09 12:00:00 UTC",
        "title": "Extracted Book Title",
        "author": "Extracted Author Names",
        "creator": "OCRmyPDF",
        "producer": "pdfcpu",
        "subject": "Extracted Subject/Topic"
    },
    "bookmarks": [
        {
            "title": "Chapter 1",
            "page": 15,
            "kids": [
                {
                    "title": "1.1 Section",
                    "page": 17
                }
            ]
        }
    ]
}
```

### Step 9: Calculate Final Page Numbers

For each TOC entry, calculate the actual page using bc:
```bash
echo "toc_page + offset" | bc
```

**Example**: If TOC shows page 41 and offset is -2:
```bash
echo "41 + (-2)" | bc
# Result: 39
```

### Step 10: Build the Hierarchy

Follow these rules:
- **Level 1**: Main chapters/topics (no "kids" if no subsections)
- **Level 2**: Subsections under "kids" array
- **Level 3**: Sub-subsections under nested "kids" arrays
- **Page Numbers**: Always use calculated actual page numbers (TOC + offset)

### Step 11: Apply Bookmarks

Apply the bookmarks to the PDF:
```bash
pdfcpu bookmarks import input.pdf bookmarks.json output_with_bookmarks.pdf
```

### Step 12: Validate Results

Verify the bookmarks were added correctly:
```bash
pdfcpu bookmarks list output_with_bookmarks.pdf
```

You should see all major sections appear with proper hierarchical structure.

## Critical Requirements You Must Follow

### Text Extraction
- **ALWAYS** use `pdftotext -layout` for text extraction
- **NEVER** use `pdfcpu extract` - it produces gibberish
- If `-layout` corrupts formatting, try `pdftotext` without it

### Arithmetic Operations
- **ALWAYS** use `bc` for any arithmetic operations
- **NEVER** do mental math or assume simple calculations are correct
- This is critical for page offset calculations

### Metadata Extraction
- **Extract metadata from the actual book content**, not PDF properties
- Look for title, authors, publisher, subject in the first few pages
- Use this extracted information in the JSON header

### JSON Format
- Must use object with "header" and "bookmarks" sections
- Header section is required by pdfcpu
- Use "kids" arrays for subsections, not "children" or "level" numbers

### Page Offset Handling
- Some books have different offsets for different sections
- Calculate separate offsets for major sections using bc if needed
- Roman numerals in front matter can affect offset calculations

## Your Success Criteria

Your task is complete when:
- All major TOC sections have corresponding bookmarks
- Bookmarks navigate to correct pages (verified with bc calculations)
- Hierarchical structure displays properly with subsections nested under main sections
- PDF metadata is populated with extracted information
- Special characters in titles display correctly

## Common Issues and Solutions

### If bookmarks don't appear:
- Check JSON format validity
- Verify header section is present
- Ensure page numbers are positive integers

### If page numbers are wrong:
- Recalculate offset with bc using more samples
- Check for Roman numeral front matter
- Test with manual page verification

### If hierarchy is broken:
- Use flat structure initially, then add nesting
- Verify "kids" array syntax
- Check for missing commas or brackets

## Final Note

You must complete this task systematically. Don't skip steps, always use bc for calculations, and ensure the metadata you extract from the book content is accurate and properly formatted in the JSON header.

---

**PDF to process:**