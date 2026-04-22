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

// ─── Scene definitions ────────────────────────────────────────────────
type SceneDef = {
  id: string;
  seconds: number;
  chapter: string;
  era: string;
  palette: keyof typeof GRADIENTS;
  audio: string;
  keywords: string[];
  render: "prehistory" | "ancient" | "power" | "couture" | "modern" | "cta";
};

const SCENES: SceneDef[] = [
  {
    id: "scene1",
    seconds: 9.0,
    chapter: "Chapter I",
    era: "c. 25,000 BCE",
    palette: "cream",
    audio: "audio/fashion-history/fashion-history-scene1.mp3",
    keywords: ["Fashion", "bone", "needle", "hide", "ancestor"],
    render: "prehistory",
  },
  {
    id: "scene2",
    seconds: 13.0,
    chapter: "Chapter II",
    era: "Ancient World",
    palette: "petal",
    audio: "audio/fashion-history/fashion-history-scene2.mp3",
    keywords: ["Linen", "silk", "wool", "Egypt", "China", "Mesopotamia", "identity"],
    render: "ancient",
  },
  {
    id: "scene3",
    seconds: 12.0,
    chapter: "Chapter III",
    era: "Antiquity → Medieval",
    palette: "rose",
    audio: "audio/fashion-history/fashion-history-scene3.mp3",
    keywords: ["togas", "status", "Medieval", "laws", "Kings", "velvet", "resume"],
    render: "power",
  },
  {
    id: "scene4",
    seconds: 13.5,
    chapter: "Chapter IV",
    era: "1858 · Paris",
    palette: "gold",
    audio: "audio/fashion-history/fashion-history-scene4.mp3",
    keywords: ["Charles", "Worth", "Paris", "fashion", "seasonal", "Runways"],
    render: "couture",
  },
  {
    id: "scene5",
    seconds: 13.0,
    chapter: "Chapter V",
    era: "20th c. → Today",
    palette: "blush",
    audio: "audio/fashion-history/fashion-history-scene5.mp3",
    keywords: ["ready-to-wear", "Sewing", "Magazines", "Instagram", "conversation"],
    render: "modern",
  },
  {
    id: "scene6",
    seconds: 11.5,
    chapter: "The Next Chapter",
    era: "Today",
    palette: "chapter",
    audio: "audio/fashion-history/fashion-history-scene6.mp3",
    keywords: ["Her", "Style", "Co", "closet", "stylist", "outfit", "today"],
    render: "cta",
  },
];

export const TOTAL_FRAMES = Math.ceil(
  SCENES.reduce((s, sc) => s + sc.seconds, 0) * FPS
);

type CaptionWord = {
  text: string;
  startMs: number;
  endMs: number;
  sceneId: string;
};
const ALL_CAPTIONS = (captionsJson as any).remotion.captions as CaptionWord[];
const captionsByScene = (sceneId: string) =>
  ALL_CAPTIONS.filter((c) => c.sceneId === sceneId);

// ─── Root composition ────────────────────────────────────────────────
export const LongFormFashionHistory: React.FC = () => (
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

// ─── Scene shell ─────────────────────────────────────────────────────
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
      <DecorativeLayer seed={index} variant={scene.render} />

      {/* Scene-specific content */}
      {scene.render === "prehistory" && <Scene1Prehistory />}
      {scene.render === "ancient" && <Scene2Ancient />}
      {scene.render === "power" && <Scene3Power />}
      {scene.render === "couture" && <Scene4Couture />}
      {scene.render === "modern" && <Scene5Modern />}
      {scene.render === "cta" && <Scene6CTA />}

      <EraBadge era={scene.era} chapter={scene.chapter} />
      <ProgressDots index={index} total={total} />
      <MinimalCaptions
        captions={captionsByScene(scene.id)}
        keywords={scene.keywords}
      />
      <SceneFade frame={frame} durationInFrames={durationInFrames} />
    </AbsoluteFill>
  );
};

// ═══════════════════════════════════════════════════════════════════
// Scene 1 — Prehistory: "It began with a needle."
// ═══════════════════════════════════════════════════════════════════
const Scene1Prehistory: React.FC = () => (
  <div
    style={{
      position: "absolute",
      top: 180,
      left: SAFE.left,
      right: SAFE.right,
      bottom: 220,
      display: "flex",
      alignItems: "center",
      justifyContent: "center",
      gap: 100,
    }}
  >
    <FadeInUp delay={0.2} distance={40}>
      <NeedleIllustration />
    </FadeInUp>

    <div style={{ display: "flex", flexDirection: "column", gap: 16, maxWidth: 820 }}>
      <FadeInUp delay={0}>
        <DateCallout date="25,000" unit="Years Ago" />
      </FadeInUp>
      <FadeInUp delay={0.35}>
        <Headline text="It began with a needle." />
      </FadeInUp>
      <FadeInUp delay={0.7}>
        <BulletList
          items={["The first tool", "The first garment", "The first idea of style"]}
        />
      </FadeInUp>
    </div>
  </div>
);

