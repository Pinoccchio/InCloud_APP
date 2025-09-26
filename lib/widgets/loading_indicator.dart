import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

enum LoadingSize { small, medium, large }

class LoadingIndicator extends StatelessWidget {
  final LoadingSize size;
  final Color? color;
  final String? message;
  final bool showBackground;

  const LoadingIndicator({
    super.key,
    this.size = LoadingSize.medium,
    this.color,
    this.message,
    this.showBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final indicator = _buildIndicator();

    if (showBackground) {
      return Container(
        color: Colors.black.withValues(alpha: 0.3),
        child: Center(child: indicator),
      );
    }

    return indicator;
  }

  Widget _buildIndicator() {
    final double indicatorSize = _getIndicatorSize();
    final double strokeWidth = _getStrokeWidth();

    if (message != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: indicatorSize,
            height: indicatorSize,
            child: CircularProgressIndicator(
              strokeWidth: strokeWidth,
              valueColor: AlwaysStoppedAnimation<Color>(
                color ?? AppColors.primaryRed,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message!,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return SizedBox(
      width: indicatorSize,
      height: indicatorSize,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? AppColors.primaryRed,
        ),
      ),
    );
  }

  double _getIndicatorSize() {
    switch (size) {
      case LoadingSize.small:
        return 16;
      case LoadingSize.medium:
        return 24;
      case LoadingSize.large:
        return 40;
    }
  }

  double _getStrokeWidth() {
    switch (size) {
      case LoadingSize.small:
        return 2;
      case LoadingSize.medium:
        return 3;
      case LoadingSize.large:
        return 4;
    }
  }
}

// Convenience constructors
class SmallLoadingIndicator extends LoadingIndicator {
  const SmallLoadingIndicator({
    super.key,
    super.color,
  }) : super(size: LoadingSize.small);
}

class MediumLoadingIndicator extends LoadingIndicator {
  const MediumLoadingIndicator({
    super.key,
    super.color,
    super.message,
  }) : super(size: LoadingSize.medium);
}

class LargeLoadingIndicator extends LoadingIndicator {
  const LargeLoadingIndicator({
    super.key,
    super.color,
    super.message,
  }) : super(size: LoadingSize.large);
}

// Full screen loading overlay
class LoadingOverlay extends StatelessWidget {
  final String? message;
  final bool isVisible;

  const LoadingOverlay({
    super.key,
    this.message,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const LargeLoadingIndicator(),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(
                  message!,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Page loading state
class PageLoadingState extends StatelessWidget {
  final String? message;

  const PageLoadingState({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfacePrimary,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const LargeLoadingIndicator(),
              if (message != null) ...[
                const SizedBox(height: 24),
                Text(
                  message!,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Button loading state
class ButtonLoadingIndicator extends StatelessWidget {
  final Color? color;

  const ButtonLoadingIndicator({
    super.key,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      width: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? AppColors.white,
        ),
      ),
    );
  }
}

// List loading state
class ListLoadingState extends StatelessWidget {
  final int itemCount;

  const ListLoadingState({
    super.key,
    this.itemCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.gray200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.gray200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 14,
                        width: 120,
                        decoration: BoxDecoration(
                          color: AppColors.gray100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}