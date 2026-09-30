# Full-Stack Task Manager (.NET 10 API + Flutter MVVM App)

A full-stack, cross-platform Task Management application featuring a backend built with **.NET 10 REST API** and a multi-platform mobile/desktop client built with **Flutter** adhering to the **MVVM (Model-View-ViewModel)** architectural pattern.

---

## 🏗️ Architecture Overview

The system follows a clean, decoupled client-server architecture:

[ Flutter Client ]                            [ .NET 10 Backend API ]
┌────────────────────────┐                    ┌─────────────────────────┐
│ View (Widgets UI)      │                    │ Controllers / Endpoints │
└───────────┬────────────┘                    └────────────┬────────────┘
│ Reacts to State                              │ Validates Input
▼                                              ▼
┌────────────────────────┐                    ┌─────────────────────────┐
│ ViewModel (Logic)      │                    │ Business / Domain Layer │
└───────────┬────────────┘                    └────────────┬────────────┘
│ Calls Service                                │ Calls Persistence
▼                                              ▼
┌────────────────────────┐    HTTP / JSON     ┌─────────────────────────┐
│ Repositories / Dio     │ ◄────────────────► │ EF Core / Database      │
└────────────────────────┘                    └─────────────────────────┘


### Layer Responsibilities
* **Flutter Client (MVVM):**
  * **View:** Pure declarative UI widgets. Contains no business logic or network code. Rebuilds reactively using `ListenableBuilder` / `ChangeNotifier`.
  * **ViewModel:** Manages screen states (`initial`, `loading`, `success`, `error`), captures user actions, and delegates network tasks.
  * **Repository Layer:** Encapsulates network operations, Dio/HTTP clients, secure token storage (`flutter_secure_storage`), and error mapping.
* **.NET 10 Backend API:**
  * **Controllers:** Expose RESTful endpoints, perform model validation via `FluentValidation`, and return structured DTOs.
  * **Middleware:** Global `IExceptionHandler` intercepts exceptions and formats responses into standard RFC 7807 `ProblemDetails`.
  * **Persistence:** Entity Framework Core handling data access and repository operations.

---

## 🚀 Setup & Execution Guide

### Prerequisites
* **Flutter SDK:** `>=3.19.0` (Dart `>=3.3.0`)
* **.NET SDK:** `10.0` or higher
* **IDE:** Visual Studio Code, Android Studio, or Visual Studio 2022+

---

### 1. Backend Setup (.NET 10 API)

1. Navigate to the backend directory:
   ```bash
   cd backend/TaskManager.API
Restore NuGet dependencies:

Bash


dotnet restore
Update database or apply EF Core migrations (using In-Memory or PostgreSQL/SQL Server context):

Bash


dotnet ef database update
Run the API project:

Bash


dotnet run
By default, the API will run on http://localhost:5246.

Open Swagger/OpenAPI documentation in browser: https://localhost:7123/swagger

2. Frontend Setup (Flutter Client)
Navigate to the frontend directory:

Bash


cd frontend/my_app
Fetch dependencies:

Bash


flutter pub get
Configure the backend API base URL in lib/core/config/api_config.dart or via a .env file:

Android Emulator: http://10.0.2.2:5246/api

iOS Simulator / Desktop: http://localhost:5246/api

Physical Device: http://<YOUR_LOCAL_IP>:5246/api

Launch the application:

Bash


# Run on default connected device / desktop
flutter run

# Explicitly run on desktop (macOS/Windows)
flutter run -d macos
flutter run -d windows
📡 Endpoint Contracts & API Reference
Base URL
http://localhost:5246/api/v1

1. Get All Tasks
Retrieves a list of all existing tasks.

URL: /tasks

Method: GET

Headers: Authorization: Bearer <token>

Response (200 OK):

JSON


[
  {
    "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    "title": "Complete Task Manager App",
    "description": "Finish Flutter MVVM setup and .NET 10 integration",
    "dueDate": "2026-10-01T12:00:00Z",
    "isCompleted": false
  }
]
2. Create Task
Creates a new task item with payload validation.

URL: /tasks

Method: POST

Headers:

Content-Type: application/json

Authorization: Bearer <token>

Request Body:

JSON


{
  "title": "Submit Project",
  "description": "Present solution to senior developers",
  "dueDate": "2026-10-05T09:00:00Z"
}
Response (201 Created):

JSON


{
  "id": "c39a04a1-8d2b-47e2-9b0d-13a52e691888",
  "title": "Submit Project",
  "description": "Present solution to senior developers",
  "dueDate": "2026-10-05T09:00:00Z",
  "isCompleted": false
}
Response (400 Bad Request - Validation Failure):

JSON


{
  "type": "[https://tools.ietf.org/html/rfc9110#section-15.5.1](https://tools.ietf.org/html/rfc9110#section-15.5.1)",
  "title": "One or more validation errors occurred.",
  "status": 400,
  "errors": {
    "Title": ["Task title is required."],
    "DueDate": ["Due date must be in the future."]
  }
}
3. Update Task Status (Toggle Completion)
Updates the completion status of an existing task.

URL: /tasks/{id}/status

Method: PATCH

Request Body:

JSON


{
  "isCompleted": true
}
Response (200 OK):

JSON


{
  "id": "c39a04a1-8d2b-47e2-9b0d-13a52e691888",
  "isCompleted": true
}
Response (404 Not Found):

JSON


{
  "type": "NotFound",
  "title": "Resource Not Found",
  "status": 404,
  "detail": "Task with ID 'c39a04a1-8d2b-47e2-9b0d-13a52e691888' was not found."
}
4. Delete Task
Deletes a task by ID.

URL: /tasks/{id}

Method: DELETE

Response: 204 No Content

🔒 Error Handling & Security
Token Storage: JWT tokens are stored on mobile devices using flutter_secure_storage (iOS Keychain & Android Keystore) to guarantee secure encrypted storage at rest.

Backend Exceptions: All unhandled exceptions in .NET are caught by custom global exception handling middleware and serialized into standard ProblemDetails payloads, preventing internal stack traces from leaking to public clients.


---

### Direct Next Step
Save this content to `README.md` at the root of your project directory and commit it to git:
```bash
git add README.md
git commit -m "docs: add complete project README with setup and endpoint contracts"