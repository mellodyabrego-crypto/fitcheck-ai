import React from "react";
import {
  AbsoluteFill,
  Audio,
  Series,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
  interpolate,
  spring,
  Easing,
} from "remotion";
import { loadFont as loadDancing } from "@remotion/google-fonts/DancingScript";
import { loadFont as loadInter } from "@remotion/google-fonts/Inter";
import { loadFont as loadPacifico } from "@remotion/google-fonts/Pacifico";
import { COLORS, GRADIENTS, SAFE } from "./lib/brand";
import captionsJson from "../public/audio/fashion-history/fashion-history-captions.json";

const { fontFamily: dancingFamily } = loadDancing();
const { fontFamily: interFamily } = loadInter();
const { fontFamily: pacificoFamily } = loadPacifico();

export const FPS = 30;

type SceneDef = {
  id: string;
  seconds: number;
  chapter: string;
  era: string;
  headline: string;
  subhead: string;
  palette: keyof typeof GRADIENTS;
  audio: string;
  keywords: string[];
};

const SCENES: SceneDef[] = [
  {
    id: "scene1",
    seconds: 9.0,
    chapter: "Chapter I",
    era: "c. 25,000 BCE",
    headline: "It began with a needle.",
    subhead: "The very first idea of style.",
    palette: "cream",
    audio: "audio/fashion-history/fashion-history-scene1.mp3",
    keywords: ["Fashion", "bone", "needle", "ancestor"],
  },
  {
    id: "scene2",
    seconds: 13.0,
    chapter: "Chapter II",
    era: "Ancient World",
    headline: "Threads became identity.",
    subhead: "Linen · silk · wool.",
    palette: "petal",
    audio: "audio/fashion-history/fashion-history-scene2.mp3",
    keywords: [
      "Linen",
      "silk",
      "wool",
      "Egypt",
      "China",
      "Mesopotamia",
      "identity",
    ],
  },
  {
    id: "scene3",
    seconds: 12.0,
    chapter: "Chapter III",
    era: "Rome → Medieval",
    headline: "Fashion meant power.",
    subhead: "Togas. Sumptuary laws. Hoarded velvet.",
    palette: "rose",
    audio: "audio/fashion-history/fashion-history-scene3.mp3",
    keywords: ["Roman", "togas", "Medieval", "Kings", "velvet", "resume"],
  },
  {
    id: "scene4",
    seconds: 13.5,
    chapter: "Chapter IV",
    era: "1858 · Paris",
    headline: "Couture is born.",
    subhead: "Charles Worth invents the fashion house.",
    palette: "gold",
    audio: "audio/fashion-history/fashion-history-scene4.mp3",
    keywords: [
      "Charles",
      "Worth",
      "Paris",
      "fashion",
      "seasonal",
      "Runways",
    ],
  },
  {
    id: "scene5",
    seconds: 13.0,
    chapter: "Chapter V",
    era: "20th c. → Today",
    headline: "Style goes public.",
    subhead: "Ready-to-wear. Magazines. Instagram.",
    palette: "blush",
    audio: "audio/fashion-history/fashion-history-scene5.mp3",
    keywords: [
      "ready-to-wear",
      "Sewing",
      "Magazines",
      "Instagram",
      "conversation",
      "trend",
    ],
  },
  {
    id: "scene6",
    seconds: 11.5,
    chapter: "The Next Chapter",
    era: "Today",
    headline: "Her Style Co.",
    subhead: "Your personal AI stylist.",
    palette: "chapter",
    audio: "audio/fashion-history/fashion-history-scene6.mp3",
    keywords: ["Her", "Style", "Co", "closet", "stylist", "outfit", "today"],
  },
];

export const TOTAL_FRAMES = Math.ceil(
  SCENES.reduce((s, sc) => s + sc.seconds, 0) * FPS
);

type CaptionWord = {
  text: string;
  startMs: number;
  endMs: number;
  timestampMs: number;
  sceneId: string;
};

const ALL_CAPTIONS = (captionsJson as any).remotion.captions as CaptionWord[];
const captionsByScene = (sceneId: string): CaptionWord[] =>
  ALL_CAPTIONS.filter((c) => c.sceneId === sceneId);

