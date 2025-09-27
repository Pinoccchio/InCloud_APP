import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class BranchService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Get the default active branch
  static Future<BranchData?> getDefaultBranch() async {
    try {
      print('🏢 FETCHING DEFAULT BRANCH from database...');

      final response = await _client
          .from('branches')
          .select('id, name, address, contact_info')
          .eq('is_active', true)
          .limit(1)
          .maybeSingle();

      print('🔍 SUPABASE RESPONSE: $response');

      if (response != null) {
        print('✅ DEFAULT BRANCH FETCHED SUCCESSFULLY:');
        print('   ID: ${response['id']}');
        print('   Name: ${response['name']}');
        print('   Address: ${response['address']}');
        print('   Contact Info: ${response['contact_info']}');

        final branch = BranchData.fromJson(response);
        print('📦 PARSED BRANCH DATA: ${branch.toString()}');
        return branch;
      } else {
        print('⚠️ No active branch found in database - response was null');
        print('🔍 This could indicate:');
        print('   - No branches with is_active = true');
        print('   - RLS policy blocking access');
        print('   - Database connection issue');
        return null;
      }
    } on PostgrestException catch (e) {
      print('❌ POSTGREST ERROR FETCHING DEFAULT BRANCH:');
      print('   Code: ${e.code}');
      print('   Message: ${e.message}');
      print('   Details: ${e.details}');
      print('   Hint: ${e.hint}');
      debugPrint('Postgrest error: $e');
      return null;
    } catch (e, stackTrace) {
      print('❌ UNEXPECTED ERROR FETCHING DEFAULT BRANCH: $e');
      print('📋 STACK TRACE: $stackTrace');
      debugPrint('Branch fetch error: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  // Get all active branches (for future multi-branch support)
  static Future<List<BranchData>> getAllActiveBranches() async {
    try {
      print('🏢 FETCHING ALL ACTIVE BRANCHES...');

      final response = await _client
          .from('branches')
          .select('id, name, address, contact_info')
          .eq('is_active', true)
          .order('name');

      print('🔍 SUPABASE RESPONSE: $response');
      print('✅ FETCHED ${response.length} ACTIVE BRANCHES');

      if (response.isNotEmpty) {
        final branches = response.map<BranchData>((branch) => BranchData.fromJson(branch)).toList();
        print('📦 PARSED BRANCHES: ${branches.map((b) => b.name).join(', ')}');
        return branches;
      } else {
        print('⚠️ No active branches found in database');
        return [];
      }
    } on PostgrestException catch (e) {
      print('❌ POSTGREST ERROR FETCHING ACTIVE BRANCHES:');
      print('   Code: ${e.code}');
      print('   Message: ${e.message}');
      print('   Details: ${e.details}');
      print('   Hint: ${e.hint}');
      debugPrint('Postgrest error: $e');
      return [];
    } catch (e, stackTrace) {
      print('❌ UNEXPECTED ERROR FETCHING ACTIVE BRANCHES: $e');
      print('📋 STACK TRACE: $stackTrace');
      debugPrint('Branches fetch error: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }
}

// Branch data model
class BranchData {
  final String id;
  final String name;
  final String address;
  final Map<String, dynamic>? contactInfo;

  const BranchData({
    required this.id,
    required this.name,
    required this.address,
    this.contactInfo,
  });

  factory BranchData.fromJson(Map<String, dynamic> json) {
    return BranchData(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      contactInfo: json['contact_info'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'contact_info': contactInfo,
    };
  }

  // Get formatted display text
  String get displayText => '$name\n$address';

  // Get short location (just city/area from address)
  String get shortLocation {
    // Extract location from address (assumes format: "Main Office, Sampaloc, Manila, Philippines")
    final parts = address.split(',');
    if (parts.length >= 2) {
      return parts.sublist(1).join(',').trim(); // "Sampaloc, Manila, Philippines"
    }
    return address;
  }

  // Get contact email if available
  String? get email => contactInfo?['email'];

  // Get contact phone if available
  String? get phone => contactInfo?['phone'];

  // Get manager name if available
  String? get manager => contactInfo?['manager'];

  @override
  String toString() => 'BranchData(id: $id, name: $name, address: $address)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BranchData &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}