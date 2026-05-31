import os
import re
import sys
from fpdf import FPDF

class AcademicPDF(FPDF):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.set_margins(20, 20, 20)
        self.set_auto_page_break(auto=True, margin=20)
        
    def header(self):
        if self.page_no() > 1:
            self.set_font("SegoeUI", "I", 9)
            self.set_text_color(120, 120, 120)
            self.cell(0, 8, "Ακαδημαϊκή Αναφορά Συστήματος UniSnap — Χαράλαμπος Τσακηρίδης (ΑΜ: 3180190)", align="R")
            self.ln(6)
            self.set_draw_color(220, 220, 220)
            self.set_line_width(0.3)
            self.line(20, self.get_y(), 190, self.get_y())
            self.ln(4)

    def footer(self):
        self.set_y(-15)
        self.set_font("SegoeUI", "I", 9)
        self.set_text_color(120, 120, 120)
        self.cell(0, 10, f"Σελίδα {self.page_no()} / {{nb}}", align="C")

def draw_cover_header(pdf):
    # Top decorative colored banner
    pdf.set_fill_color(12, 28, 54) # Deep Navy
    pdf.rect(0, 0, 210, 55, style="F")
    
    # Title inside banner
    pdf.set_font("SegoeUI", "B", 20)
    pdf.set_text_color(255, 255, 255)
    pdf.set_y(10)
    pdf.cell(0, 10, "Ακαδημαϊκή Αναφορά Συστήματος UniSnap", align="C")
    
    # Subtitle / Course
    pdf.set_font("SegoeUI", "B", 12)
    pdf.set_text_color(0, 168, 204) # Cyan accent
    pdf.set_y(22)
    pdf.cell(0, 8, "Μάθημα: Αλληλεπίδραση Ανθρώπου - Υπολογιστή", align="C")
    
    # Student details
    pdf.set_font("SegoeUI", "I", 11)
    pdf.set_text_color(230, 230, 230)
    pdf.set_y(30)
    pdf.cell(0, 8, "Φοιτητής: Χαράλαμπος Τσακηρίδης (ΑΜ: 3180190)", align="C")
    
    # Decorative Divider Line
    pdf.set_draw_color(247, 127, 0) # Amber line
    pdf.set_line_width(1.5)
    pdf.line(0, 55, 210, 55)
    
    # Return cursor to regular page area
    pdf.set_y(65)

def draw_lucid_stages(pdf, y_start):
    stages = [
        "Στάδιο 1: Λήψη & UI Layout (Capture & UI)",
        "Στάδιο 2: Ανάλυση & OCR (ML Kit Text Recognition)",
        "Στάδιο 3: Εξαγωγή Προθεσμιών (Deadline Date Extraction)",
        "Στάδιο 4: Τοπικές Ειδοποιήσεις (Local Notification Scheduling)",
        "Στάδιο 5: Οργάνωση & Σημειώσεις (Categorization & Notepad)",
        "Στάδιο 6: Ρυθμίσεις & Πολυμορφικότητα (Theme & Settings)"
    ]
    
    current_y = y_start
    box_w = 140
    box_h = 10
    x = 35
    
    for i, stage in enumerate(stages):
        # Draw soft background
        pdf.set_fill_color(245, 248, 252) # Premium soft light blue
        pdf.set_draw_color(0, 168, 204)   # Cyan border
        pdf.set_line_width(0.3)
        
        pdf.rect(x, current_y, box_w, box_h, style="FD", round_corners=True, corner_radius=1.5)
        
        # Print text inside centered
        pdf.set_font("SegoeUI", "B", 9.5)
        pdf.set_text_color(12, 28, 54) # Navy
        pdf.set_y(current_y + 2)
        pdf.set_x(x)
        pdf.cell(box_w, 6, stage, align="C")
        
        # Draw connector arrow to next box
        if i < len(stages) - 1:
            arrow_y = current_y + box_h
            pdf.set_draw_color(0, 168, 204)
            pdf.set_line_width(0.5)
            pdf.line(x + box_w/2, arrow_y, x + box_w/2, arrow_y + 5)
            # Arrow head
            pdf.line(x + box_w/2 - 2, arrow_y + 3, x + box_w/2, arrow_y + 5)
            pdf.line(x + box_w/2 + 2, arrow_y + 3, x + box_w/2, arrow_y + 5)
            current_y += box_h + 5
        else:
            current_y += box_h
            
    return current_y

