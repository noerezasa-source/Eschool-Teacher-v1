import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ProfileImageContainer extends StatelessWidget {
  final String imageUrl;
  final double? heightAndWidth;
  final bool removePadding;
  final BoxFit? fit;
  final BorderRadius? borderRadius;

  const ProfileImageContainer({
    super.key,
    this.heightAndWidth,
    required this.imageUrl,
    this.removePadding = false,
    this.fit,
    this.borderRadius,
  });

  /// Creates a ProfileImageContainer with full display (no padding/margins)
  /// Perfect for user profile photos that should fill the entire container
  static ProfileImageContainer fullDisplay({
    required String imageUrl,
    double? size,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
  }) {
    return ProfileImageContainer(
      imageUrl: imageUrl,
      heightAndWidth: size,
      removePadding: true,
      fit: fit,
      borderRadius: borderRadius,
    );
  }

  /// Creates a circular ProfileImageContainer with full display
  static ProfileImageContainer circular({
    required String imageUrl,
    double? size,
    BoxFit fit = BoxFit.cover,
  }) {
    final double radius = (size ?? 70) / 2;
    return ProfileImageContainer(
      imageUrl: imageUrl,
      heightAndWidth: size,
      removePadding: true,
      fit: fit,
      borderRadius: BorderRadius.circular(radius),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double size = heightAndWidth ?? 70;
    final BorderRadius radius = borderRadius ?? BorderRadius.circular(5.0);
    final BoxFit imageFit = fit ?? BoxFit.cover;

    if (removePadding) {
      // Full display without any padding or margin
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: radius,
          image: imageUrl.isEmpty
              ? null
              : DecorationImage(
                  fit: imageFit,
                  image: CachedNetworkImageProvider(imageUrl),
                ),
          color: imageUrl.isEmpty ? Theme.of(context).colorScheme.surface : null,
        ),
        child: imageUrl.isEmpty
            ? Center(
                child: Icon(
                  Icons.person,
                  size: size * 0.4,
                  color: Theme.of(context).iconTheme.color,
                ),
              )
            : null,
      );
    }

    // Original behavior with background container
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: radius,
        image: imageUrl.isEmpty
            ? null
            : DecorationImage(
                fit: imageFit,
                image: CachedNetworkImageProvider(imageUrl),
              ),
      ),
      child: imageUrl.isEmpty
          ? const Center(
              child: Icon(
                Icons.person,
                size: 25,
              ),
            )
          : null,
    );
  }
}
