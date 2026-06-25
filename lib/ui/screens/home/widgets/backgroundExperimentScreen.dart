import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eschool_saas_staff/cubits/settings/appThemeCubit.dart';
import 'package:eschool_saas_staff/ui/widgets/system/modern_background.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';

class BackgroundExperimentScreen extends StatelessWidget {
  const BackgroundExperimentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppThemeCubit, AppThemeState>(
      builder: (context, themeState) {
        final currentTheme = themeState.themeMode;
        
        return Scaffold(
          body: ModernBackground(
            child: Stack(
              children: [
                // Top Custom Header / App Bar
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 20,
                  right: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor.withValues(alpha: 0.8),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            size: 20,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          "BACKGROUND EXPERIMENT",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 44), // Spacer to balance back button
                    ],
                  ),
                ),

                // Center visual guidance
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.insights_outlined,
                          size: 64,
                          color: AppColorPalette.primaryMaroon.withValues(alpha: 0.8),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Nikmati Aliran Dinamis Latar Belakang",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Ganti tema di bawah ini untuk melihat adaptasi warna gradien dan pergerakan gelombang secara real-time.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Theme selection control panel floating at the bottom
                Positioned(
                  bottom: MediaQuery.of(context).padding.bottom + 40,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "PILIH TEMA UNTUK DIUJI",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              SizedBox(
                                width: (MediaQuery.of(context).size.width - 100) / 3,
                                child: _buildThemeButton(
                                  context,
                                  label: "Terang",
                                  themeValue: "light",
                                  activeColor: const Color(0xFF8B1F41),
                                  isSelected: currentTheme == "light",
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: (MediaQuery.of(context).size.width - 100) / 3,
                                child: _buildThemeButton(
                                  context,
                                  label: "Gelap",
                                  themeValue: "dark",
                                  activeColor: Colors.grey[800]!,
                                  isSelected: currentTheme == "dark",
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: (MediaQuery.of(context).size.width - 100) / 3,
                                child: _buildThemeButton(
                                  context,
                                  label: "Violet",
                                  themeValue: "violet",
                                  activeColor: const Color(0xFF6B4EFF),
                                  isSelected: currentTheme == "violet",
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: (MediaQuery.of(context).size.width - 100) / 3,
                                child: _buildThemeButton(
                                  context,
                                  label: "Indonesia",
                                  themeValue: "indonesia",
                                  activeColor: const Color(0xFFD32F2F),
                                  isSelected: currentTheme == "indonesia",
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeButton(
    BuildContext context, {
    required String label,
    required String themeValue,
    required Color activeColor,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        context.read<AppThemeCubit>().changeTheme(themeValue);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : Theme.of(context).dividerColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isSelected
                  ? Colors.white
                  : Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
      ),
    );
  }
}
