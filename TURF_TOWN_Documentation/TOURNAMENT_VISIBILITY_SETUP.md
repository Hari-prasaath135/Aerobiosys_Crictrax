# Tournament Visibility Setup - Make Tournaments Visible to All Users

## ✅ Changes Made

### 1. **Updated Tournament Model** (`tournament_model.dart`)
- ✅ Added `createdBy` field to track who created each tournament
- ✅ Updated all constructors and factory methods to include `createdBy`
- ✅ **Changed Firestore collection path from `/users/{uid}/tournaments/` to `/tournaments/`**
  - This makes tournaments **global** and visible to all users

### 2. **Updated Tournament Page** (`tournament_page.dart`)
- ✅ Added `createdBy: user.uid` when creating tournaments to track the organizer

---

## 📋 What You Need to Do

### **Step 1: Update Firestore Security Rules**

Go to Firebase Console → Firestore → Rules and update to:

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    // Everyone must be authenticated
    match /tournaments/{document=**} {
      // ✅ All authenticated users can READ all tournaments
      allow read: if request.auth != null;
      
      // ✅ Only the creator can CREATE, UPDATE, DELETE their own tournament
      allow create: if request.auth != null && 
                       request.resource.data.createdBy == request.auth.uid;
      
      allow update, delete: if request.auth != null && 
                               resource.data.createdBy == request.auth.uid;
    }

    // Keep existing user-related collections if any
    match /users/{uid}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
  }
}
```

**Key Points:**
- `allow read`: All authenticated users can view all tournaments
- `allow create`: Only logged-in users can create
- `allow update/delete`: Only the tournament creator (createdBy) can edit/delete

---

## 🔄 Migration (Optional but Recommended)

If you have existing tournaments in the old user-specific paths, you should migrate them to the new global collection:

### Via Firebase Console:
1. Go to Firestore → Collections → users → [userId] → tournaments
2. Copy each tournament document
3. Create new document in tournaments collection with the same ID
4. Add `createdBy` field with the user's UID
5. Delete old documents

### Via Code (Run once):
```dart
// Add this temporary migration code to your app
Future<void> migrateTournamentsToGlobal() async {
  final db = FirebaseFirestore.instance;
  final users = await db.collection('users').get();
  
  for (var userDoc in users.docs) {
    final tournaments = await userDoc.reference.collection('tournaments').get();
    
    for (var tourDoc in tournaments.docs) {
      final data = tourDoc.data();
      data['createdBy'] = userDoc.id;
      
      await db.collection('tournaments').doc(tourDoc.id).set(data);
      await tourDoc.reference.delete();
    }
  }
  
  print('✅ Migration complete!');
}
```

---

## 🎯 How It Works Now

1. **Any logged-in user can:**
   - ✅ View all tournaments created by any user
   - ✅ Create their own tournaments (marked with their `createdBy`)
   - ✅ Search and filter tournaments

2. **Only tournament creator can:**
   - ✅ Edit their tournament details
   - ✅ Delete their tournament

3. **Tournament visibility:**
   - ✅ Global `/tournaments` collection in Firestore
   - ✅ All users load from the same collection via `Tournament.getAll()`

---

## 📱 Testing

1. Create a tournament with **User A** → ✅ Should appear
2. Login as **User B** → ✅ Should see User A's tournament
3. Create another tournament with **User B** → ✅ Both tournaments visible to each user
4. Try to delete User A's tournament as User B → ❌ Should fail (only creator can delete)

---

## 🚀 Result

**Before:** Each user only saw their own tournaments
**After:** All users see ALL tournaments, but can only edit/delete their own

