from mistralai import Mistral
import datauri
import os
import sys
import base64
import mimetypes

# Load environment variables
api_key = os.environ["MISTRAL_API_KEY"]
client = Mistral(api_key=api_key)

def save_image(image):
    """Save base64 image data to file"""
    parsed = datauri.parse(image.image_base64)
    with open(image.id, "wb") as file:
        file.write(parsed.data)

def create_markdown_file(ocr_response, output_filename="output.md"):
    """Create markdown file from OCR response and save images"""
    with open(output_filename, "wt") as f:
        for page in ocr_response.pages:
            f.write(page.markdown)
            for image in page.images:
                save_image(image)

def upload_pdf(filename):
    """Upload PDF to Mistral and return signed URL"""
    uploaded_pdf = client.files.upload(
        file={"file_name": os.path.basename(filename), "content": open(filename, "rb")},
        purpose="ocr"
    )
    return client.files.get_signed_url(file_id=uploaded_pdf.id).url

def load_image(image_path):
    """Load local image into base64 URL"""
    mime_type, _ = mimetypes.guess_type(image_path)
    with open(image_path, "rb") as image_file:
        base64_encoded = base64.b64encode(image_file.read()).decode('utf-8')
    return f"data:{mime_type};base64,{base64_encoded}"

def process_file(file_path):
    """Process local file based on its type"""
    mime_type, _ = mimetypes.guess_type(file_path)
    
    if mime_type == "application/pdf":
        return {
            "type": "document_url",
            "document_url": upload_pdf(file_path)
        }
    elif mime_type and mime_type.startswith("image/"):
        return {
            "type": "image_url",
            "image_url": load_image(file_path)
        }
    else:
        raise ValueError("Unsupported file type. Only PDF and images are supported.")

def main():
    try:
        # Get file path from command line argument
        file_path = sys.argv[1]

        # Process file based on type
        document = process_file(file_path)
        
        # Perform OCR
        ocr_response = client.ocr.process(
            model="mistral-ocr-latest",
            document=document,
            include_image_base64=True,
        )
        
        # Generate markdown output
        base_name = os.path.splitext(os.path.basename(file_path))[0]
        output_file = f"{base_name}.md"
        create_markdown_file(ocr_response, output_filename=output_file)
        
        print(f"Successfully processed {file_path}")
        print(f"Markdown output saved to: {output_file}")
        print(f"Extracted {len(ocr_response.pages)} pages with {sum(len(page.images) for page in ocr_response.pages)} images")
        
    except IndexError:
        print("Error: Please provide a file path as argument")
        print("Usage: mistralocr <path-to-file.pdf>")
    except Exception as e:
        print(f"Error processing file: {str(e)}")

if __name__ == "__main__":
    main()
