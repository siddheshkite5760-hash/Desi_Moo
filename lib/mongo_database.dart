import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter/material.dart';

class MongoDatabase {
  static late Db db;
  static late DbCollection userCollection;
  static late DbCollection cattleCollection; // <-- Added this collection

  // ⚠️ Note: Be careful committing this file to public GitHub repos with your password exposed!
  static const String mongoConnUrl = "mongodb+srv://Siddhesh_1123:Ssk1123@cluster0.qlmzzkp.mongodb.net/DesiMoo?appName=Cluster0";

  static Future<void> connect() async {
    try {
      db = await Db.create(mongoConnUrl);
      await db.open();
      userCollection = db.collection("users");
      cattleCollection = db.collection("cattle"); // <-- Initialized it here
      debugPrint("✅ Connected to MongoDB Atlas successfully!");
    } catch (e) {
      debugPrint("❌ Error connecting to MongoDB: $e");
    }
  }

  // Handle Sign Up
  static Future<String> registerUser(String name, String id, String password, bool isAdmin) async {
    try {
      // Check if user already exists
      var existingUser = await userCollection.findOne({"id": id});
      if (existingUser != null) {
        return "User ID already exists.";
      }

      // Insert new user
      await userCollection.insert({
        "name": name,
        "id": id,
        "password": password,
        "isAdmin": isAdmin,
        "createdAt": DateTime.now().toIso8601String(),
      });
      return "Success";
    } catch (e) {
      return "Database Error: $e";
    }
  }

  // Handle Login
  static Future<bool> loginUser(String id, String password, bool isAdmin) async {
    try {
      var user = await userCollection.findOne({
        "id": id,
        "password": password,
        "isAdmin": isAdmin
      });
      return user != null; // Returns true if it found a matching user
    } catch (e) {
      debugPrint("Login Error: $e");
      return false;
    }
  }

  // --- NEW: PASHU AADHAAR CHECK-BEFORE-INSERT ---
  static Future<Map<String, dynamic>> registerCattleSafe(String pashuId, String farmerId, String breed) async {
    try {
      // 1. Check if the 12-digit UID already exists in the 'cattle' collection
      var existingRecord = await cattleCollection.findOne({"_id": pashuId});

      if (existingRecord != null) {
        return {
          "success": false,
          "message": "Registration Denied: Cattle UID $pashuId is already registered."
        };
      }

      // 2. Insert new cattle record linked to the farmer's Aadhaar
      await cattleCollection.insert({
        "_id": pashuId,
        "owner_aadhaar_ref": farmerId,
        "breed": breed,
        "registration_date": DateTime.now().toIso8601String(),
      });

      return {
        "success": true,
        "message": "Success! Cattle securely linked to Farmer."
      };
    } catch (e) {
      debugPrint("Database Error: $e");
      return {"success": false, "message": "Database Error occurred."};
    }
  }
}