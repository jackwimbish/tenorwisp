import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tenorwisp/services/submission_service.dart';

class SubmissionScreen extends StatefulWidget {
  const SubmissionScreen({super.key});

  @override
  State<SubmissionScreen> createState() => _SubmissionScreenState();
}

class _SubmissionScreenState extends State<SubmissionScreen> {
  final SubmissionService _submissionService = SubmissionService();
  bool _isSubmitting = false;

  void _onSubmissionStarted() {
    setState(() {
      _isSubmitting = true;
    });
  }

  void _onSubmissionFinished() {
    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _onSubmissionWithdrawn() {
    // This function remains to allow the child to trigger a rebuild
    // in the parent after a withdrawal, showing the form again.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share an Idea'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _submissionService.userDocStream,
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!userSnapshot.hasData || userSnapshot.data?.data() == null) {
            return const Center(child: Text("Could not load user data."));
          }

          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
          final liveSubmissionId =
              userData['live_submission_id'] as String? ?? '';

          if (liveSubmissionId.isNotEmpty) {
            return StreamBuilder<DocumentSnapshot>(
              stream: _submissionService.getSubmissionStream(liveSubmissionId),
              builder: (context, submissionSnapshot) {
                if (submissionSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!submissionSnapshot.hasData ||
                    !submissionSnapshot.data!.exists) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        "Could not load your submission. It may have been withdrawn.",
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                final submissionData =
                    submissionSnapshot.data!.data() as Map<String, dynamic>;
                submissionData['id'] = submissionSnapshot.data!.id;

                return ActiveSubmissionView(
                  submissionService: _submissionService,
                  submissionData: submissionData,
                  onWithdrawn: _onSubmissionWithdrawn,
                );
              },
            );
          } else if (_isSubmitting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Submitting your idea..."),
                ],
              ),
            );
          } else {
            return SubmissionCreationForm(
              submissionService: _submissionService,
              onSubmissionStarted: _onSubmissionStarted,
              onSubmissionFinished: _onSubmissionFinished,
            );
          }
        },
      ),
    );
  }
}

class SubmissionCreationForm extends StatefulWidget {
  final SubmissionService submissionService;
  final VoidCallback onSubmissionStarted;
  final VoidCallback onSubmissionFinished;

  const SubmissionCreationForm({
    super.key,
    required this.submissionService,
    required this.onSubmissionStarted,
    required this.onSubmissionFinished,
  });

  @override
  State<SubmissionCreationForm> createState() => _SubmissionCreationFormState();
}

class _SubmissionCreationFormState extends State<SubmissionCreationForm> {
  final _submissionController = TextEditingController();

  @override
  void dispose() {
    _submissionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submissionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an idea to submit.')),
      );
      return;
    }
    widget.onSubmissionStarted();

    try {
      await widget.submissionService.submitIdea(
        _submissionController.text.trim(),
      );
      // No need to do anything on success, the parent stream will handle it.
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('An error occurred: $e')));
    } finally {
      // In case of an error, we need to revert the submitting state.
      // On success, the parent widget will have rebuilt and this form will
      // no longer be in the tree, so this call will be a no-op.
      widget.onSubmissionFinished();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "What's on your mind?",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _submissionController,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: "Share a topic idea for the next discussion...",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: Theme.of(context).textTheme.titleMedium,
            ),
            child: const Text('Submit Idea'),
          ),
        ],
      ),
    );
  }
}

class ActiveSubmissionView extends StatefulWidget {
  final SubmissionService submissionService;
  final Map<String, dynamic> submissionData;
  final VoidCallback onWithdrawn;

  const ActiveSubmissionView({
    super.key,
    required this.submissionService,
    required this.submissionData,
    required this.onWithdrawn,
  });

  @override
  State<ActiveSubmissionView> createState() => _ActiveSubmissionViewState();
}

class _ActiveSubmissionViewState extends State<ActiveSubmissionView> {
  bool _isLoading = false;

  Future<void> _withdraw() async {
    final submissionIdToWithdraw = widget.submissionData['id'];
    if (submissionIdToWithdraw == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot withdraw submission: Missing ID.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await widget.submissionService.withdrawActiveSubmission(
        submissionIdToWithdraw,
      );
      if (!mounted) return;
      widget.onWithdrawn();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred while withdrawing: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final submissionText = widget.submissionData['submissionText'];
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Your Active Submission:",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                submissionText,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _isLoading ? null : _withdraw,
            icon: _isLoading
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline, size: 20),
            label: const Text('Withdraw Submission'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }
}
