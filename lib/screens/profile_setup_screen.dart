import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../providers/profile_provider.dart';
import '../services/storage_service.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  String? _selectedGender;
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    // Pre-fill from existing profile if available
    final existing = ref.watch(profileProvider);

    if (!_initialized && existing != null) {
      _selectedGender = existing.gender;
      _initialized = true;
    }

    return Scaffold(
      appBar: AppBar(
          title:
              Text(existing != null ? 'Edit Profile' : 'Quick Profile Setup')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: FormBuilder(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (existing != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Update your profile details below.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                FormBuilderTextField(
                  name: 'name',
                  initialValue: existing?.name,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                  ]),
                ),
                const SizedBox(height: 16),
                FormBuilderTextField(
                  name: 'phone',
                  initialValue: existing?.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number (Optional)',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                FormBuilderTextField(
                  name: 'age',
                  initialValue: existing?.age.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Age',
                    prefixIcon: Icon(Icons.cake),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                    FormBuilderValidators.numeric(),
                    FormBuilderValidators.min(1),
                    FormBuilderValidators.max(120),
                  ]),
                ),
                const SizedBox(height: 16),
                FormBuilderDropdown<String>(
                  name: 'gender',
                  initialValue: existing?.gender,
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                    prefixIcon: Icon(Icons.wc),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Male', child: Text('Male')),
                    DropdownMenuItem(value: 'Female', child: Text('Female')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  validator: FormBuilderValidators.required(),
                  onChanged: (val) {
                    setState(() {
                      _selectedGender = val;
                      _initialized = true;
                    });
                  },
                ),
                const SizedBox(height: 16),
                FormBuilderTextField(
                  name: 'height',
                  initialValue: existing?.height?.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Height (cm)',
                    prefixIcon: Icon(Icons.height),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.numeric(),
                  ]),
                ),
                const SizedBox(height: 16),
                FormBuilderTextField(
                  name: 'weight',
                  initialValue: existing?.weight?.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)',
                    prefixIcon: Icon(Icons.monitor_weight),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.numeric(),
                  ]),
                ),
                if (_selectedGender == 'Female') ...[
                  const SizedBox(height: 32),
                  const Text(
                      'Women\'s Health & Reproductive History (Optional)',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.pink)),
                  const SizedBox(height: 16),
                  FormBuilderTextField(
                    name: 'menstrualCycleLength',
                    initialValue: existing?.menstrualCycleLength?.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Average Menstrual Cycle Length (Days)',
                      prefixIcon: Icon(Icons.calendar_month),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: FormBuilderValidators.numeric(),
                  ),
                  const SizedBox(height: 16),
                  FormBuilderDropdown<String>(
                    name: 'cycleRegularity',
                    initialValue: existing?.cycleRegularity,
                    decoration: const InputDecoration(
                      labelText: 'Cycle Regularity',
                      prefixIcon: Icon(Icons.sync),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'Regular',
                          child: Text('Regular (predictable)')),
                      DropdownMenuItem(
                          value: 'Irregular',
                          child: Text('Irregular (unpredictable)')),
                      DropdownMenuItem(
                          value: 'Absent', child: Text('Absent (no periods)')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FormBuilderSlider(
                    name: 'periodPainScore',
                    initialValue: existing?.periodPainScore?.toDouble() ?? 0.0,
                    min: 0.0,
                    max: 10.0,
                    divisions: 10,
                    decoration: const InputDecoration(
                      labelText: 'Average Period Pain (0 = None, 10 = Severe)',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FormBuilderDropdown<String>(
                    name: 'reproductiveHistory',
                    initialValue: existing?.reproductiveHistory,
                    decoration: const InputDecoration(
                      labelText: 'Reproductive History',
                      prefixIcon: Icon(Icons.pregnant_woman),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'Nulliparous (Never given birth)',
                          child: Text('Nulliparous (Never given birth)')),
                      DropdownMenuItem(
                          value: 'Parous (Given birth)',
                          child: Text('Parous (Given birth)')),
                      DropdownMenuItem(
                          value: 'Currently Pregnant',
                          child: Text('Currently Pregnant')),
                      DropdownMenuItem(
                          value: 'Post-menopausal',
                          child: Text('Post-menopausal')),
                    ],
                  ),
                ],
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  onPressed: () async {
                    if (_formKey.currentState?.saveAndValidate() ?? false) {
                      final data = _formKey.currentState!.value;
                      final profile = UserProfile(
                        name: data['name'],
                        phone: data['phone'],
                        age: int.parse(data['age'].toString()),
                        gender: data['gender'],
                        height: data['height'] != null
                            ? double.tryParse(data['height'].toString())
                            : null,
                        weight: data['weight'] != null
                            ? double.tryParse(data['weight'].toString())
                            : null,
                        menstrualCycleLength:
                            data['menstrualCycleLength'] != null
                                ? int.tryParse(
                                    data['menstrualCycleLength'].toString())
                                : null,
                        cycleRegularity: data['cycleRegularity'],
                        periodPainScore: data['periodPainScore'] != null
                            ? (data['periodPainScore'] as double).toInt()
                            : null,
                        reproductiveHistory: data['reproductiveHistory'],
                      );

                      await ref
                          .read(profileProvider.notifier)
                          .saveProfile(profile);

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profile saved successfully!'),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        context.go('/dashboard');
                      }
                    }
                  },
                   child: Text(existing != null
                       ? 'Update Profile'
                       : 'Save Profile & Continue'),
                 ),
                 if (existing != null) ...[
                   const SizedBox(height: 32),
                   const Divider(),
                   const SizedBox(height: 8),
                   Text('Danger Zone', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 14)),
                   const SizedBox(height: 8),
                   SizedBox(
                     width: double.infinity,
                     child: OutlinedButton.icon(
                       onPressed: () {
                         showDialog(
                           context: context,
                           builder: (ctx) => AlertDialog(
                             title: const Text('Delete Account?'),
                             content: const Text('This will permanently delete your account, all reports, and health data. This cannot be undone.'),
                             actions: [
                               TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                               TextButton(
                                 onPressed: () async {
                                   Navigator.pop(ctx);
                                   try {
                                     await StorageService.deleteAccount();
                                     ref.invalidate(profileProvider);
                                     if (context.mounted) context.go('/login');
                                   } catch (e) {
                                     if (context.mounted) {
                                       ScaffoldMessenger.of(context).showSnackBar(
                                         SnackBar(content: Text('Failed to delete account: $e'), backgroundColor: Colors.red),
                                       );
                                     }
                                   }
                                 },
                                 style: TextButton.styleFrom(foregroundColor: Colors.red),
                                 child: const Text('Delete Forever'),
                               ),
                             ],
                           ),
                         );
                       },
                       icon: const Icon(Icons.delete_forever, size: 18),
                       label: const Text('Delete Account'),
                       style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                     ),
                   ),
                 ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