// ────────────────────────────────────────────────────────────────────
export const LongFormFashionHistory: React.FC = () => {
  return (
    <AbsoluteFill style={{ backgroundColor: COLORS.cream }}>
      <Series>
        {SCENES.map((scene, i) => (
          <Series.Sequence
            key={scene.id}
            durationInFrames={Math.round(scene.seconds * FPS)}
          >
            <Scene scene={scene} index={i} total={SCENES.length} />
          </Series.Sequence>
        ))}
      </Series>
    </AbsoluteFill>
  );
};

// ─── Scene ──────────────────────────────────────────────────────────
const Scene: React.FC<{ scene: SceneDef; index: number; total: number }> = ({
  scene,
  index,
  total,
}) => {
  const frame = useCurrentFrame();
  const { durationInFrames } = useVideoConfig();

  return (
    <AbsoluteFill>
      <Audio src={staticFile(scene.audio)} />
      <SoftGradient palette={scene.palette} />
      <DecorativeDots />
      <GoldSparkles seed={index} />
      <FloatingPetals seed={index} />
      <FlourishCurve seed={index} />

      <AbsoluteFill
        style={{
          padding: `${SAFE.top}px ${SAFE.right}px 260px ${SAFE.left}px`,
          justifyContent: "flex-start",
          alignItems: "center",
          paddingTop: 120,
        }}
      >
        <ChapterKicker text={scene.chapter} />
        <Headline text={scene.headline} sceneId={scene.id} />
        <RibbonUnderline />
        <Subhead text={scene.subhead} />
      </AbsoluteFill>

      <EraBadge era={scene.era} />
      <ProgressDots index={index} total={total} />
      <Captions captions={captionsByScene(scene.id)} keywords={scene.keywords} />
      <SceneFade frame={frame} durationInFrames={durationInFrames} />
    </AbsoluteFill>
  );
};

// ─── Background ─────────────────────────────────────────────────────
const SoftGradient: React.FC<{ palette: keyof typeof GRADIENTS }> = ({
  palette,
}) => {
  const frame = useCurrentFrame();
  const colors = GRADIENTS[palette];
  const angle = 140 + Math.sin(frame / 50) * 10;
  const ox = Math.sin(frame / 70) * 30;
  const oy = Math.cos(frame / 95) * 20;
  return (
    <AbsoluteFill
      style={{
        background: `linear-gradient(${angle}deg, ${colors.join(", ")})`,
        transform: `translate(${ox}px, ${oy}px) scale(1.08)`,
      }}
    >
      {/* Radial bloom */}
      <AbsoluteFill
        style={{
          background: `radial-gradient(ellipse at ${
            50 + Math.sin(frame / 60) * 10
          }% ${40 + Math.cos(frame / 80) * 10}%, rgba(255, 255, 255, 0.35), transparent 55%)`,
        }}
      />
      {/* Soft grain */}
      <AbsoluteFill
        style={{
          backgroundImage:
            "radial-gradient(rgba(255,255,255,0.05) 1px, transparent 1px)",
          backgroundSize: "3px 3px",
          mixBlendMode: "overlay",
        }}
      />
    </AbsoluteFill>
  );
};

// ─── Decorative Particles ────────────────────────────────────────────
const seeded = (seed: number, i: number, mod: number) =>
  ((seed * 131 + i * 997 + 17) * 1103515245) % mod;

const DecorativeDots: React.FC = () => {
  const frame = useCurrentFrame();
  const dots = React.useMemo(
    () =>
      Array.from({ length: 14 }).map((_, i) => ({
        x: ((i * 211) % 1800) + 60,
        y: ((i * 137) % 900) + 90,
        phase: (i * 11) % 90,
        size: 4 + ((i * 7) % 6),
      })),
    []
  );
  return (
    <AbsoluteFill style={{ pointerEvents: "none" }}>
      {dots.map((d, i) => {
        const p = ((frame + d.phase) % 120) / 120;
        const op = 0.15 + Math.sin(p * Math.PI) * 0.25;
        return (
          <div
            key={i}
            style={{
              position: "absolute",
              left: d.x,
              top: d.y,
              width: d.size,
              height: d.size,
              borderRadius: "50%",
              background: COLORS.accent,
              opacity: op,
            }}
          />
        );
      })}
    </AbsoluteFill>
  );
};

