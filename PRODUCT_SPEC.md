# Chapter Design Companion - Product Specification Document

**Version:** 1.0
**Last Updated:** January 2025
**Product Owner:** Chapter (hellochapter.com)
**Platform:** iOS (iPhone with LiDAR - iPhone 12 Pro and later)

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Product Overview](#product-overview)
3. [Core Features](#core-features)
4. [User Flows](#user-flows)
5. [Technical Architecture](#technical-architecture)
6. [Screen Specifications](#screen-specifications)
7. [Data Models](#data-models)
8. [API Integration](#api-integration)
9. [Design System](#design-system)
10. [Future Enhancements](#future-enhancements)

---

## Executive Summary

The Chapter Design Companion App is an iOS application that leverages Apple's LiDAR sensor and AI technology to generate personalized interior design concepts. Users scan their room, provide style preferences, and receive AI-generated design visualizations that respect the room's architectural features while applying modern design aesthetics.

**Key Value Proposition:**
- Instant room scanning using iPhone LiDAR
- AI-powered design generation
- Preservation of architectural features (windows, doors, dimensions)
- Shareable design reports with ratings

---

## Product Overview

### Target Users
- Homeowners planning renovations
- Renters looking to redesign their space
- Interior design enthusiasts
- Real estate agents showcasing potential

### Key Objectives
1. **Simplify Interior Design:** Make professional design concepts accessible to everyone
2. **Accurate Spatial Understanding:** Use LiDAR to capture exact room dimensions
3. **Personalization:** Allow users to express their style preferences
4. **Transparency:** Provide design rationale and build trust through reporting

### Platform Requirements
- **Device:** iPhone 12 Pro or later (LiDAR required)
- **OS:** iOS 16.0+
- **iOS 17.0+:** Enhanced room type auto-detection
- **Permissions:** Camera, Photos Library

---

## Core Features

### 1. LiDAR Room Scanning
**Description:** Capture accurate 3D room data using Apple's RoomPlan API.

**Capabilities:**
- Real-time room scanning with visual feedback
- Automatic detection of walls, windows, doors, and openings
- Spatial relationship mapping (which wall has which window)
- Dimension capture (width, height, depth, area)
- Room type auto-detection (iOS 17+)

**Output:**
- Room dimensions (meters)
- Floor area (square meters)
- Feature counts (windows, doors, walls, openings)
- Spatial layout with precise positioning
- 3D transform matrices for all surfaces

### 2. Room Type Detection & Manual Override
**Description:** Intelligent room type identification with user fallback.

**Auto-Detection (iOS 17+):**
- Living Room
- Bedroom
- Kitchen
- Bathroom
- Dining Room

**Fallback Logic (iOS 16 or detection failure):**
- Area < 8 sq m → Bathroom (inferred)
- Area 8-15 sq m → Bedroom (inferred)
- Area > 15 sq m → Living Room (inferred)

**User Override:**
- If auto-detection fails, user selects from dropdown
- Selection updates room description dynamically
- Prevents wasted scanning effort

### 3. Style Input & Preferences
**Description:** Multi-modal style input system.

**Input Methods:**
1. **Reference Photos** (up to 5)
   - Upload from camera roll
   - Displayed as grid thumbnails
   - Uploaded to Supabase Storage

2. **Reference URLs**
   - Pinterest, Instagram, Houzz, design blogs
   - Multiple links supported
   - Platform-specific icons (pin, camera, house)
   - Validated and formatted URLs

3. **Style Keywords**
   - Pre-defined tags: Modern, Minimalist, Scandinavian, Industrial, Bohemian, Farmhouse, Mid-Century, Traditional, Coastal
   - Multi-select support
   - Visual chip design

4. **User Vision (Text)**
   - Free-form text input
   - 5-10 line limit
   - Example: "I want a cozy reading corner with natural light..."

### 4. AI Design Generation
**Description:** Backend workflow processing using N8N automation.

**Processing Steps:**
1. Analyzing room dimensions
2. Processing style references
3. Extracting color palette
4. Generating design concepts
5. Rendering interior images

**Processing Time:** ~1-2 minutes

**Visual Feedback:**
- Animated progress dots (5 steps, 12s each)
- Encouraging message: "Great things take time ✨ This might take 1-2 minutes..."
- Step-by-step status updates
- Real-time polling for results

### 5. Design Results Display
**Description:** Image gallery with sharing capabilities.

**Features:**
- Grid layout (2 columns)
- Tap to view full-screen
- Swipeable image viewer
- Image count indicator
- Save to Photos (batch download)
- Share on social media
- Re-style same room option

**Actions:**
- View Design Report
- Save to Photos
- Share Images
- Re-Style This Room (preserves LiDAR data)

### 6. Design Report (NEW)
**Description:** Comprehensive design journey documentation with rating system.

**Report Sections:**

**a) Room Analysis**
- Room type (Living Room, Bedroom, etc.)
- Dimensions (W × D × H in meters)
- Floor area (square meters)
- Features (window/door counts)

**b) Your Vision**
- User's free-form design thoughts
- Displayed in styled quote box

**c) Style Keywords**
- Visual tag display
- Color-coded chips

**d) Your Inspiration**
- Reference image thumbnails (up to 6 shown)
- Image count summary
- URL count summary

**e) Why This Design?**
- AI-generated design rationale
- Explains design decisions
- References room features, style preferences
- Natural language explanation

**f) Rate Your Experience**
- 5-star rating system
- Optional feedback text field
- Submit to analytics
- Thank you confirmation

**Sharing:**
- Render entire report as high-resolution image
- Share via social media, email, messaging
- Includes "Generated with ❤️ by Chapter" branding

### 7. Navigation & Flow Control
**Description:** Streamlined navigation preventing confusion.

**Navigation Rules:**
- Home screen: No back button (root)
- Results screen: No back button (prevents returning to processing)
- Processing screen: Back button hidden during active processing
- Style Input (from Results): Back button hidden, "New Scan" button provided

**Flow Controls:**
- "Re-Style This Room" → Returns to Style Input with same LiDAR data
- "New Scan" → Returns to Home to start fresh
- "Generate Design" → Proceeds to processing
- "View Design Report" → Opens report modal

---

## User Flows

### Primary Flow: First-Time User

```
1. Launch App
   ↓
2. Home Screen (ContentView)
   - See app introduction
   - Read feature highlights
   - Tap "Start Your Design Journey"
   ↓
3. Room Scan View
   - Grant camera permission
   - Read scanning instructions
   - Tap "Start Room Scan"
   ↓
4. RoomPlan Scanner (Modal)
   - Scan room by moving iPhone
   - Capture walls, windows, doors
   - Tap "Done" when complete
   ↓
5. Room Scan Summary
   - Review detected room type
   - OR select room type if not detected
   - Review dimensions and features
   - Tap "Let's Style This Room"
   ↓
6. Style Input View
   - Add reference photos (optional)
   - Add reference URLs (optional)
   - Select style keywords (optional)
   - Write vision/thoughts (optional)
   - Tap "Generate Design"
   ↓
7. Processing View
   - Watch progress animation
   - Read encouraging messages
   - Wait 1-2 minutes
   - Auto-navigate when complete
   ↓
8. Results View
   - View generated designs in grid
   - Tap image to view full-screen
   - Tap "View Design Report"
   ↓
9. Design Report (Modal)
   - Review room analysis
   - See style summary
   - Read design rationale
   - Rate experience (1-5 stars)
   - Add feedback (optional)
   - Tap "Share This Report"
   - Tap "Done" to close
   ↓
10. Back to Results
    - Save images to Photos
    - Share designs on social media
    - Tap "Re-Style This Room" for variations
    - OR Tap "New Scan" button to start over
```

### Secondary Flow: Re-Styling

```
Results View
   ↓
Tap "Re-Style This Room"
   ↓
Style Input View (same LiDAR data)
   - Change style keywords
   - Add different references
   - Update vision
   - Tap "Generate Design"
   ↓
Processing → New Results
```

### Tertiary Flow: New Scan

```
Style Input View (after re-style)
   ↓
Tap "New Scan" (top-left)
   ↓
Returns to Home Screen
   ↓
Start fresh scan
```

---

## Technical Architecture

### Frontend: SwiftUI iOS App

**Architecture Pattern:** MVVM (Model-View-ViewModel)

**Key Technologies:**
- **SwiftUI:** UI framework
- **RoomPlan API:** LiDAR scanning (iOS 16+)
- **Combine:** Reactive programming
- **URLSession:** Network requests
- **PhotosUI:** Image picker
- **ImageRenderer:** Report sharing

**App Structure:**
```
DesignCompanionApp/
├── DesignCompanionAppApp.swift      # App entry point
├── ContentView.swift                 # Home/landing screen
├── RoomPlanScannerView.swift        # LiDAR scanning
├── StyleInputView.swift             # Style preferences input
├── ProcessingView.swift             # Processing animation
├── ResultsView.swift                # Design results gallery
├── DesignReportView.swift           # Design report & rating
├── Models.swift                     # Data models
├── APIService.swift                 # Backend communication
├── Config.swift                     # Configuration
├── ChapterColors.swift              # Design system
└── Assets.xcassets/                 # Images & icons
```

### Backend: N8N Workflow Automation

**Workflow Steps:**
1. **Webhook Receiver:** Accept POST from iOS app
2. **Image Processing:** Download reference images
3. **LLM Processing:** Generate design prompts using spatial data
4. **Image Generation:** Call Gemini/Imagen API
5. **Storage:** Upload to Supabase Storage
6. **Database Update:** Write results to Supabase

**Endpoints:**
- **Webhook URL:** `https://chapterdesignapp.app.n8n.cloud/webhook/[id]`
- **Test Webhook:** `https://chapterdesignapp.app.n8n.cloud/webhook-test/[id]`

### Database: Supabase PostgreSQL

**Tables:**

**1. design_requests**
```sql
{
  id: UUID (primary key),
  lidar_data: JSONB,
  style_reference: JSONB,
  timestamp: TIMESTAMP,
  user_id: TEXT (nullable)
}
```

**2. design_responses**
```sql
{
  id: UUID (primary key),
  request_id: UUID (foreign key),
  generated_images: TEXT[] (array of URLs),
  status: ENUM (queued, processing, completed, failed),
  created_at: TIMESTAMP,
  completed_at: TIMESTAMP (nullable),
  error: TEXT (nullable)
}
```

### Storage: Supabase Storage

**Buckets:**
- `reference-images/` - User-uploaded reference photos
- `generated-images/` - AI-generated design images

**Access:** Public URLs

### API Communication Flow

```
iOS App → APIService.submitDesignRequest()
   ↓
1. Upload images to Supabase Storage
   ↓
2. Save request to design_requests table
   ↓
3. Trigger N8N webhook with payload
   ↓
N8N processes in background (~1-2 min)
   ↓
iOS App → APIService.checkProcessingStatus()
   (polls every 5 seconds)
   ↓
4. Query design_responses table
   ↓
5. Return results when status = 'completed'
```

---

## Screen Specifications

### 1. ContentView (Home Screen)

**Elements:**
- **Logo:** Chapter "C" icon (120×120, rounded rect, accent color)
- **Title:** "Chapter" (36pt, bold)
- **Tagline:** "Interior Design. Reimagined."
- **Subtitle:** "Transform your space with AI-powered design"
- **Feature Cards:** 3 rows
  - Room Setup (house icon)
  - AI Style Generation (wand icon)
  - Visual References (photo icon)
- **CTA Button:** "Start Your Design Journey"

**Colors:**
- Background: Cream
- Text: Dark charcoal
- Accent: Dark charcoal
- Cards: Light cream with border

**Navigation:**
- No back button
- Button → RoomScanView (iOS 16+) or StyleInputView (iOS < 16)

### 2. RoomScanView (Scanner Entry)

**Elements:**
- **Icon:** Viewfinder circle (60pt, accent color)
- **Title:** "Scan Your Room"
- **Subtitle:** "Use your iPhone's LiDAR to capture room dimensions"
- **Instructions Card:**
  1. Point your phone at room corners
  2. Move slowly around the room
  3. Capture all walls and openings
  4. Tap done when complete
- **Button:** "Start Room Scan" (accent color)

**Permissions:**
- Camera access required
- Shows permission dialog if not granted

**Scanner Modal:**
- Full-screen RoomPlan capture session
- Native iOS controls
- "Done" button when satisfied

### 3. RoomScanSummaryView

**Elements:**
- **Success Icon:** Green checkmark (60pt)
- **Title:** "Room Scan Complete!"
- **Subtitle:** "Here's what we discovered about your space"
- **Details Card:**
  - **Room Type:**
    - If auto-detected: Shows type + "Auto-detected ✓"
    - If inferred: Shows picker dropdown + "Please select your room type"
  - **Dimensions:** W × D × H meters
  - **Floor Area:** XX.X sq m
  - **Features:** X walls, X doors, X windows, X openings
- **Button:** "Let's Style This Room" (accent, paintbrush icon)

**Interaction:**
- Room type picker (if needed) updates in real-time
- Picker options: Living Room, Bedroom, Kitchen, Bathroom, Dining Room

### 4. StyleInputView

**Elements:**

**a) Photo Picker**
- Placeholder: Large card with photo icon
- Text: "Add Reference Photos" / "Tap to select up to 5 images"
- After selection: 3-column grid of thumbnails (80×80)

**b) Your Vision Card**
- Title: "Your Vision"
- Subtitle: "Describe your dream space, style preferences..."
- Text field: 5-10 lines, multiline
- Placeholder: "Example: I want a cozy reading corner..."

**c) Design Inspiration Links Card**
- Title: "Design Inspiration Links"
- Subtitle: "Add links from Pinterest, Instagram, Houzz..."
- Input: URL field with "Add" button
- Display: Chips showing platform icon + domain name
- Remove: X button on each chip

