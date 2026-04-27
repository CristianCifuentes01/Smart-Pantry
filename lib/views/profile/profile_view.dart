import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../auth/login_view.dart';
import 'notification_settings_view.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.green,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 30),
            ListTile(
              leading: const Icon(Icons.notifications_active, color: Colors.green),
              title: const Text('Configuración de Alertas'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationSettingsView()),
                );
              },
            ),
            const Divider(),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text(
                  'Cerrar Sesión',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  await authViewModel.logout();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginView()),
                      (route) => false,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