def draw_moire_diagram(pdf, y_start):
    pdf.set_line_width(0.3)
    
    # 1. Screen Grid Box
    pdf.set_fill_color(240, 248, 255) # Light blue
    pdf.set_draw_color(12, 28, 54) # Deep Navy
    pdf.rect(20, y_start, 70, 14, style="FD", round_corners=True, corner_radius=2)
    pdf.set_font("SegoeUI", "B", 9)
    pdf.set_text_color(12, 28, 54)
    pdf.text(23, y_start + 5, "Ψηφιακή Οθόνη (Display Pixel Grid)")
    pdf.set_font("SegoeUI", "", 8)
    pdf.text(23, y_start + 10, "Υψηλή Χωρική Συχνότητα (f_screen)")
    
    # 2. Sensor Grid Box
    pdf.set_fill_color(255, 248, 240) # Light Orange/Amber
    pdf.set_draw_color(247, 127, 0) # Amber
    pdf.rect(120, y_start, 70, 14, style="FD", round_corners=True, corner_radius=2)
    pdf.set_font("SegoeUI", "B", 9)
    pdf.set_text_color(247, 127, 0)
    pdf.text(123, y_start + 5, "Αισθητήρας Κάμερας (CMOS)")
    pdf.set_font("SegoeUI", "", 8)
    pdf.text(123, y_start + 10, "Δειγματοληψία Bayer (f_sensor)")
    
    # 3. Connectors to Center
    pdf.set_draw_color(12, 28, 54)
    pdf.line(55, y_start + 14, 85, y_start + 24)
    pdf.set_draw_color(247, 127, 0)
    pdf.line(155, y_start + 14, 125, y_start + 24)
    
    # 4. Central Interaction Box
    pdf.set_fill_color(245, 245, 245) # Light grey
    pdf.set_draw_color(100, 100, 100)
    pdf.rect(75, y_start + 24, 60, 12, style="FD", round_corners=True, corner_radius=1.5)
    pdf.set_font("SegoeUI", "B", 9)
    pdf.set_text_color(50, 50, 50)
    pdf.set_y(y_start + 25)
    pdf.set_x(75)
    pdf.cell(60, 10, "Αλληλεπίδραση & Παρεμβολή", align="C")
    
    # Connector down
    pdf.set_draw_color(100, 100, 100)
    pdf.line(105, y_start + 36, 105, y_start + 41)
    
    # 5. Condition Box
    pdf.set_fill_color(255, 255, 224) # Pale Yellow
    pdf.set_draw_color(180, 180, 0)
    pdf.rect(80, y_start + 41, 50, 10, style="FD", round_corners=True, corner_radius=1.5)
    pdf.set_font("SegoeUI", "B", 9)
    pdf.set_text_color(120, 120, 0)
    pdf.set_y(y_start + 41.5)
    pdf.set_x(80)
    pdf.cell(50, 10, "f_screen ≈ f_sensor?", align="C")
    
    # Connector Left (Yes)
    pdf.set_draw_color(180, 180, 0)
    pdf.line(80, y_start + 46, 50, y_start + 46)
    pdf.line(50, y_start + 46, 50, y_start + 55)
    # Arrow head
    pdf.line(48, y_start + 53, 50, y_start + 55)
    pdf.line(52, y_start + 53, 50, y_start + 55)
    pdf.set_font("SegoeUI", "B", 8)
    pdf.set_text_color(200, 0, 0)
    pdf.text(58, y_start + 45, "Ναι (Collision)")
    
    # Connector Right (No)
    pdf.set_draw_color(180, 180, 0)
    pdf.line(130, y_start + 46, 160, y_start + 46)
    pdf.line(160, y_start + 46, 160, y_start + 55)
    # Arrow head
    pdf.line(158, y_start + 53, 160, y_start + 55)
    pdf.line(162, y_start + 53, 160, y_start + 55)
    pdf.set_font("SegoeUI", "B", 8)
    pdf.set_text_color(0, 128, 0)
    pdf.text(136, y_start + 45, "Όχι")
    
    # 6. Branch YES: Aliasing Box
    pdf.set_fill_color(255, 230, 230) # Pale Red
    pdf.set_draw_color(200, 0, 0)
    pdf.rect(20, y_start + 55, 70, 24, style="FD", round_corners=True, corner_radius=2)
    pdf.set_font("SegoeUI", "B", 8.5)
    pdf.set_text_color(150, 0, 0)
    pdf.text(23, y_start + 59, "Παραβίαση Nyquist & Aliasing")
    pdf.set_font("SegoeUI", "", 7.5)
    pdf.set_text_color(50, 50, 50)
    pdf.text(23, y_start + 64, "• Low-Frequency Spatial Beats")
    pdf.text(23, y_start + 68, "• Κυματοειδείς γραμμές (Moire)")
    pdf.text(23, y_start + 72, "• Παραμόρφωση ακμών γραμμάτων")
    pdf.text(23, y_start + 76, "-> Αποτυχία On-Device Latin OCR")
    
    # 7. Branch NO: Clean Box
    pdf.set_fill_color(230, 245, 230) # Pale Green
    pdf.set_draw_color(0, 150, 0)
    pdf.rect(120, y_start + 55, 70, 24, style="FD", round_corners=True, corner_radius=2)
    pdf.set_font("SegoeUI", "B", 8.5)
    pdf.set_text_color(0, 100, 0)
    pdf.text(123, y_start + 60, "Καθαρή Ψηφιακή Αναπαράσταση")
    pdf.set_font("SegoeUI", "", 7.5)
    pdf.set_text_color(50, 50, 50)
    pdf.text(123, y_start + 65, "• Απουσία παρεμβολών (Scanlines)")
    pdf.text(123, y_start + 69, "• Καθαρές ακμές χαρακτήρων")
    pdf.text(123, y_start + 73, "-> Επιτυχής Αναγνώριση OCR")

    return y_start + 81

