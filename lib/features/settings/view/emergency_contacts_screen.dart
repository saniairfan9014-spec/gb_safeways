import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../emergency/controller/emergency_controller.dart';
import '../controller/settings_controller.dart';
import '../model/personal_contact_model.dart';

class EmergencyContactsScreen extends StatelessWidget {
  const EmergencyContactsScreen({super.key});

  void _showContactFormDialog(
    BuildContext context,
    SettingsController controller, {
    PersonalContact? contact,
    required bool isDark,
  }) {
    final nameController = TextEditingController(text: contact?.name ?? '');
    final phoneController = TextEditingController(text: contact?.phone ?? '');
    final locationController = TextEditingController(text: contact?.location ?? '');
    String selectedCategory = contact?.category ?? 'Family';

    final textPrim = isDark ? AppColors.textPrimary : const Color(0xFF0F172A);
    final cardBg = isDark ? AppColors.surfaceElevated : Colors.white;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: cardBg,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(
              contact == null ? "Add Personal Contact" : "Edit Personal Contact",
              style: TextStyle(fontWeight: FontWeight.bold, color: textPrim, fontSize: 18),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    style: TextStyle(color: textPrim),
                    decoration: const InputDecoration(
                      labelText: "Contact Name",
                      prefixIcon: Icon(Icons.person_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneController,
                    style: TextStyle(color: textPrim),
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: "Phone Number",
                      prefixIcon: Icon(Icons.phone_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: locationController,
                    style: TextStyle(color: textPrim),
                    decoration: const InputDecoration(
                      labelText: "Location (e.g. Gilgit, Hunza)",
                      prefixIcon: Icon(Icons.location_on_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    dropdownColor: cardBg,
                    style: TextStyle(color: textPrim, fontSize: 14),
                    decoration: const InputDecoration(
                      labelText: "Category",
                      prefixIcon: Icon(Icons.category_rounded),
                    ),
                    items: ['Family', 'Friend', 'Doctor', 'Local Rescue', 'Other'].map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat,
                        child: Text(cat),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() {
                          selectedCategory = val;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text("Cancel", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  final phone = phoneController.text.trim();
                  final location = locationController.text.trim();

                  if (name.isEmpty || phone.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Name and phone number are required.")),
                    );
                    return;
                  }

                  if (contact == null) {
                    // New contact
                    final newContact = PersonalContact(
                      id: 'contact-${DateTime.now().millisecondsSinceEpoch}',
                      name: name,
                      phone: phone,
                      category: selectedCategory,
                      location: location.isEmpty ? 'Unknown Location' : location,
                    );
                    controller.addContact(newContact);
                  } else {
                    // Update contact
                    final updated = contact.copyWith(
                      name: name,
                      phone: phone,
                      category: selectedCategory,
                      location: location.isEmpty ? 'Unknown Location' : location,
                    );
                    controller.updateContact(updated);
                  }

                  Navigator.pop(ctx);
                },
                child: const Text("Save"),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsController = context.watch<SettingsController>();
    final emergencyController = context.read<EmergencyController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgCol = isDark ? AppColors.background : const Color(0xFFF8FAFC);
    final textPrim = isDark ? AppColors.textPrimary : const Color(0xFF0F172A);
    final textSec = isDark ? AppColors.textSecondary : const Color(0xFF475569);
    final borderCol = isDark ? AppColors.border : const Color(0xFFF1F5F9);
    final cardBg = isDark ? AppColors.surface : Colors.white;

    final contacts = settingsController.personalContacts;

    return Scaffold(
      backgroundColor: bgCol,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surface : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPrim, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Personal Contacts",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: textPrim,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF0284C7)),
            onPressed: () => _showContactFormDialog(context, settingsController, isDark: isDark),
          ),
        ],
      ),
      body: SafeArea(
        child: contacts.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.people_alt_rounded, size: 48, color: Color(0xFF0284C7)),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "No Personal Contacts",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrim),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Add safety contacts to quickly message/call during SOS alerts.",
                      style: TextStyle(fontSize: 13, color: textSec),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _showContactFormDialog(context, settingsController, isDark: isDark),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text("Add New Contact"),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: contacts.length,
                itemBuilder: (context, index) {
                  final contact = contacts[index];
                  Color categoryColor = const Color(0xFF64748B);
                  if (contact.category == 'Family') {
                    categoryColor = Colors.orange;
                  } else if (contact.category == 'Local Rescue') {
                    categoryColor = Colors.red;
                  } else if (contact.category == 'Doctor') {
                    categoryColor = Colors.blue;
                  } else if (contact.category == 'Friend') {
                    categoryColor = Colors.green;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderCol, width: 1.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.04 : 0.01),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: categoryColor.withOpacity(0.1),
                        child: Text(
                          contact.name.isNotEmpty ? contact.name[0].toUpperCase() : 'C',
                          style: TextStyle(color: categoryColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              contact.name,
                              style: TextStyle(fontWeight: FontWeight.bold, color: textPrim, fontSize: 15),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: categoryColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              contact.category.toUpperCase(),
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: categoryColor, letterSpacing: 0.5),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          "${contact.phone} • ${contact.location}",
                          style: TextStyle(color: textSec, fontSize: 12),
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.phone_forwarded_rounded, color: Color(0xFF0284C7), size: 20),
                            onPressed: () {
                              emergencyController.makeCall(contact.phone);
                            },
                          ),
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert_rounded, color: textSec),
                            color: cardBg,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            onSelected: (action) {
                              if (action == 'edit') {
                                _showContactFormDialog(context, settingsController, contact: contact, isDark: isDark);
                              } else if (action == 'delete') {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: isDark ? AppColors.surfaceElevated : Colors.white,
                                    surfaceTintColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    title: Text("Delete Contact", style: TextStyle(fontWeight: FontWeight.bold, color: textPrim)),
                                    content: Text("Are you sure you want to remove ${contact.name} from emergency contacts?", style: TextStyle(color: textSec, fontSize: 14)),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: Text("Cancel", style: TextStyle(color: textSec)),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          settingsController.deleteContact(contact.id);
                                          Navigator.pop(ctx);
                                        },
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                        child: const Text("Delete"),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: ListTile(
                                  leading: Icon(Icons.edit_rounded, size: 18),
                                  title: Text("Edit Info", style: TextStyle(fontSize: 13)),
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                  leading: Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                                  title: Text("Delete", style: TextStyle(color: Colors.red, fontSize: 13)),
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
