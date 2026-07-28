import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/connectivity_provider.dart';

class NoInternetBannerWrapper extends StatelessWidget {
  final Widget child;

  const NoInternetBannerWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivity, _) {
        return Stack(
          children: [
            child,

            // No Internet Banner (Top Overlay)
            if (connectivity.isOffline)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Material(
                  elevation: 6,
                  color: Colors.transparent,
                  child: Container(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 8,
                      bottom: 10,
                      left: 16,
                      right: 16,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xffDC2626), // Modern crimson red
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.wifi_off_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "No Internet Connection",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                "Please check your network settings",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            connectivity.retryConnection();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.refresh_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),

                      ],
                    ),
                  ),
                ),
              ),

            // Back Online Banner
            if (connectivity.showBackOnlineBanner)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Material(
                  elevation: 6,
                  color: Colors.transparent,
                  child: Container(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 8,
                      bottom: 10,
                      left: 16,
                      right: 16,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xff16A34A), // Emerald green
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(16),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.wifi_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Back Online!",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
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
