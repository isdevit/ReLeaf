import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final username = "Dan Smith"; // Replace with dynamic data later
    final greeting = getGreeting();

    final weeklyTasks = List.generate(10, (index) => "Use public transport");
    final dailyTasks = ["Do 10 pushups", "Complete 10000 steps"];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar with Greeting
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundImage: AssetImage('assets/images/avatar.png'),
                        radius: 22,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            greeting,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            username,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: const [
                      Icon(Icons.search, size: 24, color: Colors.black54),
                      SizedBox(width: 14),
                      Icon(Icons.notifications_none, size: 24, color: Colors.black54),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 24),

              // Weekly Tasks
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "My Weekly Tasks",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  Row(
                    children: const [
                      Icon(Icons.tune, size: 20),
                      SizedBox(width: 10),
                      Icon(Icons.add, size: 20),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "18 Tasks Pending",
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 210,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: weeklyTasks.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    return Container(
                      width: 200,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Chip(
                                label: Text("Environment"),
                                backgroundColor: Colors.purple[100],
                                labelStyle: const TextStyle(fontSize: 10),
                              ),
                              const SizedBox(width: 4),
                              Chip(
                                label: Text("High"),
                                backgroundColor: Colors.red[100],
                                labelStyle: const TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            weeklyTasks[index],
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: const [
                              CircleAvatar(radius: 10, backgroundColor: Colors.grey),
                              SizedBox(width: 4),
                              CircleAvatar(radius: 10, backgroundColor: Colors.grey),
                              SizedBox(width: 4),
                              Text("+3")
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: const [
                              Icon(Icons.calendar_today, size: 14, color: Colors.black45),
                              SizedBox(width: 4),
                              Text("Mon, 12 July 2025", style: TextStyle(fontSize: 12)),
                              Spacer(),
                              Icon(Icons.camera_alt, size: 20, color: Colors.green),
                            ],
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Today's Tasks
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Today's Tasks",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  Row(
                    children: const [
                      Icon(Icons.tune, size: 20),
                      SizedBox(width: 10),
                      Icon(Icons.add, size: 20),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "18 Tasks Pending",
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: dailyTasks.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F8E9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  dailyTasks[index],
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const Icon(Icons.check_circle, color: Colors.blue),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text("Indoor", style: TextStyle(fontSize: 12)),
                          const SizedBox(height: 10),
                          Row(
                            children: const [
                              Icon(Icons.calendar_today, size: 14, color: Colors.black45),
                              SizedBox(width: 4),
                              Text("Mon, 10 July 2025", style: TextStyle(fontSize: 12)),
                              Spacer(),
                              CircleAvatar(radius: 10, backgroundColor: Colors.grey),
                              SizedBox(width: 4),
                              CircleAvatar(radius: 10, backgroundColor: Colors.grey),
                              SizedBox(width: 4),
                              Text("+1")
                            ],
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return "Good Morning";
    } else if (hour < 17) {
      return "Good Afternoon";
    } else {
      return "Good Evening";
    }
  }
}
