# Full-Stack Task Manager (.NET 10 API + Flutter MVVM App)

A full-stack, cross-platform Task Management application featuring a backend built with **.NET 10 REST API** and a multi-platform mobile/desktop client built with **Flutter** adhering to the **MVVM (Model-View-ViewModel)** architectural pattern.

---

flowchart TD
    subgraph Client["Flutter Client (MVVM)"]
        direction TB
        V["View (Widgets UI)"]
        VM["ViewModel (State & Logic)"]
        R["Repositories / Dio"]

        V -->|"User Actions / Reacts to State"| VM
        VM -->|"Calls API Service"| R
    end

    subgraph Backend[".NET 10 Backend API"]
        direction TB
        C["Controllers / Endpoints"]
        BL["Business / Domain Layer"]
        DB["EF Core / Database"]

        C -->|"Validates Input"| BL
        BL -->|"Calls Persistence"| DB
    end

    R <===>|"HTTP / REST (JSON)"| C   
                    


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
   ```
   cd backend/TaskManager.API
Restore NuGet dependencies:




dotnet restore
Update database or apply EF Core migrations (using In-Memory or PostgreSQL/SQL Server context):




dotnet ef database update
Run the API project:




dotnet run
By default, the API will run on http://localhost:5246.



2. Frontend Setup (Flutter Client)
Navigate to the frontend directory:




cd frontend/my_app
Fetch dependencies:




flutter pub get
Configure the backend API base URL in lib/core/config/api_config.dart or via a .env file:

Android Emulator: http://10.0.2.2:5246/api

iOS Simulator / Desktop: http://localhost:5246/api

Physical Device: http://<YOUR_LOCAL_IP>:5246/api

Launch the application:




# Run on default connected device / desktop
flutter run

# Explicitly run on desktop (Chrome)
flutter run -d chrome
📡 Endpoint Contracts & API Reference
Base URL
http://localhost:5246/api/v1

1. Get All Tasks
Retrieves a list of all existing tasks.

URL: /tasks

Method: GET

Response (200 OK):

JSON


[
  {
    "id": " ",
    "title": "Complete Task Manager App",
    "description": "Finish Flutter MVVM setup",
    "dueDate": "2026-10-01",
    "isCompleted": false
  }
]
2. Create Task
Creates a new task item with payload validation.

URL: /tasks

Method: POST

Request Body:

JSON


{
  "title": "Submit Project",
  "description": "Present to devs",
  "dueDate": "2026-09-05"
}
Response (201 Created):

JSON


{
  "id": " ",(auto incremented)
  "title": "Submit Project",
  "description": "Present solution to senior developers",
  "dueDate": "2026-09-05",
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
3. Update Task Status 


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
  "id": " ",
  "isCompleted": true
}
Response (404 Not Found):

JSON


{
  "type": "NotFound",
  "title": "Resource Not Found",
  "status": 404,
  "detail": "Task with ID ' ' was not found."
}
4. Delete Task
Deletes a task by ID.

URL: /tasks/{id}

Method: DELETE

Response: 204 No Content


### Direct Next Step
Save this content to `README.md` at the root of your project directory and commit it to git:
```
git add README.md
git commit -m "docs: add complete project README"
