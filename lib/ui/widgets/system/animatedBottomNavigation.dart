import 'package:eschool_saas_staff/data/models/system/bottomNavItem.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customTextContainer.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AnimatedBottomNavigation extends StatefulWidget {
  final List<BottomNavItem> items;
  final int selectedIndex;
  final Function(int) onItemSelected;

  const AnimatedBottomNavigation({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  State<AnimatedBottomNavigation> createState() =>
      _AnimatedBottomNavigationState();
}

class _AnimatedBottomNavigationState extends State<AnimatedBottomNavigation> {
  // Updated maroon color palette
  Color get maroonPrimary => AppColorPalette.primaryMaroon; 

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      bottom: true,
      child: Container(
        margin: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(35.0),
          boxShadow: [
            BoxShadow(
              color: isDark 
                  ? Colors.black.withValues(alpha: 0.4) 
                  : AppColorPalette.shadowColor.withValues(alpha: 0.15),
              blurRadius: 20.0,
              spreadRadius: 2.0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(widget.items.length, (index) {
            final item = widget.items[index];
            final isSelected = index == widget.selectedIndex;
            
            return GestureDetector(
              onTap: () {
                widget.onItemSelected(index);
              },
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: (MediaQuery.of(context).size.width - 80) / widget.items.length,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? (isDark ? const Color(0xFF333333) : AppColorPalette.accentPink)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        transitionBuilder: (child, animation) {
                          return ScaleTransition(scale: animation, child: child);
                        },
                        child: SvgPicture.asset(
                          Utils.getImagePath(isSelected ? item.selectedIconPath : item.iconPath),
                          key: ValueKey('${isSelected ? 'selected' : 'normal'}${item.iconPath}'),
                          height: 22.0,
                          width: 22.0,
                          colorFilter: ColorFilter.mode(
                            isSelected
                                ? (isDark ? Colors.white : maroonPrimary)
                                : (isDark
                                    ? Colors.grey.withValues(alpha: 0.6)
                                    : maroonPrimary.withValues(alpha: 0.6)),
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    CustomTextContainer(
                      textKey: item.title,
                      style: TextStyle(
                        fontSize: Utils.getScaledValue(context, 11.0),
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? (isDark ? Colors.white : maroonPrimary)
                            : (isDark
                                ? Colors.grey.withValues(alpha: 0.6)
                                : maroonPrimary.withValues(alpha: 0.6)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
