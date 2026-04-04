# Fighting Vipers Fan Remake (Prototype)

## 🎯 Project Goal
This project is a **research-driven, non-commercial fan remake prototype** inspired by *Fighting Vipers*.

Working assumption for this plan:

- Original game resources may be studied, extracted, and used for prototype work
- The focus is learning, validation, and rebuilding a playable slice rather than shipping a commercial product

The prototype should prove:

- Arena-based 3D combat  
- A stable Honey base-texture coverage path and character material hookup
- Signature armor break presentation remains a later milestone, but is intentionally deferred in the current Honey pass because broken-state asset coverage is still too expensive
- Strong single-action combat feel before deeper combo design  
- A practical pipeline from original-game research to extracted assets to a Unity prototype  

---

## 🧠 Development Principles

### 1. Original-Game-First Research
Use the original game, emulator captures, extracted assets, move lists, and hidden-content documentation as the primary reference layer.

### 2. Single Actions Before Combos
Prioritize **punch, kick, block, damage, knockback, and Honey base-texture coverage**. Combo depth and armor break are later expansions, not early blockers.

### 3. Prototype Fast, Replace Selectively
Allow temporary direct-use placeholders from extracted original resources to validate feel quickly. Rebuild or clean up only where it improves quality or workflow.

### 4. Minimal Reinvention
If the original game already solves a problem visually, structurally, or rhythmically, study it first before inventing a new solution.

### 5. Windows-First Development
Use a **Windows PC** as the main machine for Unity, emulator tooling, controllers, extraction utilities, and GPU-heavy workflows.

---

## ⚙️ Engine & Core Stack
- Unity LTS on Windows PC (**local-only project, not synced to Git**)
- C# gameplay code with data-driven combat definitions
- Unity Input System
- Animator-based prototype animation control
- Cinemachine for camera exploration
- Blender for inspection, cleanup, and conversion
- Git for version control of **technical documents and tool scripts only**

### Recommended Technical Scope
- Offline local prototype only
- 1v1 arena combat
- No netcode in the first slice
- No story or progression systems in the first slice

---

## 🔎 Research & Asset Strategy

### Source Priority
1. **Original-game research and extraction**
2. **Community archives and reverse-engineering references**
3. **AI support tools for gaps or variants**
4. **Generic free placeholders only when needed**

### Primary Sources
- Original game running in emulator or on original media
- Gameplay captures, screenshots, and timing notes
- Extracted models, textures, UI graphics, audio, and move references

### Supporting Sources
- TCRF
- SegaXtreme
- Hidden Palace
- Models / Textures / Sounds Resource
- Community extraction and conversion tools

### AI Support Only
AI should now be treated as a **secondary helper**, not the main art path. Use it when the original material is missing, unclear, or needs variation.

---

## 🎮 Re-Evaluated Core Features

### Arena Combat
- Fixed 3D arena
- Two fighters
- Controlled movement space
- Camera tuned for readability over cinematic complexity

### Single-Action Combat Core
- Punch
- Kick
- Block
- Basic hit confirm and recovery states
- Combo system intentionally deferred

### Honey Base Texture Coverage
- First lock Honey's normal-state face / hair / body / ornament texture set before broken-armor work
- Build a fixed master texture set with manifest, atlas sheets, and a known missing-part list
- Use gameplay and INTRO captures to fill normal-state coverage gaps first
- Defer broken-armor-only textures until the base set and material mapping are stable

### Deferred Armor Break System
- Temporarily postponed from the current implementation slice because broken-state part capture and reconstruction is higher risk than the base Honey pass
- Later reintroduce a shared armor durability pipeline and visible broken-state transitions
- Target visual states when this returns:
  - Intact
  - Damaged
  - Broken

### Combat Feel
- Hit stop
- Knockback
- Hit reaction
- Impact audio / visual feedback
- Readable recovery timing

### Authentic Reference Layer
- Study original animation timing, sound cues, character proportions, and UI rhythm
- Reuse or adapt original-resource findings whenever it speeds up prototype validation

---

## 🧱 Technical Direction

### Gameplay Architecture
- Start with a small character state machine:
  - Idle
  - Move
  - Attack
  - Block
  - Hit
  - ArmorBreak (reserved for the deferred armor-break milestone)
