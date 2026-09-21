import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../shared/services/voice_service.dart';
import '../../shared/widgets/custom_button.dart';
import '../bloc/hazard_bloc.dart';

class ReportHazardScreen extends StatefulWidget {
  const ReportHazardScreen({super.key});

  @override
  State<ReportHazardScreen> createState() => _ReportHazardScreenState();
}

class _ReportHazardScreenState extends State<ReportHazardScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final VoiceService _voiceService = VoiceService();
  final ImagePicker _picker = ImagePicker();

  String _selectedType = 'Gas Leak';
  String _selectedSeverity = 'High';
  String _selectedZone = 'Zone-A (Shaft 3)';
  bool _isListening = false;
  final List<String> _photos = [];

  final List<String> _hazardTypes = [
    'Gas Leak',
    'Rockfall Risk',
    'Ventilation Failure',
    'Flooding',
    'Machinery Malfunction',
    'Electrical Hazard',
    'Structural Crack',
    'Other',
  ];

  final List<String> _severities = ['Low', 'Medium', 'High', 'Critical'];
  final List<String> _zones = [
    'Zone-A (Shaft 3)',
    'Zone-B (Conveyor 2)',
    'Zone-C (Drill Face)',
    'Zone-D (Haulage Road)',
  ];

  @override
  void initState() {
    super.initState();
    _voiceService.initialize();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _voiceService.stopListening();
    super.dispose();
  }

  void _toggleVoiceRecording() async {
    if (_isListening) {
      await _voiceService.stopListening();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await _voiceService.startListening(
        onResult: (text) {
          setState(() {
            _descController.text = text;
          });
        },
      );
    }
  }

  Future<void> _capturePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera, maxWidth: 1200);
      if (photo != null) {
        setState(() {
          _photos.add(photo.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera error: $e'), backgroundColor: AppTheme.safetyRed),
      );
    }
  }

  void _submitHazard() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<HazardBloc>().add(
        SubmitHazardReport(
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          hazardType: _selectedType,
          severity: _selectedSeverity,
          zone: _selectedZone,
          photos: _photos,
          voiceNotes: _isListening ? _descController.text : null,
        ),
      );
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return AppTheme.safetyRed;
      case 'high':
        return AppTheme.safetyOrange;
      case 'medium':
        return AppTheme.safetyAmber;
      case 'low':
      default:
        return AppTheme.safetyGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.cardBg,
        title: const Text('Report Safety Hazard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: BlocConsumer<HazardBloc, HazardState>(
        listener: (context, state) {
          if (state is HazardSubmittedSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.isOfflineQueued
                    ? 'Report queued locally. Will sync online.'
                    : 'Hazard report transmitted & alert triggered!'),
                backgroundColor: AppTheme.safetyGreen,
              ),
            );
            Navigator.of(context).pop();
          } else if (state is HazardError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppTheme.safetyRed),
            );
          }
        },
        builder: (context, state) {
          final isSubmitting = state is HazardSubmitting;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hazard Type Selector
                  const Text('HAZARD CATEGORY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.safetyAmber, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedType,
                        dropdownColor: AppTheme.cardBg,
                        isExpanded: true,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        items: _hazardTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (val) => setState(() => _selectedType = val!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Severity Selection Chips
                  const Text('SEVERITY LEVEL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.safetyAmber, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Row(
                    children: _severities.map((sev) {
                      final isSelected = _selectedSeverity == sev;
                      final color = _getSeverityColor(sev);
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedSeverity = sev),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? color.withOpacity(0.25) : AppTheme.cardBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? color : Colors.white12,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                sev,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? color : Colors.white60,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

                  // Mine Location Zone
                  const Text('MINE LOCATION / ZONE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.safetyAmber, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedZone,
                        dropdownColor: AppTheme.cardBg,
                        isExpanded: true,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        items: _zones.map((z) => DropdownMenuItem(value: z, child: Text(z))).toList(),
                        onChanged: (val) => setState(() => _selectedZone = val!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Title Field
                  const Text('HAZARD SUMMARY / TITLE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.safetyAmber, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'e.g. High Methane Reading near Chute 4',
                      filled: true,
                      fillColor: AppTheme.cardBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter a hazard title' : null,
                  ),
                  const SizedBox(height: 18),

                  // Description & Voice Dictation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('DESCRIPTION & DETAILS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.safetyAmber, letterSpacing: 1)),
                      TextButton.icon(
                        onPressed: _toggleVoiceRecording,
                        icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: _isListening ? AppTheme.safetyRed : AppTheme.safetyOrange, size: 18),
                        label: Text(
                          _isListening ? 'Listening...' : 'Voice Dictate',
                          style: TextStyle(color: _isListening ? AppTheme.safetyRed : AppTheme.safetyOrange, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descController,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Describe observations, sensor readings, or equipment numbers...',
                      filled: true,
                      fillColor: AppTheme.cardBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter description' : null,
                  ),
                  const SizedBox(height: 18),

                  // Photos / Evidence Capture
                  const Text('PHOTO EVIDENCE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.safetyAmber, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      InkWell(
                        onTap: _capturePhoto,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppTheme.cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.safetyOrange, style: BorderStyle.solid),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt, color: AppTheme.safetyOrange, size: 28),
                              SizedBox(height: 4),
                              Text('Add Photo', style: TextStyle(color: Colors.white70, fontSize: 10)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _photos.isEmpty
                            ? const Text('No photos attached yet.', style: TextStyle(color: Colors.white38, fontSize: 12))
                            : SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: _photos.map((p) {
                                    return Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: Colors.white12,
                                      ),
                                      child: const Icon(Icons.image, color: AppTheme.safetyOrange, size: 32),
                                    );
                                  }).toList(),
                                ),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Submit Report Button
                  CustomButton(
                    text: 'TRANSMIT HAZARD REPORT',
                    icon: Icons.send_rounded,
                    isLoading: isSubmitting,
                    onPressed: _submitHazard,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
