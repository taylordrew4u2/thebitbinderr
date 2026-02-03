# The Gym - Architecture & Flow Diagrams

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                       ContentView                            │
│                     (Launch Screen)                          │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
         ┌───────────────────────────┐
         │     MainTabView           │
         │   (6 Bottom Tabs)         │
         └─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬──┘
           │ │ │ │ │ │
        ┌──┘ │ │ │ │ └──────────────┐
        │    │ │ │ │                 │
      Home Jokes Sets Record Gym←NEW Notebook
                                     
                          ▼
                    ┌──────────────┐
                    │  GymView     │
                    │ (Homepage)   │
                    └──┬───────────┘
                       │
        ┌──────────────┼──────────────┐
        │              │              │
    Workouts      Completed      House Icon
                  Workouts       (Navigation)
        │              │
        ▼              ▼
  Workouts List   Completed List
        │              │
        ▼              ▼
  Config View    Detail View
        │
        ▼
  Execution View
        │
        └──────► (Auto-Save)
                 GymWorkout Model
                 (SwiftData)
```

---

## Data Model Relationships

```
┌────────────────────────────┐
│     GymWorkout             │
│  (SwiftData Model)         │
├────────────────────────────┤
│ • id: UUID                 │
│ • workoutType: enum        │
│ • topic: String            │
│ • outerQuestion: String    │
│ • entries: [String]        │
│ • dateStarted: Date        │
│ • dateCompleted: Date?     │
│ • sourceJokeId: UUID?      │──────┐
│ • isCompleted: Bool        │      │
│ • notes: String?           │      │
└────────────────────────────┘      │
                                    │
                    ┌───────────────┘
                    │
                    ▼
            ┌─────────────────┐
            │  Joke (existing)│
            │  (for reference)│
            └─────────────────┘
```

---

## Navigation Stack

```
MainTabView
    ↓
GymView (Homepage)
    ├─→ WorkoutsListView
    │       ↓
    │   WorkoutConfigView (Type-Specific)
    │       │
    │       ├─→ SelectJokeForTagStackingView
    │       │   (Tag Stacking only)
    │       │       ↓
    │       │   [Back to Config]
    │       │
    │       ↓
    │   WorkoutExecutionView
    │       │
    │       └─→ [Auto-Save to GymWorkout]
    │           └─→ GymWorkout Model
    │
    └─→ CompletedWorkoutsView
            ↓
        [Filtered List]
            │
            ├─→ CompletedWorkoutDetailView
            │       │
            │       └─→ [Save Entry to Jokes]
            │           └─→ New Joke Created
            │
            └─→ [Back to Gym]

House Icon (Navigation)
    └─→ Always returns to GymView
```

---

## Workout Type Configuration Flow

```
┌─────────────────────────────────────────────────────────────┐
│                  WorkoutType Selection                       │
└──┬────────────────────────┬────────────────────────────────┘
   │                        │
   │                        │
   ▼                        ▼
Premise Expansion      Observation Compression
   │                        │
   ├─ Topic Input           ├─ Random Paragraph
   │  (random/custom)       │  (or topic-based)
   │                        │
   └─→ 10 Reps             └─→ 1 Rep
       Punchlines              Condensed Line


Assumption Flips              Tag Stacking
   │                             │
   ├─ Belief Input              ├─ Select Existing Joke
   │                             │  (or type new)
   ├─ Auto-Generate Opposite    │
   │                             │
   └─→ 2 Reps                  └─→ 10 Reps
       (Belief + Opposite)          Tags
```

---

## Question Generation Flow

```
User Input or Selection
        │
        ▼
    Topic Selected
        │
        ├─────────────────────────────────┐
        │                                 │
        ▼                                 ▼
   Topic in Library          Topic NOT in Library
        │                                 │
        ├─────────────────────┬──────────┤
        │                     │          │
        ▼                     ▼          ▼
   Return            Generate from    Fallback
   Pre-built         Generic Template Generation
   Questions         
   (quality)         (custom)         (standard)
        │                     │          │
        └─────────────┬───────┴──────────┘
                      │
                      ▼
            User Selects Question
                      │
                      ▼
            WorkoutExecutionView
```

---

## Data Persistence Flow

```
User Types Response
        │
        ▼
"Add Response" Button
        │
        ▼
WorkoutExecutionView.addEntry()
        │
        ├─→ Append to entries array
        │
        └─→ workout.addEntry(entry)
                │
                ▼
        GymWorkout.addEntry()
        [Updates model]
                │
                ▼
        modelContext.save()
                │
                ▼
        SwiftData
        (Persistent Storage)
```

---

## Workout Completion Flow

```
User Finishes Workout
        │
        ├─ Enters all required reps
        │
        ├─ Clicks "Finish Workout"
        │
        ▼
WorkoutExecutionView.finishWorkout()
        │
        ├─→ workout.markComplete()
        │
        ├─→ Sets isCompleted = true
        │
        ├─→ Sets dateCompleted = now()
        │
        ├─→ modelContext.save()
        │
        ▼
Completion Alert
        │
        ├─ View Completed Workouts
        │
        └─ Done
        