// ═══════════════════════════════════════════════════════════════════
// Scene 2 — Ancient World: "Threads became identity."
// ═══════════════════════════════════════════════════════════════════
const Scene2Ancient: React.FC = () => (
  <div
    style={{
      position: "absolute",
      top: 180,
      left: SAFE.left,
      right: SAFE.right,
      bottom: 220,
      display: "flex",
      flexDirection: "column",
      alignItems: "center",
      justifyContent: "flex-start",
      gap: 36,
    }}
  >
    <FadeInUp delay={0}>
      <Headline text="Threads became identity." />
    </FadeInUp>
    <FadeInUp delay={0.25}>
      <Subhead text="Three civilizations. Three fibers. One universal language." />
    </FadeInUp>

    <div
      style={{
        marginTop: 24,
        display: "flex",
        gap: 40,
        alignItems: "stretch",
        justifyContent: "center",
      }}
    >
      <FabricCard delay={0.55} place="Egypt" fiber="Linen" color={COLORS.beige} />
      <FabricCard delay={0.75} place="China" fiber="Silk" color={COLORS.blushSoft} />
      <FabricCard delay={0.95} place="Mesopotamia" fiber="Wool" color={COLORS.accentAlt} />
    </div>
  </div>
);

const FabricCard: React.FC<{
  delay: number;
  place: string;
  fiber: string;
  color: string;
}> = ({ delay, place, fiber, color }) => (
  <FadeInUp delay={delay} distance={30}>
    <div
      style={{
        width: 340,
        padding: "36px 28px",
        borderRadius: 28,
        background: "rgba(255, 248, 241, 0.75)",
        border: `1.5px solid ${COLORS.accent}60`,
        boxShadow: "0 14px 36px rgba(169, 110, 122, 0.15)",
        backdropFilter: "blur(10px)",
        textAlign: "center",
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        gap: 14,
      }}
    >
      <SpoolIllustration color={color} />
      <div
        style={{
          fontFamily: interFamily,
          fontSize: 22,
          fontWeight: 700,
          color: COLORS.accent,
          letterSpacing: "0.25em",
          textTransform: "uppercase",
        }}
      >
        {place}
      </div>
      <div
        style={{
          fontFamily: dancingFamily,
          fontSize: 72,
          fontWeight: 700,
          color: COLORS.primaryDark,
          lineHeight: 1,
        }}
      >
        {fiber}
      </div>
    </div>
  </FadeInUp>
);

// ═══════════════════════════════════════════════════════════════════
// Scene 3 — Fashion as Power
// ═══════════════════════════════════════════════════════════════════
const Scene3Power: React.FC = () => (
  <div
    style={{
      position: "absolute",
      top: 180,
      left: SAFE.left,
      right: SAFE.right,
      bottom: 220,
      display: "flex",
      alignItems: "center",
      justifyContent: "center",
      gap: 80,
    }}
  >
    <FadeInUp delay={0.15} distance={40}>
      <CrownIllustration />
    </FadeInUp>

    <div style={{ display: "flex", flexDirection: "column", gap: 24, maxWidth: 900 }}>
      <FadeInUp delay={0}>
        <Headline text="Clothes meant power." />
      </FadeInUp>
      <FadeInUp delay={0.25}>
        <Subhead text="For two thousand years, your outfit was your rank." />
      </FadeInUp>
      <div style={{ marginTop: 12 }}>
        <StatusRow delay={0.55} label="TOGA" meaning="Roman citizenship" />
        <StatusRow delay={0.85} label="SUMPTUARY LAWS" meaning="What peasants couldn't wear" />
        <StatusRow delay={1.15} label="VELVET" meaning="Reserved for kings" />
      </div>
    </div>
  </div>
);

const StatusRow: React.FC<{ delay: number; label: string; meaning: string }> = ({
  delay,
  label,
  meaning,
}) => (
  <FadeInUp delay={delay} distance={20}>
    <div
      style={{
        display: "flex",
        alignItems: "center",
        gap: 20,
        padding: "14px 0",
        borderBottom: `1px solid ${COLORS.accent}40`,
      }}
    >
      <span
        style={{
          fontFamily: interFamily,
          fontSize: 24,
          fontWeight: 800,
          color: COLORS.primaryDark,
          letterSpacing: "0.18em",
          minWidth: 300,
        }}
      >
        {label}
      </span>
      <span
        style={{
          fontFamily: interFamily,
          fontSize: 30,
          fontWeight: 400,
          color: COLORS.foreground,
          fontStyle: "italic",
        }}
      >
        — {meaning}
      </span>
    </div>
  </FadeInUp>
);

