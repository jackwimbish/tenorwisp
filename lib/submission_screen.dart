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
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData ||
              snapshot.hasError ||
              snapshot.data?.data() == null) {
            return const Center(child: Text("Could not load user data."));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final liveSubmissionId = userData.containsKey('live_submission_id')
              ? userData['live_submission_id']
              : null;

          if (liveSubmissionId == null) {
            return SubmissionCreationForm(
              submissionService: _submissionService,
            );
          } else {
            return ActiveSubmissionView(
              submissionId: liveSubmissionId,
              submissionService: _submissionService,
            );
          }
        },
      ),
    );
  }
}

class SubmissionCreationForm extends StatefulWidget {
  final SubmissionService submissionService;

  const SubmissionCreationForm({super.key, required this.submissionService});

  @override
  State<SubmissionCreationForm> createState() => _SubmissionCreationFormState();
}

class _SubmissionCreationFormState extends State<SubmissionCreationForm> {
  final _submissionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _submissionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await widget.submissionService.submitIdea(
        _submissionController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your submission has been received!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('An error occurred: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
            onPressed: _isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: Theme.of(context).textTheme.titleMedium,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  )
                : const Text('Submit Idea'),
          ),
        ],
      ),
    );
  }
}

class ActiveSubmissionView extends StatefulWidget {
  final String submissionId;
  final SubmissionService submissionService;

  const ActiveSubmissionView({
    super.key,
    required this.submissionId,
    required this.submissionService,
  });

  @override
  State<ActiveSubmissionView> createState() => _ActiveSubmissionViewState();
}

class _ActiveSubmissionViewState extends State<ActiveSubmissionView> {
  bool _isLoading = false;

  Future<void> _withdraw() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await widget.submissionService.withdrawActiveSubmission(
        widget.submissionId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your submission has been withdrawn.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred while withdrawing: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: widget.submissionService.getSubmissionStream(widget.submissionId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.hasError || !snapshot.data!.exists) {
          return const Center(
            child: Text(
              "Could not load your submission. It may have been withdrawn.",
            ),
          );
        }

        final submissionData = snapshot.data!.data() as Map<String, dynamic>;
        final submissionText = submissionData['submissionText'];

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
      },
    );
  }
}
