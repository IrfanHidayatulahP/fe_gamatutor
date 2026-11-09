import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/group_call/group_call_bloc.dart';
import '../../bloc/group_call/group_call_event.dart';
import '../../bloc/group_call/group_call_state.dart';

class CreateGroupCallScreen extends StatefulWidget {
  const CreateGroupCallScreen({super.key});

  @override
  State<CreateGroupCallScreen> createState() => _CreateGroupCallScreenState();
}

class _CreateGroupCallScreenState extends State<CreateGroupCallScreen> {
  final TextEditingController _titleController = TextEditingController();
  // Voice-only app: type is always 'audio'
  String _selectedType = 'audio';
  DateTime? _scheduledAt;
  int _maxParticipants = 10;
  bool _isRecording = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group Call'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createGroupCall,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: BlocConsumer<GroupCallBloc, GroupCallState>(
        listener: (context, state) {
          if (state is GroupCallScheduled) {
            Navigator.pop(context, state.groupCall);
          } else if (state is GroupCallActive) {
            Navigator.pop(context, state.groupCall);
          } else if (state is GroupCallError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
          setState(() => _isLoading = state is GroupCallCreating);
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title field
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Call Title',
                    hintText: 'Enter a title for your group call',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                  maxLength: 100,
                ),
                const SizedBox(height: 24),

                // Call type (Voice-only app - always audio)
                Text(
                  'Call Type',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.call,
                        size: 32,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Voice Call',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Audio only call (voice-only app)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Schedule
                Text(
                  'Schedule',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _buildScheduleOption(),
                const SizedBox(height: 24),

                // Max participants
                Text(
                  'Max Participants',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _buildMaxParticipantsSlider(),
                const SizedBox(height: 24),

                // Recording
                Card(
                  child: SwitchListTile(
                    title: const Text('Record Call'),
                    subtitle: const Text('Save recording to cloud storage'),
                    value: _isRecording,
                    onChanged: (value) => setState(() => _isRecording = value),
                    secondary: const Icon(Icons.fiber_manual_record),
                  ),
                ),
                const SizedBox(height: 24),

                // Advanced settings
                ExpansionTile(
                  title: const Text('Advanced Settings'),
                  children: [
                    SwitchListTile(
                      title: const Text('Mute participants on entry'),
                      subtitle: const Text('Automatically mute new participants'),
                      value: _isRecording, // Placeholder
                      onChanged: (value) {},
                    ),
                    SwitchListTile(
                      title: const Text('Allow screen sharing'),
                      subtitle: const Text('Participants can share their screen'),
                      value: true,
                      onChanged: (value) {},
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypeOption({
    required String type,
    required IconData icon,
    required String label,
    required String description,
  }) {
    final isSelected = _selectedType == type;

    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey[600],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleOption() {
    String groupValue = _scheduledAt == null ? 'now' : 'scheduled';

    return RadioGroup<String>(
      groupValue: groupValue,
      onChanged: (value) => setState(() {
        if (value == 'now') {
          _scheduledAt = null;
        } else {
          _pickDateTime();
        }
      }),
      child: Column(
        children: [
          RadioListTile<String>(
            value: 'now',
            title: const Text('Start Now'),
            subtitle: const Text('Begin the call immediately'),
            secondary: const Icon(Icons.access_time),
          ),
          RadioListTile<String>(
            value: 'scheduled',
            title: const Text('Schedule for Later'),
            subtitle: _scheduledAt != null
                ? Text('Scheduled: ${_formatDateTime(_scheduledAt!)}')
                : const Text('Pick a date and time'),
            secondary: const Icon(Icons.schedule),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          DateTime.now().add(const Duration(hours: 1)),
        ),
      );

      if (time != null && mounted) {
        setState(() {
          _scheduledAt = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildMaxParticipantsSlider() {
    return Column(
      children: [
        Slider(
          value: _maxParticipants.toDouble(),
          min: 2,
          max: 50,
          divisions: 48,
          label: '$_maxParticipants participants',
          onChanged: (value) => setState(() => _maxParticipants = value.round()),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('2', style: TextStyle(color: Colors.grey[600])),
            Text('$_maxParticipants participants', style: const TextStyle(fontWeight: FontWeight.w600)),
            Text('50', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ],
    );
  }

  void _createGroupCall() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    context.read<GroupCallBloc>().add(CreateGroupCall(
      title: _titleController.text.trim(),
      scheduledAt: _scheduledAt,
      maxParticipants: _maxParticipants,
      isRecording: _isRecording,
      settings: {
        'muteOnEntry': true,
        'allowScreenShare': true,
      },
    ));
  }
}