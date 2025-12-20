import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Support Tab Widget
/// Provides direct messaging with sales representatives and FAQ section
class SupportTabWidget extends StatefulWidget {
  const SupportTabWidget({super.key});

  @override
  State<SupportTabWidget> createState() => _SupportTabWidgetState();
}

class _SupportTabWidgetState extends State<SupportTabWidget> {
  final TextEditingController _messageController = TextEditingController();

  // Mock messages data
  final List<Map<String, dynamic>> _messages = [
    {
      "id": 1,
      "sender": "support",
      "senderName": "Marie Kouassi",
      "message": "Bonjour ! Comment puis-je vous aider aujourd'hui ?",
      "timestamp": DateTime(2025, 11, 27, 9, 30),
      "isRead": true,
    },
    {
      "id": 2,
      "sender": "customer",
      "senderName": "Vous",
      "message": "Bonjour, j'ai une question concernant ma dernière commande.",
      "timestamp": DateTime(2025, 11, 27, 9, 32),
      "isRead": true,
    },
    {
      "id": 3,
      "sender": "support",
      "senderName": "Marie Kouassi",
      "message":
          "Bien sûr ! Pouvez-vous me donner le numéro de votre commande ?",
      "timestamp": DateTime(2025, 11, 27, 9, 33),
      "isRead": true,
    },
    {
      "id": 4,
      "sender": "customer",
      "senderName": "Vous",
      "message": "C'est la commande CMD-2024-1156",
      "timestamp": DateTime(2025, 11, 27, 9, 35),
      "isRead": true,
    },
  ];

