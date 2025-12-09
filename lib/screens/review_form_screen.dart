import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';

/// Screen for submitting a review for a fuel station
/// 
/// Allows users to:
/// - Rate a station with 1-5 stars
/// - Add an optional comment
/// - Submit the review to Supabase
class ReviewFormScreen extends StatefulWidget {
  final String stationId;
  final String stationName;

  const ReviewFormScreen({
    super.key,
    required this.stationId,
    required this.stationName,
  });

  @override
  State<ReviewFormScreen> createState() => _ReviewFormScreenState();
}

class _ReviewFormScreenState extends State<ReviewFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  
  int? _selectedRating;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة تقييم'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Station name card
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تقييم المحطة',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.stationName,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Star rating section
                Text(
                  'التقييم *',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                _buildStarRating(),
                
                if (_selectedRating == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'الرجاء اختيار تقييم',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ),
                
                const SizedBox(height: 24),
                
                // Comment section
                Text(
                  'التعليق (اختياري)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: _commentController,
                  maxLines: 5,
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText: 'شارك تجربتك مع هذه المحطة...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  textDirection: TextDirection.rtl,
                ),
                
                const SizedBox(height: 32),
                
                // Submit button
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _onSubmit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'إرسال التقييم',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build star rating widget
  Widget _buildStarRating() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(5, (index) {
            final starValue = index + 1;
            final isSelected = _selectedRating != null && starValue <= _selectedRating!;
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedRating = starValue;
                });
              },
              child: Icon(
                isSelected ? Icons.star : Icons.star_border,
                size: 48,
                color: isSelected ? Colors.amber : Colors.grey[400],
              ),
            );
          }),
        ),
      ),
    );
  }

  /// Handle submit button tap
  Future<void> _onSubmit() async {
    // Validate rating is selected
    if (_selectedRating == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء اختيار تقييم من 1 إلى 5 نجوم'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final supabaseService = context.read<SupabaseService>();
      
      // Create review object
      final review = Review(
        id: '', // Will be generated by Supabase
        stationId: widget.stationId,
        userId: 'anonymous', // TODO: Replace with actual user ID when auth is implemented
        rating: _selectedRating!,
        comment: _commentController.text.trim(),
        createdAt: DateTime.now(),
      );

      // Submit review to Supabase
      await supabaseService.submitReview(review);

      // Show success message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إرسال التقييم بنجاح'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back and signal refresh
      Navigator.pop(context, true);
    } catch (e) {
      // Show error message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل إرسال التقييم: ${e.toString()}'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'إعادة المحاولة',
            textColor: Colors.white,
            onPressed: _onSubmit,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
