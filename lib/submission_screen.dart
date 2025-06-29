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
  Map<String, dynamic>? _optimisticSubmissionData;

  void _onSubmissionCreated(Map<String, dynamic> newSubmission) {
    setState(() {
      _optimisticSubmissionData = newSubmission;
    });
  }

  void _onSubmissionWithdrawn() {
    setState(() {
      _optimisticSubmissionData = null;
    });
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
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              _optimisticSubmissionData == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData ||
              snapshot.hasError ||
              snapshot.data?.data() == null) {
            // Use optimistic data if available during an error state
            if (_optimisticSubmissionData != null) {
              return ActiveSubmissionView(
                submissionService: _submissionService,
                initialData: _optimisticSubmissionData,
                onWithdrawn: _onSubmissionWithdrawn,
              );
            }
            return const Center(child: Text("Could not load user data."));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final liveSubmissionId =
              userData['live_submission_id'] as String? ?? '';

          if (liveSubmissionId.isEmpty && _optimisticSubmissionData == null) {
            return SubmissionCreationForm(
              submissionService: _submissionService,
              onSubmissionCreated: _onSubmissionCreated,
            );
          } else {
            return ActiveSubmissionView(
              submissionId: liveSubmissionId,
              submissionService: _submissionService,
              initialData: _optimisticSubmissionData,
              onWithdrawn: _onSubmissionWithdrawn,
            );
          }
        },
      ),
    );
  }
}

class SubmissionCreationForm extends StatefulWidget {
  final SubmissionService submissionService;
  final Function(Map<String, dynamic>) onSubmissionCreated;

  const SubmissionCreationForm({
    super.key,
    required this.submissionService,
    required this.onSubmissionCreated,
  });

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
    if (_submissionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an idea to submit.')),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });

    try {
      final newSubmission = await widget.submissionService.submitIdea(
        _submissionController.text.trim(),
      );
      if (!mounted) return;
      widget.onSubmissionCreated(newSubmission);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your submission has been received!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('An error occurred: $e')));
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
  final String? submissionId;
  final SubmissionService submissionService;
  final Map<String, dynamic>? initialData;
  final VoidCallback onWithdrawn;

  const ActiveSubmissionView({
    super.key,
    this.submissionId,
    required this.submissionService,
    this.initialData,
    required this.onWithdrawn,
  });

  @override
  State<ActiveSubmissionView> createState() => _ActiveSubmissionViewState();
}

class _ActiveSubmissionViewState extends State<ActiveSubmissionView> {
  bool _isLoading = false;

  Future<void> _withdraw() async {
    final submissionIdToWithdraw =
        widget.submissionId ?? widget.initialData?['id'];
    if (submissionIdToWithdraw == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.submissionService.withdrawActiveSubmission(
        submissionIdToWithdraw,
      );
      if (!mounted) return;
      widget.onWithdrawn();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your submission has been withdrawn.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred while withdrawing: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.submissionId == null || widget.submissionId!.isEmpty) {
      if (widget.initialData != null) {
        return _buildContent(widget.initialData!);
      }
      return const Center(child: Text("Loading submission..."));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: widget.submissionService.getSubmissionStream(
        widget.submissionId!,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          if (widget.initialData != null) {
            return _buildContent(widget.initialData!);
          }
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.hasError || !snapshot.data!.exists) {
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

        final submissionData = snapshot.data!.data() as Map<String, dynamic>;
        return _buildContent(submissionData);
      },
    );
  }

  Widget _buildContent(Map<String, dynamic> submissionData) {
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
  }
}
