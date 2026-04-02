# Fighting Vipers Fan Remake (Prototype)

## 🎯 Project Goal
This project is a **non-commercial fan remake prototype** inspired by *Fighting Vipers*.

The goal is to build a **vertical slice** that demonstrates core gameplay:

- Arena-based 3D combat  
- Armor break system (signature feature)  
- Simple combo system  
- Satisfying physics feel  

---

## 🧠 Development Principles

### 1. Prototype First
Focus on **playable gameplay**, not polish.

### 2. Minimal Cost
Use:
- Unity (free)
- Free assets where possible
- Existing AI tools:
  - KelingAI (可灵AI)
  - SeedanceAI

### 3. AI-Assisted Workflow
AI is used for:
- Character concepts
- Armor break design
- Motion reference
- Style exploration

---

## ⚙️ Engine
- Unity

---

## 🎮 Core Features

### Arena Combat
- Fixed 3D arena
- Two fighters
- Controlled movement space

### Armor Break System
- Armor degrades with hits
- Multiple visual stages:
  - Intact
  - Damaged
  - Broken

### Simple Combat System
- Punch
- Kick
- Block
- Basic combos

### Physics Feel
- Knockback
- Hit reaction
- Impact feedback

---

## 🎨 Art Pipeline (AI-Assisted)

### KelingAI
Used for:
- Character concept (front / side / back)
- Armor break stages
- Visual style consistency

### SeedanceAI
Used for:
- Motion reference (punch/kick)
- Fighting stance exploration

### 3D Strategy
- Use free humanoid base OR low-poly Blender model
- Apply AI-generated references for design

---

## 💰 Cost Strategy

Target: **€0 additional cost**

- Unity: Free
- UI: Built-in Unity
- Animations: Mixamo (free)
- Models: Free or self-made
- AI tools: already owned

---

## 🧱 Project Structure

Assets/
  Art/
    Characters/
    Arena/
    Materials/
    Textures/
    Concept/
  Animations/
  Audio/
  Prefabs/
  Scenes/
  Scripts/
    Core/
    Combat/
    Characters/
    UI/
    Camera/
    Arena/
  UI/
Docs/
Reference/

---

## 🚀 Development Phases

### Phase 1 — Setup
- Project structure
- Git repo
- Basic scene

### Phase 2 — Core Combat
- Movement
- Punch / kick
- Hit detection
- Health system

### Phase 3 — Armor Break
- Armor durability
- Visual state changes

### Phase 4 — Arena & Feedback
- Arena setup
- Camera
- UI (health bars)
- Knockback

### Phase 5 — AI Art Pass
- Apply KelingAI concepts
- Refine visual identity

---

## 🧪 MVP Scope

- 1 character
- 1 arena
- 3 actions (punch, kick, block)
- Health system
- Armor break system

---

## ✅ Definition of Success

The prototype is successful if:

- Combat is playable
- Hits register correctly
- Armor visibly breaks
- Scene is stable and expandable

---

## 🔜 Next Steps

1. Create Unity project
2. Import into this repo
3. Build first playable scene
