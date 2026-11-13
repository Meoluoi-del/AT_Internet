import re
import docx
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml import OxmlElement, parse_xml
from docx.oxml.ns import nsdecls, qn

def set_cell_background(cell, hex_color):
    tcPr = cell._tc.get_or_add_tcPr()
    shd = parse_xml(f'<w:shd {nsdecls("w")} w:fill="{hex_color}"/>')
    tcPr.append(shd)

def set_cell_margins(cell, top=100, bottom=100, left=150, right=150):
    tcPr = cell._tc.get_or_add_tcPr()
    tcMar = OxmlElement('w:tcMar')
    for m, val in [('top', top), ('bottom', bottom), ('left', left), ('right', right)]:
        node = OxmlElement(f'w:{m}')
        node.set(qn('w:w'), str(val))
        node.set(qn('w:type'), 'dxa')
        tcMar.append(node)
    tcPr.append(tcMar)

def set_table_borders(table, color="D3D3D3"):
    tblPr = table._tbl.tblPr
    borders = parse_xml(
        f'<w:tblBorders {nsdecls("w")}>\n'
        f'  <w:top w:val="single" w:sz="4" w:space="0" w:color="{color}"/>\n'
        f'  <w:bottom w:val="single" w:sz="6" w:space="0" w:color="1B365D"/>\n'
        f'  <w:left w:val="none"/>\n'
        f'  <w:right w:val="none"/>\n'
        f'  <w:insideH w:val="single" w:sz="4" w:space="0" w:color="{color}"/>\n'
        f'  <w:insideV w:val="none"/>\n'
        f'</w:tblBorders>'
    )
    tblPr.append(borders)

def add_styled_paragraph(doc, text, style='Normal', space_before=0, space_after=6, line_spacing=1.15, bullet=False):
    if bullet:
        p = doc.add_paragraph(style='List Bullet')
    else:
        p = doc.add_paragraph()
    
    p.paragraph_format.space_before = Pt(space_before)
    p.paragraph_format.space_after = Pt(space_after)
    p.paragraph_format.line_spacing = line_spacing

    # Pre-clean LaTeX math arrows
    text = text.replace('$\\to$', '→').replace('\\to', '→')
    text = text.replace('$\\leftrightarrow$', '↔').replace('\\leftrightarrow', '↔')

    # Regex parse inline formatting: `code`, **bold**, *italic*
    pattern = re.compile(r'(`[^`]+`|\*\*[^*]+\*\*|\*[^*]+\*)')
    tokens = pattern.split(text)

    for token in tokens:
        if not token:
            continue
        if token.startswith('`') and token.endswith('`'):
            run = p.add_run(token[1:-1])
            run.font.name = 'Consolas'
            run.font.size = Pt(10)
            run.font.color.rgb = RGBColor(180, 40, 40)
        elif token.startswith('**') and token.endswith('**'):
            run = p.add_run(token[2:-2])
            run.bold = True
            run.font.name = 'Calibri'
        elif token.startswith('*') and token.endswith('*'):
            run = p.add_run(token[1:-1])
            run.italic = True
            run.font.name = 'Calibri'
        else:
            run = p.add_run(token)
            run.font.name = 'Calibri'
            
    return p

