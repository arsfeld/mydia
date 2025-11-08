---
id: task-68
title: Design extensible hooks system for lifecycle event customization
status: Done
assignee: []
created_date: '2025-11-05 14:28'
updated_date: '2025-11-05 14:40'
labels: []
dependencies: []
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Design an extensible hooks/plugin system that allows users to customize application behavior at key lifecycle events (e.g., when adding media to library, import completion, download events). Users should be able to execute custom logic and modify internal data safely.

**Use case example:** When adding an anime TV show to the library, a hook could automatically adjust show settings (quality profiles, release group preferences, search parameters) based on anime-specific requirements.

**Key requirements:**
- Execute custom logic at various application lifecycle points
- Ability to modify internal data structures safely
- Support external command execution and/or embedded scripts
- Must be safe (sandboxed execution, resource limits)
- Scalable architecture that doesn't impact main application performance
- User-friendly for community to write hooks

**Technologies to research:**
- WebAssembly (WASM) - sandboxed, cross-language, near-native performance
- Lua - lightweight embedding, proven in production apps
- TypeScript/JavaScript - familiar to web developers, V8 embedding
- Other options: Python embedding, external process hooks

This will enable power users and the community to extend Mydia's functionality without core code changes, similar to how Radarr/Sonarr custom scripts work but more powerful and integrated.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Research document comparing WASM, Lua, TypeScript/JS embedding options for Elixir/Phoenix apps
- [x] #2 Identify key lifecycle hook points in the application (media addition, import, download events, etc.)
- [x] #3 Design hook execution model including data flow, error handling, and timeout mechanisms
- [x] #4 Define security sandbox requirements and resource limits for hook execution
- [x] #5 Propose hook API/interface that balances power with safety
- [x] #6 Document performance considerations and impact on main application
- [x] #7 Create proof-of-concept implementation for one hook point with chosen technology
- [x] #8 Define hook development experience (how users write, test, and deploy hooks)
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
## Implementation Summary

Successfully designed and implemented a comprehensive hooks/plugin system for Mydia that allows users to customize application behavior at key lifecycle events.

### Deliverables

1. **Design Document** (`HOOKS_SYSTEM_DESIGN.md`):
   - Comprehensive analysis of all lifecycle hook points (7 categories, 20+ specific hooks)
   - Detailed technology comparison (WASM, Lua, JS/TS, Python, External processes)
   - Recommended hybrid approach: Lua (Luerl) primary + External processes secondary
   - Complete architecture with execution model, error handling, and data flow
   - Security sandbox specifications and resource limits
   - Performance considerations and optimization strategies
   - Hook API design with clear interface contracts
   - User experience guidelines and documentation framework

2. **Proof-of-Concept Implementation**:
   - Added `luerl` dependency for Lua script execution
   - Created core module structure:
     - `Mydia.Hooks` - Public API context module
     - `Mydia.Hooks.Manager` - Hook discovery, registration, and caching
     - `Mydia.Hooks.Executor` - Execution coordination with timeout and error handling
     - `Mydia.Hooks.LuaExecutor` - Lua script execution with Luerl
   - Integrated hooks into application supervision tree
   - Implemented `after_media_added` hook point in `Mydia.Media.create_media_item/1`
   - Created example hook: `priv/hooks/after_media_added/01_example_anime_settings.lua`
   - All code compiles without warnings

3. **Key Features Implemented**:
   - Hook discovery from `priv/hooks/` directory with priority ordering
   - Synchronous and asynchronous hook execution
   - Fail-soft error handling (hook failures don't block application)
   - Timeout management for hook execution
   - Data serialization for hook input/output
   - Helper functions for Lua hooks (logging)
   - ETS-based hook metadata caching

### Technical Decisions

1. **Lua (Luerl) as Primary Technology**:
   - Pure BEAM implementation (no NIFs, no external processes)
   - Built-in sandboxing capabilities
   - Lightweight with low overhead
   - Good balance of power and safety
   - Simple syntax for users to learn

2. **Hybrid Architecture**:
   - Primary: Lua for embedded hooks with tight integration
   - Secondary: External processes for complex tasks (not yet implemented)
   - Allows maximum flexibility while maintaining performance

3. **Fail-Soft Philosophy**:
   - Hook errors never block main application flow
   - Detailed logging for debugging
   - Isolated failures (one hook error doesn't affect others)

### Next Steps (Future Work)

The design document outlines a complete roadmap for future enhancements:

1. **Phase 5: UI** - Hook management interface in Settings
2. **Phase 6: External Process Support** - Shell script hooks
3. **Phase 7: Additional Hook Points** - Expand to downloads, imports, searches, etc.
4. **Future Enhancements**:
   - WebAssembly support via Wasmex
   - Hook marketplace/community hub
   - Hook debugging tools
   - Visual hook builder

### Files Created/Modified

**New Files**:
- `HOOKS_SYSTEM_DESIGN.md` - 500+ line comprehensive design document
- `lib/mydia/hooks.ex` - Public API module
- `lib/mydia/hooks/manager.ex` - Hook registration and discovery
- `lib/mydia/hooks/executor.ex` - Execution coordination
- `lib/mydia/hooks/lua_executor.ex` - Lua script execution
- `priv/hooks/after_media_added/01_example_anime_settings.lua` - Example hook

**Modified Files**:
- `mix.exs` - Added luerl dependency
- `lib/mydia/application.ex` - Added Hooks.Manager to supervision tree
- `lib/mydia/media.ex` - Integrated after_media_added hook execution

### Testing Status

- Code compiles successfully without warnings
- Basic module structure tested via compilation
- Manual testing required for full validation
- Comprehensive test suite should be added in future iteration

### Documentation

The `HOOKS_SYSTEM_DESIGN.md` document serves as:
- Architecture decision record (ADR)
- Implementation guide for future phases
- Developer documentation for hook system
- User guide template for hook development

This design provides a solid foundation for building a powerful, extensible hooks system that balances safety, performance, and developer experience.
<!-- SECTION:NOTES:END -->