**d) Style Keywords Card**
- Title: "Style Keywords"
- Subtitle: "Select design styles that match your preferences"
- Grid: 3 columns of chips
- Selected: White text on accent background
- Unselected: Dark text on card background with border

**e) CTA Button**
- "Generate Design" (accent color, full-width)

**Navigation:**
- Back button (default) OR hidden with "New Scan" button (if from Results)

### 5. ProcessingView

**Elements:**
- **Spinner:** Animated progress (2× scale, accent color)
- **Title:** "Creating Your Design..."
- **Step Text:** "Analyzing room dimensions..." (changes every 12s)
- **Encouraging Message:** "Great things take time ✨ This might take 1-2 minutes..."
- **Progress Dots:** 5 circles (filled = completed, unfilled = pending)
- **Step Counter:** "Step X of 5"
- **Info Card:** Shows counts of references, links, keywords

**States:**
- Processing: Animated, no back button
- Completed: Shows success, "View Your Designs" button
- Error: Shows error icon, message, "Try Again" button

**Timing:**
- Step animation: 12 seconds per step
- Polling: Every 5 seconds
- Timeout: 5 minutes (60 polls)

### 6. ResultsView

**Elements:**
- **Title:** "Your AI Designs"
- **Grid:** 2-column layout, 150px height
- **Images:** Async loading with placeholder
- **Primary Button:** "View Design Report" (accent, doc icon)
- **Secondary Button:** "Save to Photos" (outlined, download icon)
- **Share Button:** Circle with share icon
- **Re-Style Button:** "Re-Style This Room" (outlined, full-width)

