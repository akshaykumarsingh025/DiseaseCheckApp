import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../providers/profile_provider.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    // Pre-fill from existing profile if available
    final existing = ref.read(profileProvider);

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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
