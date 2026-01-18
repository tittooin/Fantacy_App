import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class LoadingSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final BoxShape shape;

  const LoadingSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
    this.shape = BoxShape.rectangle,
  });

  const LoadingSkeleton.circle({
    super.key,
    required double size,
  })  : width = size,
        height = size,
        borderRadius = size / 2,
        shape = BoxShape.circle;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: shape,
          borderRadius: shape == BoxShape.rectangle ? BorderRadius.circular(borderRadius) : null,
        ),
      ),
    );
  }
}

class MatchCardSkeleton extends StatelessWidget {
  const MatchCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               LoadingSkeleton(width: 120, height: 12),
               LoadingSkeleton(width: 50, height: 16, borderRadius: 12),
            ],
          ),
          SizedBox(height: 24),
          
          // Teams
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Team 1
              Row(
                children: [
                  LoadingSkeleton.circle(size: 48),
                  SizedBox(width: 12),
                  LoadingSkeleton(width: 40, height: 20),
                ],
              ),
              
              // VS & Date
              Column(
                children: [
                   LoadingSkeleton(width: 20, height: 12),
                   SizedBox(height: 8),
                   LoadingSkeleton(width: 60, height: 10),
                ],
              ),

              // Team 2
              Row(
                children: [
                  LoadingSkeleton(width: 40, height: 20),
                  SizedBox(width: 12),
                  LoadingSkeleton.circle(size: 48),
                ],
              ),
            ],
          ),
          
          Padding(
             padding: EdgeInsets.symmetric(vertical: 16),
             child: LoadingSkeleton(width: double.infinity, height: 1), 
          ),

          // Footer
          Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               LoadingSkeleton(width: 100, height: 14),
               LoadingSkeleton(width: 60, height: 12),
             ],
          )
        ],
      ),
    );
  }
}