// ═══════════════════════════════════════════════════════════════════
// Scene 4 — Paris 1858 · Couture is born
// ═══════════════════════════════════════════════════════════════════
const Scene4Couture: React.FC = () => (
  <div
    style={{
      position: "absolute",
      top: 180,
      left: SAFE.left,
      right: SAFE.right,
      bottom: 220,
      display: "flex",
      flexDirection: "column",
      alignItems: "center",
      justifyContent: "flex-start",
    }}
  >
    <FadeInUp delay={0}>
      <div
        style={{
          fontFamily: dancingFamily,
          fontSize: 280,
          fontWeight: 700,
          lineHeight: 1.0,
          background: `linear-gradient(135deg, ${COLORS.accent} 0%, ${COLORS.primaryDark} 100%)`,
          WebkitBackgroundClip: "text",
          backgroundClip: "text",
          color: "transparent",
          letterSpacing: "-0.02em",
          filter: "drop-shadow(0 8px 24px rgba(184, 154, 93, 0.3))",
        }}
      >
        1858
      </div>
    </FadeInUp>
    <FadeInUp delay={0.3}>
      <div
        style={{
          fontFamily: interFamily,
          fontSize: 28,
          fontWeight: 700,
          color: COLORS.accent,
          letterSpacing: "0.35em",
          textTransform: "uppercase",
          marginTop: -10,
          marginBottom: 16,
        }}
      >
        Paris · Charles Frederick Worth
      </div>
    </FadeInUp>
    <FadeInUp delay={0.55}>
      <Headline text="Couture is born." />
    </FadeInUp>

    <div style={{ display: "flex", gap: 48, marginTop: 28, alignItems: "center" }}>
      <TimelineStep delay={0.85} year="1858" label="First fashion house" />
      <Connector delay={1.0} />
      <TimelineStep delay={1.15} year="1860s" label="Seasonal collections" />
      <Connector delay={1.3} />
      <TimelineStep delay={1.45} year="1900s" label="Runway shows" />
    </div>
  </div>
);

const TimelineStep: React.FC<{ delay: number; year: string; label: string }> = ({
  delay,
  year,
  label,
}) => (
  <FadeInUp delay={delay} distance={20}>
    <div style={{ textAlign: "center", minWidth: 220 }}>
      <div
        style={{
          fontFamily: dancingFamily,
          fontSize: 56,
          fontWeight: 700,
          color: COLORS.primaryDark,
          lineHeight: 1,
        }}
      >
        {year}
      </div>
      <div
        style={{
          marginTop: 8,
          fontFamily: interFamily,
          fontSize: 22,
          fontWeight: 500,
          color: COLORS.foreground,
          letterSpacing: "0.02em",
        }}
      >
        {label}
      </div>
    </div>
  </FadeInUp>
);

const Connector: React.FC<{ delay: number }> = ({ delay }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const p = spring({
    frame: frame - delay * fps,
    fps,
    config: { damping: 20, stiffness: 80 },
    durationInFrames: 30,
  });
  return (
    <div
      style={{
        width: 80 * p,
        height: 2,
        background: COLORS.accent,
        opacity: 0.6,
      }}
    />
  );
};

// ═══════════════════════════════════════════════════════════════════
// Scene 5 — Modern: Style goes public
// ═══════════════════════════════════════════════════════════════════
const Scene5Modern: React.FC = () => (
  <div
    style={{
      position: "absolute",
      top: 180,
      left: SAFE.left,
      right: SAFE.right,
      bottom: 220,
      display: "flex",
      flexDirection: "column",
      alignItems: "center",
      justifyContent: "flex-start",
      gap: 28,
    }}
  >
    <FadeInUp delay={0}>
      <Headline text="Style goes public." />
    </FadeInUp>
    <FadeInUp delay={0.25}>
      <Subhead text="Three revolutions made fashion a conversation." />
    </FadeInUp>

    <div
      style={{
        display: "flex",
        gap: 24,
        marginTop: 24,
        alignItems: "stretch",
        justifyContent: "center",
      }}
    >
      <ModernCard
        delay={0.55}
        era="1850s"
        icon={<SewingMachineIcon />}
        title="Sewing Machines"
        desc="Clothes become affordable."
      />
      <Arrow delay={0.75} />
      <ModernCard
        delay={0.85}
        era="1900s"
        icon={<MagazineIcon />}
        title="Magazines"
        desc="Style travels the world."
      />
      <Arrow delay={1.05} />
      <ModernCard
        delay={1.15}
        era="2010s"
        icon={<PhoneIcon />}
        title="Instagram"
        desc="Everyone's a designer."
      />
    </div>
  </div>
);