**Navigation:**
- No back button
- Tap image → Full-screen viewer
- Tap "View Design Report" → Opens modal

**Actions:**
- Save: Batch download to Photos
- Share: System share sheet
- Re-Style: Navigate to StyleInputView with same LiDAR

### 7. DesignReportView (Modal)

**Sections:**

**Header:**
- "Your Design Journey"
- "with Chapter"

**1. Room Analysis Card:**
- Icon: Ruler
- Room Type: "Living Room"
- Dimensions: "4.2m × 3.8m × 2.7m"
- Floor Area: "15.96 sq m"
- Features: "2 windows, 1 door"

**2. Your Vision Card** (if provided):
- Icon: Lightbulb
- User's text in quote style

**3. Style Keywords Card** (if provided):
- Icon: Tag
- Flow layout of chips

**4. Your Inspiration Card** (if provided):
- Icon: Photo grid
- 3-column grid (up to 6 images)
- Image/link counts

**5. Why This Design Card:**
- Icon: Sparkles
- AI-generated rationale text

**6. Rate Your Experience Card:**
- Icon: Star
- 5-star tap selector (yellow/gray)
- Feedback text field (optional)
- "Submit Feedback" button (disabled until rated)

**Actions:**
- Top-right: "Done" button
- Bottom: "Share This Report" button (renders as image)

