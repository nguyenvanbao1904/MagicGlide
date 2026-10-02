# MagicGlide - Testing Documentation

## Overview

This document describes the testing strategy and implementation for the MagicGlide application. The test suite ensures the quality and reliability of tap detection, gesture processing, multi-finger detection, and architecture contracts.

## Test Architecture

The codebase is structured to isolate core gesture logic for maximum testability:

```
Sources/
├── Gestures/
│   ├── TapDetector.swift                 # Single-finger tap logic
│   ├── TwoFingerTapDetector.swift        # Two-finger tap & drag-lock logic
│   ├── ThreeFingerGestureDetector.swift  # Three-finger taps & continuous tab scrubbing
│   ├── PinchZoomDetector.swift           # Two-finger pinch zoom
│   ├── TwoFingerMoveZoomDetector.swift   # Two-finger move zoom
│   └── TwoFingerSwipeDetector.swift      # Two-finger swipes (Mission Control)
├── Actions/
│   ├── GestureAction.swift               # Action definitions & compatibility mapping
│   ├── GestureConfiguration.swift        # Slot binding model & persistence
│   └── GestureDispatcher.swift           # Event dispatch pipeline
└── Tests/
    ├── TapDetectorTests.swift                 # 22 unit tests
    ├── TwoFingerTapDetectorTests.swift        # 8 unit tests
    ├── ThreeFingerGestureDetectorTests.swift  # 8 unit tests
    └── GestureArchitectureTests.swift         # 13 unit tests
```

The pure-logic components run independently of system event taps and private frameworks, allowing instant, deterministic unit testing via Swift Package Manager.

## Running Tests

### Quick Start

```bash
# Run all tests (51 unit tests)
./Scripts/run_tests.sh
```

## Test Suites

### TapDetectorTests (22 tests)

Comprehensive unit tests for single-finger tap detection.

#### Basic Tap Detection (6 tests)
- ✅ `testValidTap_WithinTimeAndMovementThreshold` - Verifies valid taps are detected
- ✅ `testValidTap_NoMovement` - Tests stationary taps
- ✅ `testInvalidTap_ExceedsMovementThreshold` - Rejects taps with too much movement
- ✅ `testInvalidTap_ExceedsTimeThreshold` - Rejects taps that take too long
- ✅ `testTapAtBoundary_MovementThreshold` - Tests edge case at exact threshold
- ✅ `testTapJustOverBoundary_MovementThreshold` - Tests boundary precision

#### Touch Movement Detection (3 tests)
- ✅ `testTouchMoved_WithinThreshold` - Allows small movements during tap
- ✅ `testTouchMoved_ExceedsThreshold` - Cancels tap on large movement
- ✅ `testTouchMoved_AfterExceedingThreshold_ShouldInvalidateTap` - Ensures cancelled taps stay cancelled

#### State Management (4 tests)
- ✅ `testReset_ClearsTrackingState` - Verifies reset functionality
- ✅ `testTouchEnded_ResetsState` - Ensures state cleanup after tap
- ✅ `testIsTracking_InitiallyFalse` - Tests initial state
- ✅ `testIsTracking_TrueAfterTouchBegan` - Verifies tracking activation

#### Multiple Taps (2 tests)
- ✅ `testMultipleTaps_Sequential` - Tests rapid sequential taps
- ✅ `testInvalidTap_FollowedByValidTap` - Ensures failed taps don't affect subsequent taps

#### Edge Cases (3 tests)
- ✅ `testTouchEnded_WithoutTouchBegan` - Handles out-of-order events
- ✅ `testTouchMoved_WithoutTouchBegan` - Handles missing initialization
- ✅ `testMultipleTouchBegan_WithoutEnding` - Tests overwriting behavior

#### Custom Thresholds (3 tests)
- ✅ `testCustomThresholds_StrictTime` - Validates time threshold configuration
- ✅ `testCustomThresholds_StrictMovement` - Validates movement threshold configuration
- ✅ `testCustomThresholds_RelaxedThresholds` - Tests lenient settings

#### Performance (1 test)
- ✅ `testPerformance_RapidTaps` - Benchmarks 1000 rapid taps

---

### TwoFingerTapDetectorTests (8 tests)

Unit tests for multi-touch gesture processing, staggered landings, and drag-lock toggles.

- ✅ `testTwoFingerTap_WithStaggeredLandingAndLift_IsRecognized` - Accurately recognizes taps even when fingers do not land or lift in the exact same frame
- ✅ `testSingleFingerTap_IsNotClaimed` - Ensures single-finger touches are ignored by multi-touch detector
- ✅ `testTwoFingerTap_AtTimeThreshold_IsRejected` - Rejects touches exceeding duration threshold
- ✅ `testTwoFingerTap_WithTooMuchMovement_IsRejected` - Rejects scrolling or moving gestures
- ✅ `testThreeFingerGesture_IsRejected` - Prevents 3+ finger gestures from triggering drag lock
- ✅ `testTwoIdentifiersWithoutOverlap_AreRejected` - Rejects sequential distinct touches without simultaneous overlap
- ✅ `testResetClearsPartialGesture` - Verifies clean state reset
- ✅ `testInvalidGesture_DoesNotPoisonNextTap` - Ensures rejected gestures do not contaminate subsequent valid taps

## Test Results

```
Test Suite 'All tests' passed
  Executed 51 tests, with 0 failures (0 unexpected)
  Total duration: ~1.6 seconds

TapDetectorTests: 22/22 passed ✅
TwoFingerTapDetectorTests: 8/8 passed ✅
ThreeFingerGestureDetectorTests: 8/8 passed ✅
GestureArchitectureTests: 13/13 passed ✅
```

## Manual Testing Checklist

For features that interact with hardware, private frameworks, or the Window Server:

### Tap-to-Click
- [ ] App icon appears in menu bar
- [ ] Menu items respond to clicks
- [ ] Toggle updates menu item title and state
- [ ] Quit command terminates app
- [ ] Accessibility permission dialog appears when untrusted
- [ ] Tap left side of mouse triggers left-click
- [ ] Tap right side of mouse triggers right-click
- [ ] Right-click zone threshold adjusts in menu bar and persists

### Drag Lock
- [ ] Quick two-finger tap engages drag lock (status shows `Locked`)
- [ ] Moving mouse while drag lock is engaged drags windows/selection without keeping fingers on surface
- [ ] Moving mouse with fingers resting on surface does not accidentally release drag lock
- [ ] Second two-finger tap cleanly disengages drag lock (status shows `Unlocked`)
- [ ] Stationary one-finger tap cleanly releases an active drag lock without producing another click
- [ ] Disabling tap-to-click or quitting the app automatically releases an active drag lock