def convert_markdown_to_docx(md_path, docx_path):
    with open(md_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    doc = docx.Document()
    
    # Page setup - 1 inch margins
    sections = doc.sections
    for section in sections:
        section.top_margin = Inches(1)
        section.bottom_margin = Inches(1)
        section.left_margin = Inches(1)
        section.right_margin = Inches(1)

    i = 0
    in_table = False
    table_lines = []

    def flush_table(tbl_lines):
        if not tbl_lines:
            return
        rows_data = []
        for line in tbl_lines:
            parts = [c.strip() for c in line.strip().split('|')[1:-1]]
            if all(set(c) <= set('-: ') for c in parts):
                continue
            rows_data.append(parts)

        if not rows_data:
            return

        cols_count = max(len(r) for r in rows_data)
        table = doc.add_table(rows=len(rows_data), cols=cols_count)
        table.alignment = WD_TABLE_ALIGNMENT.CENTER
        set_table_borders(table)

        col_widths = [Inches(1.8), Inches(1.8), Inches(3.2)] if cols_count == 3 else [Inches(6.5 / cols_count)] * cols_count

        for row_idx, r_data in enumerate(rows_data):
            row = table.rows[row_idx]
            is_header = (row_idx == 0)
            for col_idx, text in enumerate(r_data):
                if col_idx < len(row.cells):
                    cell = row.cells[col_idx]
                    cell.width = col_widths[col_idx] if col_idx < len(col_widths) else Inches(2.0)
                    set_cell_margins(cell, top=120, bottom=120, left=150, right=150)
                    p = cell.paragraphs[0]
                    p.paragraph_format.space_before = Pt(0)
                    p.paragraph_format.space_after = Pt(0)
                    p.paragraph_format.line_spacing = 1.15
                    
                    text = text.replace('$\\to$', '→').replace('\\to', '→')
                    pattern = re.compile(r'(`[^`]+`|\*\*[^*]+\*\*|\*[^*]+\*)')
                    tokens = pattern.split(text)
                    for token in tokens:
                        if not token:
                            continue
                        if token.startswith('`') and token.endswith('`'):
                            run = p.add_run(token[1:-1])
                            run.font.name = 'Consolas'
                            run.font.size = Pt(9.5)
                            if is_header:
                                run.font.color.rgb = RGBColor(255, 255, 255)
                            else:
                                run.font.color.rgb = RGBColor(180, 40, 40)
                        elif token.startswith('**') and token.endswith('**'):
                            run = p.add_run(token[2:-2])
                            run.bold = True
                            run.font.name = 'Calibri'
                            run.font.size = Pt(10 if not is_header else 10.5)
                            if is_header:
                                run.font.color.rgb = RGBColor(255, 255, 255)
                        elif token.startswith('*') and token.endswith('*'):
                            run = p.add_run(token[1:-1])
                            run.italic = True
                            run.font.name = 'Calibri'
                            run.font.size = Pt(10 if not is_header else 10.5)
                            if is_header:
                                run.font.color.rgb = RGBColor(255, 255, 255)
                        else:
                            run = p.add_run(token)
                            run.font.name = 'Calibri'
                            run.font.size = Pt(10 if not is_header else 10.5)
                            if is_header:
                                run.bold = True
                                run.font.color.rgb = RGBColor(255, 255, 255)

                    if is_header:
                        set_cell_background(cell, "1B365D")
                    else:
                        if row_idx % 2 == 1:
                            set_cell_background(cell, "F8FAFC")
                        else:
                            set_cell_background(cell, "FFFFFF")

        # add a small space after table
        sp_p = doc.add_paragraph()
        sp_p.paragraph_format.space_before = Pt(4)
        sp_p.paragraph_format.space_after = Pt(8)

    while i < len(lines):
        line = lines[i].rstrip('\r\n')
        stripped = line.strip()

        # Handle tables
        if stripped.startswith('|') and stripped.endswith('|'):
            table_lines.append(stripped)
            i += 1
            continue
        elif table_lines:
            flush_table(table_lines)
            table_lines = []

        if not stripped:
            i += 1
            continue

        # Document Title (H1)
        if stripped.startswith('# '):
            p = doc.add_paragraph()
            p.paragraph_format.space_before = Pt(14)
            p.paragraph_format.space_after = Pt(8)
            run = p.add_run(stripped[2:])
            run.font.name = 'Calibri'
            run.font.size = Pt(20)
            run.bold = True
            run.font.color.rgb = RGBColor(27, 54, 93) # Navy
            i += 1
            continue

        # Blockquote (Project Info box)
        if stripped.startswith('> '):
            p = doc.add_paragraph()
            p.paragraph_format.left_indent = Inches(0.4)
            p.paragraph_format.space_before = Pt(2)
            p.paragraph_format.space_after = Pt(2)
            # Add subtle gray text
            text = stripped[2:]
            text = text.replace('$\\to$', '→')
            pattern = re.compile(r'(\*\*[^*]+\*\*|\*[^*]+\*)')
            tokens = pattern.split(text)
            for token in tokens:
                if token.startswith('**') and token.endswith('**'):
                    run = p.add_run(token[2:-2])
                    run.bold = True
                    run.font.name = 'Calibri'
                    run.font.size = Pt(10.5)
                    run.font.color.rgb = RGBColor(70, 80, 95)
                elif token.startswith('*') and token.endswith('*'):
                    run = p.add_run(token[1:-1])
                    run.italic = True
                    run.font.name = 'Calibri'
                    run.font.size = Pt(10.5)
                    run.font.color.rgb = RGBColor(70, 80, 95)
                else:
                    run = p.add_run(token)
                    run.font.name = 'Calibri'
                    run.font.size = Pt(10.5)
                    run.font.color.rgb = RGBColor(70, 80, 95)
            i += 1
            continue

        # Horizontal Divider
        if stripped == '---':
            i += 1
            continue

        # Heading 2 (##)
        if stripped.startswith('## '):
            p = doc.add_paragraph()
            p.paragraph_format.space_before = Pt(16)
            p.paragraph_format.space_after = Pt(6)
            p.paragraph_format.keep_with_next = True
            run = p.add_run(stripped[3:])
            run.font.name = 'Calibri'
            run.font.size = Pt(15)
            run.bold = True
            run.font.color.rgb = RGBColor(27, 54, 93) # Deep Blue
            i += 1
            continue

        # Heading 3 (###)
        if stripped.startswith('### '):
            p = doc.add_paragraph()
            p.paragraph_format.space_before = Pt(13)
            p.paragraph_format.space_after = Pt(4)
            p.paragraph_format.keep_with_next = True
            run = p.add_run(stripped[4:])
            run.font.name = 'Calibri'
            run.font.size = Pt(12.5)
            run.bold = True
            run.font.color.rgb = RGBColor(0, 102, 153) # Teal Blue
            i += 1
            continue

        # Heading 4 (####)
        if stripped.startswith('#### '):
            p = doc.add_paragraph()
            p.paragraph_format.space_before = Pt(10)
            p.paragraph_format.space_after = Pt(3)
            p.paragraph_format.keep_with_next = True
            run = p.add_run(stripped[5:])
            run.font.name = 'Calibri'
            run.font.size = Pt(11.5)
            run.bold = True
            run.font.color.rgb = RGBColor(40, 70, 110)
            i += 1
            continue

        # Numbered List items (1. 2. 3. etc.)
        num_match = re.match(r'^(\d+)\.\s+(.*)$', stripped)
        if num_match:
            num = num_match.group(1)
            content = num_match.group(2)
            p = add_styled_paragraph(doc, f"{num}.  {content}", space_before=1, space_after=3)
            p.paragraph_format.left_indent = Inches(0.3)
            i += 1
            continue

        # Bullet List items (- ...)
        if stripped.startswith('- '):
            content = stripped[2:]
            p = add_styled_paragraph(doc, content, bullet=True, space_before=1, space_after=3)
            i += 1
            continue

        # Regular Paragraph
        add_styled_paragraph(doc, stripped, space_before=0, space_after=5)
        i += 1

    if table_lines:
        flush_table(table_lines)

    doc.save(docx_path)
    print(f"Successfully converted to {docx_path}")

if __name__ == "__main__":
    convert_markdown_to_docx(
        r"D:\AT_Internet\docs\day1_scope_and_user_stories.md",
        r"D:\AT_Internet\docs\day1_scope_and_user_stories.docx"
    )
