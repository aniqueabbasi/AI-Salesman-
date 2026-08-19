import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:prac/res/app_theme.dart';
import 'package:prac/res/ui_kit.dart';
import 'package:prac/services/api_service.dart';

/// Form a seller fills in to publish a new product to the shared catalogue.
class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  static const Color _accent = AppTheme.accent;

  /// Kept in step with the category tabs the customer storefront shows.
  static const List<String> _categories = [
    'Shirt',
    'Jean',
    'Shoes',
    'Jacket',
    "Women's Clothing",
    'Kids',
    'Accessories',
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController(text: '1');

  String _category = _categories.first;
  File? _imageFile;
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        // Keep uploads comfortably under the server's 5 MB limit.
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked == null) return;
      setState(() => _imageFile = File(picked.path));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not open image picker: $e')),
      );
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: _accent),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: _accent),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickImage(ImageSource.camera);
              },
            ),
            if (_imageFile != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppTheme.accentPressed),
                title: const Text('Remove photo',
                    style: TextStyle(color: AppTheme.accentPressed)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  setState(() => _imageFile = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final navigator = Navigator.of(context);

    try {
      // Upload the photo first so the product carries a resolvable URL.
      final images = <String>[];
      if (_imageFile != null) {
        images.add(await ApiService.uploadProductImage(_imageFile!));
      }

      await ApiService.createProduct(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        stock: int.parse(_stockController.text.trim()),
        category: _category,
        images: images,
      );

      // `true` tells the dashboard to reload its list.
      navigator.pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        centerTitle: false,
        title: Text('New listing', style: AppTheme.display(26)),
        iconTheme: const IconThemeData(color: AppTheme.ink),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Center(
              child: Text('POST /products',
                  style: AppTheme.mono(12, tracking: 0.06)),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildImagePicker(),
            const SizedBox(height: 20),
            _field(
              controller: _nameController,
              label: 'Product name',
              icon: Icons.label_outline,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please enter a product name'
                  : null,
            ),
            const SizedBox(height: 14),
            _field(
              controller: _descriptionController,
              label: 'Description',
              icon: Icons.notes_outlined,
              maxLines: 3,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please describe the product'
                  : null,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _field(
                    controller: _priceController,
                    label: 'Price (PKR)',
                    icon: Icons.payments_outlined,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    validator: (v) {
                      final parsed = double.tryParse((v ?? '').trim());
                      if (parsed == null) return 'Enter a number';
                      if (parsed <= 0) return 'Must be above 0';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(
                    controller: _stockController,
                    label: 'Stock',
                    icon: Icons.inventory_2_outlined,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      final parsed = int.tryParse((v ?? '').trim());
                      if (parsed == null) return 'Enter a number';
                      if (parsed < 0) return 'Cannot be negative';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildCategoryPicker(),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.accentWash,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.accentWashBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppTheme.accentPressed),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_error!,
                          style: AppTheme.ui(14, color: AppTheme.accentPressed)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 26),
            PrimaryButton('Publish product',
                onPressed: _save, isBusy: _isSaving),
            const SizedBox(height: 10),
            Text(
              'Published products appear in the customer storefront immediately.',
              textAlign: TextAlign.center,
              style: AppTheme.ui(13, color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _showImageSourceSheet,
      child: Container(
        height: 190,
        decoration: BoxDecoration(
          color: AppTheme.surfaceRaised,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: _imageFile == null ? AppTheme.borderStrong : _accent,
            width: 1.5,
          ),
        ),
        child: _imageFile == null
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, size: 40, color: _accent),
                  SizedBox(height: 10),
                  Text('Add product photo',
                      style: TextStyle(
                          color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                  SizedBox(height: 4),
                  Text('Tap to choose from gallery or camera',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(_imageFile!, fit: BoxFit.cover),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: CircleAvatar(
                        backgroundColor: AppTheme.ink,
                        radius: 18,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.edit,
                              size: 17, color: Colors.white),
                          onPressed: _showImageSourceSheet,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildCategoryPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Eyebrow('Category'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final category in _categories)
              FilterPill(
                category,
                selected: _category == category,
                onTap: () => setState(() => _category = category),
              ),
          ],
        ),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _accent),
        filled: true,
        fillColor: AppTheme.surfaceRaised,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.borderStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.borderStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _accent, width: 1.5),
        ),
      ),
    );
  }
}
