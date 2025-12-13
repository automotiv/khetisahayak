import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/models/scheme.dart';
import 'package:kheti_sahayak_app/services/language_service.dart';

class SchemeComparisonScreen extends StatelessWidget {
  final List<Scheme> schemes;

  const SchemeComparisonScreen({Key? key, required this.schemes}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('${localizations.compare} ${localizations.governmentSchemes}'),
        backgroundColor: Colors.green[700],
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            columns: [
              const DataColumn(label: Text('Attribute', style: TextStyle(fontWeight: FontWeight.bold))), // Add to translations
              ...schemes.map((s) => DataColumn(
                label: Container(
                  width: 150,
                  child: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                ),
              )),
            ],
            rows: [
              _buildRow('Category', (s) => s.category ?? '-'), // Add to translations
              _buildRow(localizations.benefits, (s) => s.benefits ?? '-'),
              _buildRow(localizations.eligibility, (s) => s.eligibility ?? '-'),
              _buildRow('Deadline', (s) => s.deadline != null ? s.deadline.toString().split(' ')[0] : '-'), // Add to translations
              _buildRow('Farm Size', (s) => '${s.minFarmSize ?? 0} - ${s.maxFarmSize ?? 'Any'} acres'), // Add to translations
              _buildRow('Income Limit', (s) => s.maxIncome != null ? 'Rs ${s.maxIncome}' : 'None'), // Add to translations
              _buildRow('Crops', (s) => s.crops.isNotEmpty ? s.crops.join(', ') : 'All'), // Add to translations
            ],
          ),
        ),
      ),
    );
  }

  DataRow _buildRow(String attribute, String Function(Scheme) extractor) {
    return DataRow(
      cells: [
        DataCell(Text(attribute, style: const TextStyle(fontWeight: FontWeight.bold))),
        ...schemes.map((s) => DataCell(
          Container(
            width: 150,
            child: Text(extractor(s), softWrap: true),
          ),
        )),
      ],
    );
  }
}
