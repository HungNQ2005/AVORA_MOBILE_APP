import 'package:flutter/material.dart';
import 'package:avora_mobile/features/auth/data/auth_model.dart';
import 'profile_widgets.dart';

class ProfileInfoSection extends StatelessWidget {
  final UserModel profile;
  final bool isEditing;
  final bool isSaving;
  final String? message;
  final bool messageIsError;
  final TextEditingController fullNameController;
  final TextEditingController phoneController;
  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const ProfileInfoSection({
    super.key,
    required this.profile,
    required this.isEditing,
    required this.isSaving,
    required this.message,
    required this.messageIsError,
    required this.fullNameController,
    required this.phoneController,
    required this.onEdit,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final verified = profile.accountStatus?.toUpperCase() == 'ACTIVE';
    return ProfileCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thông tin cá nhân',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Quản lý thông tin dùng cho các kỳ nghỉ của bạn.',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isEditing)
                IconButton(
                  tooltip: 'Chỉnh sửa thông tin',
                  onPressed: onEdit,
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: Color(0xFF003580),
                  ),
                ),
            ],
          ),
          if (message != null) ...[
            const SizedBox(height: 14),
            ProfileInlineMessage(
              message: message!,
              isError: messageIsError,
            ),
          ],
          const SizedBox(height: 16),
          ProfileFormLabel(
            label: 'Họ và tên đầy đủ',
            isEditable: isEditing,
          ),
          const SizedBox(height: 7),
          if (isEditing)
            TextField(
              controller: fullNameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: profileInputDecoration('Nhập họ và tên đầy đủ'),
            )
          else
            ProfileReadOnlyValue(
              value: profile.fullName?.trim().isNotEmpty == true
                  ? profile.fullName!.trim()
                  : 'Chưa điền thông tin',
            ),
          const SizedBox(height: 16),
          const ProfileFormLabel(label: 'Địa chỉ email'),
          const SizedBox(height: 7),
          ProfileReadOnlyValue(
            value: profile.email,
            leading: Icons.lock_outline,
            trailing: verified ? 'Đã xác minh' : 'Chưa xác minh',
            verified: verified,
          ),
          const SizedBox(height: 16),
          ProfileFormLabel(
            label: 'Số điện thoại liên lạc',
            isEditable: isEditing,
          ),
          const SizedBox(height: 7),
          if (isEditing)
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              decoration: profileInputDecoration('+84 0905 123 456'),
            )
          else
            ProfileReadOnlyValue(
              value: profile.phone?.trim().isNotEmpty == true
                  ? profile.phone!.trim()
                  : 'Chưa điền thông tin',
            ),
          if (isEditing) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isSaving ? null : onCancel,
                    child: const Text('Hủy'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isSaving ? null : onSave,
                    icon: isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined, size: 18),
                    label: Text(isSaving ? 'Đang lưu' : 'Lưu thay đổi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003580),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