const ModernCard: React.FC<{
  delay: number;
  era: string;
  icon: React.ReactNode;
  title: string;
  desc: string;
}> = ({ delay, era, icon, title, desc }) => (
  <FadeInUp delay={delay} distance={30}>
    <div
      style={{
        width: 300,
        padding: "28px 22px",
        borderRadius: 24,
        background: "rgba(255, 248, 241, 0.8)",
        border: `1.5px solid ${COLORS.primary}50`,
        boxShadow: "0 10px 28px rgba(169, 110, 122, 0.15)",
        backdropFilter: "blur(10px)",
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        gap: 12,
      }}
    >
      <div
        style={{
          fontFamily: interFamily,
          fontSize: 18,
          fontWeight: 700,
          color: COLORS.accent,
          letterSpacing: "0.3em",
          textTransform: "uppercase",
        }}
      >
        {era}
      </div>
      <div style={{ width: 90, height: 90, display: "flex", alignItems: "center", justifyContent: "center" }}>{icon}</div>
      <div
        style={{
          fontFamily: dancingFamily,
          fontSize: 44,
          fontWeight: 700,
          color: COLORS.primaryDark,
          textAlign: "center",
          lineHeight: 1,
        }}
      >
        {title}
      </div>
      <div
        style={{
          fontFamily: interFamily,
          fontSize: 20,
          fontWeight: 500,
          color: COLORS.foreground,
          textAlign: "center",
          marginTop: 4,
        }}
      >
        {desc}
      </div>
    </div>
  </FadeInUp>
);

const Arrow: React.FC<{ delay: number }> = ({ delay }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const p = spring({
    frame: frame - delay * fps,
    fps,
    config: { damping: 20, stiffness: 90 },
  });
  return (
    <div
      style={{
        alignSelf: "center",
        fontSize: 48,
        color: COLORS.accent,
        opacity: p,
        transform: `translateX(${interpolate(p, [0, 1], [-20, 0])}px)`,
      }}
    >
      →
    </div>
  );
};

// ═══════════════════════════════════════════════════════════════════
// Scene 6 — CTA: Her Style Co.
// ═══════════════════════════════════════════════════════════════════
const Scene6CTA: React.FC = () => (
  <div
    style={{
      position: "absolute",
      top: 160,
      left: SAFE.left,
      right: SAFE.right,
      bottom: 220,
      display: "flex",
      flexDirection: "column",
      alignItems: "center",
      justifyContent: "flex-start",
      gap: 24,
    }}
  >
    <FadeInUp delay={0} distance={40}>
      <div
        style={{
          fontFamily: pacificoFamily,
          fontSize: 180,
          lineHeight: 1.0,
          background: `linear-gradient(135deg, ${COLORS.primary} 0%, ${COLORS.primaryDark} 45%, ${COLORS.accent} 100%)`,
          WebkitBackgroundClip: "text",
          backgroundClip: "text",
          color: "transparent",
          fontWeight: 400,
          letterSpacing: "-0.015em",
          filter: "drop-shadow(0 6px 18px rgba(169, 110, 122, 0.3))",
        }}
      >
        Her Style Co.
      </div>
    </FadeInUp>
    <FadeInUp delay={0.25}>
      <div
        style={{
          fontFamily: interFamily,
          fontSize: 36,
          fontWeight: 500,
          color: COLORS.foreground,
          letterSpacing: "0.04em",
        }}
      >
        Your personal <span style={{ color: COLORS.accent, fontWeight: 700 }}>AI stylist</span>.
      </div>
    </FadeInUp>

    <div
      style={{
        marginTop: 32,
        display: "flex",
        gap: 48,
        alignItems: "flex-start",
      }}
    >
      <StepCard delay={0.55} num="01" title="Upload" desc="Your closet" />
      <StepCard delay={0.8} num="02" title="Style" desc="AI builds the outfit" />
      <StepCard delay={1.05} num="03" title="Wear" desc="Save your looks" />
    </div>
  </div>
);

