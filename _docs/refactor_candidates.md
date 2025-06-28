# Frontend Refactor Candidates

This document outlines potential refactoring opportunities within the Flutter frontend codebase. The goal of these suggestions is to improve code readability, maintainability, and testability by better separating concerns and breaking down complex widgets.

---

## 1. `submission_screen.dart`

The `SubmissionScreen` is a core feature but its implementation in a single `StatefulWidget` mixes UI, state management, and business logic (direct Firestore calls), making it complex and difficult to maintain.

### Why it needs refactoring:

-   **Tightly Coupled Logic:** The `_SubmissionScreenState` is directly responsible for making Firestore batch writes (`_submit`, `_withdrawSubmission`). This business logic is not reusable and makes the widget hard to test in isolation.
-   **Complex Widget Tree:** The `build` method contains a `StreamBuilder` that conditionally renders one of two different, non-trivial UI layouts (`_buildSubmissionForm` or `_buildSubmissionStatusView`). The status view contains *another* nested `StreamBuilder`, which can lead to confusing state management and rebuild cycles.
-   **Boilerplate State Management:** The loading state is managed via a simple boolean `_isLoading` and manual `setState` calls, which is repeated in every asynchronous action. This is error-prone and verbose.
-   **Repetitive UI Feedback:** `ScaffoldMessenger.of(context).showSnackBar(...)` calls are scattered within `try/catch` blocks, leading to code duplication for user feedback.

### Suggested Changes:

1.  **Introduce a `SubmissionService`:**
    -   Create a new file `lib/services/submission_service.dart`.
    -   Move all Firestore-related logic from `_SubmissionScreenState` into this new service.
    -   The service would expose methods like:
        ```dart
        Future<void> submitIdea(String text);
        Future<void> withdrawActiveSubmission();
        Stream<DocumentSnapshot> get liveSubmissionStream; // To check status
        ```
    -   The widget would then simply call these service methods, decoupling it from the database implementation.

2.  **Break Down Widgets:**
    -   Extract the UI for creating a submission into its own widget: `SubmissionCreationForm`. This widget would be stateless and take callbacks (`onSubmited`).
    -   Extract the UI for viewing an active submission into its own widget: `ActiveSubmissionView`. This widget would take the `submissionId` and be responsible for its own `StreamBuilder` to fetch and display the submission data.
    -   The main `SubmissionScreen`'s `build` method would become much simpler, primarily handling the logic to decide which of these two child widgets to show.

3.  **Centralize User Feedback:**
    -   Create a small UI helper utility that provides a method like `showAppSnackBar(BuildContext context, String message, {bool isError = false})`. This would centralize the look and feel of snackbars and reduce code duplication in the widgets.

---

## 2. `chat_screen.dart`

The `ChatScreen` is another feature-rich widget that would benefit from better separation of concerns. It currently manages service instantiation, complex media picking/uploading logic, and the chat UI all in one place.

### Why it needs refactoring:

-   **Direct Service Instantiation:** The widget creates its own instances of `ChatService`, `StorageService`, and `MediaService`. This makes the widget difficult to test, as you cannot easily provide mock implementations of these services.
-   **Business Logic in UI:** Complex workflows, like picking media (`_pickMedia`) and the multi-step process of uploading it with a placeholder message (`_uploadAndSendMedia`), are implemented directly in the `_ChatScreenState`. This logic is not part of the UI's responsibility.
-   **Monolithic Build Method:** The `build` method constructs the entire screen, including the message list and the message input bar. These are distinct components that could be separated.

### Suggested Changes:

1.  **Use Dependency Injection (DI):**
    -   Instead of the widget creating its own services, they should be provided to it. This could be done via a simple service locator (like `get_it`) or a more complete state management solution that supports DI (like `provider`).
    -   The widget would then retrieve its dependencies, e.g., `final chatService = getIt<ChatService>();`.

2.  **Move Business Logic to Services:**
    -   The logic in `_uploadAndSendMedia` is a prime candidate to be moved into the `ChatService`. The widget should only be responsible for getting a `File` object and calling a single method:
        ```dart
        // In ChatService
        Future<void> sendMediaMessage(String chatId, File file, bool isVideo);
        ```
    -   The service would handle creating the placeholder, uploading to storage, and updating the message status. This makes the logic reusable and keeps the widget clean.

3.  **Decompose the UI into Smaller Widgets:**
    -   **`MessageList` Widget:** The `StreamBuilder` and the `ListView.builder` that display the messages should be extracted into a `MessageList` widget. It would take the `chatId` as a parameter and handle its own data fetching and rendering.
    -   **`MessageInputBar` Widget:** The `Row` containing the `TextField` and `IconButton`s for sending messages and attaching files should be extracted into its own `MessageInputBar` widget. It would expose callbacks like `onSendMessage(String text)` and `onAttachFile()`.
    -   The `ChatScreen`'s `build` method would then simply be a `Column` containing the `Expanded(MessageList(...))` and `MessageInputBar(...)`. 