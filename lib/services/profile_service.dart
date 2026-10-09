import '../main.dart';
import '../models/models.dart';

class ProfileService {
  Future<Profile> getProfile(String userId) async {
    final res = await supabase.from('profiles').select().eq('id', userId).single();
    return Profile.fromMap(res);
  }

  Future<Profile> getMyProfile() => getProfile(supabase.auth.currentUser!.id);
}