[Workout now visible in CompletedWorkoutsView]
```

---

## Jokes Integration Flow

```
Completed Workout
        │
        ▼
CompletedWorkoutDetailView
        │
        ├─→ Display all entries
        │
        ├─ User taps "Save to Jokes"
        │   on specific entry
        │
        ▼
        │
        ├─→ Create new Joke object
        │
        ├─→ Set content = entry text
        │
        ├─→ Generate title from
        │   workout type + topic
        │
        └─→ modelContext.insert(newJoke)
                │
                ├─→ modelContext.save()
                │
                ▼
        New Joke in BitBinder
        (Available in JokesView)
```

---

## Component Hierarchy

```
GymView (Container)
├── VStack
    ├── Header Section
    │   ├── HStack
    │   │   ├── Image (dumbbell)
    │   │   ├── Image (microphone)
    │   │   └── Text ("TheBitBinder Gym")
    │   └── Text (subtitle)
    │
    └── MenuGrid
        ├── GymMenuCard
        │   ├── Icon
        │   ├── Title
        │   ├── Subtitle
        │   └── ChevronRight
        │
        └── GymMenuCard
            ├── Icon
            ├── Title
            ├── Subtitle
            └── ChevronRight

WorkoutExecutionView (Container)
├── VStack
    ├── Header
    │   ├── Workout title
    │   └── Progress bar
    │
    ├── ScrollView
    │   ├── Premise display
    │   ├── Instructions
    │   ├── TextEditor (input)
    │   ├── Add button
    │   └── Entries list
    │
    ├── Finish button
    │
    └── House icon (overlay)
```

---

## State Management

```
GymWorkout Model
├── @Model (SwiftData)
├── Observed by Views
└── Changes trigger UI updates

View State Variables
├── @State private var selectedTopic: String
├── @State private var selectedQuestion: String
├── @State private var entries: [String]
├── @State private var workout: GymWorkout?
└── @State private var showCompletionAlert: Bool

Environment Values
├── @Environment(\.modelContext)
├── @Environment(\.dismiss)
└── @Query (from SwiftData)

Navigation State
├── NavigationStack
├── NavigationLink (destination)
└── navigationBarBackButtonHidden()
```

---

## Event Flow Diagram

```
┌─────────────────────────────────────────────┐
│        User Taps Gym Tab                    │
└────────────────┬────────────────────────────┘
                 │
                 ▼
         ┌──────────────────┐
         │  GymView Loaded  │
         │  (Homepage)      │
         └────┬───────────┬─┘
              │           │
              ▼           ▼
         Workouts    Completed
              │           │
          ┌───┴───┐   ┌───┴────┐
          │       │   │        │
          ▼       ▼   ▼        ▼
        Type  Config  List   Detail
        List   View   View    View
          │       │   │        │
          └───────┴───┴────────┴──────→ [User Can Navigate]
                  │
                  ▼
        [Save Entry to Jokes]
                  │
                  ▼
        [Return to Main BitBinder]
```

---

## Outsider Question Examples by Topic

```
TV
├─ "Why do TVs still need remotes if they're 'smart'?"
├─ "Why is every TV louder than real life?"
└─ "Why does everyone fall asleep watching them but refuse to turn them off?"

Coffee
├─ "Why does burnt water cost $6?"
├─ "Why do people act addicted if it's just a drink?"
└─ "If pouring hot water on beans is fancy, what isn't?"

Smartphones
├─ "Why do phones break if you drop them one inch?"
├─ "Why can't the battery last a full day?"
└─ "Why does my phone know I'm thinking about something I never searched?"

Fitness
├─ "Why do people pay to sweat indoors?"
├─ "If it's healthy, why does it hurt so much?"
└─ "Why do people go to the gym to not use the equipment?"

Dating
├─ "Why is everyone on the same app looking for different things?"
├─ "Why do people lie about their height by three inches?"
└─ "Why does everyone say they want something serious on a dating app?"
```

---

## File Dependencies

```
thebitbinderApp.swift
├── imports GymWorkout (for SwiftData schema)
└── ModelContainer setup

ContentView.swift
├── imports GymView
└── Added to TabView

GymView.swift
├── imports WorkoutsListView
├── imports CompletedWorkoutsView
└── Container for Gym feature

WorkoutsListView.swift
└── imports WorkoutConfigView

WorkoutConfigView.swift
├── imports GymService
├── imports SelectJokeForTagStackingView
└── imports WorkoutExecutionView

WorkoutExecutionView.swift
├── imports GymWorkout
├── imports GymView (house nav)
└── Saves to modelContext

CompletedWorkoutsView.swift
├── @Query GymWorkout
├── imports CompletedWorkoutDetailView
└── imports GymView (house nav)

CompletedWorkoutDetailView.swift
├── imports Joke (for save)
├── @Query Joke
├── imports GymView (house nav)
└── Creates new Joke instances

SelectJokeForTagStackingView.swift
├── @Query Joke
└── Returns UUID to parent

GymService.swift
├── Standalone service
└── No imports needed
```

---

## Summary

The Gym is a complete, self-contained feature system with:
- Clear data flow
- Persistent storage
- Multiple workout types
- Flexible navigation
- Integration points
- All necessary components

Ready for production testing and deployment.
