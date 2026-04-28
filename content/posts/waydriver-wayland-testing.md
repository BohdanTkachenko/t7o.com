+++
title = "WayDriver: Playwright-style functional testing for Wayland apps"
date = 2026-04-26
description = "A Rust library that boots a private Mutter compositor, PipeWire, and D-Bus per session so you can drive Wayland desktop apps the way Playwright drives a browser."

[taxonomies]
tags = ["rust", "wayland", "testing", "open-source", "gtk"]
+++

Playwright made web testing pleasant. You get a real browser, real input events, screenshots, video recording, an activity log, and an API that auto-waits on the things that need waiting on. Writing a functional test stops being a chore.

There is no equivalent for Wayland desktop apps. Each compositor has its own headless mode, its own input-injection protocol, its own way of exposing a screencast, and none of them speak directly to a test runner. On X11 you reach for `xvfb` — old, simple, reliable. On Wayland you improvise.

[**WayDriver**](https://github.com/BohdanTkachenko/waydriver) is a Rust library that tries to close that gap. Every test session boots its own Mutter in headless mode, its own PipeWire daemon, its own private D-Bus, and launches your app inside that bubble. You drive the app through two complementary channels: the AT-SPI accessibility tree (for finding widgets and invoking actions) and real Wayland input events (for pixel-accurate screenshots and hover states).

## A test, end to end

```rust
let mut compositor = MutterCompositor::new();
compositor.start(None).await?;
let state = compositor.state().expect("…after start");

let session = Session::start(
    Box::new(compositor),
    Box::new(MutterInput::new(state.clone())),
    Box::new(MutterCapture::new(state)),
    SessionConfig {
        command: "my-gtk-app".into(),
        app_name: "my-gtk-app".into(),
        video_output: Some("/tmp/run.webm".into()),
        ..Default::default()
    },
).await?;

session.locate("//Button[@name='Sign in']").click().await?;
session.locate("//Text[@name='username']").fill("alice").await?;
session.press_chord("Ctrl+S").await?;
session.locate("//Label[@name='status']")
    .wait_for_text(|t| t == "saved")
    .await?;
```

AT-SPI exposes every widget as a node with a role and properties, so XPath picks them out the way you'd query a DOM. The locator is lazy — each method re-snapshots the tree and re-runs the XPath, so there are no stale handles when GTK rebuilds a list view under your feet. Single-target actions return `AmbiguousSelector` if your XPath matches more than one element, rather than silently picking the first.

Each session produces a self-contained `index.html` viewer with the WebM recording embedded and an event log, so when a test fails in CI you have something to look at.

<figure>
  <video controls autoplay muted loop playsinline preload="metadata" src="/videos/waydriver-demo-gnome-calculator.webm" aria-describedby="demo-caption">
    Your browser does not support embedded video. The clip shows a WayDriver test session driving GNOME Calculator: typing <code>2 + 3</code>, pressing equals, and observing the result <code>5</code>.
  </video>
  <figcaption id="demo-caption">A WayDriver session recording: GNOME Calculator is launched inside the headless Mutter bubble, then driven through AT-SPI to compute <code>2 + 3 = 5</code>.</figcaption>
</figure>

## The architecture

```
┌─────────────────────────────────────────────────────┐
│             Test or MCP process                     │
│  Session                                            │
│   ├─ Box<dyn CompositorRuntime>                     │
│   ├─ Box<dyn InputBackend>                          │
│   ├─ Box<dyn CaptureBackend>                        │
│   ├─ keepalive PipeWireStream                       │
│   └─ AppHandle                                      │
└─────────────────────────────────────────────────────┘
       │                                       ▲
       ▼ private D-Bus              host bus   │ AT-SPI
┌──────────────────────────────┐               │
│ Per-session XDG_RUNTIME_DIR  │               │
│   ├─ dbus-daemon (private)   │               │
│   ├─ mutter --headless       │               │
│   ├─ pipewire                │               │
│   └─ wireplumber             │               │
└──────────────────────────────┘               │
                                               │
                         target app  ──────────┘
```

The library is backend-agnostic. Three traits — `CompositorRuntime`, `InputBackend`, `CaptureBackend` — define the contract; concrete implementations live in sibling crates. Mutter is wired up today. KWin and sway are reachable from the same trait surface.

## The MCP server

WayDriver started as a tool to let an AI coding assistant see and click around in a GTK app under development, so there is also `waydriver-mcp` — a separate binary that exposes the same primitives over the [Model Context Protocol](https://modelcontextprotocol.io). Any MCP-aware agent can use it. Drop it in your `.mcp.json`:

```json
{
  "mcpServers": {
    "waydriver-mcp": {
      "command": "sh",
      "args": ["-c", "docker run --rm -i --network none \
        -v \"$PWD:/workspace:ro\" \
        -v /tmp/waydriver:/tmp/waydriver \
        ghcr.io/bohdantkachenko/waydriver-mcp:latest"]
    }
  }
}
```

…and the agent gets tools for `start_session`, `dump_tree`, `query`, `click`, `fill`, `press_key`, `hover`, `drag_to`, `take_screenshot`, and the rest. The `--network none` is intentional: the MCP server spawns processes, talks to them over D-Bus, and captures their screen, so it runs in a container with a read-only `$PWD` mount and no network access. Real test code, being reviewed and trusted, doesn't need the container.

The MCP path is useful for exploration and for letting an agent manually verify a feature. The library path is useful for actual test suites, which is what most people will probably want.

## A note on how this was built

WayDriver was built with heavy use of Claude — about 15M tokens worth, in evenings after work. The architecture, crate separation, and trait-based backend split came out of design pushback against the AI's natural tendency to under-engineer. Mentioning this seems fair given what the project is for.

Open-source desktops have always had passion behind them and rarely enough hands. That ratio is shifting. A small library like this, which would have been a multi-month side project a few years ago, fit into spare evenings between video games. There are a lot of GTK and Qt apps that could exist if writing them got cheaper, and the testing story is part of writing them.

## Try it

- crates.io: [`waydriver`](https://crates.io/crates/waydriver)
- Docker/Podman: `bohdantkachenko/waydriver-mcp:latest`
  
License is Apache-2.0.

What would help most right now is people actually using it on real projects — finding the rough edges, filing issues, telling me what's missing. KWin and sway backends are doable from the existing trait surface; if there's interest, they'll happen.
