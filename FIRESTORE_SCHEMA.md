# Firestore Database Schema

This document details the complete Firestore schema for the Harsh Learning Management System.

## Collections Overview

```
firestore
├── users
├── courses
├── lectures
├── liveSessions
├── analytics
├── notificationRequests
└── scheduledNotifications
```

## Detailed Schema

### 1. users

Stores user profile and authentication information.

**Document ID**: `{userId}` (from Firebase Auth)

**Fields**:
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| email | string | Yes | User's email address |
| displayName | string | No | User's full name |
| photoUrl | string | No | Profile picture URL |
| role | string | Yes | User role: "student" or "admin" |
| createdAt | timestamp | Yes | Account creation timestamp |
| enrolledCourses | array<string> | Yes | List of course IDs user is enrolled in |
| fcmToken | string | No | Firebase Cloud Messaging token for push notifications |
| fcmTokenUpdatedAt | timestamp | No | When FCM token was last updated |

**Indexes**:
- `role` (ascending)
- `createdAt` (descending)

**Example Document**:
```json
{
  "email": "john.doe@example.com",
  "displayName": "John Doe",
  "photoUrl": "https://storage.googleapis.com/...",
  "role": "student",
  "createdAt": "2024-01-15T10:30:00Z",
  "enrolledCourses": ["course123", "course456"],
  "fcmToken": "fT_xM9...",
  "fcmTokenUpdatedAt": "2024-01-20T08:15:00Z"
}
```

---

### 2. courses

Stores course metadata and information.

**Document ID**: Auto-generated

**Fields**:
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| title | string | Yes | Course title |
| description | string | Yes | Course description |
| thumbnailUrl | string | No | Course thumbnail image URL |
| instructor | string | Yes | Instructor name |
| createdAt | timestamp | Yes | Course creation timestamp |
| updatedAt | timestamp | No | Last update timestamp |
| isPublished | boolean | Yes | Whether course is visible to students |
| pdfUrls | array<string> | Yes | List of PDF URLs for course materials |
| enrolledCount | number | Yes | Number of enrolled students |
| tags | array<string> | Yes | Course tags/categories |

**Indexes**:
- `isPublished` (ascending) + `createdAt` (descending)
- `tags` (array-contains) + `isPublished` (ascending)

**Example Document**:
```json
{
  "title": "Introduction to Flutter",
  "description": "Learn Flutter from scratch...",
  "thumbnailUrl": "https://storage.googleapis.com/.../thumbnail.jpg",
  "instructor": "Dr. Sarah Johnson",
  "createdAt": "2024-01-10T09:00:00Z",
  "updatedAt": "2024-01-20T14:30:00Z",
  "isPublished": true,
  "pdfUrls": [
    "https://storage.googleapis.com/.../chapter1.pdf",
    "https://storage.googleapis.com/.../chapter2.pdf"
  ],
  "enrolledCount": 127,
  "tags": ["Flutter", "Mobile Development", "Dart"]
}
```

---

### 3. lectures

Stores lecture metadata and video information.

**Document ID**: Auto-generated

**Fields**:
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| courseId | string | Yes | Reference to parent course |
| title | string | Yes | Lecture title |
| description | string | No | Lecture description |
| videoUrl | string | No | Video file URL (Firebase Storage) |
| thumbnailUrl | string | No | Video thumbnail URL |
| durationSeconds | number | Yes | Video duration in seconds |
| orderIndex | number | Yes | Order within course (0-indexed) |
| createdAt | timestamp | Yes | Creation timestamp |
| isPublished | boolean | Yes | Whether lecture is visible |
| type | string | Yes | "recorded" or "live" |

**Indexes**:
- `courseId` (ascending) + `orderIndex` (ascending)
- `courseId` (ascending) + `isPublished` (ascending) + `orderIndex` (ascending)

**Example Document**:
```json
{
  "courseId": "course123",
  "title": "Getting Started with Flutter",
  "description": "Introduction to Flutter framework...",
  "videoUrl": "https://storage.googleapis.com/.../lecture1.mp4",
  "thumbnailUrl": "https://storage.googleapis.com/.../thumb1.jpg",
  "durationSeconds": 1800,
  "orderIndex": 0,
  "createdAt": "2024-01-12T10:00:00Z",
  "isPublished": true,
  "type": "recorded"
}
```

---

### 4. liveSessions

Stores live class session information.

**Document ID**: Auto-generated

**Fields**:
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| courseId | string | Yes | Reference to parent course |
| title | string | Yes | Session title |
| scheduledAt | timestamp | Yes | Scheduled start time |
| startedAt | timestamp | No | Actual start time |
| endedAt | timestamp | No | Actual end time |
| channelName | string | Yes | Agora channel name |
| isActive | boolean | Yes | Whether session is currently live |
| recordingUrl | string | No | Recording URL (if recorded) |

**Indexes**:
- `courseId` (ascending) + `scheduledAt` (ascending)
- `isActive` (ascending) + `scheduledAt` (ascending)
- `scheduledAt` (ascending) where `scheduledAt > now()`

**Example Document**:
```json
{
  "courseId": "course123",
  "title": "Live Q&A: State Management",
  "scheduledAt": "2024-01-25T15:00:00Z",
  "startedAt": "2024-01-25T15:02:30Z",
  "endedAt": null,
  "channelName": "live_1706191200000",
  "isActive": true,
  "recordingUrl": null
}
```

---

### 5. analytics

