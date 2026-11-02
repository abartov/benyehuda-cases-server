# Builds a minimal valid PDF of +pages+ blank pages (each +width+ x +height+ points), without any
# external tool, so specs can exercise PDF handling.
module PdfHelpers
  def blank_pdf(pages: 1, width: 72, height: 144)
    page_ids = (0...pages).map { |i| 3 + i }
    objects = [
      '<< /Type /Catalog /Pages 2 0 R >>',
      "<< /Type /Pages /Kids [#{page_ids.map { |id| "#{id} 0 R" }.join(' ')}] /Count #{pages} >>"
    ]
    pages.times { objects << "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 #{width} #{height}] >>" }

    pdf = +"%PDF-1.4\n"
    offsets = objects.each_with_index.map do |body, i|
      offset = pdf.bytesize
      pdf << "#{i + 1} 0 obj\n#{body}\nendobj\n"
      offset
    end
    xref = pdf.bytesize
    pdf << "xref\n0 #{objects.size + 1}\n0000000000 65535 f \n"
    offsets.each { |o| pdf << format("%010d 00000 n \n", o) }
    pdf << "trailer\n<< /Size #{objects.size + 1} /Root 1 0 R >>\nstartxref\n#{xref}\n%%EOF\n"
  end
end

RSpec.configure { |c| c.include PdfHelpers }
