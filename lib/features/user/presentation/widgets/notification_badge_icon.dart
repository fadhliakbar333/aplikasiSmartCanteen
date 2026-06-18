import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/notification_service.dart';

/// AppBar notification bell with a live unread-count badge.
class NotificationBadgeIcon extends StatelessWidget {
  const NotificationBadgeIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthService>().userId;

    if (userId == null) {
      return IconButton(
        icon: const Icon(Icons.notifications_outlined),
        color: const Color(0xFF7C3AED),
        onPressed: () =>
            Navigator.pushNamed(context, AppRoutes.userNotification),
      );
    }

    return StreamBuilder<int>(
      stream: NotificationService().streamUnreadCount(userId),
      builder: (context, snap) {
        final count = snap.data ?? 0;
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              color: const Color(0xFF7C3AED),
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.userNotification),
            ),
            if (count > 0)
              Positioned(
                right: 8,
                top: 8,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
