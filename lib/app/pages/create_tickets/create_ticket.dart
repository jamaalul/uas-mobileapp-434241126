import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../routes/app_router.dart';
import '../../../features/tickets/presentation/providers/ticket_provider.dart';
import '../../../features/tickets/presentation/providers/ticket_state.dart';

class CreateTicketPage extends ConsumerStatefulWidget {
  const CreateTicketPage({super.key});

  @override
  ConsumerState<CreateTicketPage> createState() => _CreateTicketPageState();
}

class _CreateTicketPageState extends ConsumerState<CreateTicketPage> {
  final TextEditingController _issueController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  File? _imageFile;
  
  final String _dummyImageUrl = "https://dipstrategy.co.id/blog/wp-content/uploads/2018/02/stop-making-memes-and-get-back-to-work.jpg";
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _issueController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _submitTicket() {
    final issue = _issueController.text.trim();
    final description = _descriptionController.text.trim();

    if (issue.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kendala dan Deskripsi tidak boleh kosong')),
      );
      return;
    }

    ref.read(ticketProvider.notifier).createTicket(
      issue: issue,
      description: description,
      attachmentUrl: _imageFile != null ? _dummyImageUrl : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ticketState = ref.watch(ticketProvider);

    ref.listen<TicketState>(ticketProvider, (previous, next) {
      if (next is TicketSuccess) {
        context.pushReplacementNamed(
          AppRoutes.userTicketDetail,
          extra: next.ticket,
        );
      } else if (next is TicketError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.message)),
        );
      }
    });

    final isLoading = ticketState is TicketLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Buat tiket",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Sampaikan detail kendala untuk\nditangani helpdesk.",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _issueController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelText: 'Kendala',
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: TextField(
                  controller: _descriptionController,
                  maxLines: null,
                  expands: true,
                  keyboardType: TextInputType.multiline,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    labelText: 'Deskripsi',
                    alignLabelWithHint: true,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_imageFile != null) ...[
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: FileImage(_imageFile!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _imageFile = null;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                            ),
                            builder: (context) {
                              return SafeArea(
                                child: Wrap(
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                                      child: Text(
                                        'Pilih Sumber Gambar',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.photo_library),
                                      title: const Text('Galeri'),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _pickImage(ImageSource.gallery);
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.camera_alt),
                                      title: const Text('Kamera'),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _pickImage(ImageSource.camera);
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        icon: Icon(
                          Icons.attach_file_rounded,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        label: Text(
                          'Lampirkan gambar',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimaryContainer
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submitTicket,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text("Kirim"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
