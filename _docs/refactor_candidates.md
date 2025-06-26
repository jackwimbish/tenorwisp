# Frontend Refactoring Candidates

This document outlines several areas in the Flutter frontend codebase (`lib` folder) that are good candidates for refactoring. The primary theme across these candidates is the need to **separate business logic from UI code** by introducing a service layer and creating more focused, reusable widgets.

---

## 1. Introduce a Service Layer for Firebase Operations

A clear pattern across the codebase is the tight coupling of Firebase logic (Auth, Firestore, Storage) directly within `StatefulWidget` State classes. This makes widgets complex, hard to test, and difficult to maintain.

**Recommendation:** Create a dedicated service layer to handle all backend interactions. This could be structured as follows:

-   `lib/services/auth_service.dart`: Handles user authentication (sign up, login, logout).
-   `lib/services/user_service.dart`: Handles user profile management (updating username, photoURL, managing friends).
-   `lib/services/chat_service.dart`: Handles chat-related operations (sending messages, fetching chat streams).
-   `lib/services/storage_service.dart`: Handles file uploads to Firebase Storage.

This single change would simplify almost every screen in the application.

---

## 2. Refactor `registration_screen.dart` & `account_screen.dart`

### Why Refactor?

-   The `_register` function in `RegistrationScreen` is responsible for form validation, username uniqueness checks, creating an auth user, and setting up two different documents in Firestore via a batch write.
-   The `_updateUsername` function in `AccountScreen` is similarly complex, involving reads, writes, and deletes across multiple documents to ensure username uniqueness.
-   The `_pickAndUploadImage` function in `AccountScreen` mixes UI concerns (`ImagePicker`), storage logic (`FirebaseStorage`), and database updates (`Firestore`, `FirebaseAuth`).

### Proposed Changes

-   Move the registration logic into an `AuthService.signUp(email, password, username)` method.
-   Move the username update logic into a `UserService.updateUsername(newUsername)` method.
-   Move the profile picture update logic into a `UserService.updateProfilePicture(file)` method.
-   The widgets will then call these service methods, and the functions within the widgets' State classes will be reduced to a few lines for handling UI state (e.g., `_isLoading`) and navigation.

---

## 3. Refactor `friends_screen.dart` & `users_list_screen.dart`

### Why Refactor?

These screens fetch a list of user IDs and then use a `ListView.builder` with a nested `FutureBuilder` for each item in the list. This is highly inefficient.

-   **Performance:** It triggers a separate database read for every single user in the list, which doesn't scale.
-   **UI Experience:** It often leads to a "janky" UI where list items pop in one by one as their individual futures complete.

### Proposed Changes

-   Refactor the data fetching logic to use a single, efficient `whereIn` query.
-   First, fetch the list of friend/request IDs from the current user's document.
-   Then, use that list to perform a single query to get all the necessary user profiles at once:
    ```dart
    FirebaseFirestore.instance
        .collection('users')
        .where(FieldPath.documentId, whereIn: listOfFriendIds)
        .snapshots() 
    ```
-   This can be managed by a single `StreamBuilder` that drives the entire list, removing the need for nested `FutureBuilder`s and dramatically improving performance.
-   Additionally, the friend management logic (`_acceptFriendRequest`, `_declineFriendRequest`, `_sendFriendRequest`) should be moved into the `UserService`.

---

## 4. Refactor `chat_screen.dart`

### Why Refactor?

The `_ChatScreenState` is a "fat widget" that handles media picking, media uploading to Firebase Storage, and sending messages to Firestore. This mixes many distinct responsibilities. A bug was also found where `lastMessage` was being set twice with slightly different logic.

### Proposed Changes

-   Move the logic for sending messages (text, image, or video) into a `ChatService.sendMessage(...)` method. This method would also contain the corrected and consolidated logic for updating the `lastMessage` field on the chat document.
-   Move the media uploading logic to a `StorageService.uploadChatMedia(...)` method, which would return the `downloadUrl`.
-   The UI would then become a coordinator: call a media picker, pass the file to the storage service, and pass the resulting URL to the chat service.

---

## 5. Create Reusable, Focused Widgets

### Why Refactor?

Some widgets contain complex, but self-contained, logic that could be extracted to make them more reusable and the parent widget cleaner.

### Proposed Changes

1.  **`UserAvatar` Widget:**
    -   **Location:** `main_app_shell.dart`
    -   **Problem:** The `AppBar` contains a complex `StreamBuilder` with nested conditional logic to display a user's avatar from a normal `NetworkImage`, an SVG from `dicebear.com`, or a default icon.
    -   **Solution:** Create a `UserAvatar(userId)` widget that encapsulates this stream and rendering logic. The `AppBar` would then contain a clean, single-line widget.

2.  **`VideoPlayerWidget`:**
    -   **Location:** `chat_bubble.dart`
    -   **Problem:** `ChatBubble` is a `StatefulWidget` solely to manage the lifecycle of `VideoPlayerController` and `ChewieController`.
    -   **Solution:** Create a dedicated `VideoPlayerWidget(videoUrl)` that handles all the video player state management. `ChatBubble` can then become a `StatelessWidget`, and simply instantiate `VideoPlayerWidget` when it needs to display a video. 