const GoldSparkles: React.FC<{ seed: number }> = ({ seed }) => {
  const frame = useCurrentFrame();
  const sparkles = React.useMemo(
    () =>
      Array.from({ length: 22 }).map((_, i) => ({
        x: seeded(seed + 1, i, 1800) + 60,
        y: seeded(seed + 2, i, 900) + 90,
        delay: seeded(seed + 3, i, 90),
        size: 8 + (seeded(seed + 4, i, 14) as number),
        drift: seeded(seed + 5, i, 40) - 20,
      })),
    [seed]
  );
  return (
    <AbsoluteFill style={{ pointerEvents: "none" }}>
      {sparkles.map((s, i) => {
        const progress = ((frame - s.delay) % 140) / 140;
        const op = Math.sin(progress * Math.PI) * 0.6;
        const dy = (progress - 0.5) * 60 + s.drift;
        return (
          <div
            key={i}
            style={{
              position: "absolute",
              left: s.x,
              top: s.y + dy,
              width: s.size,
              height: s.size,
              borderRadius: "50%",
              background: `radial-gradient(circle, ${COLORS.accent} 0%, ${COLORS.accentAlt} 40%, transparent 70%)`,
              opacity: op,
              filter: `blur(${s.size / 4}px)`,
            }}
          />
        );
      })}
    </AbsoluteFill>
  );
};

const FloatingPetals: React.FC<{ seed: number }> = ({ seed }) => {
  const frame = useCurrentFrame();
  const petals = React.useMemo(
    () =>
      Array.from({ length: 12 }).map((_, i) => ({
        startX: seeded(seed + 10, i, 1920),
        startY: 1100 + (seeded(seed + 11, i, 200) as number),
        speed: 0.4 + (seeded(seed + 12, i, 40) as number) / 100,
        size: 14 + (seeded(seed + 13, i, 18) as number),
        hue: (seeded(seed + 14, i, 3) as number),
        rotSpeed: (seeded(seed + 15, i, 5) as number) - 2,
        drift: (seeded(seed + 16, i, 80) as number) - 40,
      })),
    [seed]
  );
  return (
    <AbsoluteFill style={{ pointerEvents: "none" }}>
      {petals.map((p, i) => {
        const travelled = frame * p.speed;
        const y = p.startY - travelled;
        const x = p.startX + Math.sin((frame + i * 13) / 50) * p.drift;
        const rot = frame * p.rotSpeed;
        const color =
          p.hue === 0
            ? COLORS.primaryLight
            : p.hue === 1
            ? COLORS.primary
            : COLORS.blushSoft;
        return (
          <div
            key={i}
            style={{
              position: "absolute",
              left: x,
              top: y,
              width: p.size * 1.4,
              height: p.size,
              background: color,
              borderRadius: "70% 30% 70% 30% / 50% 50% 50% 50%",
              transform: `rotate(${rot}deg)`,
              opacity: 0.55,
              filter: "blur(0.5px)",
              boxShadow: `0 0 ${p.size / 2}px rgba(196, 138, 150, 0.35)`,
            }}
          />
        );
      })}
    </AbsoluteFill>
  );
};

const FlourishCurve: React.FC<{ seed: number }> = ({ seed }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const intro = spring({ frame, fps, config: { damping: 200 }, durationInFrames: 45 });
  const dashOffset = interpolate(intro, [0, 1], [1200, 0]);
  const flip = seed % 2 === 0;
  return (
    <svg
      width={1920}
      height={1080}
      style={{ position: "absolute", inset: 0, pointerEvents: "none" }}
    >
      <path
        d={
          flip
            ? "M -50 780 C 420 720, 760 920, 1250 700 S 1900 720, 1970 620"
            : "M -50 300 C 420 360, 760 160, 1250 380 S 1900 360, 1970 460"
        }
        fill="none"
        stroke={COLORS.accent}
        strokeWidth={2.4}
        strokeLinecap="round"
        strokeDasharray={1200}
        strokeDashoffset={dashOffset}
        opacity={0.45}
      />
      <path
        d={
          flip
            ? "M -50 830 C 380 770, 780 970, 1230 750 S 1880 770, 1970 670"
            : "M -50 260 C 380 320, 780 120, 1230 340 S 1880 320, 1970 420"
        }
        fill="none"
        stroke={COLORS.primary}
        strokeWidth={1.6}
        strokeLinecap="round"
        strokeDasharray={1200}
        strokeDashoffset={interpolate(intro, [0, 1], [1400, 0])}
        opacity={0.35}
      />
    </svg>
  );
};