const StepCard: React.FC<{
  delay: number;
  num: string;
  title: string;
  desc: string;
}> = ({ delay, num, title, desc }) => (
  <FadeInUp delay={delay} distance={24}>
    <div
      style={{
        textAlign: "center",
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        gap: 10,
        minWidth: 260,
      }}
    >
      <div
        style={{
          width: 88,
          height: 88,
          borderRadius: "50%",
          background: `linear-gradient(135deg, ${COLORS.primary} 0%, ${COLORS.primaryDark} 100%)`,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          fontFamily: interFamily,
          fontSize: 34,
          fontWeight: 800,
          color: "#fff",
          letterSpacing: "0.02em",
          boxShadow: "0 8px 20px rgba(169, 110, 122, 0.35)",
        }}
      >
        {num}
      </div>
      <div
        style={{
          fontFamily: dancingFamily,
          fontSize: 54,
          fontWeight: 700,
          color: COLORS.primaryDark,
          lineHeight: 1,
        }}
      >
        {title}
      </div>
      <div
        style={{
          fontFamily: interFamily,
          fontSize: 22,
          fontWeight: 500,
          color: COLORS.foreground,
        }}
      >
        {desc}
      </div>
    </div>
  </FadeInUp>
);

// ═══════════════════════════════════════════════════════════════════
// Shared Atoms
// ═══════════════════════════════════════════════════════════════════
const FadeInUp: React.FC<{
  children: React.ReactNode;
  delay?: number;
  distance?: number;
}> = ({ children, delay = 0, distance = 20 }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const p = spring({
    frame: frame - delay * fps,
    fps,
    config: { damping: 20, stiffness: 85 },
  });
  return (
    <div
      style={{
        opacity: p,
        transform: `translateY(${interpolate(p, [0, 1], [distance, 0])}px)`,
      }}
    >
      {children}
    </div>
  );
};

const Headline: React.FC<{ text: string }> = ({ text }) => (
  <div
    style={{
      fontFamily: dancingFamily,
      fontSize: 110,
      fontWeight: 700,
      color: COLORS.foreground,
      lineHeight: 1.05,
      letterSpacing: "-0.01em",
      textShadow: "0 2px 14px rgba(255, 245, 238, 0.7)",
    }}
  >
    {text}
  </div>
);

const Subhead: React.FC<{ text: string }> = ({ text }) => (
  <div
    style={{
      fontFamily: interFamily,
      fontSize: 32,
      fontWeight: 500,
      color: COLORS.primaryDark,
      letterSpacing: "0.03em",
      textAlign: "center",
    }}
  >
    {text}
  </div>
);

const DateCallout: React.FC<{ date: string; unit: string }> = ({ date, unit }) => (
  <div style={{ display: "flex", alignItems: "baseline", gap: 16 }}>
    <span
      style={{
        fontFamily: dancingFamily,
        fontSize: 150,
        fontWeight: 700,
        background: `linear-gradient(135deg, ${COLORS.accent} 0%, ${COLORS.primaryDark} 100%)`,
        WebkitBackgroundClip: "text",
        backgroundClip: "text",
        color: "transparent",
        lineHeight: 1,
      }}
    >
      {date}
    </span>
    <span
      style={{
        fontFamily: interFamily,
        fontSize: 26,
        fontWeight: 700,
        color: COLORS.accent,
        letterSpacing: "0.3em",
        textTransform: "uppercase",
      }}
    >
      {unit}
    </span>
  </div>
);

const BulletList: React.FC<{ items: string[] }> = ({ items }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 12, marginTop: 10 }}>
      {items.map((item, i) => {
        const p = spring({
          frame: frame - (0.9 + i * 0.18) * fps,
          fps,
          config: { damping: 20, stiffness: 85 },
        });
        return (
          <div
            key={i}
            style={{
              display: "flex",
              alignItems: "center",
              gap: 16,
              opacity: p,
              transform: `translateX(${interpolate(p, [0, 1], [-30, 0])}px)`,
            }}
          >
            <div
              style={{
                width: 14,
                height: 14,
                borderRadius: "50%",
                background: `linear-gradient(135deg, ${COLORS.primary}, ${COLORS.accent})`,
                flexShrink: 0,
              }}
            />
            <span
              style={{
                fontFamily: interFamily,
                fontSize: 32,
                fontWeight: 500,
                color: COLORS.foreground,
              }}
            >
              {item}
            </span>
          </div>
        );
      })}
    </div>
  );
};

