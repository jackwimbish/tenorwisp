# App Data Model Overview

This document outlines the data model for the application, using Google's Firestore as the database. The model is designed to support the core features: private user submissions, AI-powered topic generation, and public discussion threads, while ensuring data integrity and security.

---

## 1. `users` Collection

This collection stores information about each registered user. Its primary purpose is to manage user identity and link users to their current, active topic submission.

### Schema: `/users/{userId}`

A document in this collection uses the user's Firebase Authentication UID as its unique document ID.

| Field Name               | Data Type | Description                                                                                                                                                                           |
| ------------------------ | --------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `username`               | `string`  | The user's public display name.                                                                                                                                                       |
| `email`                  | `string`  | The user's registration email address.                                                                                                                                                |
| `photoURL`               | `string`  | A URL pointing to the user's profile picture.                                                                                                                                         |
| `live_submission_id`     | `string`  | **Crucial Field.** A reference to the document ID of the user's current, active submission in the `submissions` collection. This field is `null` if the user has no active submission. |
| `friends`                | `array`   | An array of strings, where each string is the UID of another user on their friends list. (Existing feature)                                                                           |
| `friendRequestsSent`     | `array`   | An array of UIDs for friend requests the user has sent. (Existing feature)                                                                                                            |
| `friendRequestsReceived` | `array`   | An array of UIDs for friend requests the user has received. (Existing feature)                                                                                                        |

### Example Document: `/users/E6ByTx25RvTmQ4EZgaJ2dMDtq8p2`

```json
{
  "username": "jack",
  "email": "wimbishjack@gmail.com",
  "photoURL": "https://api.dicebear.com/8.x/adventurer/svg?seed=...",
  "live_submission_id": "sub_doc_id_12345",
  "friends": ["5JfifYuQGxc8kAX6chRj1gx0Vek2"],
  "friendRequestsSent": [],
  "friendRequestsReceived": []
}
```

## 2. `submissions` Collection

This collection is the heart of the private submission system. It stores every topic idea submitted by users, tracking whether it is "live" (eligible for the next processing round) or "archived" (already processed).

### Schema: `/submissions/{submissionId}`

Documents in this collection have an auto-generated ID.

| Field Name       | Data Type   | Description                                                                                              |
| ---------------- | ----------- | -------------------------------------------------------------------------------------------------------- |
| `author_uid`     | `string`    | The UID of the user who created the submission. This is used for security rules to enforce ownership.   |
| `submissionText` | `string`    | The raw text content of the user's topic idea.                                                          |
| `status`         | `string`    | The current state of the submission. It can be either "live" or "archived". This is essential for filtering. |
| `createdAt`      | `timestamp` | The server timestamp for when the document was created.                                                 |
| `lastEdited`     | `timestamp` | The server timestamp for when the document was last modified by the user.                               |

### Example Document: `/submissions/sub_doc_id_12345`

```json
{
  "author_uid": "E6ByTx25RvTmQ4EZgaJ2dMDtq8p2",
  "submissionText": "I think we should discuss how advances in longevity will affect social structures like retirement and inheritance.",
  "status": "live",
  "createdAt": "June 27, 2025 at 2:05:15 PM UTC-5",
  "lastEdited": "June 27, 2025 at 2:10:00 PM UTC-5"
}
```

## 3. `public_threads` Collection

This collection holds the final, AI-generated discussion threads that are visible to all users in the app. Documents here are created exclusively by the backend server.

### Schema: `/public_threads/{threadId}`

Documents in this collection can have an auto-generated ID.

| Field Name      | Data Type   | Description                                                                                                    |
| --------------- | ----------- | -------------------------------------------------------------------------------------------------------------- |
| `title`         | `string`    | The concise, AI-generated topic title, framed as an open-ended question.                                      |
| `generatedAt`   | `timestamp` | The server timestamp for when the backend process created this thread. Used for sorting threads chronologically. |
| `cluster_topic` | `string`    | (Optional) A short keyword summary of the source cluster (e.g., "AI & Unemployment"). Useful for internal analytics. |

### Sub-collections

This document also contains a sub-collection for its posts:
- `/posts/`: A sub-collection containing the initial AI-generated post and all subsequent user-generated comments.

### Example Document: `/public_threads/thread_abc_987`

```json
{
  "title": "How can we ensure AI augments human creativity rather than replacing it?",
  "generatedAt": "June 28, 2025 at 12:01:00 AM UTC-5",
  "cluster_topic": "AI & Creative Professions"
}
```

## 4. `posts` Sub-collection (Updated for Prototype)

This is a sub-collection nested within each document in `public_threads`. For the prototype, it will contain a single initial AI-generated post and all subsequent user-generated comments.

### Schema: `/public_threads/{threadId}/posts/{postId}`

| Field Name          | Data Type   | Description                                                                                                    |
| ------------------- | ----------- | -------------------------------------------------------------------------------------------------------------- |
| `postText`          | `string`    | The text content of the post.                                                                                 |
| `author_uid`        | `string`    | The UID of the user who wrote the post. This is `null` for the initial, AI-generated post.                   |
| `author_username`   | `string`    | The display name of the author. For AI posts, this can be a placeholder like "Moderator" or "Thread Starter". |
| `author_photoURL`   | `string`    | A URL to the author's profile picture. A placeholder icon can be used for the AI.                            |
| `createdAt`         | `timestamp` | The server timestamp for when the post was created. This is used for sorting.                                |

### Example 1: AI-Generated Initial Post

```json
{
  "postText": "Let's start the discussion. Based on your collective thoughts, a key question is how we can ensure new technology empowers artists. What are your ideas?",
  "author_uid": null,
  "author_username": "Thread Starter",
  "author_photoURL": "url/to/your/app/ai_icon.svg",
  "createdAt": "June 28, 2025 at 12:01:05 AM UTC-5"
}
```

### Example 2: User-Generated Comment

```json
{
  "postText": "I think universal basic income for creatives could be one way to approach this. It would provide a safety net.",
  "author_uid": "5JfifYuQGxc8kAX6chRj1gx0Vek2",
  "author_username": "jane",
  "author_photoURL": "https://api.dicebear.com/8.x/adventurer/svg?seed=...",
  "createdAt": "June 28, 2025 at 12:15:30 AM UTC-5"
}
```