Stores user engagement analytics events.

**Document ID**: Auto-generated

**Fields**:
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| eventName | string | Yes | Event type name |
| data | map | Yes | Event-specific data |
| timestamp | timestamp | Yes | When event occurred |

**Common Event Types**:
- `lecture_played`: User watched a lecture
- `pdf_viewed`: User opened a PDF
- `video_uploaded`: Admin uploaded video
- `pdf_uploaded`: Admin uploaded PDF
- `file_downloaded`: User downloaded file

**Indexes**:
- `eventName` (ascending) + `timestamp` (descending)
- `timestamp` (descending)

**Example Documents**:
```json
// lecture_played event
{
  "eventName": "lecture_played",
  "data": {
    "userId": "user123",
    "courseId": "course123",
    "lectureId": "lecture456"
  },
  "timestamp": "2024-01-20T16:45:00Z"
}

// pdf_viewed event
{
  "eventName": "pdf_viewed",
  "data": {
    "userId": "user123",
    "courseId": "course123",
    "pdfUrl": "https://storage.googleapis.com/.../chapter1.pdf"
  },
  "timestamp": "2024-01-20T17:10:00Z"
}
```

---

### 6. notificationRequests

Stores pending notification requests (processed by Cloud Functions).

**Document ID**: Auto-generated

**Fields**:
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| topic | string | Yes | FCM topic to send to |
| title | string | Yes | Notification title |
| body | string | Yes | Notification body |
| data | map | No | Additional data payload |
| createdAt | timestamp | Yes | Request creation time |
| status | string | Yes | "pending", "sent", or "failed" |

**Example Document**:
```json
{
  "topic": "course_course123",
  "title": "New Content Available",
  "body": "New lecture: Getting Started with Flutter",
  "data": {
    "type": "new_content",
    "courseId": "course123",
    "contentType": "lecture"
  },
  "createdAt": "2024-01-20T10:00:00Z",
  "status": "pending"
}
```

---

### 7. scheduledNotifications

Stores notifications to be sent at a specific time (processed by Cloud Functions).

**Document ID**: Auto-generated

**Fields**:
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| type | string | Yes | Notification type |
| courseId | string | Yes | Related course ID |
| title | string | Yes | Notification title |
| body | string | Yes | Notification body |
| scheduledAt | timestamp | Yes | When to send |
| status | string | Yes | "pending", "sent", or "cancelled" |

**Example Document**:
```json
{
  "type": "live_class_reminder",
  "courseId": "course123",
  "title": "Live Class Starting Soon",
  "body": "Live Q&A session starts in 10 minutes",
  "scheduledAt": "2024-01-25T14:50:00Z",
  "status": "pending"
}
```

---

## Security Rules Summary

### users
- **Read**: Any authenticated user
- **Create**: User can create their own document
- **Update**: User can update their own document, admins can update any
- **Delete**: Admin only

### courses
- **Read**: Authenticated users can read published courses, admins can read all
- **Write**: Admin only

### lectures
- **Read**: Authenticated users can read published lectures, admins can read all
- **Write**: Admin only

### liveSessions
- **Read**: Any authenticated user
- **Write**: Admin only

### analytics
- **Create**: Any authenticated user
- **Read**: Admin only
- **Update/Delete**: None

### notificationRequests & scheduledNotifications
- **Create**: Admin only
- **Read**: Admin only
- **Update**: Admin only (for status changes)
- **Delete**: None

---

## Relationships

```
courses (1) ─── (N) lectures
courses (1) ─── (N) liveSessions
users (N) ─── (M) courses (via enrolledCourses array)
```

---

## Storage Buckets Structure

```
gs://{project-id}.appspot.com
├── courses/
│   ├── {courseId}/
│   │   ├── pdfs/
│   │   │   └── {filename}.pdf
│   │   ├── videos/
│   │   │   └── {filename}.mp4
│   │   └── thumbnails/
│   │       └── {filename}.jpg
└── users/
    └── {userId}/
        └── profile/
            └── {filename}.jpg
```

---

## Required Indexes

These indexes must be created in Firestore:

```javascript
// courses
courses: {
  indexes: [
    { fields: ['isPublished', 'createdAt'], order: 'DESC' },
    { fields: ['tags', 'isPublished', 'createdAt'], order: 'DESC' }
  ]
}

// lectures
lectures: {
  indexes: [
    { fields: ['courseId', 'orderIndex'] },
    { fields: ['courseId', 'isPublished', 'orderIndex'] }
  ]
}

// liveSessions
liveSessions: {
  indexes: [
    { fields: ['courseId', 'scheduledAt'] },
    { fields: ['isActive', 'scheduledAt'] }
  ]
}

// analytics
analytics: {
  indexes: [
    { fields: ['eventName', 'timestamp'], order: 'DESC' },
    { fields: ['timestamp'], order: 'DESC' }
  ]
}
```

---

## Data Migration Notes

When migrating from another system:
1. User passwords cannot be migrated (require password reset)
2. Maintain original creation timestamps
3. Map old user IDs to new Firebase Auth UIDs
4. Batch write operations in groups of 500
5. Update enrolledCount after migrating enrollments

---

## Backup Strategy

Recommended backup approach:
- Daily automated Firestore exports to Cloud Storage
- Retention: 30 days
- Export collections: users, courses, lectures, liveSessions
- Don't backup: analytics (can be regenerated)

---

For implementation details, see `firebase_rules/firestore.rules`.