**Sharing:**
- Generates 600px wide image
- Includes header, room analysis, keywords, rating
- "Generated with ❤️ by Chapter" footer

---

## Data Models

### LIDARData
```swift
struct LIDARData: Codable {
    let id: UUID
    let roomDimensions: RoomDimensions
    let pointCloud: [LIDARPoint]
    let timestamp: Date
    let roomType: String
    let roomFeatures: RoomFeatures
    let spatialLayout: RoomSpatialLayout?
}
```

### RoomDimensions
```swift
struct RoomDimensions: Codable {
    let width: Float       // meters
    let height: Float      // meters
    let depth: Float       // meters
    let area: Float        // square meters
}
```

### RoomFeatures
```swift
struct RoomFeatures: Codable {
    let walls: Int
    let doors: Int
    let windows: Int
    let openings: Int
}
```

### RoomSpatialLayout
```swift
struct RoomSpatialLayout: Codable {
    let walls: [WallLayout]
    let windows: [ElementLayout]
    let doors: [ElementLayout]
    let openings: [ElementLayout]
}

struct WallLayout: Codable {
    let id: String
    let orientation: String       // north, south, east, west
    let dimensions: SimpleDimensions
    let position: SimplePosition
    let attachedElements: [String] // IDs
}

struct ElementLayout: Codable {
    let id: String
    let type: String              // window, door, opening
    let dimensions: SimpleDimensions
    let wallId: String
    let positionOnWall: WallPosition
}

struct WallPosition: Codable {
    let fromLeft: Float
    let fromBottom: Float
    let normalizedX: Float        // 0.0 to 1.0
    let normalizedY: Float        // 0.0 to 1.0
}
```