// ─── SVG Illustrations ──────────────────────────────────────────────
const NeedleIllustration: React.FC = () => {
  const frame = useCurrentFrame();
  const rot = Math.sin(frame / 40) * 3 - 25;
  return (
    <svg width={300} height={360} viewBox="0 0 300 360" style={{ overflow: "visible" }}>
      <g transform={`rotate(${rot} 150 180)`}>
        {/* Thread trail */}
        <path
          d="M 220 250 Q 160 290 120 260 T 80 300 Q 50 320 40 340"
          fill="none"
          stroke={COLORS.primary}
          strokeWidth={3}
          strokeLinecap="round"
          strokeDasharray="3 8"
          opacity={0.7}
        />
        {/* Bone shaft */}
        <path
          d="M 100 150 L 220 250"
          stroke={COLORS.beigeDeep}
          strokeWidth={16}
          strokeLinecap="round"
        />
        <path
          d="M 100 150 L 220 250"
          stroke={COLORS.surface}
          strokeWidth={6}
          strokeLinecap="round"
        />
        {/* Eye of needle */}
        <circle cx={96} cy={146} r={18} fill="none" stroke={COLORS.beigeDeep} strokeWidth={5} />
        <circle cx={96} cy={146} r={18} fill={COLORS.cream} />
        {/* Tip */}
        <circle cx={222} cy={252} r={6} fill={COLORS.primaryDark} />
        {/* Gold accent */}
        <circle cx={96} cy={146} r={22} fill="none" stroke={COLORS.accent} strokeWidth={1.5} opacity={0.5} />
      </g>
    </svg>
  );
};

const SpoolIllustration: React.FC<{ color: string }> = ({ color }) => (
  <svg width={120} height={120} viewBox="0 0 120 120">
    {/* Spool wood */}
    <rect x={16} y={28} width={88} height={14} rx={3} fill={COLORS.beigeDeep} />
    <rect x={16} y={78} width={88} height={14} rx={3} fill={COLORS.beigeDeep} />
    {/* Thread body */}
    <rect x={28} y={40} width={64} height={40} rx={4} fill={color} />
    {/* Thread lines */}
    {Array.from({ length: 6 }).map((_, i) => (
      <line
        key={i}
        x1={30}
        x2={90}
        y1={44 + i * 6}
        y2={44 + i * 6}
        stroke="rgba(0,0,0,0.12)"
        strokeWidth={1}
      />
    ))}
    {/* Trailing thread */}
    <path
      d="M 90 60 Q 104 64 108 78"
      fill="none"
      stroke={color}
      strokeWidth={2.5}
      strokeLinecap="round"
    />
  </svg>
);

const CrownIllustration: React.FC = () => {
  const frame = useCurrentFrame();
  const glow = 0.4 + Math.sin(frame / 30) * 0.15;
  return (
    <svg width={340} height={340} viewBox="0 0 340 340" style={{ overflow: "visible" }}>
      {/* Glow halo */}
      <circle cx={170} cy={170} r={150} fill={COLORS.accent} opacity={glow * 0.12} />
      <circle cx={170} cy={170} r={115} fill={COLORS.accent} opacity={glow * 0.18} />
      {/* Crown band */}
      <rect x={70} y={205} width={200} height={42} rx={6} fill={COLORS.accent} />
      <rect x={70} y={205} width={200} height={12} fill={COLORS.accentAlt} />
      {/* Crown points */}
      <path
        d="M 70 205 L 95 110 L 130 185 L 170 90 L 210 185 L 245 110 L 270 205 Z"
        fill={COLORS.accent}
        stroke={COLORS.primaryDark}
        strokeWidth={2}
      />
      {/* Gems */}
      <circle cx={95} cy={108} r={10} fill={COLORS.primary} stroke={COLORS.cream} strokeWidth={2} />
      <circle cx={170} cy={86} r={14} fill={COLORS.primaryDark} stroke={COLORS.cream} strokeWidth={2} />
      <circle cx={245} cy={108} r={10} fill={COLORS.primary} stroke={COLORS.cream} strokeWidth={2} />
      {/* Band jewels */}
      <circle cx={110} cy={226} r={6} fill={COLORS.primaryDark} />
      <circle cx={170} cy={226} r={8} fill={COLORS.primary} />
      <circle cx={230} cy={226} r={6} fill={COLORS.primaryDark} />
    </svg>
  );
};

const SewingMachineIcon: React.FC = () => (
  <svg width={90} height={90} viewBox="0 0 90 90">
    <path d="M 15 60 L 15 35 Q 15 28 22 28 L 50 28 L 60 40 L 72 40 Q 78 40 78 46 L 78 60" fill={COLORS.primary} stroke={COLORS.primaryDark} strokeWidth={2.5} strokeLinejoin="round" />
    <rect x={10} y={58} width={72} height={12} rx={3} fill={COLORS.beigeDeep} />
    <circle cx={66} cy={48} r={3} fill={COLORS.accent} />
    <line x1={66} y1={50} x2={66} y2={58} stroke={COLORS.foreground} strokeWidth={1.5} />
    <circle cx={26} cy={38} r={4} fill={COLORS.cream} stroke={COLORS.primaryDark} strokeWidth={1.5} />
  </svg>
);

