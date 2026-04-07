import 'package:flutter/material.dart';
import '../models/onboarding_model.dart';
import '../models/constants.dart';

class OnboardingPageWidget extends StatelessWidget {
  final OnboardingPageModel data;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final bool isLastPage;
  final int currentIndex;
  final int totalPages;

  const OnboardingPageWidget({
    super.key,
    required this.data,
    required this.onNext,
    required this.onSkip,
    required this.isLastPage,
    required this.currentIndex,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Top Glowing Illustration (Scaled to fill boundaries without black lines)
        Positioned(
          // Shift image 17 (index 1) up a little bit as requested
          top: currentIndex == 1 ? -60.0 : 0.0, 
          left: 0,
          right: 0,
          height: MediaQuery.of(context).size.height *
              0.65, // Extends deeper but scales perfectly
          child: Image.asset(
            data.imagePath,
            // Replaces contain with cover to completely cover the left and right black spaces!
            fit: BoxFit.cover,
            alignment: Alignment
                .topCenter, // Anchors the image high so the card doesn't cover its center
          ),
        ),

        // Bottom Rounded Container with Orange Stroke
        Positioned(
          bottom: isLastPage ? 52.0 : 74.0, // Reverted screen 1 & 2 to their original layout
          left: 20,
          right: 20,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              left: 24.0,
              right: 24.0,
              top: 28.0,
              bottom: 30.0, // Space below Next button
            ),
            decoration: BoxDecoration(
              color: FigmaColors.containerBg,
              borderRadius: BorderRadius.circular(18.0),
              border: Border.all(
                color: FigmaColors.containerBorder,
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Indicators inside the top of the container
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    totalPages,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      height: 4.0,
                      width: currentIndex == index ? 24.0 : 12.0,
                      decoration: BoxDecoration(
                        color: currentIndex == index
                            ? FigmaColors.activeIndicator
                            : FigmaColors.inactiveIndicator,
                        borderRadius: BorderRadius.circular(2.0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32.0),

                // Title
                Text(
                  data.title.toUpperCase(),
                  style: FigmaTypography.title,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16.0),

                // Fine line divider
                Container(
                  height: 1.0,
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 32.0),
                  color: FigmaColors.dividerLine,
                ),
                const SizedBox(height: 16.0),

                // Subtitle
                Text(
                  data.subtitle,
                  style: FigmaTypography.subtitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32.0),

                // Next Button
                SizedBox(
                  width: double.infinity,
                  height: 55.0, // Specific height from layout 311x55
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FigmaColors.nextBtnBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      elevation: 0,
                    ),
                    onPressed: onNext,
                    child: Text(
                      isLastPage ? 'Next' : 'Next',
                      style: FigmaTypography.nextButton,
                    ),
                  ),
                ),
                
                const SizedBox(height: 16.0), // Gap to finish the container properly
              ],
            ),
          ),
        ),

        // Skip Button - Dynamically switches layout depending on whether it's page 3 or page 1/2
        isLastPage
            // PAGE 3: The exact measurements explicitly extracted from Figma frame 3
            ? Positioned(
                bottom: 9.0,   // Exact constraint for page 3
                right: 27.0,   // Exact constraint for page 3
                child: SizedBox(
                   width: 102.0, 
                   height: 36.0, 
                   child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FigmaColors.skipBtnBg,
                      padding: EdgeInsets.zero, 
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11.0), 
                      ),
                      elevation: 0,
                    ),
                    onPressed: onSkip,
                    child: Text('Skip', style: FigmaTypography.skipButton),
                  ),
                ),
              )
            // PAGES 1 & 2: Restored to the previous universally acclaimed safe layout margins
            : Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 20.0, bottom: 20.0),
                  child: SizedBox(
                     height: 32, // Classic compact height
                     child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FigmaColors.skipBtnBg,
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        elevation: 0,
                      ),
                      onPressed: onSkip,
                      child: Text('Skip', style: FigmaTypography.skipButton),
                    ),
                  ),
                ),
              ),
      ],
    );
  }
}
