import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class ImageGalleryWidget extends StatefulWidget {
  final List<String> images;
  final IconData fallbackIcon;
  final bool isFrozen;
  final double? height;
  final bool showIndicators;
  final bool showFrozenBadge;

  const ImageGalleryWidget({
    super.key,
    required this.images,
    required this.fallbackIcon,
    this.isFrozen = false,
    this.height,
    this.showIndicators = true,
    this.showFrozenBadge = true,
  });

  @override
  State<ImageGalleryWidget> createState() => _ImageGalleryWidgetState();
}

class _ImageGalleryWidgetState extends State<ImageGalleryWidget> {
  PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return _buildFallbackImage();
    }

    if (widget.images.length == 1) {
      return _buildSingleImage();
    }

    return _buildImageCarousel();
  }

  Widget _buildFallbackImage() {
    return Container(
      height: widget.height,
      width: double.infinity,
      color: AppColors.primaryBlue.withValues(alpha: 0.1),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.fallbackIcon,
                  color: AppColors.primaryBlue,
                  size: widget.height != null ? widget.height! * 0.3 : 80,
                ),
                const SizedBox(height: 12),
                Text(
                  'No Image Available',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (widget.isFrozen && widget.showFrozenBadge) _buildFrozenBadge(),
        ],
      ),
    );
  }

  Widget _buildSingleImage() {
    return Container(
      height: widget.height,
      width: double.infinity,
      child: Stack(
        children: [
          GestureDetector(
            onTap: () => _showFullScreenImage(0),
            child: Image.network(
              widget.images.first,
              fit: BoxFit.cover,
              width: double.infinity,
              height: widget.height,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: widget.height,
                  color: AppColors.surfacePrimary,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: widget.height,
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.fallbackIcon,
                        color: AppColors.primaryBlue,
                        size: widget.height != null ? widget.height! * 0.3 : 80,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Image Load Error',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (widget.isFrozen && widget.showFrozenBadge) _buildFrozenBadge(),
        ],
      ),
    );
  }

  Widget _buildImageCarousel() {
    return Container(
      height: widget.height,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _showFullScreenImage(index),
                child: Image.network(
                  widget.images[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: AppColors.surfacePrimary,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppColors.primaryBlue.withValues(alpha: 0.1),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            widget.fallbackIcon,
                            color: AppColors.primaryBlue,
                            size: widget.height != null ? widget.height! * 0.3 : 80,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Image ${index + 1} Load Error',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),

          // Image count indicator
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${_currentIndex + 1}/${widget.images.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Page indicators
          if (widget.showIndicators && widget.images.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.images.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == index
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),

          // Navigation arrows for large screens
          if (widget.images.length > 1 && widget.height != null && widget.height! > 200) ...[
            // Previous button
            Positioned(
              left: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _currentIndex > 0 ? _previousImage : null,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chevron_left,
                      color: _currentIndex > 0 ? Colors.white : Colors.white.withValues(alpha: 0.5),
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),

            // Next button
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _currentIndex < widget.images.length - 1 ? _nextImage : null,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chevron_right,
                      color: _currentIndex < widget.images.length - 1
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5),
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ],

          // Frozen badge
          if (widget.isFrozen && widget.showFrozenBadge) _buildFrozenBadge(),
        ],
      ),
    );
  }

  Widget _buildFrozenBadge() {
    return Positioned(
      top: 16,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.ac_unit,
              color: Colors.white,
              size: 14,
            ),
            SizedBox(width: 4),
            Text(
              'FROZEN',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _previousImage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextImage() {
    if (_currentIndex < widget.images.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showFullScreenImage(int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenImageGallery(
          images: widget.images,
          initialIndex: initialIndex,
          fallbackIcon: widget.fallbackIcon,
        ),
      ),
    );
  }
}

class FullScreenImageGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final IconData fallbackIcon;

  const FullScreenImageGallery({
    super.key,
    required this.images,
    required this.initialIndex,
    required this.fallbackIcon,
  });

  @override
  State<FullScreenImageGallery> createState() => _FullScreenImageGalleryState();
}

class _FullScreenImageGalleryState extends State<FullScreenImageGallery> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${_currentIndex + 1} of ${widget.images.length}',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemCount: widget.images.length,
        itemBuilder: (context, index) {
          return InteractiveViewer(
            child: Center(
              child: Image.network(
                widget.images[index],
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: Colors.white,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.fallbackIcon,
                          color: Colors.white,
                          size: 80,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Image Load Error',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}