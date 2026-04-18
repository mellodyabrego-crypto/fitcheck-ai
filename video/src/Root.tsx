import React from "react";
import { Composition } from "remotion";
import { LongFormFashionHistory, TOTAL_FRAMES, FPS } from "./LongFormFashionHistory";

export const RemotionRoot: React.FC = () => {
  return (
    <>
      <Composition
        id="LongFormFashionHistory"
        component={LongFormFashionHistory}
        durationInFrames={TOTAL_FRAMES}
        fps={FPS}
        width={1920}
        height={1080}
      />
    </>
  );
};
