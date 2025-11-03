import 'package:flutter/material.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'AgriChain',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'Welcome to AgriChain',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Select your role to get started',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 30),

              // ✅ Role Cards with Login Navigation
              AnimatedRoleCard(
                delay: 0,
                title: 'Farmer',
                description:
                    'Manage your farm\'s produce and track its journey.',
                imageUrl: 'assets/images/Farmer1.jpeg',
                onSelect: () {
                  Navigator.pushNamed(
                    context,
                    '/login',
                    arguments: 'Farmer',
                  );
                },
              ),
              AnimatedRoleCard(
                delay: 200,
                title: 'Distributor',
                description: 'Track and manage produce during transit.',
                imageUrl: 'assets/images/distributor1.jpeg',
                onSelect: () {
                  Navigator.pushNamed(
                    context,
                    '/login',
                    arguments: 'Distributor',
                  );
                },
              ),
              AnimatedRoleCard(
                delay: 400,
                title: 'Retailer',
                description: 'Verify the source and quality of your products.',
                imageUrl: 'assets/images/Retailer1.jpeg',
                onSelect: () {
                  Navigator.pushNamed(
                    context,
                    '/login',
                    arguments: 'Retailer',
                  );
                },
              ),
              AnimatedRoleCard(
                delay: 600,
                title: 'Consumer',
                description: 'Trace the origin and history of your food.',
                imageUrl: 'assets/images/Consumer1.jpeg',
                onSelect: () {
                  Navigator.pushNamed(
                    context,
                    '/login',
                    arguments: 'Consumer',
                  );
                },
              ),

              const SizedBox(height: 30),
              Center(
                child: Text(
                  'By continuing, you agree to our Terms of Service and Privacy Policy.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnimatedRoleCard extends StatefulWidget {
  final String title;
  final String description;
  final String imageUrl;
  final VoidCallback onSelect;
  final int delay;

  const AnimatedRoleCard({
    super.key,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.onSelect,
    this.delay = 0,
  });

  @override
  State<AnimatedRoleCard> createState() => _AnimatedRoleCardState();
}

class _AnimatedRoleCardState extends State<AnimatedRoleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: RoleCard(
          title: widget.title,
          description: widget.description,
          imageUrl: widget.imageUrl,
          onSelect: widget.onSelect,
        ),
      ),
    );
  }
}

class RoleCard extends StatelessWidget {
  final String title;
  final String description;
  final String imageUrl;
  final VoidCallback onSelect;

  const RoleCard({
    super.key,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
            child: imageUrl.startsWith('http')
                ? Image.network(
                    imageUrl,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Image.asset(
                    imageUrl,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: onSelect,
                    icon: const Icon(Icons.arrow_right_alt),
                    label: const Text('Select'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
