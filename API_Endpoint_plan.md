# RaceDay - API Endpoint Plan

## Overview
This document outlines all RESTful API endpoints for the RaceDay event management system.

---

## 1. Authentication Endpoints

| HTTP Method | Route | Description | Role Required | Request Body | Expected Response |
|-------------|-------|-------------|---------------|--------------|-------------------|
| POST | /api/auth/register | Register a new user (Organiser or Participant) | Public | `{ "email": "user@email.com", "password": "Password123!", "fullName": "John Doe", "role": "Organiser", "organisationName": "My Club" }` | **201 Created** - Returns user object with JWT token<br>**400 Bad Request** - Email already exists or validation error |
| POST | /api/auth/login | Log in and receive authentication token | Public | `{ "email": "user@email.com", "password": "Password123!" }` | **200 OK** - Returns `{ token, user }`<br>**401 Unauthorized** - Invalid credentials |

---

## 2. User Profile Endpoints

| HTTP Method | Route | Description | Role Required | Request Body | Expected Response |
|-------------|-------|-------------|---------------|--------------|-------------------|
| GET | /api/users/profile | Get the logged-in user's profile | Any (Logged In) | None | **200 OK** - Returns User object with role-specific data<br>**401 Unauthorized** - Not logged in |
| PUT | /api/users/profile | Update the logged-in user's profile | Any (Logged In) | `{ "fullName": "John Smith", "profileImageUrl": "https://...jpg" }` | **200 OK** - Returns updated User object<br>**400 Bad Request** - Validation error |

---

## 3. Event Management Endpoints

| HTTP Method | Route | Description | Role Required | Request Body | Expected Response |
|-------------|-------|-------------|---------------|--------------|-------------------|
| GET | /api/events | Get all events with optional filtering | Any (Logged In) | None (Query: `?status=Open&type=Running`) | **200 OK** - Returns list of Event objects |
| GET | /api/events/{eventId} | Get details of a specific event | Any (Logged In) | None | **200 OK** - Returns Event object with categories<br>**404 Not Found** - Event does not exist |
| POST | /api/events | Create a new event | Organiser | `{ "name": "Durban 10km", "description": "Scenic run", "location": "Durban", "date": "2026-07-15T07:00:00", "entryFee": 150.00, "maxParticipants": 1000, "eventType": "Running", "status": "Open" }` | **201 Created** - Returns new Event object<br>**400 Bad Request** - Validation error<br>**403 Forbidden** - User is not an Organiser |
| PUT | /api/events/{eventId} | Update an existing event | Organiser (Owner) | `{ "name": "Durban 10km", "status": "Closed" }` | **200 OK** - Returns updated Event object<br>**403 Forbidden** - Not the owner<br>**404 Not Found** - Event does not exist |
| DELETE | /api/events/{eventId} | Delete an event | Organiser (Owner) | None | **204 No Content** - Successfully deleted<br>**403 Forbidden** - Not the owner<br>**404 Not Found** - Event does not exist |

---

## 4. Category Management Endpoints

| HTTP Method | Route | Description | Role Required | Request Body | Expected Response |
|-------------|-------|-------------|---------------|--------------|-------------------|
| POST | /api/events/{eventId}/categories | Add a category to an event | Organiser (Owner) | `{ "name": "10km Senior", "description": "For ages 18-39", "ageGroup": "Senior", "price": 150.00 }` | **201 Created** - Returns new Category object<br>**403 Forbidden** - Not the owner<br>**404 Not Found** - Event does not exist |
| PUT | /api/categories/{categoryId} | Update a category | Organiser (Event Owner) | `{ "name": "10km Junior", "price": 80.00 }` | **200 OK** - Returns updated Category object<br>**403 Forbidden** - Not the owner<br>**404 Not Found** - Category does not exist |
| DELETE | /api/categories/{categoryId} | Delete a category | Organiser (Event Owner) | None | **204 No Content** - Successfully deleted<br>**403 Forbidden** - Not the owner<br>**404 Not Found** - Category does not exist |

---

## 5. Event Enrolment Endpoints