// ─── Text Blocks ────────────────────────────────────────────────────
const ChapterKicker: React.FC<{ text: string }> = ({ text }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const intro = spring({ frame, fps, config: { damping: 200 } });
  return (
    <div
      style={{
        opacity: intro,
        transform: `translateY(${interpolate(intro, [0, 1], [-15, 0])}px)`,
        fontFamily: interFamily,
        fontSize: 24,
        fontWeight: 700,
        color: COLORS.accent,
        letterSpacing: "0.35em",
        textTransform: "uppercase",
        marginBottom: 18,
      }}
    >
      — {text} —
    </div>
  );
};

const Headline: React.FC<{ text: string; sceneId: string }> = ({
  text,
  sceneId,
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const intro = spring({
    frame: frame - 5,
    fps,
    config: { damping: 150, stiffness: 180 },
  });
  const translateY = interpolate(intro, [0, 1], [40, 0]);
  const opacity = interpolate(intro, [0, 1], [0, 1]);
  const breath = 1 + Math.sin(frame / 45) * 0.006;

  if (sceneId === "scene6") {
    return (
      <div
        style={{
          transform: `translateY(${translateY}px) scale(${breath})`,
          opacity,
          textAlign: "center",
        }}
      >
        <div
          style={{
            fontFamily: pacificoFamily,
            fontSize: 168,
            lineHeight: 1.0,
            background: `linear-gradient(135deg, ${COLORS.primary} 0%, ${COLORS.primaryDark} 45%, ${COLORS.accent} 100%)`,
            WebkitBackgroundClip: "text",
            backgroundClip: "text",
            color: "transparent",
            fontWeight: 400,
            letterSpacing: "-0.015em",
            filter: "drop-shadow(0 6px 14px rgba(169, 110, 122, 0.25))",
          }}
        >
          {text}
        </div>
      </div>
    );
  }

  return (
    <div
      style={{
        transform: `translateY(${translateY}px) scale(${breath})`,
        opacity,
        textAlign: "center",
      }}
    >
      <div
        style={{
          fontFamily: dancingFamily,
          fontSize: 132,
          fontWeight: 700,
          color: COLORS.foreground,
          lineHeight: 1.05,
          letterSpacing: "-0.01em",
          textShadow: "0 2px 18px rgba(255, 245, 238, 0.8)",
          maxWidth: 1600,
        }}
      >
        {text}
      </div>
    </div>
  );
};

const RibbonUnderline: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const intro = spring({
    frame: frame - 15,
    fps,
    config: { damping: 200 },
    durationInFrames: 30,
  });
  const width = interpolate(intro, [0, 1], [0, 380]);
  return (
    <svg
      width={400}
      height={30}
      style={{ marginTop: 12, marginBottom: 8, overflow: "visible" }}
    >
      <path
        d="M 10 15 Q 105 -6 200 15 T 390 15"
        fill="none"
        stroke={COLORS.accent}
        strokeWidth={3}
        strokeLinecap="round"
        strokeDasharray={400}
        strokeDashoffset={400 - width}
        opacity={0.85}
      />
    </svg>
  );
};

const Subhead: React.FC<{ text: string }> = ({ text }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const intro = spring({ frame: frame - 18, fps, config: { damping: 200 } });
  return (
    <div
      style={{
        marginTop: 8,
        fontFamily: interFamily,
        fontSize: 40,
        fontWeight: 500,
        color: COLORS.primaryDark,
        opacity: intro,
        transform: `translateY(${interpolate(intro, [0, 1], [15, 0])}px)`,
        textAlign: "center",
        letterSpacing: "0.04em",
      }}
    >
      {text}
    </div>
  );
};

// ─── Era Badge ──────────────────────────────────────────────────────
const EraBadge: React.FC<{ era: string }> = ({ era }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const intro = spring({
    frame: frame - 10,
    fps,
    config: { damping: 200 },
  });
  const wobble = Math.sin(frame / 40) * 2;
  return (
    <div
      style={{
        position: "absolute",
        top: 72,
        right: 80,
        opacity: intro,
        transform: `translateY(${interpolate(intro, [0, 1], [-20, wobble])}px)`,
        padding: "12px 28px",
        background: "rgba(255, 248, 241, 0.85)",
        border: `1.5px solid ${COLORS.accent}`,
        borderRadius: 999,
        fontFamily: interFamily,
        fontSize: 22,
        fontWeight: 600,
        color: COLORS.primaryDark,
        letterSpacing: "0.15em",
        textTransform: "uppercase",
        boxShadow: "0 8px 24px rgba(169, 110, 122, 0.15)",
        backdropFilter: "blur(8px)",
      }}
    >
      {era}
    </div>
  );
};