- Define moves with data assets such as ScriptableObjects:
  - startup
  - active
  - recovery
  - damage
  - knockback
  - armor damage (reserved for the deferred armor-break milestone)
- Keep combat deterministic and readable before adding more depth

### Hit Detection
- Use explicit hitboxes and hurtboxes
- Activate attack windows from animation timing
- Keep the first implementation simple and debuggable

### Animation Path
- First pass: placeholder or extracted/reference motions to validate timing
- Second pass: cleaned-up clips or recreated motions only if needed
- Prioritize stance, punch, kick, block, hit reaction, and break reaction before anything flashy

### Asset Path
- Step 1: collect original references and extracted assets
- Step 2: inspect, clean, and convert them in Blender or dedicated tools
- Step 3: import them into Unity as prototype assets
- Step 4: map materials, audio events, and presentation states
- Step 5: rebuild assets only when they become a quality or workflow bottleneck

### Audio & Presentation
- Use original audio cues or direct reference where helpful
- Rebuild playback logic in Unity with clean event timing
- Keep UI minimal but readable: health, armor, and only the feedback needed for the first slice

---

## 🎨 Art & Asset Pipeline

### Original Asset Pipeline
Used for:
- Character proportion reference
- Armor part structure
- Texture and palette study
- UI study
- Sound study
- Fast prototype placeholders

