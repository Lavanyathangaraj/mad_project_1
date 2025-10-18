import 'package:flutter/material.dart';
import '../services/db_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool otpSent = false;
  bool otpVerified = false;
  bool isLoading = false;
  String message = "";

  bool isValidGSUEmail(String email) {
    return email.endsWith('@gsu.edu') || email.endsWith('@student.gsu.edu');
  }

  Future<void> sendOTP() async {
    if (!isValidGSUEmail(emailController.text.trim())) {
      setState(() {
        message =
            "Enter a valid GSU email (must end with @gsu.edu or @student.gsu.edu).";
      });
      return;
    }

    setState(() {
      isLoading = true;
      message = "";
    });

    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      isLoading = false;
      otpSent = true;
      message = "OTP sent to your GSU email!";
    });
  }

  void verifyOTP() {
    if (otpController.text.trim() == "1234") {
      setState(() {
        otpVerified = true;
        message = "OTP verified successfully!";
      });
    } else {
      setState(() {
        message = "Invalid OTP. Try again.";
      });
    }
  }

  Future<void> storeUserData() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        message = "Please fill all fields.";
      });
      return;
    }

    try {
      await DatabaseHelper.instance.insertUser(email, password);
      setState(() {
        message = "Account created successfully!";
      });

      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushReplacementNamed(context, '/login');
      });
    } catch (e) {
      setState(() {
        message = "Error: This email may already exist.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sign Up"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            const Text(
              "Create Account (GSU Email Only)",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            // Email input
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "GSU Email",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),

            // Send OTP
            if (!otpSent)
              ElevatedButton(
                onPressed: isLoading ? null : sendOTP,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Send OTP"),
              ),

            // OTP input
            if (otpSent && !otpVerified) ...[
              const SizedBox(height: 20),
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Enter OTP",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: verifyOTP,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text("Verify OTP"),
              ),
            ],

            // Password setup
            if (otpVerified) ...[
              const SizedBox(height: 20),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Set Password",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: storeUserData,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text("Create Account"),
              ),
            ],

            const SizedBox(height: 25),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: message.contains("success") ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