const ProgressDots: React.FC<{ index: number; total: number }> = ({
  index,
  total,
}) => {
  return (
    <div
      style={{
        position: "absolute",
        top: 80,
        left: 80,
        display: "flex",
        gap: 14,
        alignItems: "center",
      }}
    >
      {Array.from({ length: total }).map((_, i) => {
        const active = i === index;
        const done = i < index;
        return (
          <div
            key={i}
            style={{
              width: active ? 42 : 10,
              height: 10,
              borderRadius: 999,
              background: active
                ? COLORS.primary
                : done
                ? COLORS.primaryLight
                : "rgba(196, 138, 150, 0.28)",
              transition: "width 200ms",
              boxShadow: active
                ? `0 0 12px ${COLORS.primary}55`
                : "none",
            }}
          />
        );
      })}
    </div>
  );
};

// ─── Captions ────────────────────────────────────────────────────────
const Captions: React.FC<{
  captions: CaptionWord[];
  keywords: string[];
}> = ({ captions, keywords }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const ms = (frame / fps) * 1000;

  const activeIdx = captions.findIndex(
    (c) => ms >= c.startMs && ms <= c.endMs + 150
  );
  const idx =
    activeIdx === -1
      ? captions.findIndex((c) => c.startMs > ms) - 1
      : activeIdx;
  const windowStart = Math.max(
    0,
    Math.min(captions.length - 8, (idx < 0 ? 0 : idx) - 2)
  );
  const windowWords = captions.slice(windowStart, windowStart + 8);

  const keywordSet = new Set(
    keywords.map((k) => k.toLowerCase().replace(/[^a-z0-9\-']/g, ""))
  );

  return (
    <div
      style={{
        position: "absolute",
        left: 0,
        right: 0,
        bottom: 90,
        display: "flex",
        justifyContent: "center",
        padding: "0 80px",
      }}
    >
      <div
        style={{
          background: "rgba(255, 248, 241, 0.78)",
          padding: "22px 48px",
          borderRadius: 24,
          border: `1px solid ${COLORS.accent}40`,
          backdropFilter: "blur(14px)",
          boxShadow: "0 10px 40px rgba(169, 110, 122, 0.18)",
          maxWidth: 1600,
        }}
      >
        <div
          style={{
            fontFamily: interFamily,
            fontSize: 46,
            fontWeight: 700,
            color: COLORS.foreground,
            textAlign: "center",
            lineHeight: 1.25,
          }}
        >
          {windowWords.map((w, i) => {
            const cleaned = w.text
              .toLowerCase()
              .trim()
              .replace(/[^a-z0-9\-']/g, "");
            const isKeyword = keywordSet.has(cleaned);
            const isActive = ms >= w.startMs && ms <= w.endMs + 150;

            const scale = isActive ? 1.08 : 1.0;
            const opacity = isActive ? 1.0 : 0.72;
            const color = isKeyword
              ? COLORS.primaryDark
              : COLORS.foreground;

            return (
              <span
                key={`${windowStart}-${i}`}
                style={{
                  display: "inline-block",
                  transform: `scale(${scale})`,
                  opacity,
                  color,
                  transition: "transform 80ms linear, opacity 80ms linear",
                  marginRight: 6,
                  fontWeight: isKeyword ? 800 : 700,
                }}
              >
                {w.text}
              </span>
            );
          })}
        </div>
      </div>
    </div>
  );
};

// ─── Transitions ─────────────────────────────────────────────────────
const SceneFade: React.FC<{
  frame: number;
  durationInFrames: number;
}> = ({ frame, durationInFrames }) => {
  const fadeIn = interpolate(frame, [0, 14], [1, 0], {
    extrapolateRight: "clamp",
  });
  const fadeOut = interpolate(
    frame,
    [durationInFrames - 14, durationInFrames],
    [0, 1],
    {
      extrapolateLeft: "clamp",
      extrapolateRight: "clamp",
      easing: Easing.in(Easing.ease),
    }
  );
  const op = Math.max(fadeIn, fadeOut);
  if (op <= 0.001) return null;
  return (
    <AbsoluteFill
      style={{
        background: `linear-gradient(135deg, ${COLORS.cream}, ${COLORS.blushSoft})`,
        opacity: op,
        pointerEvents: "none",
      }}
    />
  );
};