| HTTP Method | Route | Description | Role Required | Request Body | Expected Response |
|-------------|-------|-------------|---------------|--------------|-------------------|
| GET | /api/events/{eventId}/enrolments | Get all enrolments for an event | Organiser (Owner) | None | **200 OK** - Returns list of Enrolment objects<br>**403 Forbidden** - Not the owner<br>**404 Not Found** - Event does not exist |
| GET | /api/participants/{participantId}/enrolments | Get all enrolments for a participant | Any (Logged In) | None | **200 OK** - Returns list of Enrolment objects<br>**403 Forbidden** - Accessing another user's data<br>**404 Not Found** - Participant does not exist |
| POST | /api/events/{eventId}/enrol | Enrol a participant in an event | Participant | `{ "categoryId": 1 }` | **201 Created** - Returns Enrolment object with RaceNumber<br>**400 Bad Request** - Event full, category invalid, or already enrolled<br>**404 Not Found** - Event does not exist |
| PUT | /api/enrolments/{enrolmentId}/payment | Update payment status | Participant | `{ "paymentStatus": "Paid" }` | **200 OK** - Returns updated Enrolment object<br>**403 Forbidden** - Not the enrollee<br>**404 Not Found** - Enrolment does not exist |
| DELETE | /api/enrolments/{enrolmentId} | Cancel/withdraw an enrolment | Participant | None | **204 No Content** - Successfully cancelled<br>**403 Forbidden** - Not the enrollee<br>**404 Not Found** - Enrolment does not exist |

---

## 6. Results Endpoints

| HTTP Method | Route | Description | Role Required | Request Body | Expected Response |
|-------------|-------|-------------|---------------|--------------|-------------------|
| POST | /api/enrolments/{enrolmentId}/results | Submit a result for an enrolment | Organiser (Event Owner) | `{ "finishTime": "00:45:23", "overallPosition": 15, "genderPosition": 3, "ageGroupPosition": "1", "status": "Finished" }` | **201 Created** - Returns new Result object<br>**400 Bad Request** - Validation error<br>**403 Forbidden** - Not the event owner<br>**404 Not Found** - Enrolment does not exist |
| PUT | /api/results/{resultId} | Update a result | Organiser (Event Owner) | `{ "finishTime": "00:44:50", "overallPosition": 12 }` | **200 OK** - Returns updated Result object<br>**403 Forbidden** - Not the event owner<br>**404 Not Found** - Result does not exist |
| GET | /api/events/{eventId}/results | Get all results for an event (leaderboard) | Any (Logged In) | None (Query: `?categoryId=1`) | **200 OK** - Returns list of Result objects with participant names<br>**404 Not Found** - Event does not exist |
| GET | /api/participants/{participantId}/history | Get a participant's race history | Any (Logged In) | None | **200 OK** - Returns list of Result objects with event details<br>**403 Forbidden** - Accessing another user's data<br>**404 Not Found** - Participant does not exist |

---

## 7. Weather Endpoints

| HTTP Method | Route | Description | Role Required | Request Body | Expected Response |
|-------------|-------|-------------|---------------|--------------|-------------------|
| GET | /api/events/{eventId}/weather | Get weather forecast for an event | Any (Logged In) | None | **200 OK** - Returns Weather object<br>**404 Not Found** - Event or weather data does not exist |
| POST | /api/events/{eventId}/weather | Add/update weather forecast | Organiser (Owner) | `{ "forecastDate": "2026-07-15T06:00:00", "temperature": "22°C", "condition": "Sunny", "windSpeed": "10 km/h", "humidity": "65%" }` | **201 Created** - Returns Weather object<br>**403 Forbidden** - Not the event owner<br>**404 Not Found** - Event does not exist |

---

## Summary Statistics

| Category | Number of Endpoints |
|----------|---------------------|
| Authentication | 2 |
| User Profile | 2 |
| Events | 5 |
| Categories | 3 |
| Enrolments | 5 |
| Results | 4 |
| Weather | 2 |
| **Total** | **23** |

---

## HTTP Status Codes Used

| Status Code | Meaning | When Used |
|-------------|---------|-----------|
| 200 OK | Success - returns data | GET and PUT requests that succeed |
| 201 Created | Success - resource created | POST requests that succeed |
| 204 No Content | Success - resource deleted | DELETE requests that succeed |
| 400 Bad Request | Validation error - invalid input | Invalid data sent to API |
| 401 Unauthorized | Not authenticated | User not logged in |
| 403 Forbidden | Not authorized | User logged in but wrong role/ownership |
| 404 Not Found | Resource does not exist | ID not found in database |
| 409 Conflict | Conflict (duplicate) | Email already exists, already enrolled |