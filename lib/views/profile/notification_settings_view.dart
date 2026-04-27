import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/notification_settings_viewmodel.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationSettingsView extends StatelessWidget {
  const NotificationSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Configuración de Alertas',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: Consumer<NotificationSettingsViewModel>(
        builder: (context, viewModel, child) {
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 30),
                _buildSettingCard(
                  context,
                  title: 'Antelación del aviso',
                  subtitle: '¿Cuántos días antes quieres recibir la alerta?',
                  icon: Icons.calendar_today,
                  child: DropdownButton<int>(
                    value: viewModel.daysBefore,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: [1, 2, 3, 5, 7].map((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text('$value ${value == 1 ? 'día' : 'días'} antes'),
                      );
                    }).toList(),
                    onChanged: (val) => viewModel.updateDaysBefore(val!),
                  ),
                ),
                const SizedBox(height: 20),
                _buildSettingCard(
                  context,
                  title: 'Hora de la notificación',
                  subtitle: '¿A qué hora prefieres ser notificado?',
                  icon: Icons.access_time,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${viewModel.hour.toString().padLeft(2, '0')}:${viewModel.minute.toString().padLeft(2, '0')} ${viewModel.hour < 12 ? 'AM' : 'PM'}',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    trailing: ElevatedButton(
                      onPressed: () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(
                            hour: viewModel.hour,
                            minute: viewModel.minute,
                          ),
                        );
                        if (picked != null) {
                          viewModel.updateTime(picked);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[50],
                        foregroundColor: Colors.green,
                        elevation: 0,
                      ),
                      child: const Text('Cambiar'),
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: viewModel.isLoading 
                        ? null 
                        : () async {
                            await viewModel.rescheduleAll();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✅ Alertas actualizadas con éxito'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 0,
                    ),
                    child: viewModel.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Actualizar todas las alertas',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    'Esto reprogramará los recordatorios para todos tus productos actuales.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.green, Color(0xFF81C784)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active, color: Colors.white, size: 40),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Evita el desperdicio',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'Configura tus alertas para usar tus alimentos a tiempo.',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.green, size: 20),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const Divider(),
          child,
        ],
      ),
    );
  }
}
