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
extract-pdf-pages input.pdf 1 15
```
**Note**: This command extracts pages 1-15 from the PDF to individual text files (page_1.txt, page_2.txt, etc.) using pdftotext with the `-layout` flag to preserve formatting. If the TOC appears to be later in the document, extract more pages as needed using the same pattern.

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
  extract-pdf-pages input.pdf 16 25
  ```
  **Note**: This extracts pages 16-25 to individual text files. Adjust the range as needed.

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
5. **Use calc-offset for offset calculation** (never do mental arithmetic):
   ```bash
   calc-offset actual_page toc_page
   ```

**Example**:
```bash
# If TOC shows "Tema 1" on page 41, but actual content is on page 39
calc-offset 39 41
# Result: -2 (so offset is -2)
```
**Note**: This command calculates the offset between actual PDF page and TOC page numbers using bc.

### Step 7: Verify Offset Consistency (Critical for Accuracy)

**MANDATORY**: Test the offset with multiple chapters across the document, including the final chapters:

1. **First, test with 3-4 chapters from the beginning/middle**:
```bash
calc-offset actual_page1 toc_page1
calc-offset actual_page2 toc_page2
calc-offset actual_page3 toc_page3
```

2. **CRITICAL**: **Always verify with the final 2 chapters** from the last section of the TOC:
```bash
# Extract and verify the second-to-last chapter
pdftotext -layout -f EXPECTED_PAGE -l EXPECTED_PAGE input.pdf check_final_chapter2.txt
calc-offset actual_page_final2 toc_page_final2

# Extract and verify the final chapter
pdftotext -layout -f EXPECTED_PAGE -l EXPECTED_PAGE input.pdf check_final_chapter.txt
calc-offset actual_page_final toc_page_final
```

### Step 7a: Validate Chapter Locations (MANDATORY)

**CRITICAL**: For every chapter you test during offset verification, you **MUST** use the `validate-chapter-location` tool to confirm that the chapter actually begins where you think it does:

```bash
# For each chapter being verified, extract the previous page and validate
pdftotext -layout -f PREVIOUS_PAGE -l PREVIOUS_PAGE input.pdf check_previous_page.txt
validate-chapter-location "Chapter Title" check_previous_page.txt check_chapter_page.txt
```

**Usage**: `validate-chapter-location <chapter-name> <previous-page-file> <guessed-page-file>`

**Requirements**:
- The `<chapter-name>` should be the exact title from the TOC (in quotes)
- The `<previous-page-file>` should contain the page immediately before the expected chapter start
- The `<guessed-page-file>` should contain the page where you think the chapter begins
- The tool returns the filename and exits with 0 if validation succeeds
- The tool prints "**Not found**" and exits with 1 if validation fails

**Example**:
```bash
# If testing chapter "Tema 1" expected on page 39
pdftotext -layout -f 38 -l 38 input.pdf check_page_38.txt
pdftotext -layout -f 39 -l 39 input.pdf check_page_39.txt
validate-chapter-location "Tema 1" check_page_38.txt check_page_39.txt
```

**You MUST validate at least 3-4 chapters this way before proceeding with bookmark creation.**

3. **If any offset differs**:
   - Check if there are multiple offset patterns in the document
   - Roman numerals in front matter can create different offsets for different sections
   - Some books have different numbering schemes for different parts
   - **Re-evaluate and potentially create section-specific offsets**

4. **Offset Quality Assurance**:
   - All offsets from the same section/part should be identical
   - Document any offset changes between major sections
   - If offsets vary, investigate the cause and handle accordingly

**Note**: The final chapters are crucial for verification because they represent the end of the document where page numbering inconsistencies often become apparent. Never assume the offset is correct without checking the final chapters.

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

For each TOC entry, calculate the actual page using calc-final-page:
```bash
calc-final-page toc_page offset
```

**Example**: If TOC shows page 41 and offset is -2:
```bash
calc-final-page 41 -2
# Result: 39
```
**Note**: This command calculates the final PDF page number by adding the offset to the TOC page number using bc.

### Step 9a: Validate All Chapter Locations (MANDATORY)

Before building the bookmark hierarchy, you **MUST** validate the location of every major chapter using the `validate-chapter-location` tool:

```bash
validate-chapter-location "Chapter Title" previous_page_file.txt chapter_page_file.txt
```

**Note**: This command validates that a chapter actually begins where expected by checking that the previous page doesn't contain the chapter title and the guessed page does contain it. Use this for every chapter before creating bookmarks.

### Step 10: Build the Hierarchy

Follow these rules:
- **Level 1**: Main chapters/topics (no "kids" if no subsections)
- **Level 2**: Subsections under "kids" array
- **Level 3**: Sub-subsections under nested "kids" arrays
- **Page Numbers**: Always use calculated actual page numbers (use calc-final-page toc_page offset)
- **MANDATORY**: Only include chapters that have been validated with `validate-chapter-location`

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
- **ALWAYS** use `calc-offset` and `calc-final-page` for arithmetic operations
- **NEVER** do mental math or assume simple calculations are correct
- This is critical for page offset calculations

### Chapter Validation
- **ALWAYS** use `validate-chapter-location` to verify chapter locations
- **NEVER** assume a chapter starts where the TOC says without validation
- **MANDATORY**: Validate at least 3-4 chapters before creating bookmarks
- Only include validated chapters in the final bookmark structure

### Workspace Management
- **NEVER** delete temporary files or clean the workspace
- **NEVER** perform housekeeping operations like removing check files
- Leave all extracted page files and verification files in place
- Do not attempt to organize or clean up the working directory

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
- Calculate separate offsets for major sections using calc-offset if needed
- Roman numerals in front matter can affect offset calculations

## Your Success Criteria

Your task is complete when:
- All major TOC sections have corresponding bookmarks
- Bookmarks navigate to correct pages (verified with calc-offset and calc-final-page calculations)
- **CRITICAL**: Offset consistency verified across the entire document, including final chapters
- Final 2 chapters from the last section have been manually verified for correct page navigation
- **MANDATORY**: All major chapters have been validated with `validate-chapter-location`
- Only validated chapters are included in the final bookmark structure
- Hierarchical structure displays properly with subsections nested under main sections
- PDF metadata is populated with extracted information
- Special characters in titles display correctly

## Common Issues and Solutions

### If bookmarks don't appear:
- Check JSON format validity
- Verify header section is present
- Ensure page numbers are positive integers

### If page numbers are wrong:
- Recalculate offset with calc-offset using more samples
- Check for Roman numeral front matter
- Test with manual page verification

### If hierarchy is broken:
- Use flat structure initially, then add nesting
- Verify "kids" array syntax
- Check for missing commas or brackets

## Final Note

You must complete this task systematically. Don't skip steps, always use calc-offset and calc-final-page for calculations, and ensure the metadata you extract from the book content is accurate and properly formatted in the JSON header.

**CRITICAL REMINDER**: Always verify the offset with the final 2 chapters from the last section of the TOC. This is non-negotiable for ensuring bookmark accuracy. Many documents have page numbering inconsistencies that only become apparent at the end of the document.

**WORKSPACE POLICY**: Never delete files, clean the workspace, or perform housekeeping operations. Leave all temporary and verification files in place.

---

**PDF to process:**