const MagazineIcon: React.FC = () => (
  <svg width={90} height={90} viewBox="0 0 90 90">
    <rect x={14} y={18} width={62} height={58} rx={3} fill={COLORS.surface} stroke={COLORS.primaryDark} strokeWidth={2} />
    <rect x={14} y={18} width={62} height={12} fill={COLORS.primary} />
    <text x={45} y={28} fontFamily="serif" fontSize={8} fontWeight={700} fill={COLORS.cream} textAnchor="middle">VOGUE</text>
    <circle cx={45} cy={50} r={12} fill={COLORS.blushSoft} />
    <rect x={22} y={65} width={46} height={3} rx={1} fill={COLORS.accent} opacity={0.7} />
    <rect x={22} y={70} width={34} height={2} rx={1} fill={COLORS.primaryDark} opacity={0.5} />
  </svg>
);

const PhoneIcon: React.FC = () => (
  <svg width={90} height={90} viewBox="0 0 90 90">
    <rect x={28} y={12} width={34} height={66} rx={6} fill={COLORS.primaryDark} />
    <rect x={31} y={18} width={28} height={52} rx={2} fill={COLORS.cream} />
    {/* Heart/sparkle icons */}
    <path d="M 45 32 C 41 28, 35 30, 38 36 C 39 38, 45 44, 45 44 C 45 44, 51 38, 52 36 C 55 30, 49 28, 45 32 Z" fill={COLORS.primary} />
    <circle cx={37} cy={52} r={2.5} fill={COLORS.accent} />
    <circle cx={45} cy={52} r={2.5} fill={COLORS.primary} />
    <circle cx={53} cy={52} r={2.5} fill={COLORS.accent} />
    <rect x={35} y={58} width={20} height={2} rx={1} fill={COLORS.primaryDark} opacity={0.5} />
    <rect x={35} y={63} width={16} height={2} rx={1} fill={COLORS.primaryDark} opacity={0.3} />
    {/* Home button */}
    <circle cx={45} cy={74} r={2} fill={COLORS.cream} />
  </svg>
);

// ─── Chrome: background, decorative, badges, captions ────────────────
const SoftGradient: React.FC<{ palette: keyof typeof GRADIENTS }> = ({ palette }) => {
  const frame = useCurrentFrame();
  const colors = GRADIENTS[palette];
  const angle = 140 + Math.sin(frame / 50) * 10;
  return (
    <AbsoluteFill
      style={{
        background: `linear-gradient(${angle}deg, ${colors.join(", ")})`,
      }}
    >
      <AbsoluteFill
        style={{
          background: `radial-gradient(ellipse at ${
            50 + Math.sin(frame / 70) * 8
          }% ${40 + Math.cos(frame / 85) * 8}%, rgba(255, 255, 255, 0.3), transparent 60%)`,
        }}
      />
      <AbsoluteFill
        style={{
          backgroundImage:
            "radial-gradient(rgba(255,255,255,0.04) 1px, transparent 1px)",
          backgroundSize: "3px 3px",
          mixBlendMode: "overlay",
        }}
      />
    </AbsoluteFill>
  );
};

const seeded = (seed: number, i: number, mod: number) =>
  Math.abs((seed * 131 + i * 997 + 17) * 1103515245) % mod;

const DecorativeLayer: React.FC<{
  seed: number;
  variant: SceneDef["render"];
}> = ({ seed, variant }) => {
  const frame = useCurrentFrame();
  const sparkles = React.useMemo(
    () =>
      Array.from({ length: 16 }).map((_, i) => ({
        x: seeded(seed + 1, i, 1800) + 60,
        y: seeded(seed + 2, i, 900) + 100,
        delay: seeded(seed + 3, i, 90),
        size: 6 + (seeded(seed + 4, i, 12) as number),
      })),
    [seed]
  );
  return (
    <AbsoluteFill style={{ pointerEvents: "none" }}>
      {sparkles.map((s, i) => {
        const progress = ((frame - s.delay) % 120) / 120;
        const op = Math.sin(progress * Math.PI) * 0.45;
        return (
          <div
            key={i}
            style={{
              position: "absolute",
              left: s.x,
              top: s.y,
              width: s.size,
              height: s.size,
              borderRadius: "50%",
              background: `radial-gradient(circle, ${COLORS.accent} 0%, ${COLORS.accentAlt} 50%, transparent 75%)`,
              opacity: op,
              filter: `blur(${s.size / 4}px)`,
            }}
          />
        );
      })}
      {/* Subtle flourish arc */}
      <svg
        width={1920}
        height={1080}
        style={{ position: "absolute", inset: 0, opacity: 0.25 }}
      >
        <path
          d={
            seed % 2 === 0
              ? "M -50 900 Q 480 760 960 880 T 1970 780"
              : "M -50 200 Q 480 340 960 220 T 1970 320"
          }
          fill="none"
          stroke={COLORS.accent}
          strokeWidth={1.8}
          strokeLinecap="round"
        />
      </svg>
    </AbsoluteFill>
  );
};

