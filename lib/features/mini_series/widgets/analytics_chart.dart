// lib/features/mini_series/widgets/analytics_chart.dart
import 'package:flutter/material.dart';

class AnalyticsChart extends StatelessWidget {
  final String title;
  final Map<String, int> data;
  final Color color;

  const AnalyticsChart({
    super.key,
    required this.title,
    required this.data,
    this.color = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxValue = data.values.isEmpty ? 1 : data.values.reduce((a, b) => a > b ? a : b);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: data.isEmpty
                  ? const Center(child: Text('No data available'))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        final entry = data.entries.elementAt(index);
                        final percentage = maxValue > 0 ? entry.value / maxValue : 0.0;
                        
                        return Container(
                          width: 60,
                          margin: const EdgeInsets.only(right: 8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                entry.value.toString(),
                                style: theme.textTheme.bodySmall,
                              ),
                              const SizedBox(height: 4),
                              Expanded(
                                child: Container(
                                  width: 40,
                                  alignment: Alignment.bottomCenter,
                                  child: Container(
                                    width: 40,
                                    height: 160 * percentage,
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                entry.key.length > 6 
                                    ? '${entry.key.substring(0, 6)}...'
                                    : entry.key,
                                style: theme.textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}