### Extraction / Conversion Tools
Candidates to test:
- [`cyberwarriorx/vcdextract`](https://github.com/cyberwarriorx/vcdextract)
- [`doyousketch2/SatRGB`](https://github.com/doyousketch2/SatRGB)
- Saturn model conversion tools
- Blender-based cleanup workflow

### AI Support Pipeline
Use only where it adds value:
- KelingAI: missing concept variations or armor redesign passes
- SeedanceAI: motion reference exploration
- [`tori29umai/Qwen-Image-2509-CharacterSheet`](https://huggingface.co/spaces/tori29umai/Qwen-Image-2509-CharacterSheet): turnarounds and design sheets
- [`AIARTCHAN/openpose_editor`](https://huggingface.co/spaces/AIARTCHAN/openpose_editor): pose setup for punch / kick / block
- [`diffusers/stable-diffusion-xl-inpainting`](https://huggingface.co/spaces/diffusers/stable-diffusion-xl-inpainting): armor damage variants
- [`frogleo/Image-to-3D`](https://huggingface.co/spaces/frogleo/Image-to-3D): rough volume checks only

### 3D Strategy
- Prefer extracted or reference-driven prototype assets first
- Use Blender to simplify, retopo, or re-rig only when necessary
- Do not block gameplay progress on perfect asset quality

---

## 💰 Cost Strategy

Target: **Near €0 additional cost**

- Unity: Free
- Git: Free
- Blender: Free
- Existing PC, controller, and original game resources: already available
- AI tools: already owned or optional
- Main cost: time spent on extraction, cleanup, and combat tuning

---

## 🗂️ Repository Sync Policy

### Git-Traced Scope
- `README.md`
- `Reference/ResearchNotes/`
- `Tools/Extraction/`
- `Tools/Generation/` in-house scripts and technical wrappers only
- `Tools/Windows/`

### Local-Only Scope
- `Assets/`
- `Packages/`
- `ProjectSettings/`
- `Library/`, `Temp/`, `Logs/`, `UserSettings/`
- `Resources/`
- `Reference/OriginalAssets/`
- `Reference/Captures/`
- Third-party model caches and vendor checkouts under `Tools/Generation/**/cache/` and `Tools/Generation/**/vendor/`

### Current Rule
Unity development still happens locally, but the Unity project itself is treated as a **non-synced working directory**.
Git is used as a **technical knowledge and tooling repository**, not as the transport layer for Unity scenes, imported art, generated models, emulator dumps, or binary research assets.

If this project later needs multi-machine Unity sync, switch to a separate policy first, then re-evaluate Git LFS or Perforce. Do not silently reintroduce large Unity/art binaries into normal Git history.

---

## 📚 Re-Evaluated External References

Current direction for the first playable slice:
- Prioritize **single actions** over combo depth
- Use **original-resource research** as the primary production shortcut
- Treat AI as a **support layer**, not the main content source

| Goal | Project / Resource | Simple Description | Why It Fits This Project | Current Priority / Usage |
| --- | --- | --- | --- | --- |
| Gameplay reference | [`tryandev/divekick-unity3d`](https://github.com/tryandev/divekick-unity3d) | A Unity3D two-player 3D fighting prototype. | Good reference for quickly building a playable combat loop, simple attacks, hit feedback, and character interaction. | **High priority**. Best current gameplay reference. |
| Gameplay reference | [`OmarAlesharie/Fighting-Survival`](https://github.com/OmarAlesharie/Fighting-Survival) | A simple 3D fighting prototype in Unity. The README confirms it was developed in **Unity 2018.3.0f2**. | Useful for studying how a Unity-based 3D fighting prototype is structured around attacks, hit reactions, and basic player control. | **Medium priority**. Strong secondary gameplay reference. |
| Combo architecture | [`homemech/unity-pattern-combo`](https://github.com/homemech/unity-pattern-combo) | A Unity/C# demo of a combo system built around the command pattern. | Potentially useful later for input buffering and combo architecture. | **Low priority**. Current scope should stay on single commands first. |
| Original asset archive | [`The Models Resource - Fighting Vipers (Saturn)`](https://models.spriters-resource.com/saturn/fightingvipers/) | Public archive of extracted Saturn model resources. | Fast route to character scale, silhouette, and armor structure research. | **High priority**. Best shortcut for character reconstruction study. |
| Original asset archive | [`The Textures Resource - Fighting Vipers (Saturn)`](https://textures.spriters-resource.com/saturn/fightingvipers/) | Public archive of extracted textures. | Useful for palette study, material breakup, UI look, and placeholder texture passes. | **High priority**. Strong art-reference source. |
| Original asset archive | [`The Sounds Resource - Fighting Vipers (Saturn)`](https://sounds.spriters-resource.com/saturn/fightingvipers/) | Public archive of sound resources. | Useful for impact timing, voice references, and UI / combat sound study. | **High priority**. Strong feedback-design source. |
| Hidden content research | [`TCRF - Fighting Vipers (Saturn)`](https://tcrf.net/Fighting_Vipers_(Sega_Saturn)) | Hidden content, regional differences, and debug-oriented findings. | Helps identify authentic features, variations, and content worth rebuilding. | **High priority**. Best hidden-content research source. |
| Hidden content research | [`TCRF - Fighting Vipers (Arcade)`](https://tcrf.net/Fighting_Vipers_(Arcade)) | Arcade-specific unused content and debug findings. | Useful for cross-checking the Saturn version against the arcade original. | **Medium priority**. Good secondary authenticity source. |
| Community research | [`SegaXtreme - Fighting Vipers`](https://segaxtreme.net/tags/fighting-vipers/) | Saturn patch, discovery, and discussion hub. | Useful for obscure findings, patches, and extraction clues. | **High priority**. Good practical research hub. |
| Prototype archive | [`Hidden Palace - Fighting Vipers prototype`](https://hiddenpalace.org/Fighting_Vipers_(Jul_5,_1996_prototype)) | Preserved prototype build and notes. | Useful for cut content, version differences, and historical context. | **Medium priority**. Research value, not the main production path. |
| Extraction pipeline | [`cyberwarriorx/vcdextract`](https://github.com/cyberwarriorx/vcdextract) / [`doyousketch2/SatRGB`](https://github.com/doyousketch2/SatRGB) | Saturn extraction tools for disc contents and image assets. | Practical starting point for turning owned original media into usable research files. | **High priority**. Core extraction path to test. |
| AI support | [`AIARTCHAN/openpose_editor`](https://huggingface.co/spaces/AIARTCHAN/openpose_editor) / [`tori29umai/Qwen-Image-2509-CharacterSheet`](https://huggingface.co/spaces/tori29umai/Qwen-Image-2509-CharacterSheet) / [`diffusers/stable-diffusion-xl-inpainting`](https://huggingface.co/spaces/diffusers/stable-diffusion-xl-inpainting) / [`frogleo/Image-to-3D`](https://huggingface.co/spaces/frogleo/Image-to-3D) | Pose, turnaround, localized paintover, and rough 3D support tools. | Helpful only after original sources are insufficient or need augmentation. | **Support tools**. No longer the main production path. |

---

## 🧱 Project Structure

Reference/
  Captures/
    # Local-only capture/video/image intermediates
  MoveLists/
  ResearchNotes/
  OriginalAssets/
    # Local-only curated art references and extracted binaries
    Models/
    Textures/
    Audio/
Resources/
  M2emulator/
    # Local-only Model 2 emulator install, ROM zips, runtime cache/save data
    # Kept out of Git by .gitignore; do not store curated reusable outputs here
Tools/
  Extraction/
    Model2/
  Generation/
    Hunyuan3D/
      # Keep only our scripts/config in Git; vendor/cache/output stay local-only
  Windows/
Docs/

# Local-only Unity project directories:
# Assets/
# Packages/
# ProjectSettings/

---

## 🚀 Development Phases

### Phase 0 — PC Setup & Research Pipeline
- Prepare the main Windows PC environment
- Confirm controller and emulator workflow
- Set up extraction tools and folders
- Collect reference captures and notes

### Phase 1 — Playable Arena Setup
- Create the Unity project locally at repo root, but keep Unity-owned folders ignored by Git
- Build a basic arena scene
- Set up a readable camera
- Place two test fighters

### Phase 2 — Single Action Combat Core
- Movement
- Punch
- Kick
- Block
- Hit detection
- Health system

### Phase 3 — Combat Feel & Feedback
- Hit reaction
- Knockback
- Hit stop
- Impact feedback
- Basic UI
- Basic combat audio timing

### Phase 4 — Honey Texture Coverage & Fixed Master Set
- Complete Honey normal-state texture coverage first
- Update `Honey_Master_TextureSet` manifest and sheets as the fixed reference set
- Track missing normal-state parts explicitly
- Verify face / hair / body / ornament grouping before Unity material hookup

### Phase 5 — Original Asset Integration
- Import one character-related reference asset path into Unity
- Test Honey base textures, audio, or model conversion workflow
- Validate that extracted resources can support the prototype directly

### Phase 6 — Expansion Later
- Armor break prototype and broken-state texture capture
- Per-part armor logic
- Second character or mirrored variant polish
- Combo expansion only after the single-action loop feels right

---

## 🧪 MVP Scope

- 1 playable character
- 1 test opponent or mirrored fighter
- 1 arena
- 3 actions (punch, kick, block)
- Health system
- Honey base-texture integration from a fixed master texture set
- At least one working original-resource integration path

---

## ✅ Definition of Success

The prototype is successful if:

- Combat is playable and readable
- Single actions feel close to reference footage
- Hits register correctly
- Honey normal-state textures are complete enough to support stable material hookup, while armor break is explicitly deferred
- At least one model / texture / audio path from original research works in Unity
- The scene is stable and expandable

---

## 🔜 Next Steps

### Setup & Research Checklist

- [ ] Prepare the main Windows PC development and extraction environment
  - [ ] Update GPU drivers
  - [ ] Install Unity Hub
  - [ ] Install a Unity LTS editor
  - [ ] Set up Rider or VS Code
  - [ ] Install Git
  - [ ] Install Blender
  - [ ] Confirm controller testing works
  - [ ] Prepare emulator and capture tooling

- [ ] Build the research workspace inside this repo
  - [ ] Create or confirm `Reference/Captures/`
  - [ ] Create or confirm `Reference/MoveLists/`
  - [ ] Create or confirm `Reference/ResearchNotes/`
  - [ ] Create or confirm `Reference/OriginalAssets/Models/`
  - [ ] Create or confirm `Reference/OriginalAssets/Textures/`
  - [ ] Create or confirm `Reference/OriginalAssets/Audio/`
  - [ ] Create or confirm `Tools/Extraction/`
  - [ ] Add tool notes and extraction logs

- [ ] Test the original-resource pipeline
  - [ ] Capture reference footage
  - [ ] Try one texture extraction path or one audio extraction path first
  - [ ] Verify the output files can be organized and reused

- [ ] Create the Unity project locally at repo root, but keep `Assets/`, `Packages/`, and `ProjectSettings/` ignored by Git
- [ ] Build one basic arena scene with two test fighters and a readable camera
- [ ] Implement movement, punch, kick, and block with data-driven move definitions
- [ ] Add hit detection, health, hit stop, knockback, and basic audio / UI feedback
- [ ] Complete Honey normal-state texture coverage, lock the fixed master texture manifest/sheets, and integrate one original-reference asset pass
- [ ] Keep armor break and broken-state texture capture deferred until the base Honey material path is stable