  // Mock FAQ data
  final List<Map<String, dynamic>> _faqs = [
    {
      "question": "Comment passer une nouvelle commande ?",
      "answer":
          "Pour passer une nouvelle commande, accédez à l'onglet 'Commandes' et cliquez sur le bouton 'Nouvelle'. Vous serez redirigé vers notre catalogue produits avec vos prix personnalisés.",
      "category": "Commandes",
      "isExpanded": false,
    },
    {
      "question": "Quels sont les délais de livraison ?",
      "answer":
          "Les délais de livraison standard sont de 2-3 jours ouvrables pour Abidjan et 3-5 jours pour les autres régions. Les livraisons express sont disponibles sur demande.",
      "category": "Livraison",
      "isExpanded": false,
    },
    {
      "question": "Comment puis-je suivre ma commande ?",
      "answer":
          "Vous pouvez suivre votre commande en temps réel depuis l'onglet 'Commandes'. Glissez vers la droite sur une commande et sélectionnez 'Suivre' pour voir l'état de livraison détaillé.",
      "category": "Commandes",
      "isExpanded": false,
    },
    {
      "question": "Quels modes de paiement acceptez-vous ?",
      "answer":
          "Nous acceptons les virements bancaires, Mobile Money (Orange Money, MTN Money, Moov Money), chèques et paiements en espèces à la livraison pour les commandes inférieures à 500 000 XOF.",
      "category": "Paiement",
      "isExpanded": false,
    },
    {
      "question": "Comment télécharger mes factures ?",
      "answer":
          "Accédez à l'onglet 'Documents', sélectionnez la facture souhaitée et cliquez sur 'Télécharger'. Vous pouvez également partager directement la facture par email.",
      "category": "Documents",
      "isExpanded": false,
    },
    {
      "question": "Que faire si je reçois un produit endommagé ?",
      "answer":
          "Contactez-nous immédiatement via le support avec des photos du produit endommagé. Nous organiserons un remplacement ou un remboursement dans les 24 heures.",
      "category": "Livraison",
      "isExpanded": false,
    },
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: theme.colorScheme.surface,
            child: TabBar(
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              indicatorColor: theme.colorScheme.primary,
              tabs: const [
                Tab(text: 'Messages'),
                Tab(text: 'FAQ'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildMessagesTab(context),
                _buildFaqTab(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesTab(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.05),
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 6.w,
                backgroundColor: theme.colorScheme.primary,
                child: Text(
                  'MK',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Marie Kouassi',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 2.w,
                          height: 2.w,
                          decoration: BoxDecoration(
                            color: AppTheme.successLight,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          'En ligne',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: CustomIconWidget(
                  iconName: 'phone',
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                onPressed: () {
                  _showCallDialog(context);
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(4.w),
            reverse: true,
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[_messages.length - 1 - index];
              return _buildMessageBubble(context, message);
            },
          ),
        ),
        _buildMessageInput(context),
      ],
    );
  }

  Widget _buildMessageBubble(
      BuildContext context, Map<String, dynamic> message) {
    final theme = Theme.of(context);
    final isCustomer = message['sender'] == 'customer';

    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Row(
        mainAxisAlignment:
            isCustomer ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isCustomer) ...[
            CircleAvatar(
              radius: 4.w,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              child: Text(
                'MK',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(width: 2.w),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
              decoration: BoxDecoration(
                color: isCustomer
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isCustomer ? 16 : 4),
                  topRight: Radius.circular(isCustomer ? 4 : 16),
                  bottomLeft: const Radius.circular(16),
                  bottomRight: const Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message['message'],
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isCustomer
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    _formatTime(message['timestamp']),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isCustomer
                          ? theme.colorScheme.onPrimary.withValues(alpha: 0.7)
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isCustomer) ...[
            SizedBox(width: 2.w),
            CircleAvatar(
              radius: 4.w,
              backgroundColor: theme.colorScheme.primary,
              child: CustomIconWidget(
                iconName: 'person',
                color: theme.colorScheme.onPrimary,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: CustomIconWidget(
                iconName: 'attach_file',
                color: theme.colorScheme.onSurfaceVariant,
                size: 24,
              ),
              onPressed: () {
                _showAttachmentOptions(context);
              },
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Tapez votre message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 4.w,
                    vertical: 1.5.h,
                  ),
                ),
                maxLines: null,
              ),
            ),
            SizedBox(width: 2.w),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: CustomIconWidget(
                  iconName: 'send',
                  color: theme.colorScheme.onPrimary,
                  size: 20,
                ),
                onPressed: () {
                  if (_messageController.text.trim().isNotEmpty) {
                    _sendMessage(_messageController.text.trim());
                    _messageController.clear();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqTab(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        Text(
          'Questions Fréquentes',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        ..._faqs.map((faq) {
          return _buildFaqItem(context, faq);
        }),
        SizedBox(height: 3.h),
        Card(
          color: theme.colorScheme.primary.withValues(alpha: 0.05),
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              children: [
                CustomIconWidget(
                  iconName: 'help_outline',
                  color: theme.colorScheme.primary,
                  size: 48,
                ),
                SizedBox(height: 2.h),
                Text(
                  'Vous ne trouvez pas votre réponse ?',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 1.h),
                Text(
                  'Contactez notre équipe support pour une assistance personnalisée',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 2.h),
                ElevatedButton.icon(
                  onPressed: () {
                    DefaultTabController.of(context).animateTo(0);
                  },
                  icon: CustomIconWidget(
                    iconName: 'chat',
                    color: theme.colorScheme.onPrimary,
                    size: 20,
                  ),
                  label: const Text('Contacter le Support'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFaqItem(BuildContext context, Map<String, dynamic> faq) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            faq['question'],
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Padding(
            padding: EdgeInsets.only(top: 0.5.h),
            child: Text(
              faq['category'],
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          children: [
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Text(
                faq['answer'],
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  void _sendMessage(String message) {
    setState(() {
      _messages.add({
        "id": _messages.length + 1,
        "sender": "customer",
        "senderName": "Vous",
        "message": message,
        "timestamp": DateTime.now(),
        "isRead": true,
      });
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _messages.add({
            "id": _messages.length + 1,
            "sender": "support",
            "senderName": "Marie Kouassi",
            "message":
                "Merci pour votre message. Je vérifie cela et je reviens vers vous dans quelques instants.",
            "timestamp": DateTime.now(),
            "isRead": false,
          });
        });
      }
    });
  }

  void _showAttachmentOptions(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CustomIconWidget(
                      iconName: 'photo_library',
                      color: Colors.blue,
                      size: 24,
                    ),
                  ),
                  title: const Text('Galerie'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sélection depuis la galerie...'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CustomIconWidget(
                      iconName: 'camera_alt',
                      color: Colors.green,
                      size: 24,
                    ),
                  ),
                  title: const Text('Caméra'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ouverture de la caméra...'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CustomIconWidget(
                      iconName: 'insert_drive_file',
                      color: Colors.orange,
                      size: 24,
                    ),
                  ),
                  title: const Text('Document'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sélection de document...'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCallDialog(BuildContext context) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Appeler le Support',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: const Text(
            'Voulez-vous appeler Marie Kouassi au +225 07 12 34 56 78 ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Appel en cours...'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Appeler'),
            ),
          ],
        );
      },
    );
  }
}
