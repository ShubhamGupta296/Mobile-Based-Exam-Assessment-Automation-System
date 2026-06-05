import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/student_model.dart';
import '../services/analytics_service.dart';
import '../services/firestore_service.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  final _analytics = AnalyticsService();
  final _firestore = FirestoreService();

  bool _loading = true;
  String? _error;
  AdminAnalytics? _data;
  List<StudentModel> _students = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _analytics.getAdminAnalytics();
      final students = await _firestore.getAllStudents();
      setState(() {
        _data = data;
        _students = students;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }
    final data = _data!;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _statRow('Overall Average', data.overallAverage.toStringAsFixed(1)),
          _statRow(
            'Pass %',
            '${data.overallPassPercentage.toStringAsFixed(1)}%',
          ),
          const SizedBox(height: 16),
          Text('GPA Trend', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SizedBox(height: 200, child: _lineChart(data.gpaTrend)),
          const SizedBox(height: 16),
          Text('CGPA Trend', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SizedBox(height: 200, child: _lineChart(data.cgpaTrend)),
          const SizedBox(height: 16),
          Text(
            'Attendance Trend',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SizedBox(height: 200, child: _barChart(data.attendanceTrend)),
          const SizedBox(height: 16),
          Text(
            'Subject Performance',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 220,
            child: _barChart(
              data.subjectPerformance
                  .map(
                    (s) => TrendPoint(
                      label: s.subjectId,
                      value: s.averageMarks,
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Semester Comparison',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: _barChart(
              data.semesterPerformance.entries
                  .map((e) => TrendPoint(label: 'Sem ${e.key}', value: e.value))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Year Comparison',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: _barChart(
              data.yearPerformance.entries
                  .map((e) => TrendPoint(label: 'Year ${e.key}', value: e.value))
                  .toList(),
            ),
          ),
          const SizedBox(height: 24),
          Text('Reports', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_students.isEmpty)
            const Text('No students available for reports.')
          else
            ..._students.map(_studentReportTile),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _lineChart(List<TrendPoint> points) {
    if (points.isEmpty) {
      return const Center(child: Text('No data'));
    }
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= points.length) return const SizedBox();
                return Text(
                  points[i].label,
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 32),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < points.length; i++)
                FlSpot(i.toDouble(), points[i].value),
            ],
            isCurved: true,
            color: Colors.indigo,
            barWidth: 3,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }

  Widget _barChart(List<TrendPoint> points) {
    if (points.isEmpty) {
      return const Center(child: Text('No data'));
    }
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= points.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    points[i].label,
                    style: const TextStyle(fontSize: 9),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 32),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: [
          for (var i = 0; i < points.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: points[i].value,
                  color: Colors.teal,
                  width: 14,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _studentReportTile(StudentModel student) {
    return Card(
      child: ListTile(
        title: Text(student.name),
        subtitle: Text('Roll: ${student.rollNo}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Report Card',
              icon: const Icon(Icons.description),
              onPressed: () => _showReport(student.id, isTranscript: false),
            ),
            IconButton(
              tooltip: 'Transcript',
              icon: const Icon(Icons.school),
              onPressed: () => _showReport(student.id, isTranscript: true),
            ),
            IconButton(
              tooltip: 'Download PDF',
              icon: const Icon(Icons.download),
              onPressed: () => _downloadPdf(student.id),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showReport(String studentId, {required bool isTranscript}) async {
    try {
      final report = await _analytics.generateReportCard(studentId);
      final text = isTranscript
          ? _analytics.generateTranscriptText(report)
          : _analytics.generateReportCardText(report);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(isTranscript ? 'Transcript' : 'Report Card'),
          content: SingleChildScrollView(child: Text(text)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _downloadPdf(String studentId) async {
    try {
      final report = await _analytics.generateReportCard(studentId);
      final text = _analytics.generateReportCardText(report);

      final doc = pw.Document();
      doc.addPage(
        pw.Page(
          build: (ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Report Card', style: pw.TextStyle(fontSize: 20)),
              pw.SizedBox(height: 12),
              pw.Text(text),
            ],
          ),
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => doc.save(),
        name: 'report_${report.student.rollNo}.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF error: $e')),
      );
    }
  }
}