### StyleReference
```swift
struct StyleReference: Codable {
    let images: [String]          // Supabase URLs
    let urls: [String]            // Pinterest, Instagram, etc.
    let styleKeywords: [String]
    let userThoughts: String?
}
```

### DesignRequest
```swift
struct DesignRequest: Codable {
    let id: UUID
    let lidarData: LIDARData
    let styleReference: StyleReference
    let timestamp: Date
    let userId: String?
}
```

### DesignResponse
```swift
struct DesignResponse: Codable {
    let id: String
    let requestId: String
    let generatedImages: [String]?  // URLs
    let status: ProcessingStatus
    let createdAt: Date
    let completedAt: Date?
    let error: String?
}

enum ProcessingStatus: String, Codable {
    case queued
    case processing
    case completed
    case failed
}
```

### RoomScanData
```swift
struct RoomScanData {
    let capturedRoom: CapturedRoom
    let dimensions: RoomDimensions
    var roomType: String                    // Mutable for user override
    let features: RoomFeatures
    let spatialData: RoomSpatialData
    let isRoomTypeAutoDetected: Bool        // Detection confidence
    var roomDescription: String             // Computed property
}
```

---

## API Integration

### Endpoints

**1. Supabase REST API**
- Base URL: `https://raxtpcmboalnjxbgpcez.supabase.co`
- Authentication: API Key (anon key)

**2. Supabase Storage API**
- Upload: `POST /storage/v1/object/{bucket}/{filename}`
- Public URL: `{base_url}/storage/v1/object/public/{bucket}/{filename}`

**3. N8N Webhook**
- Production: `https://chapterdesignapp.app.n8n.cloud/webhook/{id}`
- Test: `https://chapterdesignapp.app.n8n.cloud/webhook-test/{id}`

### Request Flow

**1. Submit Design Request**
```swift
func submitDesignRequest(
    lidarData: LIDARData,
    styleReference: StyleReference,
    referenceImages: [Data]
) async throws -> String
```

Steps:
1. Upload images to Supabase Storage
2. Update styleReference with image URLs
3. Save request to `design_requests` table
4. Trigger N8N webhook with payload
5. Return request ID

**2. Check Processing Status**
```swift
func checkProcessingStatus(requestId: String) async throws -> DesignResponse
```

Steps:
1. Query `design_responses` table
2. Filter by request_id
3. Order by created_at desc
4. Return latest response

**3. Polling Strategy**
- Interval: 5 seconds
- Max attempts: 60 (5 minutes timeout)
- Stops on: status = completed or failed

### Payload Structure

**N8N Webhook Payload:**
```json
{
  "requestId": "uuid-string",
  "lidarData": {
    "room_type": "living_room",
    "room_dimensions": {
      "width": 4.2,
      "height": 2.7,
      "depth": 3.8,
      "area": 15.96
    },
    "room_features": {
      "walls": 4,
      "doors": 1,
      "windows": 2,
      "openings": 0
    },
    "spatial_layout": {
      "walls": [...],
      "windows": [...],
      "doors": [...]
    }
  },
  "styleReference": {
    "images": ["https://..."],
    "urls": ["https://pinterest.com/..."],
    "style_keywords": ["Modern", "Minimalist"],
    "user_thoughts": "I want a cozy reading corner..."
  },
  "timestamp": "2025-01-11T12:00:00Z"
}
```

### System Message for LLM

The N8N workflow uses this system message to generate design prompts:

