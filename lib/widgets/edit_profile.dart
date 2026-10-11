import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echat/models/user_model.dart';
import 'package:echat/providers/user_provider.dart';
import 'package:echat/utils/validators.dart';
import 'package:echat/widgets/common/user_avatar.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_kit/shadcn_kit.dart';

/// Change your photo, name, phone number and gender.
class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _formKey = GlobalKey<FormState>();
  late final UserModel? _user = Provider.of<UserProvider>(context, listen: false).getUser;
  late final _name = TextEditingController(text: _user?.name ?? '');
  late final _phone = TextEditingController(text: _user?.phoneNumber ?? '');
  late String? _gender = (_user?.gender.isEmpty ?? true) ? null : _user!.gender;
  XFile? _newPhoto;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  bool get _hasChanges =>
      _newPhoto != null ||
      _name.text.trim() != (_user?.name ?? '') ||
      _phone.text.trim() != (_user?.phoneNumber ?? '') ||
      (_gender ?? '') != (_user?.gender ?? '');

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1024, imageQuality: 85);
    if (picked != null && mounted) setState(() => _newPhoto = picked);
  }

  Future<void> _save() async {
    final user = _user;
    FocusScope.of(context).unfocus();
    if (user == null || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final updates = <String, dynamic>{
        'name': _name.text.trim(),
        'phone_Number': _phone.text.trim(),
        'gender': _gender ?? '',
      };
      if (_newPhoto != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('Users/${user.uid}/${DateTime.now().microsecondsSinceEpoch}.jpg');
        await ref.putFile(File(_newPhoto!.path), SettableMetadata(contentType: 'image/jpeg'));
        updates['profile_photo'] = await ref.getDownloadURL();
      }
      await FirebaseFirestore.instance.collection('Users').doc(user.uid).update(updates);
      if (!mounted) return;
      await Provider.of<UserProvider>(context, listen: false).refreshUser();
      if (!mounted) return;
      showShadcnToast(context, title: 'Profile updated', variant: ShadcnToastVariant.success);
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Profile update failed: $e');
      if (!mounted) return;
      setState(() => _saving = false);
      showShadcnToast(context,
          title: 'Couldn\'t save your changes',
          description: 'Check your connection and try again.',
          variant: ShadcnToastVariant.destructive);
    }
  }

  // Leaving with unsaved edits asks first.
  Future<void> _confirmLeave() async {
    final discard = await showShadcnAlertDialog(
      context,
      title: 'Discard changes?',
      description: 'Your edits haven\'t been saved.',
      confirmLabel: 'Discard',
      cancelLabel: 'Keep editing',
      destructive: true,
    );
    if (discard == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    final t = context.shadcn;
    return PopScope(
      canPop: !_hasChanges || _saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Edit profile')),
        body: user == null
            ? const ShadcnEmptyState(
                icon: Icons.person_off_outlined,
                title: 'Profile not loaded',
                description: 'Go back and try again in a moment.',
              )
            : SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(ShadcnSpacing.xl, ShadcnSpacing.lg, ShadcnSpacing.xl, ShadcnSpacing.xl3),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Form(
                      key: _formKey,
                      onChanged: () => setState(() {}),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(child: _photo(user, t)),
                          ShadcnGap.sm,
                          Center(
                            child: ShadcnButton(
                              variant: ShadcnButtonVariant.link,
                              onPressed: _saving ? null : _pickPhoto,
                              child: Text(user.profilePhoto.isEmpty && _newPhoto == null ? 'Add a photo' : 'Change photo'),
                            ),
                          ),
                          ShadcnGap.xl,
                          ShadcnInput(
                            controller: _name,
                            label: 'Full name',
                            placeholder: 'Your name',
                            leading: const Icon(Icons.person_outline_rounded),
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.name],
                            validator: Validators.name,
                            autovalidateMode: AutovalidateMode.onUserInteractionIfError,
                            enabled: !_saving,
                            style: const ShadcnInputStyle(height: 48, iconSize: 18),
                          ),
                          ShadcnGap.lg,
                          ShadcnInput(
                            controller: _phone,
                            label: 'Phone number',
                            placeholder: '10-digit mobile number',
                            helperText: 'Friends who have your number can find you in their Contacts tab.',
                            leading: const Icon(Icons.phone_outlined),
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            autofillHints: const [AutofillHints.telephoneNumberNational],
                            validator: Validators.phone,
                            autovalidateMode: AutovalidateMode.onUserInteractionIfError,
                            enabled: !_saving,
                            style: const ShadcnInputStyle(height: 48, iconSize: 18),
                          ),
                          ShadcnGap.xl,
                          ShadcnRadioGroup<String>(
                            label: 'Gender',
                            direction: Axis.horizontal,
                            value: _gender,
                            onChanged: (value) => setState(() => _gender = value),
                            options: const [
                              ShadcnRadioOption(value: 'Male', label: 'Male'),
                              ShadcnRadioOption(value: 'Female', label: 'Female'),
                            ],
                          ),
                          ShadcnGap.xl3,
                          ShadcnButton(
                            size: ShadcnButtonSize.lg,
                            fullWidth: true,
                            loading: _saving,
                            onPressed: _hasChanges ? _save : null,
                            child: const Text('Save changes'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _photo(UserModel user, ShadcnTheme t) {
    const size = 104.0;
    return Semantics(
      button: true,
      label: 'Change profile photo',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: _saving ? null : _pickPhoto,
        child: Stack(
          children: [
            _newPhoto != null
                ? ClipOval(
                    child: Image.file(File(_newPhoto!.path), width: size, height: size, fit: BoxFit.cover),
                  )
                : UserAvatar(name: user.name, imageUrl: user.profilePhoto, size: size),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: t.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: t.background, width: 3),
                ),
                child: Icon(Icons.photo_camera_rounded, color: t.primaryForeground, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
