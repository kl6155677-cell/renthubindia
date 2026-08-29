import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/support_ticket_model.dart';
import '../../data/repositories/support_repository.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  List<SupportTicketModel> _tickets = [];
  bool _isLoading = true;
  bool _showFaq = true;

  final _faqItems = [
    {'q': 'How do I post a listing?', 'a': 'Go to the Post tab, fill in item details, pricing, and photos, then submit for review.'},
    {'q': 'How do bookings work?', 'a': 'Renters send a booking request. As an owner, you can accept, decline, or mark it complete.'},
    {'q': 'Is there a payment system?', 'a': 'RentHubIndia connects renters and owners directly. Payment arrangements are made between parties.'},
    {'q': 'How do I get verified?', 'a': 'Go to Profile → Identity Verification and upload a valid document. Review takes 1-2 business days.'},
    {'q': 'What if I have a dispute?', 'a': 'Contact support through this screen and we\'ll help mediate the situation.'},
    {'q': 'Can I pause my listing?', 'a': 'Yes! Go to My Listings in your profile, find the listing, and tap the pause icon.'},
  ];

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    try {
      final tickets = await SupportRepository().getMyTickets();
      if (mounted) setState(() { _tickets = tickets; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        title: const Text('Help & Support', style: TextStyle(fontFamily: 'Sora', fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contact support button
            GestureDetector(
              onTap: () => _showNewTicketDialog(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF0D4F4F), Color(0xFF1A7A7A)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.headset_mic_outlined, size: 28, color: Colors.white),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Need help?', style: TextStyle(fontFamily: 'Sora', fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                          SizedBox(height: 3),
                          Text('Create a support ticket and we\'ll respond within 24 hours', style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 12, color: Colors.white70)),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // FAQ Section
            GestureDetector(
              onTap: () => setState(() => _showFaq = !_showFaq),
              child: Row(
                children: [
                  const Text('Frequently Asked Questions', style: TextStyle(fontFamily: 'Sora', fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                  const Spacer(),
                  Icon(_showFaq ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: const Color(0xFF9CA3AF)),
                ],
              ),
            ),
            if (_showFaq) ...[
              const SizedBox(height: 12),
              ...List.generate(_faqItems.length, (i) => _buildFaqItem(_faqItems[i])),
            ],

            const SizedBox(height: 24),

            // My Tickets
            const Text('My Tickets', style: TextStyle(fontFamily: 'Sora', fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
            const SizedBox(height: 12),
            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)))
            else if (_tickets.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                child: const Column(
                  children: [
                    Icon(Icons.confirmation_number_outlined, size: 32, color: Color(0xFFD1D5DB)),
                    SizedBox(height: 10),
                    Text('No tickets yet', style: TextStyle(fontFamily: 'Sora', fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF9CA3AF))),
                  ],
                ),
              )
            else
              ...List.generate(_tickets.length, (i) => _buildTicketCard(_tickets[i])),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(Map<String, String> faq) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(faq['q']!, style: const TextStyle(fontFamily: 'Sora', fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        children: [
          Text(faq['a']!, style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13, color: Color(0xFF6B7280), height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildTicketCard(SupportTicketModel ticket) {
    final dateFormat = DateFormat.yMMMd();
    Color statusColor;
    switch (ticket.status) {
      case 'OPEN': statusColor = AppColors.primary; break;
      case 'RESOLVED': statusColor = AppColors.success; break;
      case 'CLOSED': statusColor = const Color(0xFF6B7280); break;
      default: statusColor = AppColors.accent;
    }

    return GestureDetector(
      onTap: () => _showTicketDetail(ticket),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ticket.subject, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Sora', fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                  const SizedBox(height: 4),
                  Text(dateFormat.format(ticket.createdAt), style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 12, color: Color(0xFF9CA3AF))),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(ticket.status, style: TextStyle(fontFamily: 'Sora', fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 20, color: Color(0xFFD1D5DB)),
          ],
        ),
      ),
    );
  }

  void _showTicketDetail(SupportTicketModel ticket) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text(ticket.subject, style: const TextStyle(fontFamily: 'Sora', fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
            const SizedBox(height: 12),
            const Text('Your Message:', style: TextStyle(fontFamily: 'Sora', fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF))),
            const SizedBox(height: 6),
            Text(ticket.message, style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, color: Color(0xFF374151), height: 1.5)),
            if (ticket.adminReply != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.support_agent, size: 16, color: AppColors.primary),
                        SizedBox(width: 6),
                        Text('Admin Reply', style: TextStyle(fontFamily: 'Sora', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(ticket.adminReply!, style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, color: Color(0xFF374151), height: 1.5)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showNewTicketDialog() {
    final subjectCtrl = TextEditingController();
    final messageCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        bool submitting = false;
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 20),
                  const Text('New Support Ticket', style: TextStyle(fontFamily: 'Sora', fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                  const SizedBox(height: 16),
                  _buildField(subjectCtrl, 'Subject', 'Brief description of your issue'),
                  const SizedBox(height: 14),
                  _buildField(messageCtrl, 'Message', 'Describe your issue in detail...', maxLines: 4),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: submitting ? null : () async {
                        if (subjectCtrl.text.trim().isEmpty || messageCtrl.text.trim().isEmpty) return;
                        setModalState(() => submitting = true);
                        try {
                          await SupportRepository().createTicket(subjectCtrl.text.trim(), messageCtrl.text.trim());
                          if (mounted) {
                            Navigator.of(ctx).pop();
                            _loadTickets();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Ticket submitted!'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
                            );
                          }
                        } catch (e) {
                          setModalState(() => submitting = false);
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontFamily: 'Sora', fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      child: submitting
                          ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Submit Ticket'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, String hint, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Sora', fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
          child: TextField(
            controller: ctrl,
            maxLines: maxLines,
            style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14),
            decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: Color(0xFF9CA3AF)), border: InputBorder.none, contentPadding: const EdgeInsets.all(14)),
          ),
        ),
      ],
    );
  }
}
