# Project Tech Stack Overview

This document outlines the core technologies chosen for the development and deployment of the social discussion application prototype. The stack is designed for rapid development, scalability, and leveraging powerful AI capabilities.

## 1. Frontend: Mobile Application

### Framework: Flutter

**Reasoning:** Enables the rapid development of a high-performance, cross-platform mobile application for Android (and eventually iOS) from a single codebase. Its tight integration with Firebase is a key advantage.

## 2. Backend: Core Logic & API

### Language: Python

**Reasoning:** The definitive choice for machine learning and data science, providing access to an unparalleled ecosystem of AI/ML libraries.

### API Framework: FastAPI

**Reasoning:** A modern, high-performance Python web framework used to build the API that the Flutter app communicates with. It's fast, easy to use, and includes automatic API documentation.

## 3. Database & Core Services

### Platform: Google Firebase

- **Firebase Authentication:** Manages user sign-up, login, and identity, providing the secure foundation for user-specific permissions.
- **Cloud Firestore:** A flexible NoSQL database used as the primary data store for all user profiles, private submissions, and public threads. Its real-time capabilities are used to instantly update the Flutter UI when new content is generated.

## 4. Deployment & Hosting

### Platform: Railway

**Reasoning:** A modern, developer-friendly platform used to host the Python/FastAPI backend. It simplifies deployment by handling infrastructure automatically, providing a public URL, and managing environment variables for secrets like API keys.

## 5. Key AI/ML Libraries (Python Backend)

### Vectorization: `sentence-transformers`

**Reasoning:** A state-of-the-art library for converting user submission text into meaningful numerical vectors (embeddings) that capture semantic meaning.

### Clustering: `hdbscan`

**Reasoning:** A powerful, density-based clustering algorithm that can identify natural groupings of ideas without needing to pre-define the number of clusters. It's also excellent at filtering out irrelevant "noise."

### Generative AI: Google's Gemini API (or similar LLM)

**Reasoning:** Used to perform the final abstractive summarization step—synthesizing the core theme from each text cluster and generating a concise, human-readable discussion topic.