const EraBadge: React.FC<{ era: string; chapter: string }> = ({ era, chapter }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const intro = spring({ frame: frame - 8, fps, config: { damping: 200 } });
  return (
    <div
      style={{
        position: "absolute",
        top: 72,
        right: 80,
        opacity: intro,
        transform: `translateY(${interpolate(intro, [0, 1], [-18, 0])}px)`,
        display: "flex",
        flexDirection: "column",
        alignItems: "flex-end",
        gap: 6,
      }}
    >
      <div
        style={{
          fontFamily: interFamily,
          fontSize: 14,
          fontWeight: 700,
          color: COLORS.accent,
          letterSpacing: "0.3em",
          textTransform: "uppercase",
        }}
      >
        {chapter}
      </div>
      <div
        style={{
          padding: "10px 22px",
          background: "rgba(255, 248, 241, 0.85)",
          border: `1.5px solid ${COLORS.accent}`,
          borderRadius: 999,
          fontFamily: interFamily,
          fontSize: 18,
          fontWeight: 600,
          color: COLORS.primaryDark,
          letterSpacing: "0.12em",
          textTransform: "uppercase",
          boxShadow: "0 6px 18px rgba(169, 110, 122, 0.15)",
          backdropFilter: "blur(8px)",
        }}
      >
        {era}
      </div>
    </div>
  );
};

const ProgressDots: React.FC<{ index: number; total: number }> = ({
  index,
  total,
}) => (
  <div
    style={{
      position: "absolute",
      top: 92,
      left: 80,
      display: "flex",
      gap: 12,
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
            width: active ? 40 : 10,
            height: 10,
            borderRadius: 999,
            background: active
              ? COLORS.primary
              : done
              ? COLORS.primaryLight
              : "rgba(196, 138, 150, 0.25)",
            boxShadow: active ? `0 0 10px ${COLORS.primary}55` : "none",
          }}
        />
      );
    })}
  </div>
);

const MinimalCaptions: React.FC<{
  captions: CaptionWord[];
  keywords: string[];
}> = ({ captions, keywords }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const ms = (frame / fps) * 1000;

  const activeIdx = captions.findIndex(
    (c) => ms >= c.startMs && ms <= c.endMs + 120
  );
  const idx =
    activeIdx === -1
      ? captions.findIndex((c) => c.startMs > ms) - 1
      : activeIdx;
  const start = Math.max(0, Math.min(captions.length - 10, (idx < 0 ? 0 : idx) - 3));
  const window = captions.slice(start, start + 10);

  const kwSet = new Set(
    keywords.map((k) => k.toLowerCase().replace(/[^a-z0-9\-']/g, ""))
  );

  return (
    <div
      style={{
        position: "absolute",
        left: 0,
        right: 0,
        bottom: 80,
        display: "flex",
        justifyContent: "center",
        padding: "0 120px",
      }}
    >
      <div
        style={{
          fontFamily: interFamily,
          fontSize: 26,
          fontWeight: 600,
          color: COLORS.muted,
          textAlign: "center",
          maxWidth: 1500,
          lineHeight: 1.3,
          letterSpacing: "0.01em",
        }}
      >
        {window.map((w, i) => {
          const cleaned = w.text.toLowerCase().trim().replace(/[^a-z0-9\-']/g, "");
          const isKeyword = kwSet.has(cleaned);
          const isActive = ms >= w.startMs && ms <= w.endMs + 120;
          return (
            <span
              key={`${start}-${i}`}
              style={{
                color: isKeyword ? COLORS.primaryDark : isActive ? COLORS.foreground : COLORS.muted,
                opacity: isActive ? 1 : 0.7,
                fontWeight: isKeyword ? 800 : isActive ? 700 : 600,
                marginRight: 5,
              }}
            >
              {w.text}
            </span>
          );
        })}
      </div>
    </div>
  );
};

const SceneFade: React.FC<{ frame: number; durationInFrames: number }> = ({
  frame,
  durationInFrames,
}) => {
  const fadeIn = interpolate(frame, [0, 14], [1, 0], { extrapolateRight: "clamp" });
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