def write_rich_text(pdf, text, font_size=10.5, line_height=5.5):
    parts = re.split(r'(\*\*.*?\*\*|`.*?`)', text)
    
    for part in parts:
        if not part:
            continue
        if part.startswith('**') and part.endswith('**'):
            pdf.set_font("SegoeUI", "B", font_size)
            pdf.set_text_color(12, 28, 54) # Deep Navy for bold emphasis
            pdf.write(line_height, part[2:-2])
        elif part.startswith('`') and part.endswith('`'):
            pdf.set_font("Consolas", "", font_size - 1)
            pdf.set_text_color(0, 130, 160) # Dark Cyan for code
            pdf.write(line_height, part[1:-1])
        else:
            pdf.set_font("SegoeUI", "", font_size)
            pdf.set_text_color(40, 40, 40) # Muted Charcoal body text
            pdf.write(line_height, part)

def build_pdf():
    pdf = AcademicPDF()
    
    # Register Segoe UI fonts
    pdf.add_font("SegoeUI", "", r"C:\Windows\Fonts\segoeui.ttf")
    pdf.add_font("SegoeUI", "B", r"C:\Windows\Fonts\segoeuib.ttf")
    pdf.add_font("SegoeUI", "I", r"C:\Windows\Fonts\segoeuii.ttf")
    pdf.add_font("Consolas", "", r"C:\Windows\Fonts\consola.ttf")
    
    pdf.add_page()
    draw_cover_header(pdf)
    
    report_path = r"c:\Users\Harry\Documents\UniSnap\Beta\UniSnap\final_report.md"
    with open(report_path, "r", encoding="utf-8") as f:
        content = f.read()
        
    lines = content.split("\n")
    
    # Skip the cover part in original text (lines 1 to 5)
    start_index = 0
    for idx, line in enumerate(lines):
        if line.startswith("## 1. Εισαγωγή"):
            start_index = idx
            break
            
    parsed_lines = lines[start_index:]
    
    in_mermaid = False
    paragraph_buffer = []
    
    def flush_paragraph():
        nonlocal paragraph_buffer
        if not paragraph_buffer:
            return
            
        para_text = " ".join(paragraph_buffer).strip()
        paragraph_buffer = []
        
        # Check space left before writing paragraph
        if pdf.get_y() > 250:
            pdf.add_page()
            
        # Check if this is a "Σημαντική Ανακάλυψη Απόδοσης" alert box
        if para_text.startswith("**Σημαντική Ανακάλυψη Απόδοσης:**"):
            pdf.ln(3)
            x_pos = pdf.get_x()
            y_pos = pdf.get_y()
            pdf.set_fill_color(255, 248, 240) # Pale Orange
            pdf.set_draw_color(247, 127, 0) # Amber
            pdf.set_line_width(0.5)
            
            # Draw sleek left vertical bar
            pdf.rect(x_pos, y_pos, 1, 28, style="F")
            pdf.set_x(x_pos + 4)
            pdf.set_font("SegoeUI", "B", 10.5)
            pdf.set_text_color(247, 127, 0)
            pdf.cell(0, 5, "ΣΗΜΑΝΤΙΚΗ ΑΝΑΚΑΛΥΨΗ ΑΠΟΔΟΣΗΣ")
            pdf.ln(6)
            pdf.set_x(x_pos + 4)
            
            # Print body of warning
            body_text = para_text.replace("**Σημαντική Ανακάλυψη Απόδοσης:**", "").strip()
            pdf.set_font("SegoeUI", "", 10)
            pdf.set_text_color(50, 50, 50)
            pdf.multi_cell(0, 5.5, body_text)
            pdf.ln(5)
            return

        write_rich_text(pdf, para_text)
        pdf.ln(8) # Space between paragraphs

    i = 0
    while i < len(parsed_lines):
        line = parsed_lines[i]
        
        # Handle Mermaid blocks
        if line.strip().startswith("```mermaid"):
            in_mermaid = True
            mermaid_content = []
            i += 1
            while i < len(parsed_lines) and not parsed_lines[i].strip().startswith("```"):
                mermaid_content.append(parsed_lines[i])
                i += 1
            
            merged_content = "\n".join(mermaid_content)
            if "Stage1" in merged_content:
                if pdf.get_y() > 180:
                    pdf.add_page()
                pdf.ln(5)
                new_y = draw_lucid_stages(pdf, pdf.get_y())
                pdf.set_y(new_y)
                pdf.ln(8)
            elif "ScreenGrid" in merged_content or "ΦΑΙΝΟΜΕΝΟ" in merged_content or "Bayer" in merged_content:
                if pdf.get_y() > 180:
                    pdf.add_page()
                pdf.ln(5)
                new_y = draw_moire_diagram(pdf, pdf.get_y())
                pdf.set_y(new_y)
                pdf.ln(8)
            
            in_mermaid = False
            i += 1
            continue

        # Handle Code block
        if line.strip().startswith("```"):
            i += 1
            while i < len(parsed_lines) and not parsed_lines[i].strip().startswith("```"):
                i += 1
            i += 1
            continue

        # Handle headings
        if line.startswith("## ") or line.startswith("### "):
            flush_paragraph()
            
            # Heading Level 2
            if line.startswith("## "):
                heading_text = line[3:].strip()
                if pdf.get_y() > 230:
                    pdf.add_page()
                else:
                    pdf.ln(4)
                
                # Draw elegant left accent border for Level 2 heading
                x_pos = pdf.get_x()
                y_pos = pdf.get_y()
                pdf.set_fill_color(12, 28, 54) # Deep Navy
                pdf.rect(x_pos, y_pos, 3, 7, style="F")
                
                pdf.set_x(x_pos + 6)
                pdf.set_font("SegoeUI", "B", 14)
                pdf.set_text_color(12, 28, 54) # Navy
                pdf.cell(0, 7, heading_text)
                pdf.ln(10)
                
            # Heading Level 3
            elif line.startswith("### "):
                heading_text = line[4:].strip()
                if pdf.get_y() > 240:
                    pdf.add_page()
                else:
                    pdf.ln(2)
                
                pdf.set_font("SegoeUI", "B", 11.5)
                pdf.set_text_color(0, 130, 160) # Cyan-blue
                pdf.cell(0, 6, heading_text)
                pdf.ln(8)
                
            i += 1
            continue
            
        # Handle divider line
        if line.strip() == "---":
            flush_paragraph()
            if pdf.get_y() > 240:
                pdf.add_page()
            else:
                pdf.ln(2)
                pdf.set_draw_color(220, 220, 220)
                pdf.set_line_width(0.3)
                pdf.line(20, pdf.get_y(), 190, pdf.get_y())
                pdf.ln(4)
            i += 1
            continue

        # Handle list items
        if line.strip().startswith("- ") or line.strip().startswith("* "):
            flush_paragraph()
            if pdf.get_y() > 250:
                pdf.add_page()
                
            list_text = line.strip()[2:].strip()
            indent = 25 if line.startswith("  ") or line.startswith("\t") else 20
            
            pdf.set_x(indent)
            pdf.set_font("SegoeUI", "B", 10.5)
            pdf.set_text_color(0, 168, 204) # Cyan bullet
            pdf.write(5.5, "  •   ")
            
            write_rich_text(pdf, list_text)
            pdf.ln(6.5)
            i += 1
            continue

        # Handle numbered lists
        match_num = re.match(r'^(\d+)\.\s+(.*)$', line.strip())
        if match_num:
            flush_paragraph()
            if pdf.get_y() > 250:
                pdf.add_page()
                
            num = match_num.group(1)
            num_text = match_num.group(2)
            
            pdf.set_x(20)
            pdf.set_font("SegoeUI", "B", 10.5)
            pdf.set_text_color(247, 127, 0) # Amber list numbers
            pdf.write(5.5, f"  {num}.  ")
            
            write_rich_text(pdf, num_text)
            pdf.ln(6.5)
            i += 1
            continue

        # Handle normal paragraphs
        if line.strip() == "":
            flush_paragraph()
        else:
            paragraph_buffer.append(line.strip())
            
        i += 1

    flush_paragraph()

    # Save PDF
    output_pdf_path = r"c:\Users\Harry\Documents\UniSnap\Beta\UniSnap\final_report.pdf"
    pdf.output(output_pdf_path)
    print(f"PDF generated successfully at: {output_pdf_path}")

if __name__ == "__main__":
    build_pdf()
