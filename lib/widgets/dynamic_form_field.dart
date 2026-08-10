import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/campaign_model.dart';

class DynamicFormFieldWidget extends StatefulWidget {
  final CampaignDynamicField field;
  final dynamic initialValue;
  final ValueChanged<dynamic> onChanged;

  const DynamicFormFieldWidget({
    super.key,
    required this.field,
    this.initialValue,
    required this.onChanged,
  });

  @override
  State<DynamicFormFieldWidget> createState() => _DynamicFormFieldWidgetState();
}

class _DynamicFormFieldWidgetState extends State<DynamicFormFieldWidget> {
  late dynamic _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue ?? (widget.field.type == 'checkbox' ? [] : '');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final f = widget.field;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label with Required Asterisk
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: f.label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.grey.shade900,
                  ),
                ),
                if (f.required)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Render based on field.type
          _buildInputControl(context, isDark),
        ],
      ),
    );
  }

  Widget _buildInputControl(BuildContext context, bool isDark) {
    final f = widget.field;

    switch (f.type.toLowerCase()) {
      case 'number':
        return TextFormField(
          keyboardType: TextInputType.number,
          initialValue: _currentValue?.toString(),
          onChanged: (val) {
            final numVal = num.tryParse(val);
            _currentValue = numVal ?? val;
            widget.onChanged(_currentValue);
          },
          validator: (val) {
            if (f.required && (val == null || val.trim().isEmpty)) {
              return '${f.label} is required';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: 'Enter ${f.label.toLowerCase()}',
            prefixIcon: const Icon(Icons.numbers_rounded, size: 20),
          ),
        );

      case 'dropdown':
        return DropdownButtonFormField<String>(
          value: f.options.contains(_currentValue) ? _currentValue.toString() : null,
          hint: Text('Select ${f.label.toLowerCase()}'),
          items: f.options
              .map((opt) => DropdownMenuItem<String>(
                    value: opt,
                    child: Text(opt),
                  ))
              .toList(),
          onChanged: (val) {
            setState(() {
              _currentValue = val;
            });
            widget.onChanged(val);
          },
          validator: (val) {
            if (f.required && (val == null || val.isEmpty)) {
              return 'Please select ${f.label.toLowerCase()}';
            }
            return null;
          },
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.arrow_drop_down_circle_outlined, size: 20),
          ),
        );

      case 'radio':
        return Column(
          children: f.options
              .map((opt) => RadioListTile<String>(
                    title: Text(opt, style: GoogleFonts.inter(fontSize: 14)),
                    value: opt,
                    groupValue: _currentValue?.toString(),
                    onChanged: (val) {
                      setState(() {
                        _currentValue = val;
                      });
                      widget.onChanged(val);
                    },
                    contentPadding: EdgeInsets.zero,
                  ))
              .toList(),
        );

      case 'checkbox':
        final selectedSet = Set<String>.from(_currentValue is List ? _currentValue : []);
        return Column(
          children: f.options
              .map((opt) => CheckboxListTile(
                    title: Text(opt, style: GoogleFonts.inter(fontSize: 14)),
                    value: selectedSet.contains(opt),
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          selectedSet.add(opt);
                        } else {
                          selectedSet.remove(opt);
                        }
                        _currentValue = selectedSet.toList();
                      });
                      widget.onChanged(_currentValue);
                    },
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ))
              .toList(),
        );

      case 'date':
        final formattedDate = _currentValue is DateTime
            ? DateFormat('yyyy-MM-dd').format(_currentValue as DateTime)
            : (_currentValue?.toString() ?? '');

        return InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(1920),
              lastDate: DateTime(2040),
            );
            if (picked != null) {
              final formattedStr = DateFormat('yyyy-MM-dd').format(picked);
              setState(() {
                _currentValue = formattedStr;
              });
              widget.onChanged(formattedStr);
            }
          },
          child: IgnorePointer(
            child: TextFormField(
              controller: TextEditingController(text: formattedDate),
              validator: (val) {
                if (f.required && (val == null || val.trim().isEmpty)) {
                  return 'Please select ${f.label.toLowerCase()}';
                }
                return null;
              },
              decoration: InputDecoration(
                hintText: 'Select date',
                prefixIcon: const Icon(Icons.calendar_today_rounded, size: 20),
              ),
            ),
          ),
        );

      case 'text':
      default:
        return TextFormField(
          initialValue: _currentValue?.toString(),
          onChanged: (val) {
            _currentValue = val;
            widget.onChanged(val);
          },
          validator: (val) {
            if (f.required && (val == null || val.trim().isEmpty)) {
              return '${f.label} is required';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: 'Enter ${f.label.toLowerCase()}',
            prefixIcon: const Icon(Icons.edit_note_rounded, size: 20),
          ),
        );
    }
  }
}