```
You are an advanced AI prompt generator for an interior design RENOVATION workflow...

CRITICAL RULES FOR WINDOWS AND DOORS:
1. Windows MUST remain on their original walls
2. Window sizes MUST match the LiDAR data
3. Window positions MUST be preserved
4. DO NOT add windows to walls that don't have them
5. DO NOT enlarge or shrink windows
6. DO NOT move windows to opposite or different walls

[Full system message in workflow configuration]
```

---

## Design System

### Color Palette

**Brand Colors:**
```swift
Primary (Dark Charcoal):  #231f20
Cream Background:         #F8F6F2
Light Cream:              #FCFBF9
Warm Gray:                #87827D
Soft Gray:                #B4AFAA
Border:                   #DCD7D2
```

**Status Colors:**
```swift
Success (Muted Green):    #4C7D5F
Error (Muted Red):        #A05A50
```

### Typography

**Font Family:** San Francisco (iOS System Font)

**Sizes:**
- Large Title: 36pt, bold
- Title: 28pt, bold
- Title 2: 22pt, bold
- Title 3: 20pt, bold
- Headline: 17pt, semibold
- Body: 17pt, regular
- Subheadline: 15pt, regular
- Caption: 12pt, regular

### Spacing

**Padding:**
- Screen horizontal: 32px
- Card padding: 24px
- Section spacing: 20-30px
- Element spacing: 8-16px

**Corner Radius:**
- Buttons: 25px
- Cards: 15-20px
- Chips: 12-20px
- Images: 8-15px

### Components

**Button Styles:**
- Primary: White text on accent, 25px radius
- Secondary: Accent text on card, 1px border, 25px radius
- Icon Button: Circle with 1px border

**Card Style:**
- Light cream background
- 1px border (subtle)
- 15-20px corner radius
- 20-24px padding

**Input Fields:**
- White background
- 1px border
- 8px corner radius
- 12px padding
- Accent tint color

---

## Future Enhancements

### Phase 2 Features

**1. User Accounts & History**
- Firebase/Supabase Auth
- Save design history
- Favorite designs
- Project folders

**2. AR Preview**
- ARKit integration
- View designs in actual room
- Furniture placement
- Walk-through mode

**3. Shopping Integration**
- Product recommendations
- Direct purchase links
- Price estimates
- Save to wishlist

**4. Professional Consultation**
- Book designer appointments
- Live chat support
- Video consultations
- Custom design packages

**5. Social Features**
- Share to community
- Like/comment on designs
- Follow designers
- Design challenges

### Technical Improvements

**1. Offline Support**
- Cache previous designs
- Queue requests offline
- Sync when online

**2. Performance Optimization**
- Image compression
- Lazy loading
- Background processing
- Reduced polling

**3. Analytics**
- User behavior tracking
- Design preferences
- Conversion funnels
- A/B testing

**4. Advanced AI**
- Multiple design variations
- Style mixing
- Custom color palettes
- Material suggestions

---

## Appendix

### Configuration

**Config.swift:**
```swift
struct Config {
    static let mockMode = false
    static let demoMode = false

    struct Supabase {
        static let url = "https://raxtpcmboalnjxbgpcez.supabase.co"
        static let anonKey = "..."
    }

    struct N8N {
        static let webhookURL = "production-url"
        static let testWebhookURL = "test-url"
        static let currentWebhookURL = webhookURL
    }

    struct Storage {
        static let referenceBucket = "reference-images"
        static let generatedBucket = "generated-images"
    }
}
```

### Error Handling

**Error Types:**
```swift
enum APIError: Error {
    case saveFailed
    case networkError
    case processingFailed
    case uploadFailed
    case invalidResponse
    case invalidData
}
```

**User-Facing Messages:**
- Network error: "Unable to connect. Please check your internet connection."
- Processing failed: "Design generation failed. Please try again."
- Upload failed: "Unable to upload images. Please try again."
- Timeout: "Processing is taking longer than expected. Your design will be ready soon."

### Testing Modes

**Demo Mode:**
- Skip API calls
- Use sample images from Unsplash
- Instant results
- Test UI/UX without backend

**Mock Mode:**
- Simulated LiDAR data
- Mock API responses
- Predictable behavior
- Unit testing support

---

## Document History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | Jan 2025 | Initial specification | Chapter Team |

---

**Contact:**
For questions or updates, contact: hello@hellochapter.com

**Repository:**
https://github.com/swathi-hellochapter/Design-Companion-App
