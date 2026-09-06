import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/student_profile.dart';

/// PDF Generation Service for 1-Page Placement Resume
class PdfService {
  /// Generate 1-Page Standard Campus Placement CV document bytes
  static Future<Uint8List> generatePlacementCv(StudentProfile profile) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        profile.name,
                        style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        '${profile.department} | ${profile.batch}',
                        style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                      ),
                      pw.Text(
                        profile.email,
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'CGPA: ${profile.cgpa.toStringAsFixed(2)}',
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.deepOrange),
                      ),
                      pw.Text(
                        'Active Backlogs: ${profile.activeBacklogs}',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.green700),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Divider(thickness: 1, color: PdfColors.grey400),
              pw.SizedBox(height: 12),

              // Target Role Blueprint
              pw.Text('PREFERRED CAMPUS TARGET ROLE', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text(profile.careerPath, style: const pw.TextStyle(fontSize: 11)),
              pw.SizedBox(height: 14),

              // Academic Summary
              pw.Text('ACADEMIC RECORD', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.TableHelper.fromTextArray(
                headers: ['Course / Degree', 'Institution', 'Year', 'Score / Metric'],
                data: [
                  ['B.Tech CSE', 'Tech University', '2022 - 2026', 'CGPA ${profile.cgpa}'],
                  ['Class XII (CBSE/State)', 'Senior Secondary School', '2022', '86%'],
                  ['Class X (CBSE/State)', 'High School', '2020', '88%'],
                ],
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                cellStyle: const pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 14),

              // Verified NPTEL Certifications
              pw.Text('VERIFIED NPTEL & ACADEMIC CREDITS', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Bullet(text: 'NPTEL Python for Data Science (IIT Madras) - 3 Minor Credits Transferred'),
              pw.Bullet(text: 'NPTEL Cloud Computing Fundamentals - 82% Elite Badge (+20 Activity Points)'),
              pw.SizedBox(height: 14),

              // Technical Stack
              pw.Text('VERIFIED TECHNICAL STACK', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Text('Languages: Python, C++, SQL, HTML5/CSS3, JavaScript', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Databases & Tools: PostgreSQL, Git, Docker, Linux Shell', style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 14),

              // Verification Seal
              pw.Spacer(),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Digitally Endorsed by Dean of Academics & T&P Cell', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                    pw.Text('TU-VERIFIED-CV-2025', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Print or download the generated placement CV PDF
  static Future<void> downloadCv(StudentProfile profile) async {
    final pdfBytes = await generatePlacementCv(profile);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Campus_Placement_CV_${profile.name.replaceAll(' ', '_')}.pdf',
    );
  }
}
