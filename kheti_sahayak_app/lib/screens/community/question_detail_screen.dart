import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/models/question.dart';
import 'package:kheti_sahayak_app/services/community_service.dart';
import 'package:kheti_sahayak_app/services/auth_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class QuestionDetailScreen extends StatefulWidget {
  final String questionId;

  const QuestionDetailScreen({Key? key, required this.questionId})
      : super(key: key);

  @override
  State<QuestionDetailScreen> createState() => _QuestionDetailScreenState();
}

class _QuestionDetailScreenState extends State<QuestionDetailScreen> {
  Question? _question;
  bool _isLoading = true;
  bool _isSubmittingAnswer = false;
  String? _currentUserId;

  final TextEditingController _answerController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final question = await CommunityService.getQuestion(widget.questionId);
      final user = await AuthService.getCurrentUser();
      setState(() {
        _question = question;
        _currentUserId = user?['id'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load question')),
        );
      }
    }
  }

  Future<void> _submitAnswer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmittingAnswer = true);

    try {
      final answer = await CommunityService.createAnswer(
        questionId: widget.questionId,
        body: _answerController.text,
      );

      if (answer != null) {
        _answerController.clear();
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Answer submitted successfully')),
          );
        }
      } else {
        throw Exception('Failed to submit answer');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => _isSubmittingAnswer = false);
    }
  }

  Future<void> _vote(String id, String type, int voteType) async {
    final result = await CommunityService.vote(
      id: id,
      type: type,
      voteType: voteType,
    );
    if (result != null) {
      _loadData();
    }
  }

  Future<void> _acceptAnswer(String answerId) async {
    final success = await CommunityService.acceptAnswer(answerId);
    if (success) {
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Answer accepted!')),
        );
      }
    }
  }

  Future<void> _deleteAnswer(String answerId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Answer'),
        content: const Text('Are you sure you want to delete this answer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await CommunityService.deleteAnswer(answerId);
      if (success) {
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Answer deleted')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Question')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_question == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Question')),
        body: const Center(child: Text('Question not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Question'),
        actions: [
          if (_question!.userId == _currentUserId)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'delete') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Question'),
                      content: const Text(
                          'Are you sure you want to delete this question?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    final success =
                        await CommunityService.deleteQuestion(_question!.id);
                    if (success && mounted) {
                      Navigator.pop(context, true);
                    }
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete Question'),
                ),
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildQuestionSection(),
              const Divider(height: 32),
              _buildAnswersSection(),
              const SizedBox(height: 24),
              _buildAnswerForm(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionSection() {
    final question = _question!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question.title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: question.profileImage != null
                  ? NetworkImage(question.profileImage!)
                  : null,
              child: question.profileImage == null
                  ? Text(question.authorName[0].toUpperCase())
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question.authorName,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Asked ${timeago.format(question.createdAt)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Text(
              '${question.views} views',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        if (question.tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: question.tags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVoteColumn(
              score: question.score,
              userVote: question.userVote,
              onUpvote: () => _vote(question.id, 'question', 1),
              onDownvote: () => _vote(question.id, 'question', -1),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                question.body,
                style: const TextStyle(fontSize: 16, height: 1.6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVoteColumn({
    required int score,
    int? userVote,
    required VoidCallback onUpvote,
    required VoidCallback onDownvote,
  }) {
    return Column(
      children: [
        IconButton(
          onPressed: onUpvote,
          icon: Icon(
            Icons.arrow_upward,
            color: userVote == 1 ? Colors.green : Colors.grey,
          ),
        ),
        Text(
          score.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: score > 0
                ? Colors.green
                : score < 0
                    ? Colors.red
                    : Colors.grey,
          ),
        ),
        IconButton(
          onPressed: onDownvote,
          icon: Icon(
            Icons.arrow_downward,
            color: userVote == -1 ? Colors.red : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildAnswersSection() {
    final answers = _question!.answers ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${answers.length} Answer${answers.length != 1 ? 's' : ''}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (answers.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'No answers yet. Be the first to answer!',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ...answers.map((answer) => _buildAnswerCard(answer)),
      ],
    );
  }

  Widget _buildAnswerCard(Answer answer) {
    final isQuestionOwner = _question!.userId == _currentUserId;
    final isAnswerOwner = answer.userId == _currentUserId;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: answer.isAccepted
            ? const BorderSide(color: Colors.green, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                _buildVoteColumn(
                  score: answer.score,
                  userVote: answer.userVote,
                  onUpvote: () => _vote(answer.id, 'answer', 1),
                  onDownvote: () => _vote(answer.id, 'answer', -1),
                ),
                if (answer.isAccepted)
                  const Icon(Icons.check_circle, color: Colors.green, size: 32)
                else if (isQuestionOwner && !_question!.isAnswered)
                  TextButton(
                    onPressed: () => _acceptAnswer(answer.id),
                    child: const Text('Accept'),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundImage: answer.profileImage != null
                            ? NetworkImage(answer.profileImage!)
                            : null,
                        child: answer.profileImage == null
                            ? Text(answer.authorName[0].toUpperCase(),
                                style: const TextStyle(fontSize: 12))
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              answer.authorName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              timeago.format(answer.createdAt),
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      if (isAnswerOwner)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: () => _deleteAnswer(answer.id),
                          color: Colors.red[400],
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    answer.body,
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                  if (answer.isAccepted) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check, size: 14, color: Colors.green),
                          SizedBox(width: 4),
                          Text(
                            'Accepted Answer',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Answer',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _answerController,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: 'Write your answer here...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your answer';
              }
              if (value.trim().length < 20) {
                return 'Answer must be at least 20 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmittingAnswer ? null : _submitAnswer,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmittingAnswer
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Post Answer'),
            ),
          ),
        ],
      ),
    );
  }
}
